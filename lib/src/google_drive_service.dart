import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  Future<http.Client?> _getAuthenticatedClient() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      debugPrint("Sign-in failed or was cancelled by user.");
      return null;
    }
    final headers = await account.authHeaders;
    return auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          headers['Authorization']!.substring(7),
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        _googleSignIn.scopes,
      ),
    );
  }

  Future<String?> _getOrCreateFolder(
    drive.DriveApi driveApi,
    String folderName, {
    String? parentId,
  }) async {
    String query =
        "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false";
    if (parentId != null) {
      query += " and '$parentId' in parents";
    }

    final response = await driveApi.files.list(q: query, $fields: 'files(id)');
    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id;
    } else {
      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';
      if (parentId != null) {
        folder.parents = [parentId];
      }
      final createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    }
  }

  Future<String?> uploadFile(File file) async {
    final client = await _getAuthenticatedClient();
    if (client == null) return null;

    final driveApi = drive.DriveApi(client);

    try {
      final sigesFolderId = await _getOrCreateFolder(driveApi, 'SIGES');
      if (sigesFolderId == null) return null;

      final buildingsFolderId = await _getOrCreateFolder(
        driveApi,
        'buildings',
        parentId: sigesFolderId,
      );
      if (buildingsFolderId == null) return null;

      final driveFile = drive.File()
        ..name =
            'building_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..parents = [buildingsFolderId];

      final media = drive.Media(file.openRead(), file.lengthSync());

      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
      return response.id;
    } catch (e) {
      debugPrint('Error uploading file to Google Drive: $e');
      return null;
    } finally {
      client.close();
    }
  }

  Future<void> deleteFile(String fileId) async {
    final client = await _getAuthenticatedClient();
    if (client == null) return;

    final driveApi = drive.DriveApi(client);
    try {
      await driveApi.files.delete(fileId);
      debugPrint('Successfully deleted file with ID: $fileId');
    } catch (e) {
      debugPrint('Error deleting file: $e');
    } finally {
      client.close();
    }
  }

  Future<Uint8List?> downloadFile(String fileId) async {
    final client = await _getAuthenticatedClient();
    if (client == null) return null;

    final driveApi = drive.DriveApi(client);
    try {
      final media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final stream = media.stream;
      final List<int> bytes = [];
      await for (final chunk in stream) {
        bytes.addAll(chunk);
      }
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    } finally {
      client.close();
    }
  }
}
