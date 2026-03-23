import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    if (!await signIn()) return null;
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
      if (!await file.exists()) return false;

      // Find if file already exists in appDataFolder
      final existingFiles = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'yakit_yonet_backup.db'",
      );

      final media = drive.Media(file.openRead(), await file.length());

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Update existing
        final fileId = existingFiles.files!.first.id!;
        final updateFile = drive.File()..name = 'yakit_yonet_backup.db';
        await driveApi.files.update(updateFile, fileId, uploadMedia: media);
      } else {
        // Create new
        final createFile = drive.File()
          ..name = 'yakit_yonet_backup.db'
          ..parents = ['appDataFolder'];
        await driveApi.files.create(createFile, uploadMedia: media);
      }

      return true;
    } catch (e) {
      print('Backup error: $e');
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

      if (existingFiles.files == null || existingFiles.files!.isEmpty) return false;

      final fileId = existingFiles.files!.first.id!;
      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final oldDbFile = File(dbPath);
      
      // Ensure directory exists
      final dir = Directory(p.dirname(dbPath));
      if (!await dir.exists()) await dir.create(recursive: true);

      // We need to close the current database before overwriting
      await DatabaseHelper.instance.close();

      final List<int> dataStore = [];
      await response.stream.forEach((data) => dataStore.addAll(data));
      final tempFile = File('$dbPath.tmp');
      await tempFile.writeAsBytes(dataStore);

      // Replace old DB
      if (await oldDbFile.exists()) await oldDbFile.delete();
      await tempFile.rename(dbPath);

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
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
