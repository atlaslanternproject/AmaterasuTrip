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
}
