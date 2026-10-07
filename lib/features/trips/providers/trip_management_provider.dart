import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/trip_management_repository.dart';

final tripManagementRepositoryProvider = Provider<TripManagementRepository>((
  ref,
) {
  return TripManagementRepository();
});
