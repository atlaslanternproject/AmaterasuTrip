import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/google_drive_archive_service.dart';
import '../data/services/trip_archive_naming_service.dart';

final googleDriveArchiveServiceProvider = Provider<GoogleDriveArchiveService>((
  ref,
) {
  return GoogleDriveArchiveService();
});

final tripArchiveNamingServiceProvider = Provider<TripArchiveNamingService>((
  ref,
) {
  return const TripArchiveNamingService();
});
