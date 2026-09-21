import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it')
  ];

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authEmailOrUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Email or Username'**
  String get authEmailOrUsernameHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordHint;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Recover password'**
  String get authForgotPassword;

  /// No description provided for @authInsertEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter Email'**
  String get authInsertEmail;

  /// No description provided for @authCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authCancel;

  /// No description provided for @authPasswordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'📜 We sent a scroll to recover your password. Check your inbox. Also check your Spam or Junk folder if you don\'t find it!'**
  String get authPasswordResetEmailSent;

  /// No description provided for @authContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// No description provided for @authForgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authForgotPasswordQuestion;

  /// No description provided for @authStaySignedIn.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get authStaySignedIn;

  /// No description provided for @authSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get authSigningIn;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authNoAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get authNoAccountRegister;

  /// No description provided for @authLoginErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No traveler found with these credentials.'**
  String get authLoginErrorUserNotFound;

  /// No description provided for @authLoginErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The secret word does not open the door of the vessel.'**
  String get authLoginErrorWrongPassword;

  /// No description provided for @authLoginErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'This email doesn\'t seem to be valid.'**
  String get authLoginErrorInvalidEmail;

  /// No description provided for @authLoginErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Access denied. Try again.'**
  String get authLoginErrorGeneric;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccount;

  /// No description provided for @authUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernameHint;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailHint;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authRegisterFillFields.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Please fill in all required fields.'**
  String get authRegisterFillFields;

  /// No description provided for @authRegisterPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'⚠️ The two secret words don\'t match.'**
  String get authRegisterPasswordsMismatch;

  /// No description provided for @authRegisterEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'⚠️ A traveler is already registered with this scroll.'**
  String get authRegisterEmailAlreadyInUse;

  /// No description provided for @authRegisterWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'⚠️ The secret word is too weak.'**
  String get authRegisterWeakPassword;

  /// No description provided for @authRegisterInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'⚠️ The raven cannot reach this address.'**
  String get authRegisterInvalidEmail;

  /// No description provided for @authRegisterGenericError.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Unable to complete registration.'**
  String get authRegisterGenericError;

  /// No description provided for @authAlreadyHaveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authAlreadyHaveAccountSignIn;

  /// No description provided for @authGoogleSignInError.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete Google sign-in.'**
  String get authGoogleSignInError;

  /// No description provided for @authGoogleSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in with Google...'**
  String get authGoogleSigningIn;

  /// No description provided for @authRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get authRetry;

  /// No description provided for @authVerifyEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'⚠️ The scroll has not been signed yet. Check your inbox. Also check your Spam or Junk folder if you don\'t find it!'**
  String get authVerifyEmailNotVerified;

  /// No description provided for @authVerifyEmailSent.
  ///
  /// In en, this message translates to:
  /// **'📜 A new scroll has been sent. Check your inbox. Also check your Spam or Junk folder if you don\'t find it!'**
  String get authVerifyEmailSent;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email address'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification email to your address.\n\nOpen it and confirm your account before entering the Tavern.\n\nIf you don\'t find it, check your Spam or Junk folder!'**
  String get authVerifyEmailDescription;

  /// No description provided for @authVerifyEmailConfirmed.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified it'**
  String get authVerifyEmailConfirmed;

  /// No description provided for @authVerifyEmailResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get authVerifyEmailResend;

  /// No description provided for @createUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Username'**
  String get createUsernameTitle;

  /// No description provided for @createUsernameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your traveler name'**
  String get createUsernameSubtitle;

  /// No description provided for @createUsernameContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get createUsernameContinue;

  /// No description provided for @createUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a username'**
  String get createUsernameRequired;

  /// No description provided for @createUsernameGoogleUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'Google user not found. Try again'**
  String get createUsernameGoogleUserNotFound;

  /// No description provided for @createUsernameAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already in use. Choose another one.'**
  String get createUsernameAlreadyTaken;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// No description provided for @commonDiscordSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Discord'**
  String get commonDiscordSignIn;

  /// No description provided for @commonGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get commonGoogleSignIn;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @homeLoginCompleted.
  ///
  /// In en, this message translates to:
  /// **'Login completed!'**
  String get homeLoginCompleted;

  /// No description provided for @homeGoogleUser.
  ///
  /// In en, this message translates to:
  /// **'Google user'**
  String get homeGoogleUser;

  /// No description provided for @homeNoUid.
  ///
  /// In en, this message translates to:
  /// **'No UID'**
  String get homeNoUid;

  /// No description provided for @homeName.
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get homeName;

  /// No description provided for @homeNoName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get homeNoName;

  /// No description provided for @homeEmail.
  ///
  /// In en, this message translates to:
  /// **'Email:'**
  String get homeEmail;

  /// No description provided for @homeNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get homeNoEmail;

  /// No description provided for @homeUid.
  ///
  /// In en, this message translates to:
  /// **'UID:'**
  String get homeUid;

  /// No description provided for @homeLogoutTest.
  ///
  /// In en, this message translates to:
  /// **'Test logout'**
  String get homeLogoutTest;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsDataSync.
  ///
  /// In en, this message translates to:
  /// **'Online/offline data'**
  String get settingsDataSync;

  /// No description provided for @settingsInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get settingsInformation;

  /// No description provided for @settingsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'This section will be available soon.'**
  String get settingsPlaceholder;

  /// Name of a language displayed using the current app language.
  ///
  /// In en, this message translates to:
  /// **'{languageCode, select, it {Italian} en {English} other {Language}}'**
  String settingsLanguageName(String languageCode);

  /// No description provided for @bottomBarHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get bottomBarHome;

  /// No description provided for @bottomBarTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get bottomBarTrips;

  /// No description provided for @bottomBarSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get bottomBarSettings;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu Trip'**
  String get appName;

  /// No description provided for @loginCompleted.
  ///
  /// In en, this message translates to:
  /// **'Login completed!'**
  String get loginCompleted;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get name;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email:'**
  String get email;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @uid.
  ///
  /// In en, this message translates to:
  /// **'UID:'**
  String get uid;

  /// No description provided for @logoutTest.
  ///
  /// In en, this message translates to:
  /// **'Test logout'**
  String get logoutTest;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account, password and data'**
  String get settingsAccountSubtitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize your profile'**
  String get settingsProfileSubtitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your notifications'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control your privacy'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsDataSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage data and synchronization'**
  String get settingsDataSyncSubtitle;

  /// No description provided for @settingsInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App version, terms and more'**
  String get settingsInformationSubtitle;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @accountEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your email address'**
  String get accountEmailSubtitle;

  /// No description provided for @accountEmailCurrent.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get accountEmailCurrent;

  /// No description provided for @accountEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get accountEmailVerified;

  /// No description provided for @accountEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified'**
  String get accountEmailNotVerified;

  /// No description provided for @accountEmailVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get accountEmailVerify;

  /// No description provided for @accountEmailResendVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get accountEmailResendVerification;

  /// No description provided for @accountEmailChange.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get accountEmailChange;

  /// No description provided for @accountEmailNew.
  ///
  /// In en, this message translates to:
  /// **'New email address'**
  String get accountEmailNew;

  /// No description provided for @accountEmailConfirmChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm email change'**
  String get accountEmailConfirmChange;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// No description provided for @accountPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your password'**
  String get accountPasswordSubtitle;

  /// No description provided for @accountPasswordChange.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get accountPasswordChange;

  /// No description provided for @accountPasswordRecover.
  ///
  /// In en, this message translates to:
  /// **'Recover password'**
  String get accountPasswordRecover;

  /// No description provided for @accountLinkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked accounts'**
  String get accountLinkedAccounts;

  /// No description provided for @accountLinkedAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your linked accounts'**
  String get accountLinkedAccountsSubtitle;

  /// No description provided for @accountLinkedGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get accountLinkedGoogle;

  /// No description provided for @accountLinkedOtherProviders.
  ///
  /// In en, this message translates to:
  /// **'Other providers'**
  String get accountLinkedOtherProviders;

  /// No description provided for @accountLinkedConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get accountLinkedConnected;

  /// No description provided for @accountLinkedNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get accountLinkedNotConnected;

  /// No description provided for @accountSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get accountSession;

  /// No description provided for @accountSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage access to your account'**
  String get accountSessionSubtitle;

  /// No description provided for @accountSessionActive.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get accountSessionActive;

  /// No description provided for @accountSessionSignOutAll.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all devices'**
  String get accountSessionSignOutAll;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// No description provided for @accountDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account is permanent and will result in the loss of associated data.'**
  String get accountDeleteDescription;

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm account deletion'**
  String get accountDeleteConfirm;

  /// No description provided for @accountLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountLogout;

  /// No description provided for @accountEmailCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountEmailCurrentPassword;

  /// No description provided for @accountEmailVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Also check your Spam or Junk folder.'**
  String get accountEmailVerificationSent;

  /// No description provided for @accountEmailChangeVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification email to the new address. Also check your Spam or Junk folder.'**
  String get accountEmailChangeVerificationSent;

  /// No description provided for @accountEmailVerifiedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your email address is verified.'**
  String get accountEmailVerifiedDescription;

  /// No description provided for @accountEmailChangeDescription.
  ///
  /// In en, this message translates to:
  /// **'Change the email address associated with your account.'**
  String get accountEmailChangeDescription;

  /// No description provided for @accountEmailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Email address unavailable'**
  String get accountEmailUnavailable;

  /// No description provided for @accountEmailErrorInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'The current password is incorrect.'**
  String get accountEmailErrorInvalidPassword;

  /// No description provided for @accountEmailErrorAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email address is already associated with an account.'**
  String get accountEmailErrorAlreadyInUse;

  /// No description provided for @accountEmailErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get accountEmailErrorInvalidEmail;

  /// No description provided for @accountEmailErrorRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'For security reasons, please sign in again and try again.'**
  String get accountEmailErrorRecentLogin;

  /// No description provided for @accountEmailErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests have been made. Please try again later.'**
  String get accountEmailErrorTooManyRequests;

  /// No description provided for @accountEmailErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'The account could not be found.'**
  String get accountEmailErrorUserNotFound;

  /// No description provided for @accountEmailErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'The operation could not be completed.'**
  String get accountEmailErrorGeneric;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @accountEmailChangeLogoutWarning.
  ///
  /// In en, this message translates to:
  /// **'After changing your email address, you will be signed out for security reasons. You will need to sign in again with your new email address.'**
  String get accountEmailChangeLogoutWarning;

  /// No description provided for @accountEmailChangeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get accountEmailChangeContinue;

  /// No description provided for @accountLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of Amaterasu Trip?'**
  String get accountLogoutTitle;

  /// No description provided for @accountLogoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Your session will be closed on this device.'**
  String get accountLogoutDescription;

  /// No description provided for @accountLogoutStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get accountLogoutStay;

  /// No description provided for @accountLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get accountLogoutConfirm;

  /// No description provided for @accountPasswordChangeDescription.
  ///
  /// In en, this message translates to:
  /// **'Change the password associated with your account'**
  String get accountPasswordChangeDescription;

  /// No description provided for @accountPasswordRecoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send an email to reset your password'**
  String get accountPasswordRecoverSubtitle;

  /// No description provided for @accountPasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountPasswordCurrent;

  /// No description provided for @accountPasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get accountPasswordNew;

  /// No description provided for @accountPasswordConfirmNew.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get accountPasswordConfirmNew;

  /// No description provided for @accountPasswordConfirmChange.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get accountPasswordConfirmChange;

  /// No description provided for @accountPasswordChanging.
  ///
  /// In en, this message translates to:
  /// **'Changing...'**
  String get accountPasswordChanging;

  /// No description provided for @accountPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get accountPasswordChanged;

  /// No description provided for @accountPasswordSendReset.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get accountPasswordSendReset;

  /// No description provided for @accountPasswordRecoverDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a password reset email to {email}.'**
  String accountPasswordRecoverDescription(String email);

  /// No description provided for @accountPasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password recovery email sent. Check your inbox and also your Spam or Junk folder.'**
  String get accountPasswordResetSent;

  /// No description provided for @accountPasswordManagedByProvider.
  ///
  /// In en, this message translates to:
  /// **'This account does not use an Amaterasu Trip password. Your password is managed by the provider you used to sign in.'**
  String get accountPasswordManagedByProvider;

  /// No description provided for @accountPasswordErrorEmptyFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get accountPasswordErrorEmptyFields;

  /// No description provided for @accountPasswordErrorWeak.
  ///
  /// In en, this message translates to:
  /// **'The new password must be at least 6 characters long.'**
  String get accountPasswordErrorWeak;

  /// No description provided for @accountPasswordErrorMismatch.
  ///
  /// In en, this message translates to:
  /// **'The new passwords do not match.'**
  String get accountPasswordErrorMismatch;

  /// No description provided for @accountPasswordErrorSamePassword.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from your current password.'**
  String get accountPasswordErrorSamePassword;

  /// No description provided for @accountPasswordErrorWrongCurrent.
  ///
  /// In en, this message translates to:
  /// **'The current password is incorrect.'**
  String get accountPasswordErrorWrongCurrent;

  /// No description provided for @accountPasswordErrorRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'For security reasons, please sign in again and try again.'**
  String get accountPasswordErrorRecentLogin;

  /// No description provided for @accountPasswordErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests have been made. Please try again later.'**
  String get accountPasswordErrorTooManyRequests;

  /// No description provided for @accountPasswordErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'The account could not be found.'**
  String get accountPasswordErrorUserNotFound;

  /// No description provided for @accountPasswordErrorNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email address is available for this account.'**
  String get accountPasswordErrorNoEmail;

  /// No description provided for @accountPasswordErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'The operation could not be completed.'**
  String get accountPasswordErrorGeneric;

  /// No description provided for @accountDeleteIntro.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your Amaterasu account.'**
  String get accountDeleteIntro;

  /// No description provided for @accountDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. The data associated with your account will be removed and cannot be recovered.'**
  String get accountDeleteWarning;

  /// No description provided for @accountDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeleteButton;

  /// No description provided for @accountDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeleteDialogTitle;

  /// No description provided for @accountDeleteDialogIntro.
  ///
  /// In en, this message translates to:
  /// **'You are about to permanently delete your Amaterasu account.'**
  String get accountDeleteDialogIntro;

  /// No description provided for @accountDeleteDialogData.
  ///
  /// In en, this message translates to:
  /// **'The personal data associated with your account will be deleted and you will be removed from the trips and groups you belong to.'**
  String get accountDeleteDialogData;

  /// No description provided for @accountDeleteDialogIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible and deleted data cannot be recovered.'**
  String get accountDeleteDialogIrreversible;

  /// No description provided for @accountDeleteDialogConfirmation.
  ///
  /// In en, this message translates to:
  /// **'I understand that the deletion is permanent.'**
  String get accountDeleteDialogConfirmation;

  /// No description provided for @accountDeleteLoading.
  ///
  /// In en, this message translates to:
  /// **'Deleting account…'**
  String get accountDeleteLoading;

  /// No description provided for @accountDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountDeleteCancel;

  /// No description provided for @accountDeleteConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get accountDeleteConfirmButton;

  /// No description provided for @accountDeleteReauthenticationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity'**
  String get accountDeleteReauthenticationTitle;

  /// No description provided for @accountDeleteReauthenticationPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'To continue deleting your account, enter your current password.'**
  String get accountDeleteReauthenticationPasswordDescription;

  /// No description provided for @accountDeleteReauthenticationPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountDeleteReauthenticationPasswordLabel;

  /// No description provided for @accountDeleteReauthenticationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get accountDeleteReauthenticationConfirm;

  /// No description provided for @accountDeleteReauthenticationWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The password you entered is incorrect.'**
  String get accountDeleteReauthenticationWrongPassword;

  /// No description provided for @accountDeleteReauthenticationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Identity verification was cancelled.'**
  String get accountDeleteReauthenticationCancelled;

  /// No description provided for @accountDeleteReauthenticationGoogleMismatch.
  ///
  /// In en, this message translates to:
  /// **'You must use the same Google account linked to Amaterasu.'**
  String get accountDeleteReauthenticationGoogleMismatch;

  /// No description provided for @accountDeleteReauthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not verify your identity. Please try again.'**
  String get accountDeleteReauthenticationFailed;

  /// No description provided for @accountDeleteReauthenticationUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not yet supported for identity verification.'**
  String get accountDeleteReauthenticationUnsupported;

  /// No description provided for @accountDeleteError.
  ///
  /// In en, this message translates to:
  /// **'We could not complete the account deletion. No further data will be deleted. Please try again.'**
  String get accountDeleteError;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Learn how Amaterasu manages your data, app permissions and privacy choices.'**
  String get privacyIntro;

  /// No description provided for @privacyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyDataTitle;

  /// No description provided for @privacyDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn what data Amaterasu uses and how it is managed.'**
  String get privacyDataSubtitle;

  /// No description provided for @privacyPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get privacyPermissionsTitle;

  /// No description provided for @privacyPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Information about permissions the app may request.'**
  String get privacyPermissionsSubtitle;

  /// No description provided for @privacyConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get privacyConsentTitle;

  /// No description provided for @privacyConsentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn how consent and optional features are managed.'**
  String get privacyConsentSubtitle;

  /// No description provided for @privacyExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Data export'**
  String get privacyExportTitle;

  /// No description provided for @privacyExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Information about obtaining a copy of your data.'**
  String get privacyExportSubtitle;

  /// No description provided for @privacyPolicyOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'General information'**
  String get privacyPolicyOverviewTitle;

  /// No description provided for @privacyPolicyOverviewBody.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu Trip is an application designed to help organise and manage travel. This policy explains which data may be processed while using the app and for what purposes.'**
  String get privacyPolicyOverviewBody;

  /// No description provided for @privacyPolicyCollectedDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data processed'**
  String get privacyPolicyCollectedDataTitle;

  /// No description provided for @privacyPolicyCollectedDataBody.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu may process data required to create and manage an account, such as your email address, user identifier, username and authentication method. Some app preferences, such as language and remembered sign-in settings, may be stored locally on your device.'**
  String get privacyPolicyCollectedDataBody;

  /// No description provided for @privacyPolicyPurposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Purpose of processing'**
  String get privacyPolicyPurposeTitle;

  /// No description provided for @privacyPolicyPurposeBody.
  ///
  /// In en, this message translates to:
  /// **'Data is used solely to provide the app\'s features, authenticate users, maintain the Amaterasu profile, allow account management and ensure the correct operation of associated services.'**
  String get privacyPolicyPurposeBody;

  /// No description provided for @privacyPolicyFirebaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Firebase'**
  String get privacyPolicyFirebaseTitle;

  /// No description provided for @privacyPolicyFirebaseBody.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu uses Google\'s Firebase services for features such as authentication and account data storage. Data required for these services may be processed through Firebase infrastructure in accordance with Google\'s applicable terms and policies.'**
  String get privacyPolicyFirebaseBody;

  /// No description provided for @privacyPolicyGoogleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get privacyPolicyGoogleTitle;

  /// No description provided for @privacyPolicyGoogleBody.
  ///
  /// In en, this message translates to:
  /// **'If you choose to sign in to Amaterasu using Google, Google provides the information required to authenticate your account. Amaterasu does not receive or store your Google account password.'**
  String get privacyPolicyGoogleBody;

  /// No description provided for @privacyPolicyStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Data retention'**
  String get privacyPolicyStorageTitle;

  /// No description provided for @privacyPolicyStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Data associated with your account is retained while your Amaterasu account remains active or for as long as required to provide the requested services. Some preferences may be stored locally on your device.'**
  String get privacyPolicyStorageBody;

  /// No description provided for @privacyPolicyDeletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account deletion'**
  String get privacyPolicyDeletionTitle;

  /// No description provided for @privacyPolicyDeletionBody.
  ///
  /// In en, this message translates to:
  /// **'You can permanently delete your account from Amaterasu settings. Deletion removes the Firebase Authentication account and the account data currently associated with your Amaterasu profile. When new features and additional categories of data are introduced, this policy will be updated accordingly.'**
  String get privacyPolicyDeletionBody;

  /// No description provided for @privacyPolicySecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get privacyPolicySecurityTitle;

  /// No description provided for @privacyPolicySecurityBody.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu uses appropriate technical measures to limit unauthorised access to data and relies on the authentication and security systems provided by the Firebase services used by the app.'**
  String get privacyPolicySecurityBody;

  /// No description provided for @privacyPolicyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes to this Privacy Policy'**
  String get privacyPolicyChangesTitle;

  /// No description provided for @privacyPolicyChangesBody.
  ///
  /// In en, this message translates to:
  /// **'This policy may be updated when Amaterasu introduces new features, services or categories of data. The updated version will be made available within the app and through the public Privacy Policy page.'**
  String get privacyPolicyChangesBody;

  /// No description provided for @privacyPolicyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacyPolicyContactTitle;

  /// No description provided for @privacyPolicyContactBody.
  ///
  /// In en, this message translates to:
  /// **'For requests relating to privacy or personal data processing, you can contact the Amaterasu team through the official support channels listed in the app.'**
  String get privacyPolicyContactBody;

  /// No description provided for @privacyPermissionsIntro.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu only requests permissions required by the features you choose to use. Additional permissions may be introduced when new features become available.'**
  String get privacyPermissionsIntro;

  /// No description provided for @privacyPermissionsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get privacyPermissionsNotificationsTitle;

  /// No description provided for @privacyPermissionsNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu may request permission to send notifications for bookings, deadlines and information relating to your trips. You can revoke this permission from your device settings.'**
  String get privacyPermissionsNotificationsBody;

  /// No description provided for @privacyPermissionsMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos and media'**
  String get privacyPermissionsMediaTitle;

  /// No description provided for @privacyPermissionsMediaBody.
  ///
  /// In en, this message translates to:
  /// **'When features for photos, videos and travel documents become available, Amaterasu may request access to content selected by the user. The app will not access such content without an action from the user.'**
  String get privacyPermissionsMediaBody;

  /// No description provided for @privacyPermissionsLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get privacyPermissionsLocationTitle;

  /// No description provided for @privacyPermissionsLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu does not currently use the device\'s location. If a future feature requires location access, permission will be requested explicitly before it is used.'**
  String get privacyPermissionsLocationBody;

  /// No description provided for @privacyConsentIntro.
  ///
  /// In en, this message translates to:
  /// **'Features required for account operation do not involve marketing consent. Any optional feature requiring specific consent will be presented separately.'**
  String get privacyConsentIntro;

  /// No description provided for @privacyConsentRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Required services'**
  String get privacyConsentRequiredTitle;

  /// No description provided for @privacyConsentRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Authentication and account management use the data required to provide the service requested by the user.'**
  String get privacyConsentRequiredBody;

  /// No description provided for @privacyConsentOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional consent'**
  String get privacyConsentOptionalTitle;

  /// No description provided for @privacyConsentOptionalBody.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu does not currently use consent for personalised advertising, marketing or the sale of personal data.'**
  String get privacyConsentOptionalBody;

  /// No description provided for @privacyConsentFutureTitle.
  ///
  /// In en, this message translates to:
  /// **'Future features'**
  String get privacyConsentFutureTitle;

  /// No description provided for @privacyConsentFutureBody.
  ///
  /// In en, this message translates to:
  /// **'If services requiring optional consent are introduced in the future, you will be able to accept or refuse them separately without affecting consent choices already made.'**
  String get privacyConsentFutureBody;

  /// No description provided for @privacyExportHeading.
  ///
  /// In en, this message translates to:
  /// **'A copy of your data'**
  String get privacyExportHeading;

  /// No description provided for @privacyExportBody.
  ///
  /// In en, this message translates to:
  /// **'Full personal data export will become available when travel data management and export features are implemented. No export control is shown until the feature is genuinely available.'**
  String get privacyExportBody;

  /// No description provided for @profileUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsername;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileBio;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @profileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get profileFirstName;

  /// No description provided for @profileLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get profileLastName;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us something about yourself'**
  String get profileBioHint;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get profileSaving;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileSaveSuccess;

  /// No description provided for @profileSaveError.
  ///
  /// In en, this message translates to:
  /// **'The profile could not be updated.'**
  String get profileSaveError;

  /// No description provided for @profileBioTooLong.
  ///
  /// In en, this message translates to:
  /// **'Your bio can contain up to 200 characters.'**
  String get profileBioTooLong;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave without saving?'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes.'**
  String get unsavedChangesMessage;

  /// No description provided for @unsavedChangesDiscard.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving'**
  String get unsavedChangesDiscard;

  /// No description provided for @unsavedChangesSaveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save and leave'**
  String get unsavedChangesSaveAndExit;

  /// No description provided for @unsavedChangesCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get unsavedChangesCancel;

  /// No description provided for @profileChangeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change username'**
  String get profileChangeUsername;

  /// No description provided for @profileNewUsername.
  ///
  /// In en, this message translates to:
  /// **'New username'**
  String get profileNewUsername;

  /// No description provided for @profileUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a username.'**
  String get profileUsernameRequired;

  /// No description provided for @profileUsernameAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This username is already in use.'**
  String get profileUsernameAlreadyInUse;

  /// No description provided for @profileUsernameChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Username updated.'**
  String get profileUsernameChangeSuccess;

  /// No description provided for @profileUsernameChangeError.
  ///
  /// In en, this message translates to:
  /// **'The username could not be updated.'**
  String get profileUsernameChangeError;

  /// No description provided for @profileUsernameConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm change'**
  String get profileUsernameConfirm;

  /// No description provided for @profileUsernameChanging.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get profileUsernameChanging;

  /// No description provided for @profileEmailReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Your email address can be changed from the Account section.'**
  String get profileEmailReadOnly;

  /// No description provided for @profilePhotoChange.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get profilePhotoChange;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profilePhotoCamera;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profilePhotoGallery;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profilePhotoRemove;

  /// No description provided for @profilePhotoPickerError.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be selected.'**
  String get profilePhotoPickerError;

  /// No description provided for @profilePhotoCameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission was denied.'**
  String get profilePhotoCameraPermissionDenied;

  /// No description provided for @profilePhotoCameraPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is disabled. You can enable it from the app settings.'**
  String get profilePhotoCameraPermissionPermanentlyDenied;

  /// No description provided for @profilePhotoOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get profilePhotoOpenSettings;

  /// No description provided for @profilePhotoGalleryPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission to access photos was denied.'**
  String get profilePhotoGalleryPermissionDenied;

  /// No description provided for @profilePhotoGalleryPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission to access photos is disabled. You can enable it from the app settings.'**
  String get profilePhotoGalleryPermissionPermanentlyDenied;

  /// No description provided for @profilePhotoRemoveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to remove profile photo.'**
  String get profilePhotoRemoveError;

  /// No description provided for @notificationsAppSection.
  ///
  /// In en, this message translates to:
  /// **'App notifications'**
  String get notificationsAppSection;

  /// No description provided for @notificationsPush.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get notificationsPush;

  /// No description provided for @notificationsPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn app notifications on or off'**
  String get notificationsPushSubtitle;

  /// No description provided for @notificationsTripReminders.
  ///
  /// In en, this message translates to:
  /// **'Trip reminders'**
  String get notificationsTripReminders;

  /// No description provided for @notificationsTripRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive reminders about your trips'**
  String get notificationsTripRemindersSubtitle;

  /// No description provided for @notificationsItineraryReminders.
  ///
  /// In en, this message translates to:
  /// **'Itinerary reminders'**
  String get notificationsItineraryReminders;

  /// No description provided for @notificationsItineraryRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive reminders for itinerary activities, bookings and stops'**
  String get notificationsItineraryRemindersSubtitle;

  /// No description provided for @notificationsTripUpdates.
  ///
  /// In en, this message translates to:
  /// **'Trip updates'**
  String get notificationsTripUpdates;

  /// No description provided for @notificationsTripUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications when your trips are updated'**
  String get notificationsTripUpdatesSubtitle;

  /// No description provided for @notificationsGroupInvitations.
  ///
  /// In en, this message translates to:
  /// **'Group invitations'**
  String get notificationsGroupInvitations;

  /// No description provided for @notificationsGroupInvitationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications when you are invited to a trip'**
  String get notificationsGroupInvitationsSubtitle;

  /// No description provided for @notificationsGroupActivity.
  ///
  /// In en, this message translates to:
  /// **'Group activity'**
  String get notificationsGroupActivity;

  /// No description provided for @notificationsGroupActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications about activity in your travel groups'**
  String get notificationsGroupActivitySubtitle;

  /// No description provided for @notificationsAppUpdates.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get notificationsAppUpdates;

  /// No description provided for @notificationsAppUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications about what\'s new and updates to Amaterasu Trip'**
  String get notificationsAppUpdatesSubtitle;

  /// No description provided for @notificationsImportantCommunications.
  ///
  /// In en, this message translates to:
  /// **'Important communications'**
  String get notificationsImportantCommunications;

  /// No description provided for @notificationsImportantCommunicationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive important communications about the service'**
  String get notificationsImportantCommunicationsSubtitle;

  /// No description provided for @notificationsEmailSection.
  ///
  /// In en, this message translates to:
  /// **'Email communications'**
  String get notificationsEmailSection;

  /// No description provided for @notificationsEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage communications received by email'**
  String get notificationsEmailSubtitle;

  /// No description provided for @notificationsAccountEmails.
  ///
  /// In en, this message translates to:
  /// **'Account communications'**
  String get notificationsAccountEmails;

  /// No description provided for @notificationsAccountEmailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emails required for account security, access and management'**
  String get notificationsAccountEmailsSubtitle;

  /// No description provided for @notificationsServiceEmails.
  ///
  /// In en, this message translates to:
  /// **'Service communications'**
  String get notificationsServiceEmails;

  /// No description provided for @notificationsServiceEmailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emails required for the operation and use of the service'**
  String get notificationsServiceEmailsSubtitle;

  /// No description provided for @notificationsPromotionalEmails.
  ///
  /// In en, this message translates to:
  /// **'Promotional communications'**
  String get notificationsPromotionalEmails;

  /// No description provided for @notificationsPromotionalEmailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive news, initiatives and promotional communications from Amaterasu Trip'**
  String get notificationsPromotionalEmailsSubtitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'it': return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
