import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'notification_service.dart';

class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._();
  GoogleDriveService._();

  static const _backupFileName = 'yakit_yonet_backup.db';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? _user;
  GoogleSignInAccount? get currentUser => _user;
  Stream<GoogleSignInAccount?> get onUserChanged => _googleSignIn.onCurrentUserChanged;

  Future<void> init() async {
    _user = await _googleSignIn.signInSilently();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _user = account;
    });
  }

  Future<bool> signIn() async {
    try {
      // Sadece driveAppdataScope isteniyor, .env'den almasına gerek yok
      _user = await _googleSignIn.signIn();
      return _user != null;
    } catch (e) {
      debugPrint('Sign in failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _user = null;
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    if (_user == null) {
      if (!await signIn()) return null;
    }

    final granted = await _googleSignIn.requestScopes([drive.DriveApi.driveAppdataScope]);
    if (!granted) return null;

    _user = await _googleSignIn.signInSilently();
    if (_user == null) return null;

    final headers = await _user!.authHeaders;
    final client = _GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  Future<drive.FileList> _listBackups(drive.DriveApi driveApi) {
    return driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
      orderBy: 'modifiedTime desc',
      $fields: 'files(id, modifiedTime)',
    );
  }

  Future<DateTime?> getBackupModifiedTime() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final existing = await _listBackups(driveApi);
      if (existing.files == null || existing.files!.isEmpty) return null;
      return existing.files!.first.modifiedTime?.toLocal();
    } catch (e) {
      debugPrint('Yedek bilgisi alınamadı: $e');
      return null;
    }
  }

  Future<bool> backupToDrive() async {
    File? snapshot;
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      await DatabaseHelper.instance.checkpointWal();

      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        debugPrint('Yedeklenecek veritabanı dosyası bulunamadı.');
        return false;
      }

      // Anlık görüntü al, canlı DB dosyası yerine onu yükle
      snapshot = await dbFile.copy('$dbPath.backup_snapshot');

      final existing = await _listBackups(driveApi);

      // Önce yeni dosya olarak yükle, eskiyi ancak yükleme başarılıysa sil
      final createFile = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder']
        ..mimeType = 'application/octet-stream';
      final media = drive.Media(
        snapshot.openRead(),
        await snapshot.length(),
        contentType: 'application/octet-stream',
      );
      await driveApi.files.create(createFile, uploadMedia: media);

      for (final old in existing.files ?? <drive.File>[]) {
        if (old.id == null) continue;
        try {
          await driveApi.files.delete(old.id!);
        } catch (e) {
          debugPrint('Eski yedek silinemedi: $e');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_backup_at', DateTime.now().toIso8601String());

      return true;
    } catch (e, st) {
      debugPrint('Backup error: $e\n$st');
      return false;
    } finally {
      if (snapshot != null && await snapshot.exists()) {
        try {
          await snapshot.delete();
        } catch (e) {
          debugPrint('Geçici yedek dosyası silinemedi: $e');
        }
      }
    }
  }

  Future<bool> restoreFromDrive() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return false;

    final existing = await _listBackups(driveApi);
    if (existing.files == null || existing.files!.isEmpty) {
      debugPrint('Drive üzerinde yedek dosyası bulunamadı.');
      return false;
    }

    final fileId = existing.files!.first.id!;
    final response = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final dbPath = await DatabaseHelper.instance.getDatabasePath();
    final tempFile = File('$dbPath.restore_tmp');

    try {
      await response.stream.pipe(tempFile.openWrite());

      await _validateSqliteFile(tempFile);

      await DatabaseHelper.instance.close();

      for (final suffix in ['-journal', '-wal', '-shm']) {
        final sidecar = File('$dbPath$suffix');
        if (await sidecar.exists()) await sidecar.delete();
      }

      final dbFile = File(dbPath);
      final bakFile = File('$dbPath.bak');
      var bakCreated = false;
      try {
        if (await dbFile.exists()) {
          if (await bakFile.exists()) await bakFile.delete();
          await dbFile.rename(bakFile.path);
          bakCreated = true;
        }
        await tempFile.rename(dbPath);
        if (bakCreated && await bakFile.exists()) await bakFile.delete();
      } catch (e) {
        // Herhangi bir hatada eski veritabanını geri getir
        if (bakCreated && await bakFile.exists()) {
          try {
            final broken = File(dbPath);
            if (await broken.exists()) await broken.delete();
            await bakFile.rename(dbPath);
          } catch (e2) {
            debugPrint('Eski veritabanı geri alınamadı: $e2');
          }
        }
        rethrow;
      }

      // DB'yi yeniden aç ve hatırlatıcıları yeni verilere göre kur
      await DatabaseHelper.instance.database;
      await NotificationService().cancelAll();
      await NotificationService().rescheduleAllFromDb();

      return true;
    } finally {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          debugPrint('Geçici geri yükleme dosyası silinemedi: $e');
        }
      }
    }
  }

  Future<void> _validateSqliteFile(File file) async {
    final raf = await file.open();
    List<int> header;
    try {
      header = await raf.read(16);
    } finally {
      await raf.close();
    }
    final expectedHeader = [...'SQLite format 3'.codeUnits, 0];
    if (header.length < 16 || !listEquals(header, expectedHeader)) {
      throw const FormatException('İndirilen dosya geçerli bir SQLite veritabanı değil.');
    }

    final db = await openDatabase(file.path, readOnly: true);
    try {
      final result = await db.rawQuery('PRAGMA integrity_check');
      final ok = result.isNotEmpty &&
          result.first.values.isNotEmpty &&
          result.first.values.first == 'ok';
      if (!ok) {
        throw const FormatException('Yedek dosyası bütünlük kontrolünden geçemedi.');
      }
    } finally {
      await db.close();
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
