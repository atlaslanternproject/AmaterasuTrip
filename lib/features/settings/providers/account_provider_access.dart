import 'package:firebase_auth/firebase_auth.dart';

class AccountProviderAccess {
  const AccountProviderAccess._();

  static bool hasPasswordProvider(User? user) {
    if (user == null) {
      return false;
    }

    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  static bool isEmailManagementEnabled(User? user) {
    return hasPasswordProvider(user);
  }

  static bool isPasswordManagementEnabled(User? user) {
    return hasPasswordProvider(user);
  }
}
