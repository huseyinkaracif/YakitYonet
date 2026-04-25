import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';

class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._();
  GoogleDriveService._();

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
      print('Sign in failed: $e');
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

  Future<bool> backupToDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final file = File(dbPath);
      if (!await file.exists()) {
        print("Backup file not found locally.");
        return false;
      }

      final existingFiles = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'yakit_yonet_backup.db'",
        $fields: 'files(id)',
      );

      drive.Media buildMedia() => drive.Media(
            file.openRead(),
            file.lengthSync(),
            contentType: 'application/octet-stream',
          );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        final fileId = existingFiles.files!.first.id!;
        await driveApi.files.update(drive.File(), fileId, uploadMedia: buildMedia());
      } else {
        final createFile = drive.File()
          ..name = 'yakit_yonet_backup.db'
          ..parents = ['appDataFolder']
          ..mimeType = 'application/octet-stream';
        await driveApi.files.create(createFile, uploadMedia: buildMedia());
      }

      return true;
    } catch (e, st) {
      print('Backup error: $e\n$st');
      return false;
    }
  }

  Future<bool> restoreFromDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final existingFiles = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'yakit_yonet_backup.db'",
      );

      if (existingFiles.files == null || existingFiles.files!.isEmpty) {
        print("No backup file found on Drive.");
        return false;
      }

      final fileId = existingFiles.files!.first.id!;
      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final oldDbFile = File(dbPath);

      final dir = Directory(p.dirname(dbPath));
      if (!await dir.exists()) await dir.create(recursive: true);

      await DatabaseHelper.instance.close();

      final tempFile = File('$dbPath.tmp');
      final List<int> bytes = [];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }
      await tempFile.writeAsBytes(bytes);

      // Replace old DB
      if (await oldDbFile.exists()) await oldDbFile.delete();
      await tempFile.rename(dbPath);
      
      // Re-init database
      await DatabaseHelper.instance.database;

      return true;
    } catch (e) {
      print('Restore error: $e');
      return false;
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
