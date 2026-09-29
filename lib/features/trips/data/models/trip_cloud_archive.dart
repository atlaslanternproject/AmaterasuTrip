enum TripCloudProvider { googleDrive, oneDrive, dropbox }

class TripCloudArchive {
  const TripCloudArchive({
    required this.provider,
    required this.folderId,
    required this.folderName,
    this.folderUrl,
    this.accountEmail,
  });

  final TripCloudProvider provider;
  final String folderId;
  final String folderName;
  final String? folderUrl;
  final String? accountEmail;

  String get providerId {
    switch (provider) {
      case TripCloudProvider.googleDrive:
        return 'google_drive';
      case TripCloudProvider.oneDrive:
        return 'onedrive';
      case TripCloudProvider.dropbox:
        return 'dropbox';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': providerId,
      'folderId': folderId,
      'folderName': folderName,
      'folderUrl': folderUrl,
      'accountEmail': accountEmail,
    };
  }

  factory TripCloudArchive.fromMap(Map<String, dynamic> map) {
    final providerValue = map['provider'] as String?;

    final provider = switch (providerValue) {
      'google_drive' => TripCloudProvider.googleDrive,
      'onedrive' => TripCloudProvider.oneDrive,
      'dropbox' => TripCloudProvider.dropbox,
      _ => throw ArgumentError.value(
        providerValue,
        'provider',
        'Unsupported cloud provider',
      ),
    };

    return TripCloudArchive(
      provider: provider,
      folderId: map['folderId'] as String? ?? '',
      folderName: map['folderName'] as String? ?? '',
      folderUrl: map['folderUrl'] as String?,
      accountEmail: map['accountEmail'] as String?,
    );
  }
}
