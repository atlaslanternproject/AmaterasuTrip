import 'invite_auth_return.dart';

abstract final class AuthRouteGuard {
  static String? redirect({
    required bool isAuthenticated,
    required bool isEmailVerified,
    required String matchedLocation,
    required Uri uri,
  }) {
    final isRoot = matchedLocation == '/';
    final isRegister = matchedLocation == '/register';
    final isVerifyEmail = matchedLocation == '/verify-email';
    final isGoogleAuth = matchedLocation == '/google-auth';
    final isCreateUsername = matchedLocation == '/create-username';
    final isTripInvite = matchedLocation.startsWith('/trip-invite/');

    final returnTo = InviteAuthReturn.normalize(
      uri.queryParameters['returnTo'],
    );

    if (!isAuthenticated) {
      if (isRoot || isRegister || isGoogleAuth || isTripInvite) {
        return null;
      }

      if (isVerifyEmail || isCreateUsername) {
        return InviteAuthReturn.route('/', returnTo);
      }

      return '/';
    }

    if (isGoogleAuth || isCreateUsername) {
      return null;
    }

    if (isRoot) {
      if (returnTo != null) {
        return returnTo;
      }

      return isEmailVerified ? '/home' : '/verify-email';
    }

    if (!isEmailVerified) {
      if (isVerifyEmail || isTripInvite) {
        return null;
      }

      return InviteAuthReturn.route('/verify-email', returnTo);
    }

    if (isVerifyEmail || isRegister) {
      return returnTo ?? '/home';
    }

    return null;
  }
}
