// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsLanguage => 'Language';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authEmailOrUsernameHint => 'Enter Email or Username';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authForgotPassword => 'Recover password';

  @override
  String get authInsertEmail => 'Enter Email';

  @override
  String get authCancel => 'Cancel';

  @override
  String get authPasswordResetEmailSent => '📜 We sent a scroll to recover your password. Check your inbox. Also check your Spam or Junk folder if you don\'t find it!';

  @override
  String get authContinue => 'Continue';

  @override
  String get authForgotPasswordQuestion => 'Forgot your password?';

  @override
  String get authStaySignedIn => 'Stay signed in';

  @override
  String get authSigningIn => 'Signing in...';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authNoAccountRegister => 'Don\'t have an account? Register';

  @override
  String get authLoginErrorUserNotFound => 'No traveler found with these credentials.';

  @override
  String get authLoginErrorWrongPassword => 'The secret word does not open the door of the vessel.';

  @override
  String get authLoginErrorInvalidEmail => 'This email doesn\'t seem to be valid.';

  @override
  String get authLoginErrorGeneric => 'Access denied. Try again.';

  @override
  String get authCreateAccount => 'Create your account';

  @override
  String get authUsernameHint => 'Username';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authConfirmPasswordHint => 'Confirm password';

  @override
  String get authRegister => 'Register';

  @override
  String get authRegisterFillFields => '⚠️ Please fill in all required fields.';

  @override
  String get authRegisterPasswordsMismatch => '⚠️ The two secret words don\'t match.';

  @override
  String get authRegisterEmailAlreadyInUse => '⚠️ A traveler is already registered with this scroll.';

  @override
  String get authRegisterWeakPassword => '⚠️ The secret word is too weak.';

  @override
  String get authRegisterInvalidEmail => '⚠️ The raven cannot reach this address.';

  @override
  String get authRegisterGenericError => '⚠️ Unable to complete registration.';

  @override
  String get authAlreadyHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get authGoogleSignInError => 'Unable to complete Google sign-in.';

  @override
  String get authGoogleSigningIn => 'Signing in with Google...';

  @override
  String get authRetry => 'Try again';

  @override
  String get authVerifyEmailNotVerified => '⚠️ The scroll has not been signed yet. Check your inbox. Also check your Spam or Junk folder if you don\'t find it!';

  @override
  String get authVerifyEmailSent => '📜 A new scroll has been sent. Check your inbox. Also check your Spam or Junk folder if you don\'t find it!';

  @override
  String get authVerifyEmailTitle => 'Verify your email address';

  @override
  String get authVerifyEmailDescription => 'We sent a verification email to your address.\n\nOpen it and confirm your account before entering the Tavern.\n\nIf you don\'t find it, check your Spam or Junk folder!';

  @override
  String get authVerifyEmailConfirmed => 'I\'ve verified it';

  @override
  String get authVerifyEmailResend => 'Resend email';

  @override
  String get createUsernameTitle => 'Create Username';

  @override
  String get createUsernameSubtitle => 'Choose your traveler name';

  @override
  String get createUsernameContinue => 'Continue';

  @override
  String get createUsernameRequired => 'Enter a username';

  @override
  String get createUsernameGoogleUserNotFound => 'Google user not found. Try again';

  @override
  String get createUsernameAlreadyTaken => 'This username is already in use. Choose another one.';

  @override
  String get commonOr => 'or';

  @override
  String get commonDiscordSignIn => 'Sign in with Discord';

  @override
  String get commonGoogleSignIn => 'Sign in with Google';

  @override
  String get commonPassword => 'Password';

  @override
  String get homeLoginCompleted => 'Login completed!';

  @override
  String get homeGoogleUser => 'Google user';

  @override
  String get homeNoUid => 'No UID';

  @override
  String get homeName => 'Name:';

  @override
  String get homeNoName => 'No name';

  @override
  String get homeEmail => 'Email:';

  @override
  String get homeNoEmail => 'No email';

  @override
  String get homeUid => 'UID:';

  @override
  String get homeLogoutTest => 'Test logout';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsDataSync => 'Online/offline data';

  @override
  String get settingsInformation => 'Information';

  @override
  String get settingsPlaceholder => 'This section will be available soon.';

  @override
  String settingsLanguageName(String languageCode) {
    String _temp0 = intl.Intl.selectLogic(
      languageCode,
      {
        'it': 'Italian',
        'en': 'English',
        'other': 'Language',
      },
    );
    return '$_temp0';
  }

  @override
  String get bottomBarHome => 'Home';

  @override
  String get bottomBarTrips => 'Trips';

  @override
  String get bottomBarSettings => 'Settings';

  @override
  String get appName => 'Amaterasu Trip';

  @override
  String get loginCompleted => 'Login completed!';

  @override
  String get name => 'Name:';

  @override
  String get noName => 'No name';

  @override
  String get email => 'Email:';

  @override
  String get noEmail => 'No email';

  @override
  String get uid => 'UID:';

  @override
  String get logoutTest => 'Test logout';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccountSubtitle => 'Manage your account, password and data';

  @override
  String get settingsLanguageSubtitle => 'Choose the app language';

  @override
  String get settingsProfileSubtitle => 'Personalize your profile';

  @override
  String get settingsNotificationsSubtitle => 'Manage your notifications';

  @override
  String get settingsPrivacySubtitle => 'Control your privacy';

  @override
  String get settingsDataSyncSubtitle => 'Manage data and synchronization';

  @override
  String get settingsInformationSubtitle => 'App version, terms and more';

  @override
  String get confirm => 'Confirm';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountEmailSubtitle => 'Manage your email address';

  @override
  String get accountEmailCurrent => 'Email address';

  @override
  String get accountEmailVerified => 'Email verified';

  @override
  String get accountEmailNotVerified => 'Email not verified';

  @override
  String get accountEmailVerify => 'Verify email';

  @override
  String get accountEmailResendVerification => 'Resend verification email';

  @override
  String get accountEmailChange => 'Change email';

  @override
  String get accountEmailNew => 'New email address';

  @override
  String get accountEmailConfirmChange => 'Confirm email change';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountPasswordSubtitle => 'Manage your password';

  @override
  String get accountPasswordChange => 'Change password';

  @override
  String get accountPasswordRecover => 'Recover password';

  @override
  String get accountLinkedAccounts => 'Linked accounts';

  @override
  String get accountLinkedAccountsSubtitle => 'Manage your linked accounts';

  @override
  String get accountLinkedGoogle => 'Google';

  @override
  String get accountLinkedOtherProviders => 'Other providers';

  @override
  String get accountLinkedConnected => 'Connected';

  @override
  String get accountLinkedNotConnected => 'Not connected';

  @override
  String get accountSession => 'Session';

  @override
  String get accountSessionSubtitle => 'Manage access to your account';

  @override
  String get accountSessionActive => 'Active sessions';

  @override
  String get accountSessionSignOutAll => 'Sign out of all devices';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteDescription => 'Deleting your account is permanent and will result in the loss of associated data.';

  @override
  String get accountDeleteConfirm => 'Confirm account deletion';

  @override
  String get accountLogout => 'Sign out';

  @override
  String get accountEmailCurrentPassword => 'Current password';

  @override
  String get accountEmailVerificationSent => 'Verification email sent. Also check your Spam or Junk folder.';

  @override
  String get accountEmailChangeVerificationSent => 'We\'ve sent a verification email to the new address. Also check your Spam or Junk folder.';

  @override
  String get accountEmailVerifiedDescription => 'Your email address is verified.';

  @override
  String get accountEmailChangeDescription => 'Change the email address associated with your account.';

  @override
  String get accountEmailUnavailable => 'Email address unavailable';

  @override
  String get accountEmailErrorInvalidPassword => 'The current password is incorrect.';

  @override
  String get accountEmailErrorAlreadyInUse => 'This email address is already associated with an account.';

  @override
  String get accountEmailErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get accountEmailErrorRecentLogin => 'For security reasons, please sign in again and try again.';

  @override
  String get accountEmailErrorTooManyRequests => 'Too many requests have been made. Please try again later.';

  @override
  String get accountEmailErrorUserNotFound => 'The account could not be found.';

  @override
  String get accountEmailErrorGeneric => 'The operation could not be completed.';

  @override
  String get cancel => 'Cancel';

  @override
  String get accountEmailChangeLogoutWarning => 'After changing your email address, you will be signed out for security reasons. You will need to sign in again with your new email address.';

  @override
  String get accountEmailChangeContinue => 'Continue';

  @override
  String get accountLogoutTitle => 'Log out of Amaterasu Trip?';

  @override
  String get accountLogoutDescription => 'Your session will be closed on this device.';

  @override
  String get accountLogoutStay => 'Stay';

  @override
  String get accountLogoutConfirm => 'Log out';

  @override
  String get accountPasswordChangeDescription => 'Change the password associated with your account';

  @override
  String get accountPasswordRecoverSubtitle => 'Send an email to reset your password';

  @override
  String get accountPasswordCurrent => 'Current password';

  @override
  String get accountPasswordNew => 'New password';

  @override
  String get accountPasswordConfirmNew => 'Confirm new password';

  @override
  String get accountPasswordConfirmChange => 'Change password';

  @override
  String get accountPasswordChanging => 'Changing...';

  @override
  String get accountPasswordChanged => 'Password changed successfully.';

  @override
  String get accountPasswordSendReset => 'Send email';

  @override
  String accountPasswordRecoverDescription(String email) {
    return 'We\'ll send a password reset email to $email.';
  }

  @override
  String get accountPasswordResetSent => 'Password recovery email sent. Check your inbox and also your Spam or Junk folder.';

  @override
  String get accountPasswordManagedByProvider => 'This account does not use an Amaterasu Trip password. Your password is managed by the provider you used to sign in.';

  @override
  String get accountPasswordErrorEmptyFields => 'Please fill in all fields.';

  @override
  String get accountPasswordErrorWeak => 'The new password must be at least 6 characters long.';

  @override
  String get accountPasswordErrorMismatch => 'The new passwords do not match.';

  @override
  String get accountPasswordErrorSamePassword => 'The new password must be different from your current password.';

  @override
  String get accountPasswordErrorWrongCurrent => 'The current password is incorrect.';

  @override
  String get accountPasswordErrorRecentLogin => 'For security reasons, please sign in again and try again.';

  @override
  String get accountPasswordErrorTooManyRequests => 'Too many requests have been made. Please try again later.';

  @override
  String get accountPasswordErrorUserNotFound => 'The account could not be found.';

  @override
  String get accountPasswordErrorNoEmail => 'No email address is available for this account.';

  @override
  String get accountPasswordErrorGeneric => 'The operation could not be completed.';

  @override
  String get accountDeleteIntro => 'Permanently delete your Amaterasu account.';

  @override
  String get accountDeleteWarning => 'This action is irreversible. The data associated with your account will be removed and cannot be recovered.';

  @override
  String get accountDeleteButton => 'Delete account';

  @override
  String get accountDeleteDialogTitle => 'Delete account';

  @override
  String get accountDeleteDialogIntro => 'You are about to permanently delete your Amaterasu account.';

  @override
  String get accountDeleteDialogData => 'The personal data associated with your account will be deleted and you will be removed from the trips and groups you belong to.';

  @override
  String get accountDeleteDialogIrreversible => 'This action is irreversible and deleted data cannot be recovered.';

  @override
  String get accountDeleteDialogConfirmation => 'I understand that the deletion is permanent.';

  @override
  String get accountDeleteLoading => 'Deleting account…';

  @override
  String get accountDeleteCancel => 'Cancel';

  @override
  String get accountDeleteConfirmButton => 'Delete permanently';

  @override
  String get accountDeleteReauthenticationTitle => 'Confirm your identity';

  @override
  String get accountDeleteReauthenticationPasswordDescription => 'To continue deleting your account, enter your current password.';

  @override
  String get accountDeleteReauthenticationPasswordLabel => 'Current password';

  @override
  String get accountDeleteReauthenticationConfirm => 'Confirm';

  @override
  String get accountDeleteReauthenticationWrongPassword => 'The password you entered is incorrect.';

  @override
  String get accountDeleteReauthenticationCancelled => 'Identity verification was cancelled.';

  @override
  String get accountDeleteReauthenticationGoogleMismatch => 'You must use the same Google account linked to Amaterasu.';

  @override
  String get accountDeleteReauthenticationFailed => 'We could not verify your identity. Please try again.';

  @override
  String get accountDeleteReauthenticationUnsupported => 'This sign-in method is not yet supported for identity verification.';

  @override
  String get accountDeleteError => 'We could not complete the account deletion. No further data will be deleted. Please try again.';
}
