import 'package:flutter/services.dart';

import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';
import 'package:amaterasutrip/features/trips/data/services/google_drive_archive_service.dart';

enum TripArchiveStatus {
  available,
  unchecked,
  authorizationRequired,
  inaccessible,
  notFound,
  insufficientSpace,
  networkUnavailable,
  error,
}

class TripArchiveVerificationResult {
  const TripArchiveVerificationResult({
    required this.status,
    this.folderName,
    this.folderUrl,
  });

  final TripArchiveStatus status;
  final String? folderName;
  final String? folderUrl;
}

class TripArchiveManagementService {
  TripArchiveManagementService(this._googleDriveService);

  static const MethodChannel _driveChannel = MethodChannel(
    'com.amaterasutrip/drive',
  );

  final GoogleDriveArchiveService _googleDriveService;

  Future<TripArchiveVerificationResult> verify(TripCloudArchive archive) async {
    switch (archive.provider) {
      case TripCloudProvider.googleDrive:
        final result = await _googleDriveService.verifyArchive(
          archive.folderId,
        );

        return TripArchiveVerificationResult(
          status: switch (result.status) {
            GoogleDriveArchiveVerificationStatus.available =>
              TripArchiveStatus.available,
            GoogleDriveArchiveVerificationStatus.authorizationRequired =>
              TripArchiveStatus.authorizationRequired,
            GoogleDriveArchiveVerificationStatus.inaccessible =>
              TripArchiveStatus.inaccessible,
            GoogleDriveArchiveVerificationStatus.notFound =>
              TripArchiveStatus.notFound,
            GoogleDriveArchiveVerificationStatus.insufficientSpace =>
              TripArchiveStatus.insufficientSpace,
            GoogleDriveArchiveVerificationStatus.networkUnavailable =>
              TripArchiveStatus.networkUnavailable,
            GoogleDriveArchiveVerificationStatus.error =>
              TripArchiveStatus.error,
          },
          folderName: result.folder?.name,
          folderUrl: result.folder?.webViewLink,
        );

      case TripCloudProvider.oneDrive:
      case TripCloudProvider.dropbox:
        return const TripArchiveVerificationResult(
          status: TripArchiveStatus.unchecked,
        );
    }
  }

  Future<TripArchiveVerificationResult> reconnect(
    TripCloudArchive archive,
  ) async {
    switch (archive.provider) {
      case TripCloudProvider.googleDrive:
        final authorization = await _googleDriveService.reauthorizeNative();

        if (authorization == null) {
          return const TripArchiveVerificationResult(
            status: TripArchiveStatus.authorizationRequired,
          );
        }

        return verify(archive);

      case TripCloudProvider.oneDrive:
      case TripCloudProvider.dropbox:
        return const TripArchiveVerificationResult(
          status: TripArchiveStatus.unchecked,
        );
    }
  }

  Future<void> open(TripCloudArchive archive) async {
    switch (archive.provider) {
      case TripCloudProvider.googleDrive:
        await _driveChannel.invokeMethod<void>(
          'openDriveFolder',
          <String, dynamic>{'folderId': archive.folderId},
        );

      case TripCloudProvider.oneDrive:
      case TripCloudProvider.dropbox:
        throw UnsupportedError('Cloud provider not supported yet.');
    }
  }
}
