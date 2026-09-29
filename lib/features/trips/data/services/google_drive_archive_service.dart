import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../models/trip_cloud_archive.dart';

class GoogleDriveArchiveService {
  static const MethodChannel _driveChannel = MethodChannel(
    'com.amaterasutrip/drive',
  );

  String? _accessToken;

  bool get isAuthorized => _accessToken?.isNotEmpty == true;

  Future<GoogleDriveNativeAuthorization?> authorizeNative() async {
    try {
      final response = await _driveChannel.invokeMapMethod<String, dynamic>(
        'authorizeDrive',
      );

      if (response == null) {
        return null;
      }

      final accessToken = response['accessToken'];
      final grantedScopes = response['grantedScopes'];
      final folderId = response['folderId'];

      if (accessToken is! String || accessToken.isEmpty) {
        throw const GoogleDriveArchiveException(
          GoogleDriveArchiveError.authenticationFailed,
        );
      }

      if (folderId is! String || folderId.isEmpty) {
        throw const GoogleDriveArchiveException(
          GoogleDriveArchiveError.folderSelectionFailed,
        );
      }

      final authorization = GoogleDriveNativeAuthorization(
        accessToken: accessToken,
        grantedScopes: grantedScopes is List
            ? grantedScopes.whereType<String>().toList(growable: false)
            : const <String>[],
        folderId: folderId,
      );

      _accessToken = authorization.accessToken;

      return authorization;
    } on PlatformException catch (exception) {
      throw GoogleDriveNativeAuthorizationException(
        code: exception.code,
        message: exception.message,
      );
    }
  }

  Future<GoogleDriveNativeAuthorization?> authorizeRootNative() async {
    try {
      final response = await _driveChannel.invokeMapMethod<String, dynamic>(
        'authorizeDriveRoot',
      );

      if (response == null) {
        return null;
      }

      final accessToken = response['accessToken'];
      final grantedScopes = response['grantedScopes'];

      if (accessToken is! String || accessToken.isEmpty) {
        throw const GoogleDriveArchiveException(
          GoogleDriveArchiveError.authenticationFailed,
        );
      }

      final authorization = GoogleDriveNativeAuthorization(
        accessToken: accessToken,
        grantedScopes: grantedScopes is List
            ? grantedScopes.whereType<String>().toList(growable: false)
            : const <String>[],
        folderId: 'root',
      );

      _accessToken = authorization.accessToken;

      return authorization;
    } on PlatformException catch (exception) {
      throw GoogleDriveNativeAuthorizationException(
        code: exception.code,
        message: exception.message,
      );
    }
  }

  Future<GoogleDriveFolder?> getFolder(String folderId) async {
    if (folderId == 'root') {
      return const GoogleDriveFolder(id: 'root', name: 'My Drive');
    }

    final client = _createClient();

    try {
      final api = drive.DriveApi(client);

      final folder = await api.files.get(
        folderId,
        $fields: 'id,name,mimeType,webViewLink',
      );

      if (folder is! drive.File ||
          folder.id == null ||
          folder.name == null ||
          folder.mimeType != 'application/vnd.google-apps.folder') {
        return null;
      }

      return GoogleDriveFolder(
        id: folder.id!,
        name: folder.name!,
        webViewLink: folder.webViewLink,
      );
    } finally {
      client.close();
    }
  }

  Future<List<GoogleDriveFolder>> listFolders({
    String parentFolderId = 'root',
  }) async {
    final client = _createClient();

    try {
      final api = drive.DriveApi(client);
      final escapedParentId = _escapeQueryValue(parentFolderId);

      final result = await api.files.list(
        q:
            "'$escapedParentId' in parents "
            "and mimeType = 'application/vnd.google-apps.folder' "
            "and trashed = false",
        spaces: 'drive',
        orderBy: 'name',
        $fields: 'files(id,name,webViewLink)',
        pageSize: 100,
      );

      return (result.files ?? const <drive.File>[])
          .where((file) => file.id != null && file.name != null)
          .map(
            (file) => GoogleDriveFolder(
              id: file.id!,
              name: file.name!,
              webViewLink: file.webViewLink,
            ),
          )
          .toList(growable: false);
    } finally {
      client.close();
    }
  }

  Future<GoogleDriveFolder> createFolder({
    required String folderName,
    String parentFolderId = 'root',
  }) async {
    final normalisedName = _normaliseFolderName(folderName);
    final client = _createClient();

    try {
      final api = drive.DriveApi(client);

      final folder = drive.File()
        ..name = normalisedName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = <String>[parentFolderId];

      final created = await api.files.create(
        folder,
        $fields: 'id,name,webViewLink',
      );

      final folderId = created.id;

      if (folderId == null || folderId.isEmpty) {
        throw const GoogleDriveArchiveException(
          GoogleDriveArchiveError.folderCreationFailed,
        );
      }

      return GoogleDriveFolder(
        id: folderId,
        name: created.name ?? normalisedName,
        webViewLink: created.webViewLink,
      );
    } finally {
      client.close();
    }
  }

  Future<TripCloudArchive> createTripArchive({
    required String tripName,
    required String parentFolderId,
    String? accountEmail,
  }) async {
    final folderName = _normaliseFolderName(tripName);
    final client = _createClient();

    try {
      final api = drive.DriveApi(client);

      final folder = await _findOrCreateFolder(
        api: api,
        folderName: folderName,
        parentFolderId: parentFolderId,
      );

      final folderId = folder.id;

      if (folderId == null || folderId.isEmpty) {
        throw const GoogleDriveArchiveException(
          GoogleDriveArchiveError.folderCreationFailed,
        );
      }

      return TripCloudArchive(
        provider: TripCloudProvider.googleDrive,
        folderId: folderId,
        folderName: folder.name ?? folderName,
        folderUrl:
            folder.webViewLink ??
            'https://drive.google.com/drive/folders/$folderId',
        accountEmail: accountEmail,
      );
    } finally {
      client.close();
    }
  }

  void clearAuthorization() {
    _accessToken = null;
  }

  http.Client _createClient() {
    final accessToken = _accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw const GoogleDriveArchiveException(
        GoogleDriveArchiveError.authenticationFailed,
      );
    }

    return _GoogleDriveAuthenticatedClient(accessToken);
  }

  Future<drive.File> _findOrCreateFolder({
    required drive.DriveApi api,
    required String folderName,
    required String parentFolderId,
  }) async {
    final escapedFolderName = _escapeQueryValue(folderName);
    final escapedParentId = _escapeQueryValue(parentFolderId);

    final existing = await api.files.list(
      q:
          "name = '$escapedFolderName' "
          "and '$escapedParentId' in parents "
          "and mimeType = 'application/vnd.google-apps.folder' "
          "and trashed = false",
      spaces: 'drive',
      $fields: 'files(id,name,webViewLink)',
      pageSize: 10,
    );

    final files = existing.files ?? const <drive.File>[];

    if (files.isNotEmpty) {
      return files.first;
    }

    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = <String>[parentFolderId];

    return api.files.create(folder, $fields: 'id,name,webViewLink');
  }

  String _normaliseFolderName(String folderName) {
    final trimmed = folderName.trim();

    if (trimmed.isEmpty) {
      throw const GoogleDriveArchiveException(
        GoogleDriveArchiveError.invalidFolderName,
      );
    }

    return trimmed;
  }

  String _escapeQueryValue(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  }
}

class _GoogleDriveAuthenticatedClient extends http.BaseClient {
  _GoogleDriveAuthenticatedClient(this.accessToken);

  final String accessToken;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class GoogleDriveFolder {
  const GoogleDriveFolder({
    required this.id,
    required this.name,
    this.webViewLink,
  });

  final String id;
  final String name;
  final String? webViewLink;
}

enum GoogleDriveArchiveError {
  authorizationDenied,
  authenticationFailed,
  folderSelectionFailed,
  folderCreationFailed,
  invalidFolderName,
}

class GoogleDriveArchiveException implements Exception {
  const GoogleDriveArchiveException(this.error);

  final GoogleDriveArchiveError error;

  @override
  String toString() => 'GoogleDriveArchiveException($error)';
}

class GoogleDriveNativeAuthorization {
  const GoogleDriveNativeAuthorization({
    required this.accessToken,
    required this.grantedScopes,
    required this.folderId,
  });

  final String accessToken;
  final List<String> grantedScopes;
  final String folderId;
}

class GoogleDriveNativeAuthorizationException implements Exception {
  const GoogleDriveNativeAuthorizationException({
    required this.code,
    this.message,
  });

  final String code;
  final String? message;

  @override
  String toString() => 'GoogleDriveNativeAuthorizationException($code)';
}
