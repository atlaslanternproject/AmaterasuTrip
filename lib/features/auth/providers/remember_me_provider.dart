import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/remember_me_storage.dart';

final rememberMeProvider = FutureProvider<bool>((ref) async {
  return RememberMeStorage.load();
});
