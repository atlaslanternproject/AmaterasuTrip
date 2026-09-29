import 'trip_cloud_archive.dart';

class TripCloudArchiveSelection {
  const TripCloudArchiveSelection({
    required this.provider,
    required this.parentFolderId,
    this.parentFolderName,
    this.isRoot = false,
  });

  final TripCloudProvider provider;
  final String parentFolderId;
  final String? parentFolderName;
  final bool isRoot;
}
