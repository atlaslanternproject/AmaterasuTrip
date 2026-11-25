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

  /// No description provided for @accountRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Security and recovery'**
  String get accountRecoveryTitle;

  /// No description provided for @accountRecoveryStatus.
  ///
  /// In en, this message translates to:
  /// **'In development'**
  String get accountRecoveryStatus;

  /// No description provided for @accountRecoveryStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted recovery is not yet active'**
  String get accountRecoveryStatusTitle;

  /// No description provided for @accountRecoveryStatusDescription.
  ///
  /// In en, this message translates to:
  /// **'This feature is being developed. No backup of your data has been created through this screen.'**
  String get accountRecoveryStatusDescription;

  /// No description provided for @accountRecoverySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'How it will work'**
  String get accountRecoverySectionTitle;

  /// No description provided for @accountRecoveryCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal recovery code'**
  String get accountRecoveryCodeTitle;

  /// No description provided for @accountRecoveryCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'You will be able to generate a recovery code and keep it somewhere safe.'**
  String get accountRecoveryCodeDescription;

  /// No description provided for @accountRecoveryStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Protected data'**
  String get accountRecoveryStorageTitle;

  /// No description provided for @accountRecoveryStorageDescription.
  ///
  /// In en, this message translates to:
  /// **'The code will help recover keys for data your account is still allowed to access.'**
  String get accountRecoveryStorageDescription;

  /// No description provided for @accountRecoveryDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'New device'**
  String get accountRecoveryDeviceTitle;

  /// No description provided for @accountRecoveryDeviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Security checks will be required before a new device can be authorised.'**
  String get accountRecoveryDeviceDescription;

  /// No description provided for @accountRecoveryNotice.
  ///
  /// In en, this message translates to:
  /// **'Password recovery and encrypted data recovery are two different processes.'**
  String get accountRecoveryNotice;

  /// No description provided for @webMediaCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Open the camera?'**
  String get webMediaCameraTitle;

  /// No description provided for @webMediaCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu will open the camera if supported by your browser. Otherwise, you can choose an image from your device. No photo will be used without your choice.'**
  String get webMediaCameraBody;

  /// No description provided for @webMediaGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a photo?'**
  String get webMediaGalleryTitle;

  /// No description provided for @webMediaGalleryBody.
  ///
  /// In en, this message translates to:
  /// **'You can choose a photo from your device. Amaterasu will only use the file you select, without accessing your entire gallery.'**
  String get webMediaGalleryBody;

  /// No description provided for @webMediaContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get webMediaContinue;

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
  /// **'We\'ve sent you an email to reset your password. Check your inbox and, if you can\'t find it, your Spam or Junk folder.'**
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
  /// **'The password you entered is incorrect.'**
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
  /// **'Please complete all required fields.'**
  String get authRegisterFillFields;

  /// No description provided for @authRegisterPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get authRegisterPasswordsMismatch;

  /// No description provided for @authRegisterEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email address.'**
  String get authRegisterEmailAlreadyInUse;

  /// No description provided for @authRegisterWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password you chose is too weak.'**
  String get authRegisterWeakPassword;

  /// No description provided for @authRegisterInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email address you entered is not valid.'**
  String get authRegisterInvalidEmail;

  /// No description provided for @authRegisterGenericError.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete registration. Please try again.'**
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
  /// **'Your email address has not been verified yet. Check your inbox and, if you can\'t find the email, your Spam or Junk folder.'**
  String get authVerifyEmailNotVerified;

  /// No description provided for @authVerifyEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox and, if you can\'t find it, your Spam or Junk folder.'**
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

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

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

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// No description provided for @accountDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account is permanent and will remove the associated data.'**
  String get accountDeleteDescription;

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
  /// **'Deleting account...'**
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

  /// No description provided for @accountDeleteBlockedByTrips.
  ///
  /// In en, this message translates to:
  /// **'Before deleting your account, leave your trips or delete them.'**
  String get accountDeleteBlockedByTrips;

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

  /// No description provided for @profilePhotoRemoveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to remove profile photo.'**
  String get profilePhotoRemoveError;

  /// No description provided for @informationApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get informationApp;

  /// No description provided for @informationAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, build and licences'**
  String get informationAppSubtitle;

  /// No description provided for @informationLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get informationLegal;

  /// No description provided for @informationLegalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Terms, privacy and legal information'**
  String get informationLegalSubtitle;

  /// No description provided for @informationSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get informationSupport;

  /// No description provided for @informationSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help, contact and reporting'**
  String get informationSupportSubtitle;

  /// No description provided for @informationCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get informationCredits;

  /// No description provided for @informationCreditsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Credits, services and SDKs used'**
  String get informationCreditsSubtitle;

  /// No description provided for @informationAppName.
  ///
  /// In en, this message translates to:
  /// **'Application name'**
  String get informationAppName;

  /// No description provided for @informationVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get informationVersion;

  /// No description provided for @informationBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get informationBuild;

  /// No description provided for @informationOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get informationOpenSourceLicenses;

  /// No description provided for @informationOpenSourceLicensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View licences for the software used'**
  String get informationOpenSourceLicensesSubtitle;

  /// No description provided for @informationPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get informationPrivacyPolicy;

  /// No description provided for @informationPrivacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read how your personal data is handled'**
  String get informationPrivacyPolicySubtitle;

  /// No description provided for @informationContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get informationContactUs;

  /// No description provided for @informationReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get informationReportProblem;

  /// No description provided for @informationReportProblemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a problem report to support'**
  String get informationReportProblemSubtitle;

  /// No description provided for @informationReportProblemSubject.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu Trip - Problem report'**
  String get informationReportProblemSubject;

  /// No description provided for @informationReportProblemBody.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem:\n\n\n---\nAmaterasu Trip\nVersion: {version}\nBuild: {build}'**
  String informationReportProblemBody(String version, String build);

  /// No description provided for @informationCreditsDevelopedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by'**
  String get informationCreditsDevelopedBy;

  /// No description provided for @informationCreditsTeam.
  ///
  /// In en, this message translates to:
  /// **'Atlas Lantern Team'**
  String get informationCreditsTeam;

  /// No description provided for @informationCreditsTechnologies.
  ///
  /// In en, this message translates to:
  /// **'Technologies and services'**
  String get informationCreditsTechnologies;

  /// No description provided for @informationCreditsTechnologiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Technologies and services used by Amaterasu Trip'**
  String get informationCreditsTechnologiesSubtitle;

  /// No description provided for @dataSyncSection.
  ///
  /// In en, this message translates to:
  /// **'Synchronisation'**
  String get dataSyncSection;

  /// No description provided for @dataSyncSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage data synchronisation'**
  String get dataSyncSectionSubtitle;

  /// No description provided for @dataStorageSection.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get dataStorageSection;

  /// No description provided for @dataStorageSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage offline data and storage usage'**
  String get dataStorageSectionSubtitle;

  /// No description provided for @dataConnectionSection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get dataConnectionSection;

  /// No description provided for @dataConnectionSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage how Amaterasu uses your connection'**
  String get dataConnectionSectionSubtitle;

  /// No description provided for @dataSyncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Data synchronisation'**
  String get dataSyncEnabled;

  /// No description provided for @dataSyncEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow data to synchronise when you are online'**
  String get dataSyncEnabledSubtitle;

  /// No description provided for @dataSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get dataSyncNow;

  /// No description provided for @dataSyncNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manually synchronise pending data'**
  String get dataSyncNowSubtitle;

  /// No description provided for @dataSyncLast.
  ///
  /// In en, this message translates to:
  /// **'Last synchronisation'**
  String get dataSyncLast;

  /// No description provided for @dataSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get dataSyncNever;

  /// No description provided for @dataSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Synchronisation status'**
  String get dataSyncStatus;

  /// No description provided for @dataSyncStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not yet available'**
  String get dataSyncStatusUnavailable;

  /// No description provided for @dataOfflineAvailable.
  ///
  /// In en, this message translates to:
  /// **'Offline data'**
  String get dataOfflineAvailable;

  /// No description provided for @dataOfflineAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View content saved on this device'**
  String get dataOfflineAvailableSubtitle;

  /// No description provided for @dataStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get dataStorageUsed;

  /// No description provided for @dataStorageUsedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No offline data available'**
  String get dataStorageUsedUnavailable;

  /// No description provided for @dataManageOffline.
  ///
  /// In en, this message translates to:
  /// **'Manage offline data'**
  String get dataManageOffline;

  /// No description provided for @dataManageOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage content available without an internet connection'**
  String get dataManageOfflineSubtitle;

  /// No description provided for @dataClearOffline.
  ///
  /// In en, this message translates to:
  /// **'Clear offline data'**
  String get dataClearOffline;

  /// No description provided for @dataClearOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove already synchronised offline copies from this device'**
  String get dataClearOfflineSubtitle;

  /// No description provided for @dataWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Sync on Wi-Fi only'**
  String get dataWifiOnly;

  /// No description provided for @dataWifiOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Avoid synchronisation over mobile data'**
  String get dataWifiOnlySubtitle;

  /// No description provided for @dataMobileData.
  ///
  /// In en, this message translates to:
  /// **'Use mobile data'**
  String get dataMobileData;

  /// No description provided for @dataMobileDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow synchronisation over a mobile network'**
  String get dataMobileDataSubtitle;

  /// No description provided for @dataAutomaticDownloads.
  ///
  /// In en, this message translates to:
  /// **'Automatic downloads'**
  String get dataAutomaticDownloads;

  /// No description provided for @dataAutomaticDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically download content available offline'**
  String get dataAutomaticDownloadsSubtitle;

  /// No description provided for @tripsTitle.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get tripsTitle;

  /// No description provided for @tripsNewTrip.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get tripsNewTrip;

  /// No description provided for @tripsInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get tripsInProgress;

  /// No description provided for @tripsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tripsUpcoming;

  /// No description provided for @tripsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripsCompleted;

  /// No description provided for @tripsDayProgress.
  ///
  /// In en, this message translates to:
  /// **'Day {currentDay} of {totalDays}'**
  String tripsDayProgress(int currentDay, int totalDays);

  /// No description provided for @tripsCompletedStatus.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get tripsCompletedStatus;

  /// No description provided for @createTripTitle.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get createTripTitle;

  /// No description provided for @createTripChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get createTripChangePhoto;

  /// No description provided for @createTripName.
  ///
  /// In en, this message translates to:
  /// **'Trip name'**
  String get createTripName;

  /// No description provided for @createTripNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Japan 2027'**
  String get createTripNameHint;

  /// No description provided for @createTripDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get createTripDestination;

  /// No description provided for @createTripDestinationHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a destination'**
  String get createTripDestinationHint;

  /// No description provided for @createTripDates.
  ///
  /// In en, this message translates to:
  /// **'DATES'**
  String get createTripDates;

  /// No description provided for @createTripDepartureDate.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get createTripDepartureDate;

  /// No description provided for @createTripReturnDate.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get createTripReturnDate;

  /// No description provided for @createTripCurrency.
  ///
  /// In en, this message translates to:
  /// **'Main currency'**
  String get createTripCurrency;

  /// No description provided for @createTripCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a currency'**
  String get createTripCurrencyHint;

  /// No description provided for @createTripStorageSection.
  ///
  /// In en, this message translates to:
  /// **'TRIP STORAGE'**
  String get createTripStorageSection;

  /// No description provided for @createTripStorage.
  ///
  /// In en, this message translates to:
  /// **'Configure storage'**
  String get createTripStorage;

  /// No description provided for @createTripStorageConfigured.
  ///
  /// In en, this message translates to:
  /// **'CONFIGURED'**
  String get createTripStorageConfigured;

  /// No description provided for @createTripStorageRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your trip first'**
  String get createTripStorageRequirementsTitle;

  /// No description provided for @createTripStorageRequirementsMessage.
  ///
  /// In en, this message translates to:
  /// **'To configure storage, complete the following first:'**
  String get createTripStorageRequirementsMessage;

  /// No description provided for @createTripStorageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive, OneDrive or Dropbox.'**
  String get createTripStorageSubtitle;

  /// No description provided for @createTripCreate.
  ///
  /// In en, this message translates to:
  /// **'CREATE TRIP'**
  String get createTripCreate;

  /// No description provided for @tripCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'{tripName} is ready!'**
  String tripCreatedTitle(String tripName);

  /// No description provided for @tripCreatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your trip has been created. Invite your travel companions or enter the trip and start organising it.'**
  String get tripCreatedSubtitle;

  /// No description provided for @tripCreatedInviteTravellers.
  ///
  /// In en, this message translates to:
  /// **'Invite travellers'**
  String get tripCreatedInviteTravellers;

  /// No description provided for @tripCreatedCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get tripCreatedCopyLink;

  /// No description provided for @tripCreatedShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tripCreatedShare;

  /// No description provided for @tripCreatedEnterTrip.
  ///
  /// In en, this message translates to:
  /// **'Enter trip'**
  String get tripCreatedEnterTrip;

  /// No description provided for @tripCreatedLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invitation link copied'**
  String get tripCreatedLinkCopied;

  /// No description provided for @tripsUpcomingStatus.
  ///
  /// In en, this message translates to:
  /// **'Upcoming trip'**
  String get tripsUpcomingStatus;

  /// No description provided for @tripNavTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get tripNavTrips;

  /// No description provided for @tripNavItinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get tripNavItinerary;

  /// No description provided for @tripNavBucketList.
  ///
  /// In en, this message translates to:
  /// **'Bucket List'**
  String get tripNavBucketList;

  /// No description provided for @tripNavMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tripNavMore;

  /// No description provided for @tripMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tripMoreTitle;

  /// No description provided for @tripMoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything related to your trip'**
  String get tripMoreSubtitle;

  /// No description provided for @tripMoreRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get tripMoreRestaurants;

  /// No description provided for @tripMoreRestaurantsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organise restaurants and places to eat'**
  String get tripMoreRestaurantsSubtitle;

  /// No description provided for @tripMoreHotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels and accommodation'**
  String get tripMoreHotels;

  /// No description provided for @tripMoreHotelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage hotels and accommodation'**
  String get tripMoreHotelsSubtitle;

  /// No description provided for @tripMoreShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get tripMoreShopping;

  /// No description provided for @tripMoreShoppingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save shops and places for shopping'**
  String get tripMoreShoppingSubtitle;

  /// No description provided for @tripMoreTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get tripMoreTransport;

  /// No description provided for @tripMoreTransportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organise transport for your trip'**
  String get tripMoreTransportSubtitle;

  /// No description provided for @tripMoreBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get tripMoreBookings;

  /// No description provided for @tripMoreBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tickets, admissions and bookings'**
  String get tripMoreBookingsSubtitle;

  /// No description provided for @tripMoreSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get tripMoreSavedPlaces;

  /// No description provided for @tripMoreSavedPlacesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep useful places for your trip together'**
  String get tripMoreSavedPlacesSubtitle;

  /// No description provided for @tripMoreMemories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get tripMoreMemories;

  /// No description provided for @tripMoreMemoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos, videos and moments from your trip'**
  String get tripMoreMemoriesSubtitle;

  /// No description provided for @tripMoreNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tripMoreNotes;

  /// No description provided for @tripMoreNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notes and useful information'**
  String get tripMoreNotesSubtitle;

  /// No description provided for @tripMoreSettings.
  ///
  /// In en, this message translates to:
  /// **'Trip settings'**
  String get tripMoreSettings;

  /// No description provided for @tripMoreSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage trip information, privacy and options'**
  String get tripMoreSettingsSubtitle;

  /// No description provided for @tripRestaurantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get tripRestaurantsTitle;

  /// No description provided for @tripHotelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hotels and accommodation'**
  String get tripHotelsTitle;

  /// No description provided for @tripShoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get tripShoppingTitle;

  /// No description provided for @tripTransportTitle.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get tripTransportTitle;

  /// No description provided for @tripBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get tripBookingsTitle;

  /// No description provided for @tripSavedPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get tripSavedPlacesTitle;

  /// No description provided for @tripMemoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get tripMemoriesTitle;

  /// No description provided for @tripNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tripNotesTitle;

  /// No description provided for @tripSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip settings'**
  String get tripSettingsTitle;

  /// No description provided for @tripSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage this trip'**
  String get tripSettingsSubtitle;

  /// No description provided for @tripSettingsInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get tripSettingsInformation;

  /// No description provided for @tripSettingsInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, destination, dates and trip details'**
  String get tripSettingsInformationSubtitle;

  /// No description provided for @tripSettingsTravellers.
  ///
  /// In en, this message translates to:
  /// **'Travellers'**
  String get tripSettingsTravellers;

  /// No description provided for @tripSettingsTravellersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage travellers, invitations and roles'**
  String get tripSettingsTravellersSubtitle;

  /// No description provided for @tripSettingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and sharing'**
  String get tripSettingsPrivacy;

  /// No description provided for @tripSettingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage trip visibility and sharing'**
  String get tripSettingsPrivacySubtitle;

  /// No description provided for @tripSettingsManagement.
  ///
  /// In en, this message translates to:
  /// **'Trip management'**
  String get tripSettingsManagement;

  /// No description provided for @tripSettingsManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud storage, trip status, duplication and deletion'**
  String get tripSettingsManagementSubtitle;

  /// No description provided for @tripPrivacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Control access, invitations and sharing for this trip.'**
  String get tripPrivacyIntro;

  /// No description provided for @tripPrivacyAccess.
  ///
  /// In en, this message translates to:
  /// **'Trip access'**
  String get tripPrivacyAccess;

  /// No description provided for @tripPrivacyInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Invitation link'**
  String get tripPrivacyInviteLink;

  /// No description provided for @tripPrivacyTravellers.
  ///
  /// In en, this message translates to:
  /// **'Travellers'**
  String get tripPrivacyTravellers;

  /// No description provided for @tripPrivacyTravellersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage trip participants'**
  String get tripPrivacyTravellersSubtitle;

  /// No description provided for @tripPrivacyRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles and permissions'**
  String get tripPrivacyRoles;

  /// No description provided for @tripManagementLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load trip management information.'**
  String get tripManagementLoadError;

  /// No description provided for @tripManagementArchiveSection.
  ///
  /// In en, this message translates to:
  /// **'Trip storage'**
  String get tripManagementArchiveSection;

  /// No description provided for @tripManagementArchiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Storage status'**
  String get tripManagementArchiveStatus;

  /// No description provided for @tripManagementArchiveNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'No storage configured'**
  String get tripManagementArchiveNotConfigured;

  /// No description provided for @tripManagementArchiveFolder.
  ///
  /// In en, this message translates to:
  /// **'Storage folder'**
  String get tripManagementArchiveFolder;

  /// No description provided for @tripManagementArchiveVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify storage'**
  String get tripManagementArchiveVerify;

  /// No description provided for @tripManagementArchiveVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check that the storage is still available and accessible'**
  String get tripManagementArchiveVerifySubtitle;

  /// No description provided for @tripManagementArchiveOpen.
  ///
  /// In en, this message translates to:
  /// **'Open storage'**
  String get tripManagementArchiveOpen;

  /// No description provided for @tripManagementArchiveOpenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the trip folder in the connected provider'**
  String get tripManagementArchiveOpenSubtitle;

  /// No description provided for @tripManagementArchiveChange.
  ///
  /// In en, this message translates to:
  /// **'Change storage'**
  String get tripManagementArchiveChange;

  /// No description provided for @tripManagementArchiveChangeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect the trip to a new storage location'**
  String get tripManagementArchiveChangeSubtitle;

  /// No description provided for @tripManagementArchiveReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect Google Drive'**
  String get tripManagementArchiveReconnect;

  /// No description provided for @tripManagementArchiveReconnectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore authorisation without moving trip files'**
  String get tripManagementArchiveReconnectSubtitle;

  /// No description provided for @tripManagementDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate trip'**
  String get tripManagementDuplicate;

  /// No description provided for @tripManagementDuplicateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy the trip\'s Firestore content without members, cloud storage or external files'**
  String get tripManagementDuplicateSubtitle;

  /// No description provided for @tripManagementDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get tripManagementDelete;

  /// No description provided for @tripManagementDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete the trip data from Amaterasu; personal cloud files remain untouched'**
  String get tripManagementDeleteSubtitle;

  /// No description provided for @tripMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tripMapTitle;

  /// No description provided for @tripExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get tripExpensesTitle;

  /// No description provided for @tripTravellersTitle.
  ///
  /// In en, this message translates to:
  /// **'Travellers'**
  String get tripTravellersTitle;

  /// No description provided for @tripTravellersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View the people taking part in the trip'**
  String get tripTravellersSubtitle;

  /// No description provided for @tripMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and organise places for your trip'**
  String get tripMapSubtitle;

  /// No description provided for @tripExpensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage expenses, splits and reimbursements'**
  String get tripExpensesSubtitle;

  /// No description provided for @tripOverviewItinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get tripOverviewItinerary;

  /// No description provided for @tripOverviewBucketListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep together everything you want to see and do'**
  String get tripOverviewBucketListSubtitle;

  /// No description provided for @tripOverviewMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tripOverviewMore;

  /// No description provided for @tripOverviewNotFound.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get tripOverviewNotFound;

  /// No description provided for @tripOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tripOverviewTitle;

  /// No description provided for @tripOverviewError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the trip'**
  String get tripOverviewError;

  /// No description provided for @tripOverviewMoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Map, expenses, travellers, bookings and more'**
  String get tripOverviewMoreSubtitle;

  /// No description provided for @tripOverviewItinerarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organise days, stops and activities'**
  String get tripOverviewItinerarySubtitle;

  /// No description provided for @tripOverviewExploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access the main sections of your trip'**
  String get tripOverviewExploreSubtitle;

  /// No description provided for @tripOverviewBucketList.
  ///
  /// In en, this message translates to:
  /// **'Bucket List'**
  String get tripOverviewBucketList;

  /// No description provided for @tripCoverRemoveError.
  ///
  /// In en, this message translates to:
  /// **'The cover could not be removed.'**
  String get tripCoverRemoveError;

  /// No description provided for @tripCoverCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get tripCoverCamera;

  /// No description provided for @tripCoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip cover'**
  String get tripCoverTitle;

  /// No description provided for @tripCoverAdd.
  ///
  /// In en, this message translates to:
  /// **'Add cover'**
  String get tripCoverAdd;

  /// No description provided for @tripCoverRemoved.
  ///
  /// In en, this message translates to:
  /// **'Cover removed'**
  String get tripCoverRemoved;

  /// No description provided for @tripCoverUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cover updated'**
  String get tripCoverUpdated;

  /// No description provided for @tripCoverGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get tripCoverGallery;

  /// No description provided for @tripCoverPickerError.
  ///
  /// In en, this message translates to:
  /// **'The cover could not be selected.'**
  String get tripCoverPickerError;

  /// No description provided for @tripCoverUploadError.
  ///
  /// In en, this message translates to:
  /// **'The cover could not be uploaded.'**
  String get tripCoverUploadError;

  /// No description provided for @tripCoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the image that represents your trip'**
  String get tripCoverSubtitle;

  /// No description provided for @tripCoverChange.
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get tripCoverChange;

  /// No description provided for @tripCoverRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get tripCoverRemove;

  /// No description provided for @destinationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose destination'**
  String get destinationPickerTitle;

  /// No description provided for @destinationPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a country or city...'**
  String get destinationPickerSearchHint;

  /// No description provided for @destinationPickerMapLabel.
  ///
  /// In en, this message translates to:
  /// **'WORLD MAP'**
  String get destinationPickerMapLabel;

  /// No description provided for @destinationPickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get destinationPickerConfirm;

  /// No description provided for @destinationPickerNoResults.
  ///
  /// In en, this message translates to:
  /// **'No destinations found'**
  String get destinationPickerNoResults;

  /// No description provided for @destinationGenericError.
  ///
  /// In en, this message translates to:
  /// **'The search could not be completed. Please try again.'**
  String get destinationGenericError;

  /// No description provided for @destinationMapResolving.
  ///
  /// In en, this message translates to:
  /// **'Identifying location...'**
  String get destinationMapResolving;

  /// No description provided for @destinationMapNoPlace.
  ///
  /// In en, this message translates to:
  /// **'No geographic location was found at this point.'**
  String get destinationMapNoPlace;

  /// No description provided for @destinationMapTapToExplore.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to explore'**
  String get destinationMapTapToExplore;

  /// No description provided for @destinationMapTwoFingers.
  ///
  /// In en, this message translates to:
  /// **'Use two fingers to explore'**
  String get destinationMapTwoFingers;

  /// No description provided for @createTripCurrencyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No currencies found'**
  String get createTripCurrencyNoResults;

  /// No description provided for @createTripCurrencySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search currency...'**
  String get createTripCurrencySearchHint;

  /// No description provided for @tripCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip storage'**
  String get tripCloudTitle;

  /// No description provided for @tripCloudHeading.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to keep your memories?'**
  String get tripCloudHeading;

  /// No description provided for @tripCloudDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect your cloud service. Amaterasu will create the trip folder inside the main folder you choose.'**
  String get tripCloudDescription;

  /// No description provided for @tripCloudGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get tripCloudGoogleDrive;

  /// No description provided for @tripCloudGoogleDriveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Drive and choose the main folder'**
  String get tripCloudGoogleDriveSubtitle;

  /// No description provided for @tripCloudOneDrive.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get tripCloudOneDrive;

  /// No description provided for @tripCloudDropbox.
  ///
  /// In en, this message translates to:
  /// **'Dropbox'**
  String get tripCloudDropbox;

  /// No description provided for @tripCloudProviderComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Setup coming soon'**
  String get tripCloudProviderComingSoon;

  /// No description provided for @tripCloudPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu will only request access required for files and folders used with the app.'**
  String get tripCloudPrivacyNote;

  /// No description provided for @tripCloudGoogleDriveLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should the archive be created?'**
  String get tripCloudGoogleDriveLocationTitle;

  /// No description provided for @tripCloudGoogleDriveLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose My Drive or a specific folder. The trip folder will only be created when you create the trip.'**
  String get tripCloudGoogleDriveLocationDescription;

  /// No description provided for @tripCloudGoogleDriveRoot.
  ///
  /// In en, this message translates to:
  /// **'My Drive'**
  String get tripCloudGoogleDriveRoot;

  /// No description provided for @tripCloudGoogleDriveRootSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the trip folder directly in your Drive'**
  String get tripCloudGoogleDriveRootSubtitle;

  /// No description provided for @tripCloudGoogleDriveChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get tripCloudGoogleDriveChooseFolder;

  /// No description provided for @tripCloudGoogleDriveChooseFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open Google Drive and select the parent folder'**
  String get tripCloudGoogleDriveChooseFolderSubtitle;

  /// No description provided for @tripCloudGoogleDriveError.
  ///
  /// In en, this message translates to:
  /// **'Google Drive could not be configured. Please try again.'**
  String get tripCloudGoogleDriveError;

  /// No description provided for @createTripCreationError.
  ///
  /// In en, this message translates to:
  /// **'The trip could not be created. Please try again.'**
  String get createTripCreationError;

  /// No description provided for @tripManagementArchiveChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get tripManagementArchiveChecking;

  /// No description provided for @tripManagementArchiveAvailable.
  ///
  /// In en, this message translates to:
  /// **'Configured and accessible'**
  String get tripManagementArchiveAvailable;

  /// No description provided for @tripManagementArchiveUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Needs checking'**
  String get tripManagementArchiveUnchecked;

  /// No description provided for @tripManagementArchiveAuthorizationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authorisation required'**
  String get tripManagementArchiveAuthorizationRequired;

  /// No description provided for @tripManagementArchiveInaccessible.
  ///
  /// In en, this message translates to:
  /// **'Storage unavailable'**
  String get tripManagementArchiveInaccessible;

  /// No description provided for @tripManagementArchiveNotFound.
  ///
  /// In en, this message translates to:
  /// **'Storage deleted or not found'**
  String get tripManagementArchiveNotFound;

  /// No description provided for @tripManagementArchiveInsufficientSpace.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Google Drive storage'**
  String get tripManagementArchiveInsufficientSpace;

  /// No description provided for @tripManagementArchiveNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Needs checking · connection unavailable'**
  String get tripManagementArchiveNetworkUnavailable;

  /// No description provided for @tripManagementArchiveError.
  ///
  /// In en, this message translates to:
  /// **'Synchronisation error'**
  String get tripManagementArchiveError;

  /// No description provided for @tripManagementArchiveVerified.
  ///
  /// In en, this message translates to:
  /// **'Storage checked successfully.'**
  String get tripManagementArchiveVerified;

  /// No description provided for @tripManagementArchiveReconnectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Google Drive has been reconnected. The trip storage is accessible.'**
  String get tripManagementArchiveReconnectSuccess;

  /// No description provided for @tripManagementArchiveReconnectUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Drive is connected, but the trip storage is not accessible with this account.'**
  String get tripManagementArchiveReconnectUnavailable;

  /// No description provided for @tripManagementArchiveChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change storage?'**
  String get tripManagementArchiveChangeTitle;

  /// No description provided for @tripManagementArchiveChangeBody.
  ///
  /// In en, this message translates to:
  /// **'A new storage folder will be created and connected. Files in the current folder will not be moved, deleted or modified.'**
  String get tripManagementArchiveChangeBody;

  /// No description provided for @tripManagementArchiveChangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change storage'**
  String get tripManagementArchiveChangeConfirm;

  /// No description provided for @tripManagementArchiveChanged.
  ///
  /// In en, this message translates to:
  /// **'New storage connected successfully.'**
  String get tripManagementArchiveChanged;

  /// No description provided for @tripManagementDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete trip?'**
  String get tripManagementDeleteTitle;

  /// No description provided for @tripManagementDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get tripManagementDeleteConfirm;

  /// No description provided for @tripManagementCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tripManagementCancel;

  /// No description provided for @tripManagementOperationError.
  ///
  /// In en, this message translates to:
  /// **'The operation failed. Please try again.'**
  String get tripManagementOperationError;

  /// No description provided for @tripInformationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip information'**
  String get tripInformationSectionTitle;

  /// No description provided for @tripInformationName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tripInformationName;

  /// No description provided for @tripInformationDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get tripInformationDestination;

  /// No description provided for @tripInformationStartDate.
  ///
  /// In en, this message translates to:
  /// **'Departure date'**
  String get tripInformationStartDate;

  /// No description provided for @tripInformationEndDate.
  ///
  /// In en, this message translates to:
  /// **'Return date'**
  String get tripInformationEndDate;

  /// No description provided for @tripInformationDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get tripInformationDescription;

  /// No description provided for @tripInformationDescriptionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get tripInformationDescriptionEmpty;

  /// No description provided for @tripInformationCurrency.
  ///
  /// In en, this message translates to:
  /// **'Main currency'**
  String get tripInformationCurrency;

  /// No description provided for @tripInformationSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tripInformationSave;

  /// No description provided for @tripInformationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tripInformationCancel;

  /// No description provided for @tripInformationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Trip information updated.'**
  String get tripInformationUpdated;

  /// No description provided for @tripInformationUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update the trip information.'**
  String get tripInformationUpdateError;

  /// No description provided for @tripInviteAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip invitation'**
  String get tripInviteAppBarTitle;

  /// No description provided for @tripInviteHeading.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited to a trip'**
  String get tripInviteHeading;

  /// No description provided for @tripInviteUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation unavailable'**
  String get tripInviteUnavailableTitle;

  /// No description provided for @tripInviteUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The link may be invalid, revoked or replaced by a newer invitation.'**
  String get tripInviteUnavailableBody;

  /// No description provided for @tripInviteRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tripInviteRetry;

  /// No description provided for @tripCreatedInviteShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Invitation to {tripName}'**
  String tripCreatedInviteShareSubject(String tripName);

  /// No description provided for @tripCreatedInviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join the trip {tripName} on Amaterasu Trip.\nOpen this invitation:\n{link}'**
  String tripCreatedInviteShareText(String tripName, String link);

  /// No description provided for @tripCreatedInviteError.
  ///
  /// In en, this message translates to:
  /// **'The invitation could not be prepared. Please try again.'**
  String get tripCreatedInviteError;

  /// No description provided for @tripTravellersSettingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Manage trip participants, invitations and profiles.'**
  String get tripTravellersSettingsIntro;

  /// No description provided for @tripTravellersInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite traveller'**
  String get tripTravellersInvite;

  /// No description provided for @tripTravellersInviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and share a private invitation link'**
  String get tripTravellersInviteSubtitle;

  /// No description provided for @tripTravellersParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get tripTravellersParticipants;

  /// No description provided for @tripTravellersEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no participants in this trip yet.'**
  String get tripTravellersEmpty;

  /// No description provided for @tripTravellersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load trip participants.'**
  String get tripTravellersLoadError;

  /// No description provided for @tripTravellersOwnerRole.
  ///
  /// In en, this message translates to:
  /// **'OWNER'**
  String get tripTravellersOwnerRole;

  /// No description provided for @tripTravellersTravelerRole.
  ///
  /// In en, this message translates to:
  /// **'TRAVELER'**
  String get tripTravellersTravelerRole;

  /// No description provided for @tripTravellersYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get tripTravellersYou;

  /// No description provided for @tripTravellersSensitiveDataNotice.
  ///
  /// In en, this message translates to:
  /// **'The trip profile contains organisational information, such as Internet connectivity and baggage preferences. Answers are visible to trip participants and can be updated by the person they belong to.'**
  String get tripTravellersSensitiveDataNotice;

  /// No description provided for @tripTravellersCopyInvite.
  ///
  /// In en, this message translates to:
  /// **'Copy invitation link'**
  String get tripTravellersCopyInvite;

  /// No description provided for @tripTravellersShareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invitation'**
  String get tripTravellersShareInvite;

  /// No description provided for @tripTravellersRegenerateInvite.
  ///
  /// In en, this message translates to:
  /// **'Regenerate invitation link'**
  String get tripTravellersRegenerateInvite;

  /// No description provided for @tripTravellersRevokeInvite.
  ///
  /// In en, this message translates to:
  /// **'Revoke invitation link'**
  String get tripTravellersRevokeInvite;

  /// No description provided for @tripTravellersInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invitation link copied.'**
  String get tripTravellersInviteCopied;

  /// No description provided for @tripTravellersInviteRegenerated.
  ///
  /// In en, this message translates to:
  /// **'A new invitation link has been generated. The previous link is no longer valid.'**
  String get tripTravellersInviteRegenerated;

  /// No description provided for @tripTravellersInviteRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invitation link revoked.'**
  String get tripTravellersInviteRevoked;

  /// No description provided for @tripTravellersInviteActionError.
  ///
  /// In en, this message translates to:
  /// **'Unable to manage the invitation link.'**
  String get tripTravellersInviteActionError;

  /// No description provided for @tripTravellersRevokeInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke the invitation link?'**
  String get tripTravellersRevokeInviteTitle;

  /// No description provided for @tripTravellersRevokeInviteBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the current link will no longer be able to use it to join the trip.'**
  String get tripTravellersRevokeInviteBody;

  /// No description provided for @tripTravellersRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get tripTravellersRevoke;

  /// No description provided for @tripTravellersCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tripTravellersCancel;

  /// No description provided for @tripTravellersMembership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get tripTravellersMembership;

  /// No description provided for @tripTravellersRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get tripTravellersRole;

  /// No description provided for @tripTravellersJoinedAt.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get tripTravellersJoinedAt;

  /// No description provided for @tripTravellersOrganisation.
  ///
  /// In en, this message translates to:
  /// **'Trip organisation'**
  String get tripTravellersOrganisation;

  /// No description provided for @tripTravellersEsim.
  ///
  /// In en, this message translates to:
  /// **'eSIM / internet connection'**
  String get tripTravellersEsim;

  /// No description provided for @tripTravellersCheckedBaggage.
  ///
  /// In en, this message translates to:
  /// **'Checked baggage'**
  String get tripTravellersCheckedBaggage;

  /// No description provided for @tripTravellersCabinBaggage.
  ///
  /// In en, this message translates to:
  /// **'10 kg cabin baggage'**
  String get tripTravellersCabinBaggage;

  /// No description provided for @tripTravellersYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get tripTravellersYes;

  /// No description provided for @tripTravellersNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get tripTravellersNo;

  /// No description provided for @tripTravellersUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get tripTravellersUnknown;

  /// No description provided for @tripTravellersNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get tripTravellersNotProvided;

  /// No description provided for @tripTravellersEditMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit my trip profile'**
  String get tripTravellersEditMyProfile;

  /// No description provided for @tripTravellersEditProfileNote.
  ///
  /// In en, this message translates to:
  /// **'This information belongs to this trip. Only you can edit your personal trip-profile information.'**
  String get tripTravellersEditProfileNote;

  /// No description provided for @tripTravellersProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Trip profile updated.'**
  String get tripTravellersProfileUpdated;

  /// No description provided for @tripTravellersRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from trip'**
  String get tripTravellersRemove;

  /// No description provided for @tripTravellersLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave trip'**
  String get tripTravellersLeave;

  /// No description provided for @tripTravellersRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove traveller?'**
  String get tripTravellersRemoveTitle;

  /// No description provided for @tripTravellersRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will lose access to the trip and to data shared with trip participants.'**
  String tripTravellersRemoveBody(String name);

  /// No description provided for @tripTravellersRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get tripTravellersRemoveConfirm;

  /// No description provided for @tripTravellersLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the trip?'**
  String get tripTravellersLeaveTitle;

  /// No description provided for @tripTravellersLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to the trip and to data shared with participants. You will only be able to rejoin through a new invitation.'**
  String get tripTravellersLeaveBody;

  /// No description provided for @tripTravellersLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave trip'**
  String get tripTravellersLeaveConfirm;

  /// No description provided for @tripTravellersRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Traveller removed from the trip.'**
  String get tripTravellersRemovedSuccess;

  /// No description provided for @tripTravellersRemoveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete the operation.'**
  String get tripTravellersRemoveError;

  /// No description provided for @tripTravellersOwnerProtected.
  ///
  /// In en, this message translates to:
  /// **'The OWNER cannot be removed from the trip. Any ownership change must use a dedicated transfer procedure.'**
  String get tripTravellersOwnerProtected;

  /// No description provided for @tripPrivacyAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Access and invitations'**
  String get tripPrivacyAccessSection;

  /// No description provided for @tripPrivacyAccessPrivateDetail.
  ///
  /// In en, this message translates to:
  /// **'This trip is private. Only authorised trip members can access it. Amaterasu does not provide a \"public trip\" mode: the invitation link only starts the joining process and does not automatically make someone a member.'**
  String get tripPrivacyAccessPrivateDetail;

  /// No description provided for @tripPrivacyInviteStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get tripPrivacyInviteStatusChecking;

  /// No description provided for @tripPrivacyInviteStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'Not created yet'**
  String get tripPrivacyInviteStatusMissing;

  /// No description provided for @tripPrivacyInviteStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tripPrivacyInviteStatusActive;

  /// No description provided for @tripPrivacyInviteStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get tripPrivacyInviteStatusRevoked;

  /// No description provided for @tripPrivacyInviteStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get tripPrivacyInviteStatusUnavailable;

  /// No description provided for @tripPrivacyInviteLinkWithStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status} · create, copy, share, regenerate or revoke the link from the Travellers section'**
  String tripPrivacyInviteLinkWithStatus(String status);

  /// No description provided for @tripPrivacyProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Trip profile data'**
  String get tripPrivacyProfileSection;

  /// No description provided for @tripPrivacyProfileData.
  ///
  /// In en, this message translates to:
  /// **'Travellers\' trip profiles'**
  String get tripPrivacyProfileData;

  /// No description provided for @tripPrivacyProfileDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Travellers\' organisational information'**
  String get tripPrivacyProfileDataSubtitle;

  /// No description provided for @tripPrivacyRolesSection.
  ///
  /// In en, this message translates to:
  /// **'Roles and permissions'**
  String get tripPrivacyRolesSection;

  /// No description provided for @tripPrivacyRolesCurrentAllowed.
  ///
  /// In en, this message translates to:
  /// **'Your role is {role}. At this stage OWNER and TRAVELER have the same trip permissions. Authorisation is determined by the trip\'s central access policy.'**
  String tripPrivacyRolesCurrentAllowed(String role);

  /// No description provided for @tripPrivacyRolesCurrentReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Your role is {role}. You can view this information, but the trip policy does not authorise you to manage roles and permissions.'**
  String tripPrivacyRolesCurrentReadOnly(String role);

  /// No description provided for @tripPrivacyExternalSection.
  ///
  /// In en, this message translates to:
  /// **'External sharing'**
  String get tripPrivacyExternalSection;

  /// No description provided for @tripPrivacyExternalArchive.
  ///
  /// In en, this message translates to:
  /// **'External cloud archive'**
  String get tripPrivacyExternalArchive;

  /// No description provided for @tripPrivacyExternalArchiveNone.
  ///
  /// In en, this message translates to:
  /// **'No external cloud archive is currently linked to this trip.'**
  String get tripPrivacyExternalArchiveNone;

  /// No description provided for @tripPrivacyExternalArchiveConnected.
  ///
  /// In en, this message translates to:
  /// **'{provider} is linked to this trip.'**
  String tripPrivacyExternalArchiveConnected(String provider);

  /// No description provided for @tripPrivacyExternalControl.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu invitation links and the cloud archive are separate. Files, available storage and Google Drive, OneDrive or Dropbox permissions remain under the control of the external provider account and are not made public by Amaterasu.'**
  String get tripPrivacyExternalControl;

  /// No description provided for @tripPrivacyAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this trip\'s privacy and sharing settings.'**
  String get tripPrivacyAccessDenied;

  /// No description provided for @tripPrivacyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load privacy and sharing settings.'**
  String get tripPrivacyLoadError;

  /// No description provided for @tripManagementFinalConfigureArchive.
  ///
  /// In en, this message translates to:
  /// **'Configure storage'**
  String get tripManagementFinalConfigureArchive;

  /// No description provided for @tripManagementFinalConfigureArchiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Link personal cloud storage to this trip'**
  String get tripManagementFinalConfigureArchiveSubtitle;

  /// No description provided for @tripManagementFinalArchiveOwnershipTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal cloud storage'**
  String get tripManagementFinalArchiveOwnershipTitle;

  /// No description provided for @tripManagementFinalArchiveOwnershipBody.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu stores the link to the archive, but the files remain under the control of the user\'s Google Drive, OneDrive or Dropbox account.'**
  String get tripManagementFinalArchiveOwnershipBody;

  /// No description provided for @tripManagementFinalArchiveProviderUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This provider is registered for the trip, but verification, opening and reconnection are not yet available. You can still change the archive.'**
  String get tripManagementFinalArchiveProviderUnsupported;

  /// No description provided for @tripManagementFinalStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Trip status'**
  String get tripManagementFinalStatusSection;

  /// No description provided for @tripManagementFinalTripStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get tripManagementFinalTripStatus;

  /// No description provided for @tripManagementFinalStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tripManagementFinalStatusActive;

  /// No description provided for @tripManagementFinalStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get tripManagementFinalStatusClosed;

  /// No description provided for @tripManagementFinalStatusActiveBody.
  ///
  /// In en, this message translates to:
  /// **'The trip is active and appears normally among current or upcoming trips.'**
  String get tripManagementFinalStatusActiveBody;

  /// No description provided for @tripManagementFinalStatusClosedBody.
  ///
  /// In en, this message translates to:
  /// **'The trip is archived, but remains fully viewable and editable.'**
  String get tripManagementFinalStatusClosedBody;

  /// No description provided for @tripManagementFinalArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive trip'**
  String get tripManagementFinalArchiveAction;

  /// No description provided for @tripManagementFinalArchiveActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Move the trip to archived trips without preventing viewing or editing'**
  String get tripManagementFinalArchiveActionSubtitle;

  /// No description provided for @tripManagementFinalReactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Reactivate trip'**
  String get tripManagementFinalReactivateAction;

  /// No description provided for @tripManagementFinalReactivateActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Return the trip to active status'**
  String get tripManagementFinalReactivateActionSubtitle;

  /// No description provided for @tripManagementFinalArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this trip?'**
  String get tripManagementFinalArchiveConfirmTitle;

  /// No description provided for @tripManagementFinalArchiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The trip will be marked as archived. All data will remain available and you will still be able to view and edit it.'**
  String get tripManagementFinalArchiveConfirmBody;

  /// No description provided for @tripManagementFinalArchiveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get tripManagementFinalArchiveConfirmAction;

  /// No description provided for @tripManagementFinalReactivateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate this trip?'**
  String get tripManagementFinalReactivateConfirmTitle;

  /// No description provided for @tripManagementFinalReactivateConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The trip will return to active status without losing or changing any content.'**
  String get tripManagementFinalReactivateConfirmBody;

  /// No description provided for @tripManagementFinalReactivateConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get tripManagementFinalReactivateConfirmAction;

  /// No description provided for @tripManagementFinalStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Trip status updated'**
  String get tripManagementFinalStatusUpdated;

  /// No description provided for @tripManagementFinalOperationsSection.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get tripManagementFinalOperationsSection;

  /// No description provided for @tripManagementFinalDuplicateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate this trip?'**
  String get tripManagementFinalDuplicateConfirmTitle;

  /// No description provided for @tripManagementFinalDuplicateConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Amaterasu will create a new trip by copying the trip document and all Firestore content stored in its subcollections, including subcollections added in the future. Members, invitations, trip profiles, Drive/OneDrive/Dropbox storage, file-backed cover references and external file references will not be copied. The new trip will be active and the person creating the duplicate will be its only initial member.'**
  String get tripManagementFinalDuplicateConfirmBody;

  /// No description provided for @tripManagementFinalDuplicateConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get tripManagementFinalDuplicateConfirmAction;

  /// No description provided for @tripManagementFinalDuplicateCopyName.
  ///
  /// In en, this message translates to:
  /// **'Copy of {name}'**
  String tripManagementFinalDuplicateCopyName(String name);

  /// No description provided for @tripManagementFinalDuplicateSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip duplicated'**
  String get tripManagementFinalDuplicateSuccessTitle;

  /// No description provided for @tripManagementFinalDuplicateSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'The copy \"{name}\" was created successfully.'**
  String tripManagementFinalDuplicateSuccessBody(String name);

  /// No description provided for @tripManagementFinalDuplicateOpen.
  ///
  /// In en, this message translates to:
  /// **'Open copy'**
  String get tripManagementFinalDuplicateOpen;

  /// No description provided for @tripManagementFinalStayHere.
  ///
  /// In en, this message translates to:
  /// **'Stay here'**
  String get tripManagementFinalStayHere;

  /// No description provided for @tripManagementFinalDangerSection.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get tripManagementFinalDangerSection;

  /// No description provided for @tripManagementFinalDeleteCloudWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting the trip from Amaterasu does NOT delete personal files stored in Google Drive, OneDrive or Dropbox. Those files remain under the control of the external cloud account.'**
  String get tripManagementFinalDeleteCloudWarning;

  /// No description provided for @tripManagementFinalDeleteConfirmInstruction.
  ///
  /// In en, this message translates to:
  /// **'To confirm permanent deletion, type \"{name}\" exactly.'**
  String tripManagementFinalDeleteConfirmInstruction(String name);

  /// No description provided for @tripManagementFinalDeleteInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip name'**
  String get tripManagementFinalDeleteInputLabel;

  /// No description provided for @tripManagementFinalAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to manage this trip.'**
  String get tripManagementFinalAccessDenied;

  /// No description provided for @budgetScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget & Expenses'**
  String get budgetScreenTitle;

  /// No description provided for @budgetAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get budgetAddExpense;

  /// No description provided for @budgetSplitExpense.
  ///
  /// In en, this message translates to:
  /// **'How the expense is split'**
  String get budgetSplitExpense;

  /// No description provided for @budgetSupplierPayments.
  ///
  /// In en, this message translates to:
  /// **'Who paid the supplier'**
  String get budgetSupplierPayments;

  /// No description provided for @budgetBalanceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update balances.'**
  String get budgetBalanceLoadError;

  /// No description provided for @budgetMovementConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get budgetMovementConfirmed;

  /// No description provided for @budgetMovementHistory.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement history'**
  String get budgetMovementHistory;

  /// No description provided for @budgetMovementPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get budgetMovementPending;

  /// No description provided for @budgetMovementRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get budgetMovementRejected;

  /// No description provided for @budgetNamesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Traveler names are unavailable.'**
  String get budgetNamesUnavailable;

  /// No description provided for @budgetNoMovements.
  ///
  /// In en, this message translates to:
  /// **'No reimbursements recorded.'**
  String get budgetNoMovements;

  /// No description provided for @budgetNothingToPay.
  ///
  /// In en, this message translates to:
  /// **'No reimbursements to make.'**
  String get budgetNothingToPay;

  /// No description provided for @budgetNothingToReceive.
  ///
  /// In en, this message translates to:
  /// **'No reimbursements to receive.'**
  String get budgetNothingToReceive;

  /// No description provided for @budgetOthersOweYou.
  ///
  /// In en, this message translates to:
  /// **'Owed to you'**
  String get budgetOthersOweYou;

  /// No description provided for @budgetPendingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get budgetPendingConfirmation;

  /// No description provided for @budgetYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get budgetYouOwe;

  /// No description provided for @budgetYourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your finances'**
  String get budgetYourBalance;

  /// No description provided for @budgetRevisionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get budgetRevisionApprove;

  /// No description provided for @budgetRevisionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get budgetRevisionApproved;

  /// No description provided for @budgetRevisionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get budgetRevisionCancel;

  /// No description provided for @budgetRevisionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get budgetRevisionEdit;

  /// No description provided for @budgetRevisionInfo.
  ///
  /// In en, this message translates to:
  /// **'Financial changes must be approved by affected travelers before taking effect.'**
  String get budgetRevisionInfo;

  /// No description provided for @budgetRevisionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check amounts, shares and payment status for consistency.'**
  String get budgetRevisionInvalid;

  /// No description provided for @budgetRevisionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load proposed changes.'**
  String get budgetRevisionLoadError;

  /// No description provided for @budgetRevisionLocked.
  ///
  /// In en, this message translates to:
  /// **'This expense has recorded reimbursements. Financial revisions are locked to preserve history.'**
  String get budgetRevisionLocked;

  /// No description provided for @budgetRevisionOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get budgetRevisionOutstanding;

  /// No description provided for @budgetRevisionPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get budgetRevisionPaid;

  /// No description provided for @budgetRevisionPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Supplier payment status'**
  String get budgetRevisionPaymentStatus;

  /// No description provided for @budgetRevisionPending.
  ///
  /// In en, this message translates to:
  /// **'Change awaiting approval'**
  String get budgetRevisionPending;

  /// No description provided for @budgetRevisionPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get budgetRevisionPlanned;

  /// No description provided for @budgetRevisionPropose.
  ///
  /// In en, this message translates to:
  /// **'Propose changes'**
  String get budgetRevisionPropose;

  /// No description provided for @budgetRevisionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get budgetRevisionReject;

  /// No description provided for @budgetRevisionSection.
  ///
  /// In en, this message translates to:
  /// **'Changes and approvals'**
  String get budgetRevisionSection;

  /// No description provided for @budgetRevisionSent.
  ///
  /// In en, this message translates to:
  /// **'Request recorded. The status will update after approval.'**
  String get budgetRevisionSent;

  /// No description provided for @budgetRevisionShares.
  ///
  /// In en, this message translates to:
  /// **'Individual shares'**
  String get budgetRevisionShares;

  /// No description provided for @budgetRevisionTotal.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get budgetRevisionTotal;

  /// No description provided for @budgetRevisionWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get budgetRevisionWaiting;

  /// No description provided for @budgetMultiPayerHeading.
  ///
  /// In en, this message translates to:
  /// **'Who actually paid the supplier'**
  String get budgetMultiPayerHeading;

  /// No description provided for @budgetMultiPayerApproval.
  ///
  /// In en, this message translates to:
  /// **'Every affected traveler, including each named payer, must approve the change.'**
  String get budgetMultiPayerApproval;

  /// No description provided for @b6Group.
  ///
  /// In en, this message translates to:
  /// **'Group expenses'**
  String get b6Group;

  /// No description provided for @b6Personal.
  ///
  /// In en, this message translates to:
  /// **'My personal expenses'**
  String get b6Personal;

  /// No description provided for @b6GroupByCategory.
  ///
  /// In en, this message translates to:
  /// **'Group expenses by category'**
  String get b6GroupByCategory;

  /// No description provided for @b6PersonalByCategory.
  ///
  /// In en, this message translates to:
  /// **'My expenses by category'**
  String get b6PersonalByCategory;

  /// No description provided for @b6Category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get b6Category;

  /// No description provided for @b6CreateCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get b6CreateCategory;

  /// No description provided for @b6EditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get b6EditCategory;

  /// No description provided for @b6CategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get b6CategoryName;

  /// No description provided for @b6LoadingError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load summary.'**
  String get b6LoadingError;

  /// No description provided for @b6PersonalTotal.
  ///
  /// In en, this message translates to:
  /// **'My expense total'**
  String get b6PersonalTotal;

  /// No description provided for @b6GroupTotal.
  ///
  /// In en, this message translates to:
  /// **'Total of shared expenses involving me'**
  String get b6GroupTotal;

  /// No description provided for @b6PartialTotal.
  ///
  /// In en, this message translates to:
  /// **'Partial total: some currencies are unavailable.'**
  String get b6PartialTotal;

  /// No description provided for @b6ExpenseCount.
  ///
  /// In en, this message translates to:
  /// **'Expense count'**
  String get b6ExpenseCount;

  /// No description provided for @b6MyShare.
  ///
  /// In en, this message translates to:
  /// **'Your share of group expenses'**
  String get b6MyShare;

  /// No description provided for @b6LatestExpense.
  ///
  /// In en, this message translates to:
  /// **'Latest expense'**
  String get b6LatestExpense;

  /// No description provided for @b6PaidToSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Paid to suppliers'**
  String get b6PaidToSuppliers;

  /// No description provided for @b6OutstandingSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Still to pay'**
  String get b6OutstandingSuppliers;

  /// No description provided for @b6NoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses available for the chart.'**
  String get b6NoExpenses;

  /// No description provided for @b6RateSource.
  ///
  /// In en, this message translates to:
  /// **'FX observations and sources:'**
  String get b6RateSource;

  /// No description provided for @b6RateDoesNotChangeDebts.
  ///
  /// In en, this message translates to:
  /// **'FX is for information only: shares, debts and repayments remain in the original currency.'**
  String get b6RateDoesNotChangeDebts;

  /// No description provided for @b6MissingRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate unavailable. Amounts excluded, no invented values:'**
  String get b6MissingRate;

  /// No description provided for @b6ExcludedCount.
  ///
  /// In en, this message translates to:
  /// **'expenses not converted.'**
  String get b6ExcludedCount;

  /// No description provided for @b6ManualRate.
  ///
  /// In en, this message translates to:
  /// **'Correct rate manually'**
  String get b6ManualRate;

  /// No description provided for @b6RateValue.
  ///
  /// In en, this message translates to:
  /// **'Rate (target units per 1 original unit)'**
  String get b6RateValue;

  /// No description provided for @b6RateReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for correction (required)'**
  String get b6RateReason;

  /// No description provided for @b6InvalidRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive rate and a reason.'**
  String get b6InvalidRate;

  /// No description provided for @b6Cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get b6Cancel;

  /// No description provided for @b6Save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get b6Save;

  /// No description provided for @b86FormerTraveler.
  ///
  /// In en, this message translates to:
  /// **'Former traveler'**
  String get b86FormerTraveler;

  /// No description provided for @b86ReadOnlyFormer.
  ///
  /// In en, this message translates to:
  /// **'Former traveler: this debt is read-only'**
  String get b86ReadOnlyFormer;

  /// No description provided for @b86CloseDebt.
  ///
  /// In en, this message translates to:
  /// **'Close debt'**
  String get b86CloseDebt;

  /// No description provided for @b86CloseDebtTitle.
  ///
  /// In en, this message translates to:
  /// **'Close a former traveler\'s debt'**
  String get b86CloseDebtTitle;

  /// No description provided for @b86CloseDebtExplain.
  ///
  /// In en, this message translates to:
  /// **'The original debt stays in the history. Who closed it, when and why will be recorded.'**
  String get b86CloseDebtExplain;

  /// No description provided for @b86CloseDebtReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get b86CloseDebtReason;

  /// No description provided for @b86CloseDebtInvalid.
  ///
  /// In en, this message translates to:
  /// **'Write a reason of at least 3 characters.'**
  String get b86CloseDebtInvalid;

  /// No description provided for @b86Closed.
  ///
  /// In en, this message translates to:
  /// **'Closed (former traveler)'**
  String get b86Closed;

  /// No description provided for @b86ClosedBy.
  ///
  /// In en, this message translates to:
  /// **'Closed by {name}'**
  String b86ClosedBy(String name);

  /// No description provided for @b86Reason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String b86Reason(String reason);

  /// No description provided for @b86TripHistory.
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get b86TripHistory;

  /// No description provided for @b86ExpenseHistory.
  ///
  /// In en, this message translates to:
  /// **'Expense history'**
  String get b86ExpenseHistory;

  /// No description provided for @b86HistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No operations recorded.'**
  String get b86HistoryEmpty;

  /// No description provided for @b86HistoryError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the history.'**
  String get b86HistoryError;

  /// No description provided for @b86HistoryVisibility.
  ///
  /// In en, this message translates to:
  /// **'Only travelers who take part in an expense see its operations. Private expenses are visible only to you.'**
  String get b86HistoryVisibility;

  /// No description provided for @b86EvCreated.
  ///
  /// In en, this message translates to:
  /// **'{actor} created the expense'**
  String b86EvCreated(String actor);

  /// No description provided for @b86EvRevised.
  ///
  /// In en, this message translates to:
  /// **'{actor} applied revision #{version}'**
  String b86EvRevised(String actor, String version);

  /// No description provided for @b86EvRefundRequested.
  ///
  /// In en, this message translates to:
  /// **'{actor} reported a reimbursement to {other}'**
  String b86EvRefundRequested(String actor, String other);

  /// No description provided for @b86EvRefundConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{actor} confirmed the reimbursement from {other}'**
  String b86EvRefundConfirmed(String actor, String other);

  /// No description provided for @b86EvRefundRejected.
  ///
  /// In en, this message translates to:
  /// **'{actor} rejected the reimbursement from {other}'**
  String b86EvRefundRejected(String actor, String other);

  /// No description provided for @b86EvDebtClosed.
  ///
  /// In en, this message translates to:
  /// **'{actor} closed the debt of {other}'**
  String b86EvDebtClosed(String actor, String other);

  /// No description provided for @b86EvCancelRequested.
  ///
  /// In en, this message translates to:
  /// **'{actor} asked to cancel the expense'**
  String b86EvCancelRequested(String actor);

  /// No description provided for @b86EvCancelApproved.
  ///
  /// In en, this message translates to:
  /// **'{actor} approved the cancellation'**
  String b86EvCancelApproved(String actor);

  /// No description provided for @b86EvCancelRejected.
  ///
  /// In en, this message translates to:
  /// **'{actor} rejected the cancellation'**
  String b86EvCancelRejected(String actor);

  /// No description provided for @b86EvCancelled.
  ///
  /// In en, this message translates to:
  /// **'Expense cancelled by {actor}'**
  String b86EvCancelled(String actor);

  /// No description provided for @b86EvRateChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} corrected the exchange rate ({rate})'**
  String b86EvRateChanged(String actor, String rate);

  /// No description provided for @b86EvUnknown.
  ///
  /// In en, this message translates to:
  /// **'Operation recorded'**
  String get b86EvUnknown;

  /// No description provided for @b86PrivateTag.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get b86PrivateTag;

  /// No description provided for @b86UnknownTime.
  ///
  /// In en, this message translates to:
  /// **'Date unavailable'**
  String get b86UnknownTime;

  /// No description provided for @b85CategoryChart.
  ///
  /// In en, this message translates to:
  /// **'Breakdown by category'**
  String get b85CategoryChart;

  /// No description provided for @b85TrendChart.
  ///
  /// In en, this message translates to:
  /// **'Spending over time'**
  String get b85TrendChart;

  /// No description provided for @b85TrendByDay.
  ///
  /// In en, this message translates to:
  /// **'Total per day'**
  String get b85TrendByDay;

  /// No description provided for @b85TrendByMonth.
  ///
  /// In en, this message translates to:
  /// **'Total per month'**
  String get b85TrendByMonth;

  /// No description provided for @b85ChartsExcludeMissingRates.
  ///
  /// In en, this message translates to:
  /// **'Charts do not include expenses without an exchange rate.'**
  String get b85ChartsExcludeMissingRates;

  /// No description provided for @b85ChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Chart: {description}'**
  String b85ChartSemantics(String description);

  /// No description provided for @btAmountOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get btAmountOriginal;

  /// No description provided for @btAmountAutomaticExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Automatic exchange rate'**
  String get btAmountAutomaticExchangeRate;

  /// No description provided for @btAmountConverting.
  ///
  /// In en, this message translates to:
  /// **'Converting'**
  String get btAmountConverting;

  /// No description provided for @btAmountExchangeRateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate unavailable'**
  String get btAmountExchangeRateUnavailable;

  /// No description provided for @btDashMyAdvances.
  ///
  /// In en, this message translates to:
  /// **'My advances'**
  String get btDashMyAdvances;

  /// No description provided for @btCatAccommodation.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get btCatAccommodation;

  /// No description provided for @btCatFoodDrinks.
  ///
  /// In en, this message translates to:
  /// **'Food & drinks'**
  String get btCatFoodDrinks;

  /// No description provided for @btCatTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get btCatTransport;

  /// No description provided for @btCatActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get btCatActivities;

  /// No description provided for @btCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get btCatOther;

  /// No description provided for @btHistHistoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'History unavailable'**
  String get btHistHistoryUnavailable;

  /// No description provided for @btHistShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get btHistShare;

  /// No description provided for @btHistAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get btHistAdvance;

  /// No description provided for @btHistAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get btHistAccount;

  /// No description provided for @btHistRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get btHistRevision;

  /// No description provided for @btMethodsCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get btMethodsCash;

  /// No description provided for @btMethodsCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get btMethodsCard;

  /// No description provided for @btMethodsBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get btMethodsBankTransfer;

  /// No description provided for @btMethodsOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get btMethodsOther;

  /// No description provided for @btMethodsPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get btMethodsPaymentMethods;

  /// No description provided for @btMethodsRecordHowYouPaid.
  ///
  /// In en, this message translates to:
  /// **'Record how you paid, using multiple methods if needed.'**
  String get btMethodsRecordHowYouPaid;

  /// No description provided for @btMethodsMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get btMethodsMethod;

  /// No description provided for @btMethodsAmountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get btMethodsAmountPaid;

  /// No description provided for @btMethodsAccountCurrencyEG.
  ///
  /// In en, this message translates to:
  /// **'Account currency (e.g. EUR)'**
  String get btMethodsAccountCurrencyEG;

  /// No description provided for @btMethodsActualAccountDebitIf.
  ///
  /// In en, this message translates to:
  /// **'Actual account debit, if known'**
  String get btMethodsActualAccountDebitIf;

  /// No description provided for @btMethodsMethodDescription.
  ///
  /// In en, this message translates to:
  /// **'Method description'**
  String get btMethodsMethodDescription;

  /// No description provided for @btActionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get btActionRemove;

  /// No description provided for @btMethodsAddMethod.
  ///
  /// In en, this message translates to:
  /// **'Add method'**
  String get btMethodsAddMethod;

  /// No description provided for @btControlsRequestRecorded.
  ///
  /// In en, this message translates to:
  /// **'Request recorded.'**
  String get btControlsRequestRecorded;

  /// No description provided for @btControlsConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm action'**
  String get btControlsConfirmAction;

  /// No description provided for @btControlsTheExpenseWillBe.
  ///
  /// In en, this message translates to:
  /// **'The expense will be cancelled only after required approvals. History is preserved.'**
  String get btControlsTheExpenseWillBe;

  /// No description provided for @btActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btActionCancel;

  /// No description provided for @btActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get btActionConfirm;

  /// No description provided for @btControlsCancelledExpenseHistoryRetained.
  ///
  /// In en, this message translates to:
  /// **'Cancelled expense · history retained'**
  String get btControlsCancelledExpenseHistoryRetained;

  /// No description provided for @btControlsExpenseManagement.
  ///
  /// In en, this message translates to:
  /// **'Expense management'**
  String get btControlsExpenseManagement;

  /// No description provided for @btControlsCancelPersonalExpense.
  ///
  /// In en, this message translates to:
  /// **'Cancel personal expense'**
  String get btControlsCancelPersonalExpense;

  /// No description provided for @btControlsProposeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Propose cancellation'**
  String get btControlsProposeCancellation;

  /// No description provided for @btControlsPendingCancellation.
  ///
  /// In en, this message translates to:
  /// **'Pending cancellation: {value1}/{value2}'**
  String btControlsPendingCancellation(Object value1, Object value2);

  /// No description provided for @btActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get btActionReject;

  /// No description provided for @btControlsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get btControlsApprove;

  /// No description provided for @btListPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get btListPaid;

  /// No description provided for @btStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get btStatusPlanned;

  /// No description provided for @btStatusOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get btStatusOutstanding;

  /// No description provided for @btListStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get btListStatusUnavailable;

  /// No description provided for @btUnableToLoadExpenses.
  ///
  /// In en, this message translates to:
  /// **'Unable to load expenses.'**
  String get btUnableToLoadExpenses;

  /// No description provided for @btListNoExpensesToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No expenses to display.'**
  String get btListNoExpensesToDisplay;

  /// No description provided for @btUntitledExpense.
  ///
  /// In en, this message translates to:
  /// **'Untitled expense'**
  String get btUntitledExpense;

  /// No description provided for @btListTravelers.
  ///
  /// In en, this message translates to:
  /// **'{value1} travelers'**
  String btListTravelers(Object value1);

  /// No description provided for @btDetailsFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get btDetailsFood;

  /// No description provided for @btStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get btStatusPaid;

  /// No description provided for @btDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get btDetailsUnavailable;

  /// No description provided for @btDetailsNoAmountsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No amounts recorded.'**
  String get btDetailsNoAmountsRecorded;

  /// No description provided for @btDetailsNameUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Name unavailable'**
  String get btDetailsNameUnavailable;

  /// No description provided for @btDetailsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get btDetailsLoading;

  /// No description provided for @btDetailsExpenseDetails.
  ///
  /// In en, this message translates to:
  /// **'Expense details'**
  String get btDetailsExpenseDetails;

  /// No description provided for @btDetailsAdjustRate.
  ///
  /// In en, this message translates to:
  /// **'Adjust rate {originalCurrency}/{target}'**
  String btDetailsAdjustRate(Object originalCurrency, Object target);

  /// No description provided for @btDetailsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get btDetailsAccount;

  /// No description provided for @btDetailsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get btDetailsNotes;

  /// No description provided for @btDetailsManageExpense.
  ///
  /// In en, this message translates to:
  /// **'Manage expense'**
  String get btDetailsManageExpense;

  /// No description provided for @btRefundsOperationRecorded.
  ///
  /// In en, this message translates to:
  /// **'Operation recorded.'**
  String get btRefundsOperationRecorded;

  /// No description provided for @btRefundsReportReimbursement.
  ///
  /// In en, this message translates to:
  /// **'Report reimbursement'**
  String get btRefundsReportReimbursement;

  /// No description provided for @btRefundsReimbursementTo.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement to {creditorName}'**
  String btRefundsReimbursementTo(Object creditorName);

  /// No description provided for @btRefundsMaximumReimbursable.
  ///
  /// In en, this message translates to:
  /// **'Maximum reimbursable'**
  String get btRefundsMaximumReimbursable;

  /// No description provided for @btRefundsRecordHowYouReimbursed.
  ///
  /// In en, this message translates to:
  /// **'Record how you reimbursed in {currency}. The recipient must confirm.'**
  String btRefundsRecordHowYouReimbursed(Object currency);

  /// No description provided for @btRefundsDeclaredTotal.
  ///
  /// In en, this message translates to:
  /// **'Declared total'**
  String get btRefundsDeclaredTotal;

  /// No description provided for @btRefundsAddValidMethodsThe.
  ///
  /// In en, this message translates to:
  /// **'Add valid methods. The total must be positive and within the maximum.'**
  String get btRefundsAddValidMethodsThe;

  /// No description provided for @btRefundsSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get btRefundsSubmitRequest;

  /// No description provided for @btRefundsReimbursementMethodNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement method not recorded'**
  String get btRefundsReimbursementMethodNotRecorded;

  /// No description provided for @btRefundsDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Details unavailable'**
  String get btRefundsDetailsUnavailable;

  /// No description provided for @btRefundsDeclaredMethods.
  ///
  /// In en, this message translates to:
  /// **'Declared methods'**
  String get btRefundsDeclaredMethods;

  /// No description provided for @btRefundsDebtsBetweenTravelersBecome.
  ///
  /// In en, this message translates to:
  /// **'Debts between travelers become final only once the supplier has been paid.'**
  String get btRefundsDebtsBetweenTravelersBecome;

  /// No description provided for @btRefundsUnableToLoadTraveler.
  ///
  /// In en, this message translates to:
  /// **'Unable to load traveler names.'**
  String get btRefundsUnableToLoadTraveler;

  /// No description provided for @btRefundsUnableToLoadReimbursements.
  ///
  /// In en, this message translates to:
  /// **'Unable to load reimbursements.'**
  String get btRefundsUnableToLoadReimbursements;

  /// No description provided for @btRefundsDebtsAndReimbursements.
  ///
  /// In en, this message translates to:
  /// **'Debts and reimbursements'**
  String get btRefundsDebtsAndReimbursements;

  /// No description provided for @btRefundsWhoOwesMoneyCan.
  ///
  /// In en, this message translates to:
  /// **'Who owes money can report a reimbursement. Who should receive it must confirm it.'**
  String get btRefundsWhoOwesMoneyCan;

  /// No description provided for @btRefundsRequestsWaitingForYour.
  ///
  /// In en, this message translates to:
  /// **'Requests waiting for your confirmation'**
  String get btRefundsRequestsWaitingForYour;

  /// No description provided for @btRefundsRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get btRefundsRequested;

  /// No description provided for @btRefundsDecision.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get btRefundsDecision;

  /// No description provided for @btRefundsDecidedBy.
  ///
  /// In en, this message translates to:
  /// **'Decided by'**
  String get btRefundsDecidedBy;

  /// No description provided for @btRefundsOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get btRefundsOutstanding;

  /// No description provided for @btRefundsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get btRefundsConfirmed;

  /// No description provided for @btRefundsPendingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Pending confirmation'**
  String get btRefundsPendingConfirmation;

  /// No description provided for @btRefundsReportAReimbursement.
  ///
  /// In en, this message translates to:
  /// **'Report a reimbursement'**
  String get btRefundsReportAReimbursement;

  /// No description provided for @btRefundsReimbursementHistory.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement history'**
  String get btRefundsReimbursementHistory;

  /// No description provided for @btRefundsRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get btRefundsRejected;

  /// No description provided for @btRefundsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get btRefundsPending;

  /// No description provided for @btPersonalEn.
  ///
  /// In en, this message translates to:
  /// **'en'**
  String get btPersonalEn;

  /// No description provided for @btPersonalBudgetCurrency.
  ///
  /// In en, this message translates to:
  /// **'Budget currency'**
  String get btPersonalBudgetCurrency;

  /// No description provided for @btSearchCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Search currencies'**
  String get btSearchCurrencies;

  /// No description provided for @btNoCurrenciesFound.
  ///
  /// In en, this message translates to:
  /// **'No currencies found'**
  String get btNoCurrenciesFound;

  /// No description provided for @btPersonalFirestoreDeniedTheWrite.
  ///
  /// In en, this message translates to:
  /// **'Firestore denied the write. B7 rules must be deployed to the Firebase project in use.'**
  String get btPersonalFirestoreDeniedTheWrite;

  /// No description provided for @btPersonalInvalidAmountOrCurrency.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount or currency.'**
  String get btPersonalInvalidAmountOrCurrency;

  /// No description provided for @btPersonalOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String btPersonalOperationFailed(Object error);

  /// No description provided for @btPersonalMyTravelBudget.
  ///
  /// In en, this message translates to:
  /// **'My travel budget'**
  String get btPersonalMyTravelBudget;

  /// No description provided for @btPersonalOnlyYouCanSee.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this budget. Exceeding it never blocks new expenses.'**
  String get btPersonalOnlyYouCanSee;

  /// No description provided for @btPersonalPlannedAmount.
  ///
  /// In en, this message translates to:
  /// **'Planned amount'**
  String get btPersonalPlannedAmount;

  /// No description provided for @btCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get btCurrencyLabel;

  /// No description provided for @btPersonalSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btPersonalSave;

  /// No description provided for @btPersonalBudgetLoadError.
  ///
  /// In en, this message translates to:
  /// **'Budget load error.'**
  String get btPersonalBudgetLoadError;

  /// No description provided for @btPersonalSetAnOptionalPersonal.
  ///
  /// In en, this message translates to:
  /// **'Set an optional personal budget visible only to you.'**
  String get btPersonalSetAnOptionalPersonal;

  /// No description provided for @btPersonalSetBudget.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get btPersonalSetBudget;

  /// No description provided for @btPersonalUnableToLoadPersonal.
  ///
  /// In en, this message translates to:
  /// **'Unable to load personal expenses.'**
  String get btPersonalUnableToLoadPersonal;

  /// No description provided for @btPersonalEditBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get btPersonalEditBudget;

  /// No description provided for @btPersonalPlannedBudget.
  ///
  /// In en, this message translates to:
  /// **'Planned budget'**
  String get btPersonalPlannedBudget;

  /// No description provided for @btPersonalYourSharePaidAnd.
  ///
  /// In en, this message translates to:
  /// **'Your share (paid and outstanding)'**
  String get btPersonalYourSharePaidAnd;

  /// No description provided for @btPersonalRemainingUnavailableAnAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining unavailable: an amount or exchange rate is missing.'**
  String get btPersonalRemainingUnavailableAnAmount;

  /// No description provided for @btPersonalOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get btPersonalOverBudget;

  /// No description provided for @btPersonalRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get btPersonalRemaining;

  /// No description provided for @btPersonalPlannedExpensesAreExcluded.
  ///
  /// In en, this message translates to:
  /// **'Planned expenses are excluded. Exceeding the budget never blocks expenses.'**
  String get btPersonalPlannedExpensesAreExcluded;

  /// No description provided for @btToolbarEn.
  ///
  /// In en, this message translates to:
  /// **'en'**
  String get btToolbarEn;

  /// No description provided for @btToolbarDisplayCurrency.
  ///
  /// In en, this message translates to:
  /// **'Display currency'**
  String get btToolbarDisplayCurrency;

  /// No description provided for @btToolbarAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get btToolbarAllCategories;

  /// No description provided for @btToolbarFiltersAndDisplay.
  ///
  /// In en, this message translates to:
  /// **'Filters and display'**
  String get btToolbarFiltersAndDisplay;

  /// No description provided for @btToolbarCustomizeHowYouView.
  ///
  /// In en, this message translates to:
  /// **'Customize how you view expenses.'**
  String get btToolbarCustomizeHowYouView;

  /// No description provided for @btToolbarOriginalAmountsRemainUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Original amounts remain unchanged.'**
  String get btToolbarOriginalAmountsRemainUnchanged;

  /// No description provided for @btToolbarSortExpenses.
  ///
  /// In en, this message translates to:
  /// **'Sort expenses'**
  String get btToolbarSortExpenses;

  /// No description provided for @btToolbarNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get btToolbarNewest;

  /// No description provided for @btToolbarOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get btToolbarOldest;

  /// No description provided for @btToolbarAmountAscending.
  ///
  /// In en, this message translates to:
  /// **'Amount ascending'**
  String get btToolbarAmountAscending;

  /// No description provided for @btToolbarAmountDescending.
  ///
  /// In en, this message translates to:
  /// **'Amount descending'**
  String get btToolbarAmountDescending;

  /// No description provided for @btCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get btCategoryLabel;

  /// No description provided for @btStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get btStatusLabel;

  /// No description provided for @btToolbarAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get btToolbarAllStatuses;

  /// No description provided for @btToolbarPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get btToolbarPeriod;

  /// No description provided for @btToolbarAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get btToolbarAnyTime;

  /// No description provided for @btToolbarLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get btToolbarLast30Days;

  /// No description provided for @btToolbarLast90Days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get btToolbarLast90Days;

  /// No description provided for @btToolbarReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get btToolbarReset;

  /// No description provided for @btToolbarApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get btToolbarApply;

  /// No description provided for @btToolbarAmountsSortedWithinEach.
  ///
  /// In en, this message translates to:
  /// **'Amounts sorted within each original currency.'**
  String get btToolbarAmountsSortedWithinEach;

  /// No description provided for @btCreateEn.
  ///
  /// In en, this message translates to:
  /// **'en'**
  String get btCreateEn;

  /// No description provided for @btCreateExpenseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Expense currency'**
  String get btCreateExpenseCurrency;

  /// No description provided for @btCreateYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get btCreateYou;

  /// No description provided for @btCreateTraveler.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get btCreateTraveler;

  /// No description provided for @btCreatePaymentsExceedTotal.
  ///
  /// In en, this message translates to:
  /// **'Payments exceed total.'**
  String get btCreatePaymentsExceedTotal;

  /// No description provided for @btCreateSplitPreview.
  ///
  /// In en, this message translates to:
  /// **'Split preview'**
  String get btCreateSplitPreview;

  /// No description provided for @btCreateRecordedBy.
  ///
  /// In en, this message translates to:
  /// **'Recorded by'**
  String get btCreateRecordedBy;

  /// No description provided for @btCreateTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get btCreateTotal;

  /// No description provided for @btCreateDeclaredPayments.
  ///
  /// In en, this message translates to:
  /// **'Declared payments'**
  String get btCreateDeclaredPayments;

  /// No description provided for @btCreateRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get btCreateRemaining;

  /// No description provided for @btCreateCompleteTheAmountParticipants.
  ///
  /// In en, this message translates to:
  /// **'Complete the amount, participants and shares to see the preview.'**
  String get btCreateCompleteTheAmountParticipants;

  /// No description provided for @btCreateConfirmNewExpense.
  ///
  /// In en, this message translates to:
  /// **'Confirm new expense'**
  String get btCreateConfirmNewExpense;

  /// No description provided for @btCreateType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get btCreateType;

  /// No description provided for @btCreateShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get btCreateShared;

  /// No description provided for @btCreatePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get btCreatePersonal;

  /// No description provided for @btCreateKindAll.
  ///
  /// In en, this message translates to:
  /// **'With everyone'**
  String get btCreateKindAll;

  /// No description provided for @btCreateKindSome.
  ///
  /// In en, this message translates to:
  /// **'With some people'**
  String get btCreateKindSome;

  /// No description provided for @btCreateKindAdvance.
  ///
  /// In en, this message translates to:
  /// **'Paid for others'**
  String get btCreateKindAdvance;

  /// No description provided for @btCreateTotalToSplit.
  ///
  /// In en, this message translates to:
  /// **'Total to split'**
  String get btCreateTotalToSplit;

  /// No description provided for @btCreatePerPerson.
  ///
  /// In en, this message translates to:
  /// **'Per person'**
  String get btCreatePerPerson;

  /// No description provided for @btCreatePricePerPerson.
  ///
  /// In en, this message translates to:
  /// **'Price per person'**
  String get btCreatePricePerPerson;

  /// No description provided for @btCreateAllTravelers.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get btCreateAllTravelers;

  /// No description provided for @btCreateLinkOptional.
  ///
  /// In en, this message translates to:
  /// **'Link (optional)'**
  String get btCreateLinkOptional;

  /// No description provided for @btCreateLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'The link must start with http:// or https://.'**
  String get btCreateLinkInvalid;

  /// No description provided for @btDetailsSourceLinks.
  ///
  /// In en, this message translates to:
  /// **'Source and link'**
  String get btDetailsSourceLinks;

  /// No description provided for @btGoToStay.
  ///
  /// In en, this message translates to:
  /// **'Go to the stay'**
  String get btGoToStay;

  /// No description provided for @btGoToTransport.
  ///
  /// In en, this message translates to:
  /// **'Go to the transport'**
  String get btGoToTransport;

  /// No description provided for @btGoToReservation.
  ///
  /// In en, this message translates to:
  /// **'Go to the booking'**
  String get btGoToReservation;

  /// No description provided for @btGoToRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Go to the restaurant'**
  String get btGoToRestaurant;

  /// No description provided for @btGoToShopping.
  ///
  /// In en, this message translates to:
  /// **'Go to shopping'**
  String get btGoToShopping;

  /// No description provided for @btCreatePaymentsRecordedInThis.
  ///
  /// In en, this message translates to:
  /// **'Payments recorded in this version must have been made by you.'**
  String get btCreatePaymentsRecordedInThis;

  /// No description provided for @btCreateBackToEditing.
  ///
  /// In en, this message translates to:
  /// **'Back to editing'**
  String get btCreateBackToEditing;

  /// No description provided for @btCreateConfirmAndSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm and save'**
  String get btCreateConfirmAndSave;

  /// No description provided for @btCreateNewExpense.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get btCreateNewExpense;

  /// No description provided for @btCreateEssentialDetails.
  ///
  /// In en, this message translates to:
  /// **'Essential details'**
  String get btCreateEssentialDetails;

  /// No description provided for @btCreateAmountsAndTravelers.
  ///
  /// In en, this message translates to:
  /// **'Amounts and travelers'**
  String get btCreateAmountsAndTravelers;

  /// No description provided for @btCreate1Details.
  ///
  /// In en, this message translates to:
  /// **'1. Details'**
  String get btCreate1Details;

  /// No description provided for @btCreate2Amounts.
  ///
  /// In en, this message translates to:
  /// **'2. Amounts'**
  String get btCreate2Amounts;

  /// No description provided for @btCreateEnterAnExpenseName.
  ///
  /// In en, this message translates to:
  /// **'Enter an expense name.'**
  String get btCreateEnterAnExpenseName;

  /// No description provided for @btCreateExpenseType.
  ///
  /// In en, this message translates to:
  /// **'Expense type'**
  String get btCreateExpenseType;

  /// No description provided for @btCreateChooseWhoCanSee.
  ///
  /// In en, this message translates to:
  /// **'Choose who can see this expense.'**
  String get btCreateChooseWhoCanSee;

  /// No description provided for @btCreateExpenseDetails.
  ///
  /// In en, this message translates to:
  /// **'Expense details'**
  String get btCreateExpenseDetails;

  /// No description provided for @btCreateExpenseName.
  ///
  /// In en, this message translates to:
  /// **'Expense name'**
  String get btCreateExpenseName;

  /// No description provided for @btCreateEGKyotoHotel.
  ///
  /// In en, this message translates to:
  /// **'E.g. Kyoto hotel'**
  String get btCreateEGKyotoHotel;

  /// No description provided for @btCreateExpenseDate.
  ///
  /// In en, this message translates to:
  /// **'Expense date'**
  String get btCreateExpenseDate;

  /// No description provided for @btCreateNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get btCreateNotesOptional;

  /// No description provided for @btCreateExpenseAmount.
  ///
  /// In en, this message translates to:
  /// **'Expense amount'**
  String get btCreateExpenseAmount;

  /// No description provided for @btCreateTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get btCreateTotalAmount;

  /// No description provided for @btCreateExpenseStatus.
  ///
  /// In en, this message translates to:
  /// **'Expense status'**
  String get btCreateExpenseStatus;

  /// No description provided for @btCreateSplitBetweenTravelers.
  ///
  /// In en, this message translates to:
  /// **'Split between travelers'**
  String get btCreateSplitBetweenTravelers;

  /// No description provided for @btCreateEqualShares.
  ///
  /// In en, this message translates to:
  /// **'Equal shares'**
  String get btCreateEqualShares;

  /// No description provided for @btCreateCustomShares.
  ///
  /// In en, this message translates to:
  /// **'Custom shares'**
  String get btCreateCustomShares;

  /// No description provided for @btCreateShare.
  ///
  /// In en, this message translates to:
  /// **'{value1} share'**
  String btCreateShare(Object value1);

  /// No description provided for @btCreateHowWasItPaid.
  ///
  /// In en, this message translates to:
  /// **'How was it paid?'**
  String get btCreateHowWasItPaid;

  /// No description provided for @btCreateRecordOnlyPaymentsYou.
  ///
  /// In en, this message translates to:
  /// **'Record only payments you actually made.'**
  String get btCreateRecordOnlyPaymentsYou;

  /// No description provided for @btCreateSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get btCreateSummary;

  /// No description provided for @btCreateBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get btCreateBack;

  /// No description provided for @btCreateContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btCreateContinue;

  /// No description provided for @btCreateSaveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get btCreateSaveExpense;

  /// No description provided for @btPageRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get btPageRefresh;

  /// No description provided for @btPageFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get btPageFilters;

  /// No description provided for @btPageUnableToLoadTrip.
  ///
  /// In en, this message translates to:
  /// **'Unable to load trip.'**
  String get btPageUnableToLoadTrip;

  /// No description provided for @btPageTripExpenseList.
  ///
  /// In en, this message translates to:
  /// **'Trip expense list'**
  String get btPageTripExpenseList;

  /// No description provided for @btPageShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get btPageShared;

  /// No description provided for @btPagePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get btPagePersonal;

  /// No description provided for @btPaidMarkAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get btPaidMarkAsPaid;

  /// No description provided for @btPaidIntro.
  ///
  /// In en, this message translates to:
  /// **'{name} paid you, even outside the app.'**
  String btPaidIntro(String name);

  /// No description provided for @btPaidRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining to settle: {amount}'**
  String btPaidRemaining(String amount);

  /// No description provided for @btPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount received ({currency})'**
  String btPaidAmount(String currency);

  /// No description provided for @btPaidAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero and not above the remaining debt.'**
  String get btPaidAmountInvalid;

  /// No description provided for @btPaidDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get btPaidDate;

  /// No description provided for @btPaidMethod.
  ///
  /// In en, this message translates to:
  /// **'Method (optional)'**
  String get btPaidMethod;

  /// No description provided for @btPaidMethodNone.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get btPaidMethodNone;

  /// No description provided for @btPaidMethodOther.
  ///
  /// In en, this message translates to:
  /// **'Which method?'**
  String get btPaidMethodOther;

  /// No description provided for @btPaidNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get btPaidNote;

  /// No description provided for @btPaidSave.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get btPaidSave;

  /// No description provided for @btPaidPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'There is a pending request'**
  String get btPaidPendingTitle;

  /// No description provided for @btPaidPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{name} already reported a reimbursement of {amount}. Do you want to confirm that request?'**
  String btPaidPendingBody(String name, String amount);

  /// No description provided for @btPaidConfirmPending.
  ///
  /// In en, this message translates to:
  /// **'Confirm the request'**
  String get btPaidConfirmPending;

  /// No description provided for @btPaidRecordAnother.
  ///
  /// In en, this message translates to:
  /// **'Record another payment'**
  String get btPaidRecordAnother;

  /// No description provided for @btPaidRecordedBy.
  ///
  /// In en, this message translates to:
  /// **'Recorded by {name}'**
  String btPaidRecordedBy(String name);

  /// No description provided for @btPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String btPaidOn(String date);

  /// No description provided for @btPaidNoteText.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String btPaidNoteText(String note);

  /// No description provided for @btPaidVoided.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get btPaidVoided;

  /// No description provided for @btPaidVoidedBy.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by {name}'**
  String btPaidVoidedBy(String name);

  /// No description provided for @btPaidVoidAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel payment'**
  String get btPaidVoidAction;

  /// No description provided for @btPaidVoidTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel the recorded payment?'**
  String get btPaidVoidTitle;

  /// No description provided for @btPaidVoidBody.
  ///
  /// In en, this message translates to:
  /// **'The payment stays in the history as cancelled and no longer counts in the remaining debt.'**
  String get btPaidVoidBody;

  /// No description provided for @btPaidVoidReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (at least 3 characters)'**
  String get btPaidVoidReason;

  /// No description provided for @btPaidAmountTooHigh.
  ///
  /// In en, this message translates to:
  /// **'The amount exceeds the remaining debt: someone has just recorded another payment.'**
  String get btPaidAmountTooHigh;

  /// No description provided for @btPaidRequestExceeds.
  ///
  /// In en, this message translates to:
  /// **'This request exceeds the remaining debt after the recorded payments: reject it and ask the traveler for a new request.'**
  String get btPaidRequestExceeds;

  /// No description provided for @btPaidDebtClosed.
  ///
  /// In en, this message translates to:
  /// **'The debt has been closed: the payment can no longer be cancelled.'**
  String get btPaidDebtClosed;

  /// No description provided for @btHistPaymentDeclared.
  ///
  /// In en, this message translates to:
  /// **'{actor} recorded a payment from {other}'**
  String btHistPaymentDeclared(String actor, String other);

  /// No description provided for @btHistPaymentVoided.
  ///
  /// In en, this message translates to:
  /// **'{actor} cancelled the recorded payment from {other}'**
  String btHistPaymentVoided(String actor, String other);

  /// No description provided for @commonLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'The link is invalid.'**
  String get commonLinkInvalid;

  /// No description provided for @commonLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link. You can copy it and open it in your browser.'**
  String get commonLinkOpenFailed;

  /// No description provided for @commonUsefulLinks.
  ///
  /// In en, this message translates to:
  /// **'Useful links'**
  String get commonUsefulLinks;

  /// No description provided for @commonLinkNumber.
  ///
  /// In en, this message translates to:
  /// **'Link {number}'**
  String commonLinkNumber(int number);

  /// No description provided for @commonLinkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get commonLinkRemove;

  /// No description provided for @commonLinkAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a link'**
  String get commonLinkAdd;

  /// No description provided for @tripMoreConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get tripMoreConvert;

  /// No description provided for @tripMoreConvertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Currencies, units, sizes and tip'**
  String get tripMoreConvertSubtitle;

  /// No description provided for @tripMoreWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get tripMoreWeather;

  /// No description provided for @tripMoreWeatherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Forecast, climate, air and what to wear'**
  String get tripMoreWeatherSubtitle;

  /// No description provided for @convertTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convertTitle;

  /// No description provided for @convertCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get convertCurrencies;

  /// No description provided for @convertAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get convertAmount;

  /// No description provided for @convertFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get convertFrom;

  /// No description provided for @convertTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get convertTo;

  /// No description provided for @convertSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get convertSwap;

  /// No description provided for @convertUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Rate not available now'**
  String get convertUnavailable;

  /// No description provided for @convertRateSource.
  ///
  /// In en, this message translates to:
  /// **'Rate {source} of {date} (the same as the budget)'**
  String convertRateSource(String source, String date);

  /// No description provided for @convertUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get convertUnits;

  /// No description provided for @convertValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get convertValue;

  /// No description provided for @convertShoeSizes.
  ///
  /// In en, this message translates to:
  /// **'Shoe sizes'**
  String get convertShoeSizes;

  /// No description provided for @convertUsMen.
  ///
  /// In en, this message translates to:
  /// **'US men'**
  String get convertUsMen;

  /// No description provided for @convertUsWomen.
  ///
  /// In en, this message translates to:
  /// **'US women'**
  String get convertUsWomen;

  /// No description provided for @convertSizesNote.
  ///
  /// In en, this message translates to:
  /// **'Indicative table: sizes change between brands, always try them on.'**
  String get convertSizesNote;

  /// No description provided for @convertTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get convertTip;

  /// No description provided for @convertTipBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get convertTipBill;

  /// No description provided for @convertTipPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get convertTipPeople;

  /// No description provided for @convertTipResult.
  ///
  /// In en, this message translates to:
  /// **'Tip {tip} · total {total} · {each} each'**
  String convertTipResult(String tip, String total, String each);

  /// No description provided for @zoneSource.
  ///
  /// In en, this message translates to:
  /// **'City data: Open-Meteo.com (CC BY 4.0)'**
  String get zoneSource;

  /// No description provided for @weatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherTitle;

  /// No description provided for @weatherForecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get weatherForecast;

  /// No description provided for @weatherForecastNote.
  ///
  /// In en, this message translates to:
  /// **'16-day forecast for {place}. Trip days are marked «Trip».'**
  String weatherForecastNote(String place);

  /// No description provided for @weatherTripFar.
  ///
  /// In en, this message translates to:
  /// **'The trip is beyond the 16 days of forecast: meanwhile see the weather of these days at the destination and the typical climate of the period.'**
  String get weatherTripFar;

  /// No description provided for @weatherTripDay.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get weatherTripDay;

  /// No description provided for @weatherHours.
  ///
  /// In en, this message translates to:
  /// **'Hour by hour · {day}'**
  String weatherHours(String day);

  /// No description provided for @weatherRainChance.
  ///
  /// In en, this message translates to:
  /// **'{value}% rain'**
  String weatherRainChance(String value);

  /// No description provided for @weatherSun.
  ///
  /// In en, this message translates to:
  /// **'Sunrise {sunrise} · sunset {sunset}'**
  String weatherSun(String sunrise, String sunset);

  /// No description provided for @weatherWindUv.
  ///
  /// In en, this message translates to:
  /// **'Wind up to {wind} km/h · UV {uv}'**
  String weatherWindUv(String wind, String uv);

  /// No description provided for @weatherClimate.
  ///
  /// In en, this message translates to:
  /// **'Typical climate of the period'**
  String get weatherClimate;

  /// No description provided for @weatherClimateBody.
  ///
  /// In en, this message translates to:
  /// **'Average of the same days in {years}: highs {max}°, lows {min}°, {precip} mm of rain a day, rainy days {rainy}%.'**
  String weatherClimateBody(String years, String max, String min, String precip, String rainy);

  /// No description provided for @weatherClimateNone.
  ///
  /// In en, this message translates to:
  /// **'Typical climate not available now.'**
  String get weatherClimateNone;

  /// No description provided for @weatherAir.
  ///
  /// In en, this message translates to:
  /// **'Air and pollen'**
  String get weatherAir;

  /// No description provided for @weatherAirIndex.
  ///
  /// In en, this message translates to:
  /// **'Air quality: {level} (European index {value})'**
  String weatherAirIndex(String level, String value);

  /// No description provided for @weatherAirNone.
  ///
  /// In en, this message translates to:
  /// **'Air quality not available for this day.'**
  String get weatherAirNone;

  /// No description provided for @weatherPollenNone.
  ///
  /// In en, this message translates to:
  /// **'Pollen: no data (only in Europe and in the pollen season).'**
  String get weatherPollenNone;

  /// No description provided for @weatherPollenLine.
  ///
  /// In en, this message translates to:
  /// **'{kind}: {level}'**
  String weatherPollenLine(String kind, String level);

  /// No description provided for @weatherWear.
  ///
  /// In en, this message translates to:
  /// **'What to wear'**
  String get weatherWear;

  /// No description provided for @weatherWearNote.
  ///
  /// In en, this message translates to:
  /// **'Advice from fixed rules on temperature, rain, snow, wind and UV.'**
  String get weatherWearNote;

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather not available now. Try again later.'**
  String get weatherUnavailable;

  /// No description provided for @weatherNoDestination.
  ///
  /// In en, this message translates to:
  /// **'The trip has no destination on the map: add it in the trip settings.'**
  String get weatherNoDestination;

  /// No description provided for @weatherRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get weatherRetry;

  /// No description provided for @weatherStale.
  ///
  /// In en, this message translates to:
  /// **'The weather service does not answer: you see the data of the last update.'**
  String get weatherStale;

  /// No description provided for @weatherUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated on {date} at {time}'**
  String weatherUpdated(String date, String time);

  /// No description provided for @weatherOpen3b.
  ///
  /// In en, this message translates to:
  /// **'Open on 3B Meteo'**
  String get weatherOpen3b;

  /// No description provided for @weatherSource.
  ///
  /// In en, this message translates to:
  /// **'Weather data: Open-Meteo.com (CC BY 4.0), summarised by day.'**
  String get weatherSource;

  /// No description provided for @weatherSkyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherSkyClear;

  /// No description provided for @weatherSkyPartly.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherSkyPartly;

  /// No description provided for @weatherSkyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherSkyCloudy;

  /// No description provided for @weatherSkyFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherSkyFog;

  /// No description provided for @weatherSkyDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherSkyDrizzle;

  /// No description provided for @weatherSkyRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherSkyRain;

  /// No description provided for @weatherSkySnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSkySnow;

  /// No description provided for @weatherSkyStorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherSkyStorm;

  /// No description provided for @weatherWearLight.
  ///
  /// In en, this message translates to:
  /// **'Light, breathable clothes'**
  String get weatherWearLight;

  /// No description provided for @weatherWearSunHat.
  ///
  /// In en, this message translates to:
  /// **'Hat and sunscreen'**
  String get weatherWearSunHat;

  /// No description provided for @weatherWearTshirt.
  ///
  /// In en, this message translates to:
  /// **'T-shirt'**
  String get weatherWearTshirt;

  /// No description provided for @weatherWearLightLayer.
  ///
  /// In en, this message translates to:
  /// **'A light layer for the evening'**
  String get weatherWearLightLayer;

  /// No description provided for @weatherWearSweater.
  ///
  /// In en, this message translates to:
  /// **'Sweatshirt or light jacket'**
  String get weatherWearSweater;

  /// No description provided for @weatherWearWarmCoat.
  ///
  /// In en, this message translates to:
  /// **'Warm jacket'**
  String get weatherWearWarmCoat;

  /// No description provided for @weatherWearHeavyCoat.
  ///
  /// In en, this message translates to:
  /// **'Winter coat'**
  String get weatherWearHeavyCoat;

  /// No description provided for @weatherWearHatGloves.
  ///
  /// In en, this message translates to:
  /// **'Beanie, scarf and gloves'**
  String get weatherWearHatGloves;

  /// No description provided for @weatherWearUmbrella.
  ///
  /// In en, this message translates to:
  /// **'Umbrella or raincoat'**
  String get weatherWearUmbrella;

  /// No description provided for @weatherWearBoots.
  ///
  /// In en, this message translates to:
  /// **'Waterproof shoes'**
  String get weatherWearBoots;

  /// No description provided for @weatherWearWindproof.
  ///
  /// In en, this message translates to:
  /// **'Windproof jacket'**
  String get weatherWearWindproof;

  /// No description provided for @weatherWearSunscreen.
  ///
  /// In en, this message translates to:
  /// **'Sunscreen'**
  String get weatherWearSunscreen;

  /// No description provided for @weatherAirGood.
  ///
  /// In en, this message translates to:
  /// **'good'**
  String get weatherAirGood;

  /// No description provided for @weatherAirFair.
  ///
  /// In en, this message translates to:
  /// **'fair'**
  String get weatherAirFair;

  /// No description provided for @weatherAirModerate.
  ///
  /// In en, this message translates to:
  /// **'moderate'**
  String get weatherAirModerate;

  /// No description provided for @weatherAirPoor.
  ///
  /// In en, this message translates to:
  /// **'poor'**
  String get weatherAirPoor;

  /// No description provided for @weatherAirVeryPoor.
  ///
  /// In en, this message translates to:
  /// **'very poor'**
  String get weatherAirVeryPoor;

  /// No description provided for @weatherPollenLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get weatherPollenLow;

  /// No description provided for @weatherPollenMedium.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get weatherPollenMedium;

  /// No description provided for @weatherPollenHigh.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get weatherPollenHigh;

  /// No description provided for @weatherPollenAlder.
  ///
  /// In en, this message translates to:
  /// **'Alder'**
  String get weatherPollenAlder;

  /// No description provided for @weatherPollenBirch.
  ///
  /// In en, this message translates to:
  /// **'Birch'**
  String get weatherPollenBirch;

  /// No description provided for @weatherPollenGrass.
  ///
  /// In en, this message translates to:
  /// **'Grass'**
  String get weatherPollenGrass;

  /// No description provided for @weatherPollenMugwort.
  ///
  /// In en, this message translates to:
  /// **'Mugwort'**
  String get weatherPollenMugwort;

  /// No description provided for @weatherPollenOlive.
  ///
  /// In en, this message translates to:
  /// **'Olive'**
  String get weatherPollenOlive;

  /// No description provided for @weatherPollenRagweed.
  ///
  /// In en, this message translates to:
  /// **'Ragweed'**
  String get weatherPollenRagweed;

  /// No description provided for @countryInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Country info'**
  String get countryInfoTitle;

  /// No description provided for @countryInfoVerify.
  ///
  /// In en, this message translates to:
  /// **'Always check official sources before leaving: this data comes from open sources and may be incomplete or out of date.'**
  String get countryInfoVerify;

  /// No description provided for @countryInfoCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryInfoCountry;

  /// No description provided for @countryInfoPick.
  ///
  /// In en, this message translates to:
  /// **'Choose a country to see its information.'**
  String get countryInfoPick;

  /// No description provided for @countryInfoPractical.
  ///
  /// In en, this message translates to:
  /// **'Practical information'**
  String get countryInfoPractical;

  /// No description provided for @countryInfoCallingCode.
  ///
  /// In en, this message translates to:
  /// **'Calling code'**
  String get countryInfoCallingCode;

  /// No description provided for @countryInfoEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency numbers'**
  String get countryInfoEmergency;

  /// No description provided for @countryInfoPlugs.
  ///
  /// In en, this message translates to:
  /// **'Power plugs'**
  String get countryInfoPlugs;

  /// No description provided for @countryInfoPlugType.
  ///
  /// In en, this message translates to:
  /// **'Type {letters}'**
  String countryInfoPlugType(String letters);

  /// No description provided for @countryInfoVoltage.
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get countryInfoVoltage;

  /// No description provided for @countryInfoDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving side'**
  String get countryInfoDriving;

  /// No description provided for @countryInfoDrivingLeft.
  ///
  /// In en, this message translates to:
  /// **'Drive on the left'**
  String get countryInfoDrivingLeft;

  /// No description provided for @countryInfoDrivingRight.
  ///
  /// In en, this message translates to:
  /// **'Drive on the right'**
  String get countryInfoDrivingRight;

  /// No description provided for @countryInfoTimeZones.
  ///
  /// In en, this message translates to:
  /// **'Time zones'**
  String get countryInfoTimeZones;

  /// No description provided for @countryInfoSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source} ({licence}) · data of {date}'**
  String countryInfoSource(String source, String licence, String date);

  /// No description provided for @countryInfoOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official pages'**
  String get countryInfoOfficial;

  /// No description provided for @countryInfoOfficialBody.
  ///
  /// In en, this message translates to:
  /// **'Drinking water, health, documents, visas and entry requirements: we have no reliable open source, so we do not show them. Read them on the official page.'**
  String get countryInfoOfficialBody;

  /// No description provided for @countryInfoViaggiareSicuri.
  ///
  /// In en, this message translates to:
  /// **'Viaggiare Sicuri (Italian Foreign Ministry)'**
  String get countryInfoViaggiareSicuri;

  /// No description provided for @countryInfoConsulate.
  ///
  /// In en, this message translates to:
  /// **'Find the consulate (Italian Foreign Ministry)'**
  String get countryInfoConsulate;

  /// No description provided for @countryInfoWikidata.
  ///
  /// In en, this message translates to:
  /// **'Page on Wikidata'**
  String get countryInfoWikidata;

  /// No description provided for @tripMoreCountryInfo.
  ///
  /// In en, this message translates to:
  /// **'Country info'**
  String get tripMoreCountryInfo;

  /// No description provided for @tripMoreCountryInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emergencies, plugs, driving, time zones and official pages'**
  String get tripMoreCountryInfoSubtitle;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and privacy'**
  String get settingsSupport;

  /// No description provided for @settingsSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reports, ideas, app status and rules'**
  String get settingsSupportSubtitle;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help and privacy'**
  String get supportTitle;

  /// No description provided for @supportReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get supportReportProblem;

  /// No description provided for @supportReportProblemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write what does not work'**
  String get supportReportProblemSubtitle;

  /// No description provided for @supportSuggestIdea.
  ///
  /// In en, this message translates to:
  /// **'Suggest an idea'**
  String get supportSuggestIdea;

  /// No description provided for @supportSuggestIdeaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What you would like in the app'**
  String get supportSuggestIdeaSubtitle;

  /// No description provided for @supportAppStatus.
  ///
  /// In en, this message translates to:
  /// **'App status'**
  String get supportAppStatus;

  /// No description provided for @supportAppStatusValue.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · updated on {date}'**
  String supportAppStatusValue(String version, String date);

  /// No description provided for @supportPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get supportPrivacy;

  /// No description provided for @supportPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens the online page'**
  String get supportPrivacySubtitle;

  /// No description provided for @supportCompliance.
  ///
  /// In en, this message translates to:
  /// **'Compliance and rules'**
  String get supportCompliance;

  /// No description provided for @supportComplianceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The rules we follow and how'**
  String get supportComplianceSubtitle;

  /// No description provided for @supportNoTracking.
  ///
  /// In en, this message translates to:
  /// **'No automatic error log and no usage statistics: only what you write reaches us.'**
  String get supportNoTracking;

  /// No description provided for @supportFeedbackBugHint.
  ///
  /// In en, this message translates to:
  /// **'What you were doing, what you expected and what happened. Do not write passwords or sensitive data.'**
  String get supportFeedbackBugHint;

  /// No description provided for @supportFeedbackIdeaHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the idea in a few lines. Do not write passwords or sensitive data.'**
  String get supportFeedbackIdeaHint;

  /// No description provided for @supportFeedbackSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get supportFeedbackSend;

  /// No description provided for @supportFeedbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write something before sending.'**
  String get supportFeedbackEmpty;

  /// No description provided for @supportFeedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Message sent.'**
  String get supportFeedbackSent;

  /// No description provided for @supportFeedbackLimit.
  ///
  /// In en, this message translates to:
  /// **'You already sent 5 messages today: try again tomorrow.'**
  String get supportFeedbackLimit;

  /// No description provided for @supportFeedbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Sending failed. Try again later.'**
  String get supportFeedbackFailed;

  /// No description provided for @supportComplianceApplies.
  ///
  /// In en, this message translates to:
  /// **'Applies to us'**
  String get supportComplianceApplies;

  /// No description provided for @supportComplianceYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get supportComplianceYes;

  /// No description provided for @supportComplianceNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get supportComplianceNo;

  /// No description provided for @supportCompliancePartial.
  ///
  /// In en, this message translates to:
  /// **'Partly'**
  String get supportCompliancePartial;

  /// No description provided for @supportComplianceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Principles we apply, not a certification nor legal advice. Last check: {date}. Points «to be verified» have not been confirmed.'**
  String supportComplianceDisclaimer(String date);

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Text, units, dates and currencies'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @appearanceTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get appearanceTextSize;

  /// No description provided for @appearanceUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get appearanceUnits;

  /// No description provided for @appearanceUnitsKm.
  ///
  /// In en, this message translates to:
  /// **'Kilometres'**
  String get appearanceUnitsKm;

  /// No description provided for @appearanceUnitsMi.
  ///
  /// In en, this message translates to:
  /// **'Miles'**
  String get appearanceUnitsMi;

  /// No description provided for @appearanceDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get appearanceDateFormat;

  /// No description provided for @appearanceDateLocale.
  ///
  /// In en, this message translates to:
  /// **'Like the language'**
  String get appearanceDateLocale;

  /// No description provided for @appearanceDateDmy.
  ///
  /// In en, this message translates to:
  /// **'dd/mm/yyyy'**
  String get appearanceDateDmy;

  /// No description provided for @appearanceDateYmd.
  ///
  /// In en, this message translates to:
  /// **'yyyy-mm-dd'**
  String get appearanceDateYmd;

  /// No description provided for @appearanceTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get appearanceTimeFormat;

  /// No description provided for @appearanceTime24.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get appearanceTime24;

  /// No description provided for @appearanceTime12.
  ///
  /// In en, this message translates to:
  /// **'12 hours (AM/PM)'**
  String get appearanceTime12;

  /// No description provided for @appearanceCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get appearanceCurrencies;

  /// No description provided for @appearanceDefaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency for new entries'**
  String get appearanceDefaultCurrency;

  /// No description provided for @appearanceDisplayCurrency.
  ///
  /// In en, this message translates to:
  /// **'Display currency'**
  String get appearanceDisplayCurrency;

  /// No description provided for @appearanceCurrencyTrip.
  ///
  /// In en, this message translates to:
  /// **'the trip\'s'**
  String get appearanceCurrencyTrip;

  /// No description provided for @appearanceDisplayOriginal.
  ///
  /// In en, this message translates to:
  /// **'the original one'**
  String get appearanceDisplayOriginal;

  /// No description provided for @appearanceDisplayFollows.
  ///
  /// In en, this message translates to:
  /// **'like new entries ({currency})'**
  String appearanceDisplayFollows(String currency);

  /// No description provided for @appearanceCurrencyAuto.
  ///
  /// In en, this message translates to:
  /// **'Back to the automatic value'**
  String get appearanceCurrencyAuto;

  /// No description provided for @appearanceOriginalsUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Original amounts stay unchanged: the display currency only changes how you see them.'**
  String get appearanceOriginalsUnchanged;

  /// No description provided for @appearanceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Choice saved on this device, but not in the profile. Try again later.'**
  String get appearanceSaveFailed;

  /// No description provided for @sectionsCategories.
  ///
  /// In en, this message translates to:
  /// **'Custom categories'**
  String get sectionsCategories;

  /// No description provided for @sectionsCategoryNew.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get sectionsCategoryNew;

  /// No description provided for @sectionsCategoryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add the category'**
  String get sectionsCategoryAdd;

  /// No description provided for @sectionsCategoriesFull.
  ///
  /// In en, this message translates to:
  /// **'At most 5 categories'**
  String get sectionsCategoriesFull;

  /// No description provided for @sectionsCategoriesUsed.
  ///
  /// In en, this message translates to:
  /// **'Already used in the trip'**
  String get sectionsCategoriesUsed;

  /// No description provided for @sectionsFilterCustomCategory.
  ///
  /// In en, this message translates to:
  /// **'Custom category'**
  String get sectionsFilterCustomCategory;

  /// No description provided for @zoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get zoneLabel;

  /// No description provided for @zoneNone.
  ///
  /// In en, this message translates to:
  /// **'choose the city'**
  String get zoneNone;

  /// No description provided for @zoneRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove the time zone'**
  String get zoneRemove;

  /// No description provided for @zoneSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Time zone of the city'**
  String get zoneSheetTitle;

  /// No description provided for @zoneSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Write a city, e.g. venice'**
  String get zoneSearchHint;

  /// No description provided for @zoneSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get zoneSearch;

  /// No description provided for @zoneNoResults.
  ///
  /// In en, this message translates to:
  /// **'No city found.'**
  String get zoneNoResults;

  /// No description provided for @zoneSearchError.
  ///
  /// In en, this message translates to:
  /// **'Search not available now. Try again later.'**
  String get zoneSearchError;

  /// No description provided for @zoneLocalTime.
  ///
  /// In en, this message translates to:
  /// **'{place}, local time {time}'**
  String zoneLocalTime(String place, String time);

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in version {version}'**
  String whatsNewTitle(String version);

  /// No description provided for @whatsNewOk.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get whatsNewOk;

  /// No description provided for @versionsTitle.
  ///
  /// In en, this message translates to:
  /// **'All versions'**
  String get versionsTitle;

  /// No description provided for @versionsOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to see all versions'**
  String get versionsOpen;

  /// No description provided for @commonLinksInvalid.
  ///
  /// In en, this message translates to:
  /// **'Useful links: write addresses starting with http:// or https:// (at most 10).'**
  String get commonLinksInvalid;

  /// No description provided for @commonLinkCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get commonLinkCopy;

  /// No description provided for @commonLinkOpen.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get commonLinkOpen;

  /// No description provided for @commonMapsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps.'**
  String get commonMapsOpenFailed;

  /// No description provided for @staysEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No accommodation yet'**
  String get staysEmptyTitle;

  /// No description provided for @staysEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add hotels, apartments and other places to stay: dates, booking and links in one place.'**
  String get staysEmptyBody;

  /// No description provided for @staysAdd.
  ///
  /// In en, this message translates to:
  /// **'Add accommodation'**
  String get staysAdd;

  /// No description provided for @staysLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the accommodation.'**
  String get staysLoadError;

  /// No description provided for @staysStatusBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get staysStatusBooked;

  /// No description provided for @staysStatusToConfirm.
  ///
  /// In en, this message translates to:
  /// **'To be confirmed'**
  String get staysStatusToConfirm;

  /// No description provided for @staysStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get staysStatusCancelled;

  /// No description provided for @staysCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get staysCheckIn;

  /// No description provided for @staysCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get staysCheckOut;

  /// No description provided for @staysNights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Same day} =1{1 night} other{{count} nights}}'**
  String staysNights(int count);

  /// No description provided for @staysBookedVia.
  ///
  /// In en, this message translates to:
  /// **'Booked on {platform}'**
  String staysBookedVia(String platform);

  /// No description provided for @staysPlatformBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking.com'**
  String get staysPlatformBooking;

  /// No description provided for @staysPlatformAirbnb.
  ///
  /// In en, this message translates to:
  /// **'Airbnb'**
  String get staysPlatformAirbnb;

  /// No description provided for @staysPlatformPropertySite.
  ///
  /// In en, this message translates to:
  /// **'Property website'**
  String get staysPlatformPropertySite;

  /// No description provided for @staysPlatformAgency.
  ///
  /// In en, this message translates to:
  /// **'Agency'**
  String get staysPlatformAgency;

  /// No description provided for @staysPlatformOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get staysPlatformOther;

  /// No description provided for @staysConfirmationCode.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String staysConfirmationCode(String code);

  /// No description provided for @staysLinkBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get staysLinkBooking;

  /// No description provided for @staysLinkProperty.
  ///
  /// In en, this message translates to:
  /// **'Property website'**
  String get staysLinkProperty;

  /// No description provided for @staysOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get staysOpenMap;

  /// No description provided for @staysGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests: {names}'**
  String staysGuests(String names);

  /// No description provided for @staysFormerGuest.
  ///
  /// In en, this message translates to:
  /// **'Former traveler'**
  String get staysFormerGuest;

  /// No description provided for @staysOverlapWarning.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second} overlap in their dates.'**
  String staysOverlapWarning(String first, String second);

  /// No description provided for @staysEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get staysEdit;

  /// No description provided for @staysDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get staysDelete;

  /// No description provided for @staysDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this accommodation?'**
  String get staysDeleteTitle;

  /// No description provided for @staysDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be deleted for all travelers. If the booking was only cancelled, set the status to \"Cancelled\" instead.'**
  String staysDeleteBody(String name);

  /// No description provided for @staysDeleted.
  ///
  /// In en, this message translates to:
  /// **'Accommodation deleted.'**
  String get staysDeleted;

  /// No description provided for @staysDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete the accommodation.'**
  String get staysDeleteError;

  /// No description provided for @staysCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get staysCancel;

  /// No description provided for @staysEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New accommodation'**
  String get staysEditorNewTitle;

  /// No description provided for @staysEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit accommodation'**
  String get staysEditorEditTitle;

  /// No description provided for @staysSectionPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get staysSectionPlace;

  /// No description provided for @staysSectionDates.
  ///
  /// In en, this message translates to:
  /// **'Dates and times'**
  String get staysSectionDates;

  /// No description provided for @staysSectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get staysSectionStatus;

  /// No description provided for @staysSectionType.
  ///
  /// In en, this message translates to:
  /// **'Type of stay'**
  String get staysSectionType;

  /// No description provided for @staysTypeHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get staysTypeHotel;

  /// No description provided for @staysTypeBnb.
  ///
  /// In en, this message translates to:
  /// **'B&B'**
  String get staysTypeBnb;

  /// No description provided for @staysTypeApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get staysTypeApartment;

  /// No description provided for @staysTypeHostel.
  ///
  /// In en, this message translates to:
  /// **'Hostel'**
  String get staysTypeHostel;

  /// No description provided for @staysTypeCamping.
  ///
  /// In en, this message translates to:
  /// **'Campsite'**
  String get staysTypeCamping;

  /// No description provided for @staysTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get staysTypeOther;

  /// No description provided for @staysSectionContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get staysSectionContacts;

  /// No description provided for @staysPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get staysPhone;

  /// No description provided for @staysEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get staysEmail;

  /// No description provided for @staysErrPhone.
  ///
  /// In en, this message translates to:
  /// **'The phone can contain only digits, spaces and + ( ) . / - (4 to 40 characters).'**
  String get staysErrPhone;

  /// No description provided for @staysErrEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email, for example name@example.com.'**
  String get staysErrEmail;

  /// No description provided for @staysContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get staysContact;

  /// No description provided for @staysContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact {name}'**
  String staysContactTitle(String name);

  /// No description provided for @placesContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get placesContactPhone;

  /// No description provided for @placesContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get placesContactEmail;

  /// No description provided for @placesContactWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get placesContactWebsite;

  /// No description provided for @placesContactCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get placesContactCall;

  /// No description provided for @placesContactWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get placesContactWrite;

  /// No description provided for @placesContactOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get placesContactOpen;

  /// No description provided for @placesContactCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get placesContactCopy;

  /// No description provided for @placesContactCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to the clipboard.'**
  String get placesContactCopied;

  /// No description provided for @placesContactOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the app. You can copy the details.'**
  String get placesContactOpenFailed;

  /// No description provided for @placesContactClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get placesContactClose;

  /// No description provided for @placesPhotoPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous photo'**
  String get placesPhotoPrevious;

  /// No description provided for @placesPhotoNext.
  ///
  /// In en, this message translates to:
  /// **'Next photo'**
  String get placesPhotoNext;

  /// No description provided for @staysFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get staysFilters;

  /// No description provided for @staysFiltersActive.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count})'**
  String staysFiltersActive(int count);

  /// No description provided for @staysFiltersShown.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String staysFiltersShown(int shown, int total);

  /// No description provided for @staysFiltersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get staysFiltersClear;

  /// No description provided for @staysFiltersDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get staysFiltersDone;

  /// No description provided for @staysFilterWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get staysFilterWhen;

  /// No description provided for @staysFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get staysFilterAll;

  /// No description provided for @staysFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get staysFilterUpcoming;

  /// No description provided for @staysFilterPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get staysFilterPast;

  /// No description provided for @staysSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get staysSortTitle;

  /// No description provided for @staysSortAsc.
  ///
  /// In en, this message translates to:
  /// **'Check-in: earliest first'**
  String get staysSortAsc;

  /// No description provided for @staysSortDesc.
  ///
  /// In en, this message translates to:
  /// **'Check-in: latest first'**
  String get staysSortDesc;

  /// No description provided for @staysNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No stays match these filters'**
  String get staysNoMatchTitle;

  /// No description provided for @staysNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try changing or clearing the filters to see the other stays.'**
  String get staysNoMatchBody;

  /// No description provided for @staysViewCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get staysViewCards;

  /// No description provided for @staysViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get staysViewList;

  /// No description provided for @staysViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get staysViewDetails;

  /// No description provided for @staysExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get staysExpense;

  /// No description provided for @staysMore.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get staysMore;

  /// No description provided for @staysSectionBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get staysSectionBooking;

  /// No description provided for @staysSectionGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get staysSectionGuests;

  /// No description provided for @staysSectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get staysSectionNotes;

  /// No description provided for @staysName.
  ///
  /// In en, this message translates to:
  /// **'Accommodation name'**
  String get staysName;

  /// No description provided for @placesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search on Google: name or address'**
  String get placesSearchHint;

  /// No description provided for @placesSearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get placesSearchButton;

  /// No description provided for @placesSearchError.
  ///
  /// In en, this message translates to:
  /// **'Search unavailable. Please retry.'**
  String get placesSearchError;

  /// No description provided for @placesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load this place.'**
  String get placesLoadError;

  /// No description provided for @placesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get placesNoResults;

  /// No description provided for @placesLinked.
  ///
  /// In en, this message translates to:
  /// **'Place linked to Google Maps'**
  String get placesLinked;

  /// No description provided for @placesUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get placesUnlink;

  /// No description provided for @staysAddress.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get staysAddress;

  /// No description provided for @staysCity.
  ///
  /// In en, this message translates to:
  /// **'City (optional)'**
  String get staysCity;

  /// No description provided for @staysCountry.
  ///
  /// In en, this message translates to:
  /// **'Country (optional)'**
  String get staysCountry;

  /// No description provided for @staysCheckInDay.
  ///
  /// In en, this message translates to:
  /// **'Check-in day'**
  String get staysCheckInDay;

  /// No description provided for @staysCheckOutDay.
  ///
  /// In en, this message translates to:
  /// **'Check-out day'**
  String get staysCheckOutDay;

  /// No description provided for @staysCheckInTime.
  ///
  /// In en, this message translates to:
  /// **'Check-in time'**
  String get staysCheckInTime;

  /// No description provided for @staysCheckOutTime.
  ///
  /// In en, this message translates to:
  /// **'Check-out time'**
  String get staysCheckOutTime;

  /// No description provided for @staysTimeNone.
  ///
  /// In en, this message translates to:
  /// **'No time set'**
  String get staysTimeNone;

  /// No description provided for @staysTimeClear.
  ///
  /// In en, this message translates to:
  /// **'Remove time'**
  String get staysTimeClear;

  /// No description provided for @staysBookedViaLabel.
  ///
  /// In en, this message translates to:
  /// **'Booked on (optional)'**
  String get staysBookedViaLabel;

  /// No description provided for @staysBookedViaNone.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get staysBookedViaNone;

  /// No description provided for @staysBookedViaOther.
  ///
  /// In en, this message translates to:
  /// **'Which platform?'**
  String get staysBookedViaOther;

  /// No description provided for @staysBookingUrl.
  ///
  /// In en, this message translates to:
  /// **'Booking link (optional)'**
  String get staysBookingUrl;

  /// No description provided for @staysPropertyUrl.
  ///
  /// In en, this message translates to:
  /// **'Property website link (optional)'**
  String get staysPropertyUrl;

  /// No description provided for @staysCode.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code (optional)'**
  String get staysCode;

  /// No description provided for @staysGuestsHint.
  ///
  /// In en, this message translates to:
  /// **'Who sleeps here (optional)'**
  String get staysGuestsHint;

  /// No description provided for @staysNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get staysNotes;

  /// No description provided for @staysSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get staysSave;

  /// No description provided for @staysSaved.
  ///
  /// In en, this message translates to:
  /// **'Accommodation saved.'**
  String get staysSaved;

  /// No description provided for @staysSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the accommodation. Check your connection and try again.'**
  String get staysSaveError;

  /// No description provided for @staysErrName.
  ///
  /// In en, this message translates to:
  /// **'Enter the accommodation name.'**
  String get staysErrName;

  /// No description provided for @staysErrTooLong.
  ///
  /// In en, this message translates to:
  /// **'Text too long (maximum {max} characters).'**
  String staysErrTooLong(int max);

  /// No description provided for @staysErrDates.
  ///
  /// In en, this message translates to:
  /// **'Check-out cannot be before check-in.'**
  String get staysErrDates;

  /// No description provided for @staysErrTime.
  ///
  /// In en, this message translates to:
  /// **'Invalid time.'**
  String get staysErrTime;

  /// No description provided for @staysErrCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Invalid place coordinates.'**
  String get staysErrCoordinates;

  /// No description provided for @staysErrOther.
  ///
  /// In en, this message translates to:
  /// **'Enter where it was booked.'**
  String get staysErrOther;

  /// No description provided for @staysErrLink.
  ///
  /// In en, this message translates to:
  /// **'The link must start with http:// or https:// and contain no spaces.'**
  String get staysErrLink;

  /// No description provided for @staysErrGuests.
  ///
  /// In en, this message translates to:
  /// **'At most 50 guests.'**
  String get staysErrGuests;

  /// No description provided for @staysErrExpense.
  ///
  /// In en, this message translates to:
  /// **'Invalid linked expense.'**
  String get staysErrExpense;

  /// No description provided for @staysErrCost.
  ///
  /// In en, this message translates to:
  /// **'Invalid expected cost: enter an amount above zero in the currency format.'**
  String get staysErrCost;

  /// No description provided for @staysErrExtras.
  ///
  /// In en, this message translates to:
  /// **'Arrival, access or tax: check the data (time, amount, people from 1 to 50).'**
  String get staysErrExtras;

  /// No description provided for @staysSectionArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival, access and tax'**
  String get staysSectionArrival;

  /// No description provided for @staysLateArrival.
  ///
  /// In en, this message translates to:
  /// **'Late arrival (time)'**
  String get staysLateArrival;

  /// No description provided for @staysReception.
  ///
  /// In en, this message translates to:
  /// **'Reception contact'**
  String get staysReception;

  /// No description provided for @staysDoorCode.
  ///
  /// In en, this message translates to:
  /// **'Door code'**
  String get staysDoorCode;

  /// No description provided for @staysWifiName.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi name'**
  String get staysWifiName;

  /// No description provided for @staysWifiPassword.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi password'**
  String get staysWifiPassword;

  /// No description provided for @staysAccessNotes.
  ///
  /// In en, this message translates to:
  /// **'Access instructions'**
  String get staysAccessNotes;

  /// No description provided for @staysCityTax.
  ///
  /// In en, this message translates to:
  /// **'City tax per person per night'**
  String get staysCityTax;

  /// No description provided for @staysCityTaxPersons.
  ///
  /// In en, this message translates to:
  /// **'People paying the tax'**
  String get staysCityTaxPersons;

  /// No description provided for @staysCityTaxPersonsHint.
  ///
  /// In en, this message translates to:
  /// **'When empty, the guests of the stay are used.'**
  String get staysCityTaxPersonsHint;

  /// No description provided for @staysLateArrivalValue.
  ///
  /// In en, this message translates to:
  /// **'Arrival at {time}'**
  String staysLateArrivalValue(String time);

  /// No description provided for @staysReceptionValue.
  ///
  /// In en, this message translates to:
  /// **'Reception: {contact}'**
  String staysReceptionValue(String contact);

  /// No description provided for @staysDoorCodeValue.
  ///
  /// In en, this message translates to:
  /// **'Door code: {code}'**
  String staysDoorCodeValue(String code);

  /// No description provided for @staysWifiValue.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi: {value}'**
  String staysWifiValue(String value);

  /// No description provided for @staysCityTaxEach.
  ///
  /// In en, this message translates to:
  /// **'City tax: {amount} per person per night'**
  String staysCityTaxEach(String amount);

  /// No description provided for @staysCityTaxValue.
  ///
  /// In en, this message translates to:
  /// **'City tax: {total} ({amount} × {nights} nights × {persons} people)'**
  String staysCityTaxValue(String total, String amount, int nights, int persons);

  /// No description provided for @staysSectionCost.
  ///
  /// In en, this message translates to:
  /// **'Cost and cancellation'**
  String get staysSectionCost;

  /// No description provided for @staysCost.
  ///
  /// In en, this message translates to:
  /// **'Expected cost'**
  String get staysCost;

  /// No description provided for @staysCostCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get staysCostCurrency;

  /// No description provided for @staysCostHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: it will be the starting amount of “Create expense”.'**
  String get staysCostHint;

  /// No description provided for @staysFreeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation until'**
  String get staysFreeCancellation;

  /// No description provided for @staysFreeCancellationNone.
  ///
  /// In en, this message translates to:
  /// **'no date'**
  String get staysFreeCancellationNone;

  /// No description provided for @staysFreeCancellationClear.
  ///
  /// In en, this message translates to:
  /// **'Remove the date'**
  String get staysFreeCancellationClear;

  /// No description provided for @staysSectionServices.
  ///
  /// In en, this message translates to:
  /// **'Services and directions'**
  String get staysSectionServices;

  /// No description provided for @staysAmenityBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get staysAmenityBreakfast;

  /// No description provided for @staysAmenityParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get staysAmenityParking;

  /// No description provided for @staysAmenityWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get staysAmenityWifi;

  /// No description provided for @staysAmenityKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get staysAmenityKitchen;

  /// No description provided for @staysDirections.
  ///
  /// In en, this message translates to:
  /// **'How to get there'**
  String get staysDirections;

  /// No description provided for @staysCancellationUntil.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation until {date}'**
  String staysCancellationUntil(String date);

  /// No description provided for @staysCancellationSoon.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Free cancellation: last day today} =1{Free cancellation: 1 day left ({date})} other{Free cancellation: {count} days left ({date})}}'**
  String staysCancellationSoon(int count, String date);

  /// No description provided for @staysCancellationExpired.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation ended on {date}'**
  String staysCancellationExpired(String date);

  /// No description provided for @staysCostEstimated.
  ///
  /// In en, this message translates to:
  /// **'Expected cost: {amount}'**
  String staysCostEstimated(String amount);

  /// No description provided for @staysAmenities.
  ///
  /// In en, this message translates to:
  /// **'Included: {list}'**
  String staysAmenities(String list);

  /// No description provided for @staysGapsWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night of the trip without a stay: {nights}.} other{{count} nights of the trip without a stay: {nights}.}}'**
  String staysGapsWarning(int count, String nights);

  /// No description provided for @staysGapsHint.
  ///
  /// In en, this message translates to:
  /// **'Just a reminder: if it is on purpose, you can ignore it.'**
  String get staysGapsHint;

  /// No description provided for @sectionsViewCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get sectionsViewCards;

  /// No description provided for @sectionsViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get sectionsViewList;

  /// No description provided for @sectionsViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get sectionsViewDetails;

  /// No description provided for @sectionsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get sectionsEdit;

  /// No description provided for @sectionsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sectionsDelete;

  /// No description provided for @sectionsMore.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get sectionsMore;

  /// No description provided for @sectionsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sectionsCancel;

  /// No description provided for @sectionsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get sectionsSave;

  /// No description provided for @sectionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get sectionsSaved;

  /// No description provided for @sectionsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Check the connection and try again.'**
  String get sectionsSaveError;

  /// No description provided for @sectionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the data. Try again later.'**
  String get sectionsLoadError;

  /// No description provided for @sectionsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone?'**
  String get sectionsDeleteTitle;

  /// No description provided for @sectionsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be deleted for every traveler. This cannot be undone.'**
  String sectionsDeleteBody(String name);

  /// No description provided for @sectionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get sectionsDeleted;

  /// No description provided for @sectionsDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: only its creator or the trip owner can delete it.'**
  String get sectionsDeleteError;

  /// No description provided for @sectionsOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get sectionsOpenMap;

  /// No description provided for @sectionsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get sectionsContact;

  /// No description provided for @sectionsContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact {name}'**
  String sectionsContactTitle(String name);

  /// No description provided for @sectionsExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get sectionsExpense;

  /// No description provided for @sectionsExpenseCreate.
  ///
  /// In en, this message translates to:
  /// **'Create expense'**
  String get sectionsExpenseCreate;

  /// No description provided for @sectionsExpenseLinkExisting.
  ///
  /// In en, this message translates to:
  /// **'Link existing expense'**
  String get sectionsExpenseLinkExisting;

  /// No description provided for @sectionsExpenseView.
  ///
  /// In en, this message translates to:
  /// **'View expense'**
  String get sectionsExpenseView;

  /// No description provided for @sectionsExpenseLinked.
  ///
  /// In en, this message translates to:
  /// **'Expense linked.'**
  String get sectionsExpenseLinked;

  /// No description provided for @sectionsExpenseLinkError.
  ///
  /// In en, this message translates to:
  /// **'Expense created but not linked: link it with “Link existing expense”.'**
  String get sectionsExpenseLinkError;

  /// No description provided for @sectionsExpensePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a shared expense'**
  String get sectionsExpensePickTitle;

  /// No description provided for @sectionsExpensePickEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no shared expenses to link.'**
  String get sectionsExpensePickEmpty;

  /// No description provided for @sectionsExpenseLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the expenses.'**
  String get sectionsExpenseLoadError;

  /// No description provided for @sectionsExpenseNotVisible.
  ///
  /// In en, this message translates to:
  /// **'Linked expense not visible to you.'**
  String get sectionsExpenseNotVisible;

  /// No description provided for @sectionsExpenseLinkedTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense: {title}'**
  String sectionsExpenseLinkedTitle(String title);

  /// No description provided for @sectionsDateNone.
  ///
  /// In en, this message translates to:
  /// **'no date'**
  String get sectionsDateNone;

  /// No description provided for @sectionsTimeNone.
  ///
  /// In en, this message translates to:
  /// **'no time'**
  String get sectionsTimeNone;

  /// No description provided for @sectionsClear.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get sectionsClear;

  /// No description provided for @sectionsCost.
  ///
  /// In en, this message translates to:
  /// **'Expected cost'**
  String get sectionsCost;

  /// No description provided for @sectionsCostCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get sectionsCostCurrency;

  /// No description provided for @sectionsCostHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: it will be the starting amount of “Create expense”.'**
  String get sectionsCostHint;

  /// No description provided for @sectionsCostEstimated.
  ///
  /// In en, this message translates to:
  /// **'Expected cost: {amount}'**
  String sectionsCostEstimated(String amount);

  /// No description provided for @sectionsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get sectionsAll;

  /// No description provided for @sectionsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get sectionsUpcoming;

  /// No description provided for @sectionsPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get sectionsPast;

  /// No description provided for @sectionsSortFirst.
  ///
  /// In en, this message translates to:
  /// **'Earliest first'**
  String get sectionsSortFirst;

  /// No description provided for @sectionsSortLast.
  ///
  /// In en, this message translates to:
  /// **'Latest first'**
  String get sectionsSortLast;

  /// No description provided for @sectionsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters.'**
  String get sectionsNoMatch;

  /// No description provided for @sectionsStatusToBook.
  ///
  /// In en, this message translates to:
  /// **'To book'**
  String get sectionsStatusToBook;

  /// No description provided for @sectionsStatusBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get sectionsStatusBooked;

  /// No description provided for @sectionsStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get sectionsStatusCancelled;

  /// No description provided for @sectionsBlockStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sectionsBlockStatus;

  /// No description provided for @sectionsBlockNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get sectionsBlockNotes;

  /// No description provided for @sectionsBlockCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get sectionsBlockCost;

  /// No description provided for @sectionsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get sectionsNotes;

  /// No description provided for @sectionsLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get sectionsLink;

  /// No description provided for @sectionsBookingCode.
  ///
  /// In en, this message translates to:
  /// **'Booking code'**
  String get sectionsBookingCode;

  /// No description provided for @sectionsBookingCodeValue.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String sectionsBookingCodeValue(String code);

  /// No description provided for @sectionsFormerMember.
  ///
  /// In en, this message translates to:
  /// **'Former traveler'**
  String get sectionsFormerMember;

  /// No description provided for @sectionsErrRequired.
  ///
  /// In en, this message translates to:
  /// **'Fill in “{field}”.'**
  String sectionsErrRequired(String field);

  /// No description provided for @sectionsErrTooLong.
  ///
  /// In en, this message translates to:
  /// **'Text too long (at most {max} characters).'**
  String sectionsErrTooLong(int max);

  /// No description provided for @sectionsErrLink.
  ///
  /// In en, this message translates to:
  /// **'The link must start with http:// or https:// and contain no spaces.'**
  String get sectionsErrLink;

  /// No description provided for @sectionsErrCost.
  ///
  /// In en, this message translates to:
  /// **'Invalid expected cost: enter an amount above zero in the currency format.'**
  String get sectionsErrCost;

  /// No description provided for @sectionsErrMembers.
  ///
  /// In en, this message translates to:
  /// **'At most 50 travelers.'**
  String get sectionsErrMembers;

  /// No description provided for @sectionsErrExpense.
  ///
  /// In en, this message translates to:
  /// **'Invalid linked expense.'**
  String get sectionsErrExpense;

  /// No description provided for @sectionsErrPlace.
  ///
  /// In en, this message translates to:
  /// **'Invalid place.'**
  String get sectionsErrPlace;

  /// No description provided for @transportAdd.
  ///
  /// In en, this message translates to:
  /// **'Add transport'**
  String get transportAdd;

  /// No description provided for @transportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transport yet: add the flights, trains, buses, ferries, rentals and transfers of the trip.'**
  String get transportEmpty;

  /// No description provided for @transportEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New transport'**
  String get transportEditorNewTitle;

  /// No description provided for @transportEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit transport'**
  String get transportEditorEditTitle;

  /// No description provided for @transportTypeFlight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get transportTypeFlight;

  /// No description provided for @transportTypeTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get transportTypeTrain;

  /// No description provided for @transportTypeBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get transportTypeBus;

  /// No description provided for @transportTypeFerry.
  ///
  /// In en, this message translates to:
  /// **'Ferry'**
  String get transportTypeFerry;

  /// No description provided for @transportTypeCarRental.
  ///
  /// In en, this message translates to:
  /// **'Car rental'**
  String get transportTypeCarRental;

  /// No description provided for @transportTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transportTypeTransfer;

  /// No description provided for @transportTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get transportTypeOther;

  /// No description provided for @transportBlockType.
  ///
  /// In en, this message translates to:
  /// **'Type and status'**
  String get transportBlockType;

  /// No description provided for @transportBlockRoute.
  ///
  /// In en, this message translates to:
  /// **'From / to'**
  String get transportBlockRoute;

  /// No description provided for @transportBlockTimes.
  ///
  /// In en, this message translates to:
  /// **'Departure and arrival'**
  String get transportBlockTimes;

  /// No description provided for @transportBlockService.
  ///
  /// In en, this message translates to:
  /// **'Company, seats and passengers'**
  String get transportBlockService;

  /// No description provided for @transportBlockBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get transportBlockBooking;

  /// No description provided for @transportFrom.
  ///
  /// In en, this message translates to:
  /// **'From (departure place)'**
  String get transportFrom;

  /// No description provided for @transportTo.
  ///
  /// In en, this message translates to:
  /// **'To (arrival place)'**
  String get transportTo;

  /// No description provided for @transportDepartureDay.
  ///
  /// In en, this message translates to:
  /// **'Departure day'**
  String get transportDepartureDay;

  /// No description provided for @transportDepartureTime.
  ///
  /// In en, this message translates to:
  /// **'Departure time'**
  String get transportDepartureTime;

  /// No description provided for @transportArrivalDay.
  ///
  /// In en, this message translates to:
  /// **'Arrival day'**
  String get transportArrivalDay;

  /// No description provided for @transportArrivalTime.
  ///
  /// In en, this message translates to:
  /// **'Arrival time'**
  String get transportArrivalTime;

  /// No description provided for @transportTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get transportTimeZone;

  /// No description provided for @transportTimeZoneNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get transportTimeZoneNone;

  /// No description provided for @transportCarrier.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get transportCarrier;

  /// No description provided for @transportNumber.
  ///
  /// In en, this message translates to:
  /// **'Number (flight, train…)'**
  String get transportNumber;

  /// No description provided for @transportSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get transportSeats;

  /// No description provided for @transportPassengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get transportPassengers;

  /// No description provided for @transportBookedVia.
  ///
  /// In en, this message translates to:
  /// **'Booked on'**
  String get transportBookedVia;

  /// No description provided for @transportBookingLink.
  ///
  /// In en, this message translates to:
  /// **'Booking link'**
  String get transportBookingLink;

  /// No description provided for @transportDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String transportDuration(String duration);

  /// No description provided for @transportSeatsValue.
  ///
  /// In en, this message translates to:
  /// **'Seats: {seats}'**
  String transportSeatsValue(String seats);

  /// No description provided for @transportBookedViaValue.
  ///
  /// In en, this message translates to:
  /// **'Booked on {name}'**
  String transportBookedViaValue(String name);

  /// No description provided for @transportPassengersValue.
  ///
  /// In en, this message translates to:
  /// **'Passengers: {names}'**
  String transportPassengersValue(String names);

  /// No description provided for @transportWarningTight.
  ///
  /// In en, this message translates to:
  /// **'Tight connection: {minutes} min between “{first}” and “{second}”.'**
  String transportWarningTight(int minutes, String first, String second);

  /// No description provided for @transportWarningOverlap.
  ///
  /// In en, this message translates to:
  /// **'“{first}” arrives after “{second}” leaves.'**
  String transportWarningOverlap(String first, String second);

  /// No description provided for @transportWarningHint.
  ///
  /// In en, this message translates to:
  /// **'Just a notice: check times and time zones.'**
  String get transportWarningHint;

  /// No description provided for @transportErrArrival.
  ///
  /// In en, this message translates to:
  /// **'The arrival cannot be before the departure.'**
  String get transportErrArrival;

  /// No description provided for @transportErrTime.
  ///
  /// In en, this message translates to:
  /// **'Invalid time.'**
  String get transportErrTime;

  /// No description provided for @transportErrTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Invalid time zone.'**
  String get transportErrTimeZone;

  /// No description provided for @reservationAdd.
  ///
  /// In en, this message translates to:
  /// **'Add booking'**
  String get reservationAdd;

  /// No description provided for @reservationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet: add tickets, entries, tours and excursions.'**
  String get reservationEmpty;

  /// No description provided for @reservationEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New booking'**
  String get reservationEditorNewTitle;

  /// No description provided for @reservationEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit booking'**
  String get reservationEditorEditTitle;

  /// No description provided for @reservationCategoryTicket.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get reservationCategoryTicket;

  /// No description provided for @reservationCategoryEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get reservationCategoryEntry;

  /// No description provided for @reservationCategoryTour.
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get reservationCategoryTour;

  /// No description provided for @reservationCategoryExcursion.
  ///
  /// In en, this message translates to:
  /// **'Excursion'**
  String get reservationCategoryExcursion;

  /// No description provided for @reservationCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reservationCategoryOther;

  /// No description provided for @reservationBlockMain.
  ///
  /// In en, this message translates to:
  /// **'Name, category and status'**
  String get reservationBlockMain;

  /// No description provided for @reservationBlockWhenWhere.
  ///
  /// In en, this message translates to:
  /// **'When and where'**
  String get reservationBlockWhenWhere;

  /// No description provided for @reservationBlockBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking and participants'**
  String get reservationBlockBooking;

  /// No description provided for @reservationName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get reservationName;

  /// No description provided for @reservationDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get reservationDay;

  /// No description provided for @reservationTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reservationTime;

  /// No description provided for @reservationPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get reservationPlace;

  /// No description provided for @reservationLink.
  ///
  /// In en, this message translates to:
  /// **'Booking link'**
  String get reservationLink;

  /// No description provided for @reservationParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get reservationParticipants;

  /// No description provided for @reservationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get reservationPolicy;

  /// No description provided for @reservationParticipantsValue.
  ///
  /// In en, this message translates to:
  /// **'Participants: {names}'**
  String reservationParticipantsValue(String names);

  /// No description provided for @reservationPolicyValue.
  ///
  /// In en, this message translates to:
  /// **'Cancellation: {policy}'**
  String reservationPolicyValue(String policy);

  /// No description provided for @restaurantAdd.
  ///
  /// In en, this message translates to:
  /// **'Add restaurant'**
  String get restaurantAdd;

  /// No description provided for @restaurantEmpty.
  ///
  /// In en, this message translates to:
  /// **'No restaurants yet: add places to eat and vote on them together.'**
  String get restaurantEmpty;

  /// No description provided for @restaurantEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New restaurant'**
  String get restaurantEditorNewTitle;

  /// No description provided for @restaurantEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit restaurant'**
  String get restaurantEditorEditTitle;

  /// No description provided for @restaurantStatusToTry.
  ///
  /// In en, this message translates to:
  /// **'To try'**
  String get restaurantStatusToTry;

  /// No description provided for @restaurantStatusBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get restaurantStatusBooked;

  /// No description provided for @restaurantStatusTried.
  ///
  /// In en, this message translates to:
  /// **'Tried'**
  String get restaurantStatusTried;

  /// No description provided for @restaurantBlockPlace.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurantBlockPlace;

  /// No description provided for @restaurantBlockKind.
  ///
  /// In en, this message translates to:
  /// **'Status, cuisine and price'**
  String get restaurantBlockKind;

  /// No description provided for @restaurantBlockReservation.
  ///
  /// In en, this message translates to:
  /// **'Reservation'**
  String get restaurantBlockReservation;

  /// No description provided for @restaurantName.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name'**
  String get restaurantName;

  /// No description provided for @restaurantPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get restaurantPhone;

  /// No description provided for @restaurantWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get restaurantWebsite;

  /// No description provided for @restaurantCuisine.
  ///
  /// In en, this message translates to:
  /// **'Cuisine (e.g. ramen, sushi)'**
  String get restaurantCuisine;

  /// No description provided for @restaurantParty.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get restaurantParty;

  /// No description provided for @restaurantPartyValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String restaurantPartyValue(int count);

  /// No description provided for @restaurantVotesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No votes: choose yours} =1{1 vote} other{{count} votes}}'**
  String restaurantVotesTitle(int count);

  /// No description provided for @restaurantSortVotes.
  ///
  /// In en, this message translates to:
  /// **'Most voted'**
  String get restaurantSortVotes;

  /// No description provided for @restaurantSortName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get restaurantSortName;

  /// No description provided for @restaurantSortDate.
  ///
  /// In en, this message translates to:
  /// **'By reservation'**
  String get restaurantSortDate;

  /// No description provided for @restaurantErrPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone: use digits, spaces and + ( ) . / -'**
  String get restaurantErrPhone;

  /// No description provided for @restaurantErrParty.
  ///
  /// In en, this message translates to:
  /// **'People: enter a number from 1 to 100.'**
  String get restaurantErrParty;

  /// No description provided for @savedPlaceAdd.
  ///
  /// In en, this message translates to:
  /// **'Save a place'**
  String get savedPlaceAdd;

  /// No description provided for @savedPlaceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved places: search on Google or paste a Google Maps link.'**
  String get savedPlaceEmpty;

  /// No description provided for @savedPlaceEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New saved place'**
  String get savedPlaceEditorNewTitle;

  /// No description provided for @savedPlaceEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit saved place'**
  String get savedPlaceEditorEditTitle;

  /// No description provided for @savedPlaceBlockPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get savedPlaceBlockPlace;

  /// No description provided for @savedPlaceBlockCategory.
  ///
  /// In en, this message translates to:
  /// **'Category and notes'**
  String get savedPlaceBlockCategory;

  /// No description provided for @savedPlaceName.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get savedPlaceName;

  /// No description provided for @savedPlaceMapsLink.
  ///
  /// In en, this message translates to:
  /// **'Google Maps link'**
  String get savedPlaceMapsLink;

  /// No description provided for @savedPlaceMapsLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: pasting the link fills the name and position when available.'**
  String get savedPlaceMapsLinkHint;

  /// No description provided for @savedPlaceAddedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String savedPlaceAddedBy(String name);

  /// No description provided for @savedPlaceCategorySight.
  ///
  /// In en, this message translates to:
  /// **'To see'**
  String get savedPlaceCategorySight;

  /// No description provided for @savedPlaceCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get savedPlaceCategoryFood;

  /// No description provided for @savedPlaceCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get savedPlaceCategoryShopping;

  /// No description provided for @savedPlaceCategoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get savedPlaceCategoryNature;

  /// No description provided for @savedPlaceCategoryNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get savedPlaceCategoryNightlife;

  /// No description provided for @savedPlaceCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get savedPlaceCategoryOther;

  /// No description provided for @savedPlaceBlockVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get savedPlaceBlockVisit;

  /// No description provided for @savedPlacePriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get savedPlacePriority;

  /// No description provided for @savedPlaceVisited.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get savedPlaceVisited;

  /// No description provided for @savedPlaceDay.
  ///
  /// In en, this message translates to:
  /// **'Planned day'**
  String get savedPlaceDay;

  /// No description provided for @savedPlaceArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get savedPlaceArea;

  /// No description provided for @savedPlaceAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Neighbourhood or area, to group places close to each other.'**
  String get savedPlaceAreaHint;

  /// No description provided for @savedPlaceMinutes.
  ///
  /// In en, this message translates to:
  /// **'Visit time (minutes)'**
  String get savedPlaceMinutes;

  /// No description provided for @savedPlaceEntryPrice.
  ///
  /// In en, this message translates to:
  /// **'Entry price per person'**
  String get savedPlaceEntryPrice;

  /// No description provided for @savedPlaceTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets link'**
  String get savedPlaceTickets;

  /// No description provided for @savedPlaceErrMinutes.
  ///
  /// In en, this message translates to:
  /// **'Visit time: from 1 to 1440 minutes.'**
  String get savedPlaceErrMinutes;

  /// No description provided for @savedPlaceNoArea.
  ///
  /// In en, this message translates to:
  /// **'No area'**
  String get savedPlaceNoArea;

  /// No description provided for @savedPlaceNoDay.
  ///
  /// In en, this message translates to:
  /// **'No day'**
  String get savedPlaceNoDay;

  /// No description provided for @savedPlaceFilterTodo.
  ///
  /// In en, this message translates to:
  /// **'To visit'**
  String get savedPlaceFilterTodo;

  /// No description provided for @savedPlaceFilterDone.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get savedPlaceFilterDone;

  /// No description provided for @savedPlaceSortPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get savedPlaceSortPriority;

  /// No description provided for @savedPlaceGroupArea.
  ///
  /// In en, this message translates to:
  /// **'By area'**
  String get savedPlaceGroupArea;

  /// No description provided for @savedPlaceGroupDay.
  ///
  /// In en, this message translates to:
  /// **'By day'**
  String get savedPlaceGroupDay;

  /// No description provided for @savedPlaceMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'Visit: {value}'**
  String savedPlaceMinutesValue(String value);

  /// No description provided for @savedPlaceEntryPriceValue.
  ///
  /// In en, this message translates to:
  /// **'Entry: {value} per person'**
  String savedPlaceEntryPriceValue(String value);

  /// No description provided for @savedPlaceMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String savedPlaceMinutesShort(int count);

  /// No description provided for @savedPlaceHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String savedPlaceHoursShort(int count);

  /// No description provided for @noteAdd.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get noteAdd;

  /// No description provided for @noteEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes: write reminders, checklists or the useful info of the trip.'**
  String get noteEmpty;

  /// No description provided for @noteEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get noteEditorNewTitle;

  /// No description provided for @noteEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEditorEditTitle;

  /// No description provided for @noteBlockText.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteBlockText;

  /// No description provided for @noteBlockChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get noteBlockChecklist;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteTitle;

  /// No description provided for @noteBody.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get noteBody;

  /// No description provided for @noteShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get noteShared;

  /// No description provided for @notePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get notePrivate;

  /// No description provided for @notePinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get notePinned;

  /// No description provided for @notePrivateSwitch.
  ///
  /// In en, this message translates to:
  /// **'Private note'**
  String get notePrivateSwitch;

  /// No description provided for @notePrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Only its author can read it; the other travelers do not see it.'**
  String get notePrivateHint;

  /// No description provided for @notePinnedSwitch.
  ///
  /// In en, this message translates to:
  /// **'Pin to the top'**
  String get notePinnedSwitch;

  /// No description provided for @noteItemHint.
  ///
  /// In en, this message translates to:
  /// **'Checklist item'**
  String get noteItemHint;

  /// No description provided for @noteItemAdd.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get noteItemAdd;

  /// No description provided for @noteChecklistProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String noteChecklistProgress(int done, int total);

  /// No description provided for @noteTemplateUseful.
  ///
  /// In en, this message translates to:
  /// **'Use the “Useful info” template'**
  String get noteTemplateUseful;

  /// No description provided for @noteTemplateUsefulTitle.
  ///
  /// In en, this message translates to:
  /// **'Useful info'**
  String get noteTemplateUsefulTitle;

  /// No description provided for @noteTemplateUsefulBody.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi (network): \nWi-Fi password: \nStay address: \nEmergency number: 112\nEmbassy or consulate: \nTravel insurance: \nTaxi: '**
  String get noteTemplateUsefulBody;

  /// No description provided for @noteErrChecklist.
  ///
  /// In en, this message translates to:
  /// **'The checklist can have at most 100 items.'**
  String get noteErrChecklist;

  /// No description provided for @noteTemplatePhrases.
  ///
  /// In en, this message translates to:
  /// **'Use the «Useful phrases» template'**
  String get noteTemplatePhrases;

  /// No description provided for @noteTemplatePhrasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Useful phrases'**
  String get noteTemplatePhrasesTitle;

  /// No description provided for @noteTemplatePhrasesBody.
  ///
  /// In en, this message translates to:
  /// **'# Useful phrases\n- Hello / Good morning: \n- Thank you: \n- Excuse me: \n- How much is it?: \n- Where is the toilet?: \n- The bill, please: \n- I\'m allergic to: \n- Help!: '**
  String get noteTemplatePhrasesBody;

  /// No description provided for @noteTemplateContacts.
  ///
  /// In en, this message translates to:
  /// **'Use the «Contacts» template'**
  String get noteTemplateContacts;

  /// No description provided for @noteTemplateContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get noteTemplateContactsTitle;

  /// No description provided for @noteTemplateContactsBody.
  ///
  /// In en, this message translates to:
  /// **'# Contacts\n- Emergency: 112\n- Embassy or consulate: \n- Accommodation: \n- Travel insurance: \n- Airline: \n- Taxi: \n- Contact at home: '**
  String get noteTemplateContactsBody;

  /// No description provided for @noteFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (line starting with #)'**
  String get noteFormatTitle;

  /// No description provided for @noteFormatList.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get noteFormatList;

  /// No description provided for @noteFormatBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get noteFormatBold;

  /// No description provided for @noteBlockLink.
  ///
  /// In en, this message translates to:
  /// **'Linked to'**
  String get noteBlockLink;

  /// No description provided for @noteLinkNone.
  ///
  /// In en, this message translates to:
  /// **'No linked element'**
  String get noteLinkNone;

  /// No description provided for @noteLinkPick.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get noteLinkPick;

  /// No description provided for @noteLinkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove the link'**
  String get noteLinkRemove;

  /// No description provided for @noteLinkEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stay, transport, booking, restaurant or place in the trip.'**
  String get noteLinkEmpty;

  /// No description provided for @noteLinkedTo.
  ///
  /// In en, this message translates to:
  /// **'Linked to {name} ({section})'**
  String noteLinkedTo(String name, String section);

  /// No description provided for @shoppingTabItems.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shoppingTabItems;

  /// No description provided for @shoppingTabPacking.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get shoppingTabPacking;

  /// No description provided for @shoppingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get shoppingAdd;

  /// No description provided for @shoppingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to buy yet: add gifts, souvenirs and things you need.'**
  String get shoppingEmpty;

  /// No description provided for @shoppingEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get shoppingEditorNewTitle;

  /// No description provided for @shoppingEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get shoppingEditorEditTitle;

  /// No description provided for @shoppingBlockItem.
  ///
  /// In en, this message translates to:
  /// **'What and for whom'**
  String get shoppingBlockItem;

  /// No description provided for @shoppingName.
  ///
  /// In en, this message translates to:
  /// **'What'**
  String get shoppingName;

  /// No description provided for @shoppingFor.
  ///
  /// In en, this message translates to:
  /// **'For whom'**
  String get shoppingFor;

  /// No description provided for @shoppingForValue.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String shoppingForValue(String name);

  /// No description provided for @shoppingForText.
  ///
  /// In en, this message translates to:
  /// **'For whom (written by you)'**
  String get shoppingForText;

  /// No description provided for @shoppingForTextHint.
  ///
  /// In en, this message translates to:
  /// **'Also someone who is not travelling, e.g. «Grandma».'**
  String get shoppingForTextHint;

  /// No description provided for @shoppingPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get shoppingPriority;

  /// No description provided for @shoppingBoughtBy.
  ///
  /// In en, this message translates to:
  /// **'Bought by {name}'**
  String shoppingBoughtBy(String name);

  /// No description provided for @shoppingWhere.
  ///
  /// In en, this message translates to:
  /// **'Where (shop or area)'**
  String get shoppingWhere;

  /// No description provided for @shoppingBought.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get shoppingBought;

  /// No description provided for @shoppingToBuy.
  ///
  /// In en, this message translates to:
  /// **'To buy'**
  String get shoppingToBuy;

  /// No description provided for @shoppingBudget.
  ///
  /// In en, this message translates to:
  /// **'Estimated budget'**
  String get shoppingBudget;

  /// No description provided for @shoppingPrice.
  ///
  /// In en, this message translates to:
  /// **'Real price'**
  String get shoppingPrice;

  /// No description provided for @shoppingBudgetValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated budget: {amount}'**
  String shoppingBudgetValue(String amount);

  /// No description provided for @shoppingPriceValue.
  ///
  /// In en, this message translates to:
  /// **'Real price: {amount}'**
  String shoppingPriceValue(String amount);

  /// No description provided for @packingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to packing list'**
  String get packingAdd;

  /// No description provided for @packingEmpty.
  ///
  /// In en, this message translates to:
  /// **'The packing list is empty: add what to bring, per person or for everyone.'**
  String get packingEmpty;

  /// No description provided for @packingEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New packing item'**
  String get packingEditorNewTitle;

  /// No description provided for @packingEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit packing item'**
  String get packingEditorEditTitle;

  /// No description provided for @packingBlockItem.
  ///
  /// In en, this message translates to:
  /// **'What to bring'**
  String get packingBlockItem;

  /// No description provided for @packingFor.
  ///
  /// In en, this message translates to:
  /// **'For whom (none = everyone)'**
  String get packingFor;

  /// No description provided for @packingForEveryone.
  ///
  /// In en, this message translates to:
  /// **'For everyone'**
  String get packingForEveryone;

  /// No description provided for @packingQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get packingQuantity;

  /// No description provided for @packingPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get packingPacked;

  /// No description provided for @packingToPack.
  ///
  /// In en, this message translates to:
  /// **'To pack'**
  String get packingToPack;

  /// No description provided for @packingErrQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity: enter a number from 1 to 99.'**
  String get packingErrQuantity;

  /// No description provided for @memoryAdd.
  ///
  /// In en, this message translates to:
  /// **'New memory'**
  String get memoryAdd;

  /// No description provided for @memoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No memories yet: write the diary of each day or link the photo album.'**
  String get memoryEmpty;

  /// No description provided for @memoryEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New memory'**
  String get memoryEditorNewTitle;

  /// No description provided for @memoryEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit memory'**
  String get memoryEditorEditTitle;

  /// No description provided for @memoryBlockKind.
  ///
  /// In en, this message translates to:
  /// **'Kind of memory'**
  String get memoryBlockKind;

  /// No description provided for @memoryDiary.
  ///
  /// In en, this message translates to:
  /// **'Day diary'**
  String get memoryDiary;

  /// No description provided for @memoryAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get memoryAlbum;

  /// No description provided for @memoryDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get memoryDay;

  /// No description provided for @memoryRating.
  ///
  /// In en, this message translates to:
  /// **'How the day went'**
  String get memoryRating;

  /// No description provided for @memoryMoment.
  ///
  /// In en, this message translates to:
  /// **'The moment of the day (one sentence)'**
  String get memoryMoment;

  /// No description provided for @memoryText.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get memoryText;

  /// No description provided for @memoryAlbumName.
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get memoryAlbumName;

  /// No description provided for @memoryAlbumLink.
  ///
  /// In en, this message translates to:
  /// **'Album link'**
  String get memoryAlbumLink;

  /// No description provided for @memoryAlbumHint.
  ///
  /// In en, this message translates to:
  /// **'Photos stay in your service (Google Photos, iCloud…): only the link is saved here.'**
  String get memoryAlbumHint;

  /// No description provided for @memoryOpenAlbum.
  ///
  /// In en, this message translates to:
  /// **'Open the album'**
  String get memoryOpenAlbum;

  /// No description provided for @memoryWrittenBy.
  ///
  /// In en, this message translates to:
  /// **'Written by {name}'**
  String memoryWrittenBy(String name);

  /// No description provided for @memoryErrDate.
  ///
  /// In en, this message translates to:
  /// **'Choose the day of the diary.'**
  String get memoryErrDate;

  /// No description provided for @budgetExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export expenses'**
  String get budgetExportTitle;

  /// No description provided for @budgetExportCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV for Excel'**
  String get budgetExportCsv;

  /// No description provided for @budgetExportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF (print or save as PDF)'**
  String get budgetExportPdf;

  /// No description provided for @budgetExportError.
  ///
  /// In en, this message translates to:
  /// **'Export failed. If a new tab should open, allow pop-ups for this site.'**
  String get budgetExportError;

  /// No description provided for @budgetExportExpenseColumns.
  ///
  /// In en, this message translates to:
  /// **'Date|Expense|Category|Status|Type|Total|Currency|Paid by|Shares|Notes'**
  String get budgetExportExpenseColumns;

  /// No description provided for @budgetExportRefundColumns.
  ///
  /// In en, this message translates to:
  /// **'Refund of the expense|From|To|Amount|Currency|Status'**
  String get budgetExportRefundColumns;

  /// No description provided for @budgetExportTotalColumns.
  ///
  /// In en, this message translates to:
  /// **'Currency|Total of the expenses'**
  String get budgetExportTotalColumns;

  /// No description provided for @budgetExportPersonColumns.
  ///
  /// In en, this message translates to:
  /// **'Person|Currency|Share|Paid'**
  String get budgetExportPersonColumns;

  /// No description provided for @budgetExportPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get budgetExportPlanned;

  /// No description provided for @budgetExportOutstanding.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get budgetExportOutstanding;

  /// No description provided for @budgetExportPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get budgetExportPaid;

  /// No description provided for @budgetExportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get budgetExportCancelled;

  /// No description provided for @budgetExportPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get budgetExportPersonal;

  /// No description provided for @budgetExportShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get budgetExportShared;

  /// No description provided for @budgetExportPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get budgetExportPending;

  /// No description provided for @budgetExportConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get budgetExportConfirmed;

  /// No description provided for @budgetExportRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get budgetExportRejected;

  /// No description provided for @budgetExportWrittenOff.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get budgetExportWrittenOff;

  /// No description provided for @uiEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get uiEdit;

  /// No description provided for @uiCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get uiCancel;

  /// No description provided for @uiConfirmAgain.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This cannot be undone.'**
  String get uiConfirmAgain;

  /// No description provided for @uiConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, confirm'**
  String get uiConfirmYes;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @filtersActive.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count})'**
  String filtersActive(int count);

  /// No description provided for @filtersShown.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String filtersShown(int shown, int total);

  /// No description provided for @filtersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get filtersClear;

  /// No description provided for @filtersDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get filtersDone;

  /// No description provided for @filtersSort.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get filtersSort;

  /// No description provided for @sectionsFilterWhen.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get sectionsFilterWhen;

  /// No description provided for @sectionsFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get sectionsFilterCategory;

  /// No description provided for @sectionsFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sectionsFilterType;

  /// No description provided for @restaurantFilterPrice.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get restaurantFilterPrice;

  /// No description provided for @noteFilterVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get noteFilterVisibility;

  /// No description provided for @allergenGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten'**
  String get allergenGluten;

  /// No description provided for @allergenCrustaceans.
  ///
  /// In en, this message translates to:
  /// **'Crustaceans'**
  String get allergenCrustaceans;

  /// No description provided for @allergenEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get allergenEggs;

  /// No description provided for @allergenFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get allergenFish;

  /// No description provided for @allergenPeanuts.
  ///
  /// In en, this message translates to:
  /// **'Peanuts'**
  String get allergenPeanuts;

  /// No description provided for @allergenSoy.
  ///
  /// In en, this message translates to:
  /// **'Soy'**
  String get allergenSoy;

  /// No description provided for @allergenMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get allergenMilk;

  /// No description provided for @allergenNuts.
  ///
  /// In en, this message translates to:
  /// **'Tree nuts'**
  String get allergenNuts;

  /// No description provided for @allergenCelery.
  ///
  /// In en, this message translates to:
  /// **'Celery'**
  String get allergenCelery;

  /// No description provided for @allergenMustard.
  ///
  /// In en, this message translates to:
  /// **'Mustard'**
  String get allergenMustard;

  /// No description provided for @allergenSesame.
  ///
  /// In en, this message translates to:
  /// **'Sesame'**
  String get allergenSesame;

  /// No description provided for @allergenSulphites.
  ///
  /// In en, this message translates to:
  /// **'Sulphites'**
  String get allergenSulphites;

  /// No description provided for @allergenLupin.
  ///
  /// In en, this message translates to:
  /// **'Lupin'**
  String get allergenLupin;

  /// No description provided for @allergenMolluscs.
  ///
  /// In en, this message translates to:
  /// **'Molluscs'**
  String get allergenMolluscs;

  /// No description provided for @dietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietVegetarian;

  /// No description provided for @dietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietVegan;

  /// No description provided for @dietHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get dietHalal;

  /// No description provided for @dietKosher.
  ///
  /// In en, this message translates to:
  /// **'Kosher'**
  String get dietKosher;

  /// No description provided for @dietGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten free'**
  String get dietGlutenFree;

  /// No description provided for @restaurantBlockFood.
  ///
  /// In en, this message translates to:
  /// **'Allergens and diet'**
  String get restaurantBlockFood;

  /// No description provided for @restaurantAllergensHint.
  ///
  /// In en, this message translates to:
  /// **'Allergens to tell the restaurant about (people\'s allergies are not saved).'**
  String get restaurantAllergensHint;

  /// No description provided for @restaurantAllergenNotes.
  ///
  /// In en, this message translates to:
  /// **'Allergen note'**
  String get restaurantAllergenNotes;

  /// No description provided for @restaurantDiets.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get restaurantDiets;

  /// No description provided for @restaurantAllergensValue.
  ///
  /// In en, this message translates to:
  /// **'To tell: {list}'**
  String restaurantAllergensValue(String list);

  /// No description provided for @restaurantFilterAllergens.
  ///
  /// In en, this message translates to:
  /// **'Allergens to tell'**
  String get restaurantFilterAllergens;

  /// No description provided for @restaurantFilterYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get restaurantFilterYes;

  /// No description provided for @restaurantFilterNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get restaurantFilterNo;

  /// No description provided for @restaurantTriedRating.
  ///
  /// In en, this message translates to:
  /// **'Rating after trying it'**
  String get restaurantTriedRating;

  /// No description provided for @restaurantTriedNote.
  ///
  /// In en, this message translates to:
  /// **'How it was'**
  String get restaurantTriedNote;

  /// No description provided for @restaurantErrRating.
  ///
  /// In en, this message translates to:
  /// **'Rating: from 1 to 5 stars.'**
  String get restaurantErrRating;

  /// No description provided for @sectionsHours.
  ///
  /// In en, this message translates to:
  /// **'Hours and prices'**
  String get sectionsHours;

  /// No description provided for @sectionsHoursNone.
  ///
  /// In en, this message translates to:
  /// **'Google has no opening hours for this place.'**
  String get sectionsHoursNone;

  /// No description provided for @sectionsHoursError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t read the opening hours now. Try again later.'**
  String get sectionsHoursError;

  /// No description provided for @sectionsHoursSource.
  ///
  /// In en, this message translates to:
  /// **'Google hours and prices, read now and not saved: check them on the place\'s website.'**
  String get sectionsHoursSource;

  /// No description provided for @sectionsClosedDay.
  ///
  /// In en, this message translates to:
  /// **'Warning: it looks closed on {date}.'**
  String sectionsClosedDay(String date);

  /// No description provided for @sectionsClosedTime.
  ///
  /// In en, this message translates to:
  /// **'Warning: it looks closed on {date} at {time}.'**
  String sectionsClosedTime(String date, String time);

  /// No description provided for @sectionsGooglePrice.
  ///
  /// In en, this message translates to:
  /// **'Indicative price on Google: {range}'**
  String sectionsGooglePrice(String range);

  /// No description provided for @sectionsGooglePriceConverted.
  ///
  /// In en, this message translates to:
  /// **'About {range} at today\'s rate'**
  String sectionsGooglePriceConverted(String range);

  /// No description provided for @placesPhotoOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the photos'**
  String get placesPhotoOpen;

  /// No description provided for @placesGoogleMark.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get placesGoogleMark;

  /// No description provided for @tripMoreChecklists.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get tripMoreChecklists;

  /// No description provided for @tripMoreChecklistsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Packing, documents and things not to forget'**
  String get tripMoreChecklistsSubtitle;

  /// No description provided for @checklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get checklistTitle;

  /// No description provided for @checklistAdd.
  ///
  /// In en, this message translates to:
  /// **'New checklist'**
  String get checklistAdd;

  /// No description provided for @checklistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No checklists yet: start from a ready template like Packing.'**
  String get checklistEmpty;

  /// No description provided for @checklistTplPacking.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get checklistTplPacking;

  /// No description provided for @checklistTplDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get checklistTplDocuments;

  /// No description provided for @checklistTplBeforeTrip.
  ///
  /// In en, this message translates to:
  /// **'Before leaving'**
  String get checklistTplBeforeTrip;

  /// No description provided for @checklistTplLeavingHome.
  ///
  /// In en, this message translates to:
  /// **'Before leaving home'**
  String get checklistTplLeavingHome;

  /// No description provided for @checklistTplHealth.
  ///
  /// In en, this message translates to:
  /// **'Medicines and hygiene'**
  String get checklistTplHealth;

  /// No description provided for @checklistTplElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get checklistTplElectronics;

  /// No description provided for @checklistTplEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get checklistTplEmpty;

  /// No description provided for @checklistCatClothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes'**
  String get checklistCatClothes;

  /// No description provided for @checklistCatBathroom.
  ///
  /// In en, this message translates to:
  /// **'Bathroom'**
  String get checklistCatBathroom;

  /// No description provided for @checklistCatAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get checklistCatAccessories;

  /// No description provided for @checklistCatDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get checklistCatDocuments;

  /// No description provided for @checklistCatTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get checklistCatTodo;

  /// No description provided for @checklistCatHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get checklistCatHome;

  /// No description provided for @checklistCatMedicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get checklistCatMedicines;

  /// No description provided for @checklistCatHygiene.
  ///
  /// In en, this message translates to:
  /// **'Hygiene'**
  String get checklistCatHygiene;

  /// No description provided for @checklistCatElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get checklistCatElectronics;

  /// No description provided for @checklistCatGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get checklistCatGeneral;

  /// No description provided for @checklistItemsClothes.
  ///
  /// In en, this message translates to:
  /// **'T-shirts|Trousers|Underwear|Socks|Pyjamas|Sweater|Jacket|Comfortable shoes'**
  String get checklistItemsClothes;

  /// No description provided for @checklistItemsBathroom.
  ///
  /// In en, this message translates to:
  /// **'Toothbrush and toothpaste|Deodorant|Shampoo|Sunscreen|Comb'**
  String get checklistItemsBathroom;

  /// No description provided for @checklistItemsAccessories.
  ///
  /// In en, this message translates to:
  /// **'Sunglasses|Water bottle|Day backpack|Umbrella'**
  String get checklistItemsAccessories;

  /// No description provided for @checklistItemsDocuments.
  ///
  /// In en, this message translates to:
  /// **'ID card or passport|Driving licence|Health card|Tickets|Bookings|Travel insurance|Payment cards|Cash'**
  String get checklistItemsDocuments;

  /// No description provided for @checklistItemsBeforeTrip.
  ///
  /// In en, this message translates to:
  /// **'Online check-in|Check document expiry dates|Tell the bank|Download maps|Change some currency|Pack the suitcase|Save the bookings'**
  String get checklistItemsBeforeTrip;

  /// No description provided for @checklistItemsLeavingHome.
  ///
  /// In en, this message translates to:
  /// **'Turn off the gas|Switch off the lights|Unplug devices|Close the windows|Take out the rubbish|Water the plants|Lock the door'**
  String get checklistItemsLeavingHome;

  /// No description provided for @checklistItemsMedicines.
  ///
  /// In en, this message translates to:
  /// **'Usual medicines|Painkiller|Plasters|Disinfectant|Antihistamine'**
  String get checklistItemsMedicines;

  /// No description provided for @checklistItemsHygiene.
  ///
  /// In en, this message translates to:
  /// **'Hand sanitiser|Tissues|Sanitary pads'**
  String get checklistItemsHygiene;

  /// No description provided for @checklistItemsElectronics.
  ///
  /// In en, this message translates to:
  /// **'Phone charger|Power bank|Plug adapter|Headphones|Cables|Camera'**
  String get checklistItemsElectronics;

  /// No description provided for @checklistEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit checklist'**
  String get checklistEditTitle;

  /// No description provided for @checklistTemplate.
  ///
  /// In en, this message translates to:
  /// **'Start from a template'**
  String get checklistTemplate;

  /// No description provided for @checklistBlockList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get checklistBlockList;

  /// No description provided for @checklistPrivate.
  ///
  /// In en, this message translates to:
  /// **'Personal list'**
  String get checklistPrivate;

  /// No description provided for @checklistPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Only its author can see it.'**
  String get checklistPrivateHint;

  /// No description provided for @checklistPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get checklistPersonal;

  /// No description provided for @checklistDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String checklistDoneOf(int done, int total);

  /// No description provided for @checklistProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} · {percent}%'**
  String checklistProgress(int done, int total, int percent);

  /// No description provided for @checklistImport.
  ///
  /// In en, this message translates to:
  /// **'Import the packing list'**
  String get checklistImport;

  /// No description provided for @checklistImportText.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shopping still has 1 item of the old packing list: import it here as a checklist.} other{Shopping still has {count} items of the old packing list: import them here as a checklist.}}'**
  String checklistImportText(int count);

  /// No description provided for @checklistImported.
  ///
  /// In en, this message translates to:
  /// **'Packing list imported into the checklists.'**
  String get checklistImported;

  /// No description provided for @checklistQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'no.'**
  String get checklistQuantityHint;

  /// No description provided for @checklistDeleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete the item?'**
  String get checklistDeleteEntry;

  /// No description provided for @checklistEntry.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get checklistEntry;

  /// No description provided for @checklistAssignee.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get checklistAssignee;

  /// No description provided for @checklistAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get checklistAddEntry;

  /// No description provided for @checklistAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add a category'**
  String get checklistAddCategory;

  /// No description provided for @checklistTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get checklistTodo;

  /// No description provided for @checklistDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get checklistDone;

  /// No description provided for @checklistReset.
  ///
  /// In en, this message translates to:
  /// **'Clear the ticks'**
  String get checklistReset;

  /// No description provided for @checklistDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate the list'**
  String get checklistDuplicate;

  /// No description provided for @checklistDuplicated.
  ///
  /// In en, this message translates to:
  /// **'List duplicated.'**
  String get checklistDuplicated;

  /// No description provided for @checklistCopyOf.
  ///
  /// In en, this message translates to:
  /// **'{title} (copy)'**
  String checklistCopyOf(String title);

  /// No description provided for @checklistPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get checklistPrint;

  /// No description provided for @checklistExport.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get checklistExport;

  /// No description provided for @checklistCsvColumns.
  ///
  /// In en, this message translates to:
  /// **'Category|Item|Quantity|Person|Done'**
  String get checklistCsvColumns;

  /// No description provided for @transportBlockExtras.
  ///
  /// In en, this message translates to:
  /// **'Seats, check-in and rental'**
  String get transportBlockExtras;

  /// No description provided for @transportSeatLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter or coach'**
  String get transportSeatLetter;

  /// No description provided for @transportSeatNumber.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get transportSeatNumber;

  /// No description provided for @transportCheckInHours.
  ///
  /// In en, this message translates to:
  /// **'Online check-in: hours before departure'**
  String get transportCheckInHours;

  /// No description provided for @transportCheckInHoursFlight.
  ///
  /// In en, this message translates to:
  /// **'Online check-in: hours before (empty = 24)'**
  String get transportCheckInHoursFlight;

  /// No description provided for @transportCheckInLink.
  ///
  /// In en, this message translates to:
  /// **'Check-in link'**
  String get transportCheckInLink;

  /// No description provided for @transportAirportMinutes.
  ///
  /// In en, this message translates to:
  /// **'Arrive early: minutes'**
  String get transportAirportMinutes;

  /// No description provided for @transportAirportMinutesFlight.
  ///
  /// In en, this message translates to:
  /// **'Be at the airport: minutes before (empty = 120)'**
  String get transportAirportMinutesFlight;

  /// No description provided for @transportFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel (e.g. full to full)'**
  String get transportFuel;

  /// No description provided for @transportDeductible.
  ///
  /// In en, this message translates to:
  /// **'Deductible'**
  String get transportDeductible;

  /// No description provided for @transportLayover.
  ///
  /// In en, this message translates to:
  /// **'Layover of {duration}'**
  String transportLayover(String duration);

  /// No description provided for @transportLayoverAt.
  ///
  /// In en, this message translates to:
  /// **'Layover of {duration} in {place}'**
  String transportLayoverAt(String duration, String place);

  /// No description provided for @transportCheckInOpensIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in opens in {duration}'**
  String transportCheckInOpensIn(String duration);

  /// No description provided for @transportCheckInOpen.
  ///
  /// In en, this message translates to:
  /// **'Online check-in open'**
  String get transportCheckInOpen;

  /// No description provided for @transportAirportBy.
  ///
  /// In en, this message translates to:
  /// **'Be at the airport by {time}'**
  String transportAirportBy(String time);

  /// No description provided for @transportFuelValue.
  ///
  /// In en, this message translates to:
  /// **'Fuel: {value}'**
  String transportFuelValue(String value);

  /// No description provided for @transportDeductibleValue.
  ///
  /// In en, this message translates to:
  /// **'Deductible: {value}'**
  String transportDeductibleValue(String value);

  /// No description provided for @transportFlightStatus.
  ///
  /// In en, this message translates to:
  /// **'Flight status'**
  String get transportFlightStatus;

  /// No description provided for @transportErrExtras.
  ///
  /// In en, this message translates to:
  /// **'Check seats, check-in hours (0-168) and minutes (0-600).'**
  String get transportErrExtras;

  /// No description provided for @reservationBlockTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get reservationBlockTickets;

  /// No description provided for @reservationBookBy.
  ///
  /// In en, this message translates to:
  /// **'Book by'**
  String get reservationBookBy;

  /// No description provided for @reservationHolder.
  ///
  /// In en, this message translates to:
  /// **'Booking holder'**
  String get reservationHolder;

  /// No description provided for @reservationTickets.
  ///
  /// In en, this message translates to:
  /// **'Number of tickets'**
  String get reservationTickets;

  /// No description provided for @reservationTicketCode.
  ///
  /// In en, this message translates to:
  /// **'Ticket code'**
  String get reservationTicketCode;

  /// No description provided for @reservationTicketCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Text or code of the ticket: it is shown as a QR code. No file is uploaded.'**
  String get reservationTicketCodeHint;

  /// No description provided for @reservationShowTicket.
  ///
  /// In en, this message translates to:
  /// **'Show ticket'**
  String get reservationShowTicket;

  /// No description provided for @reservationBookByValue.
  ///
  /// In en, this message translates to:
  /// **'Book by {date}'**
  String reservationBookByValue(String date);

  /// No description provided for @reservationHolderValue.
  ///
  /// In en, this message translates to:
  /// **'Holder: {name}'**
  String reservationHolderValue(String name);

  /// No description provided for @reservationTicketsValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ticket} other{{count} tickets}}'**
  String reservationTicketsValue(int count);

  /// No description provided for @reservationErrTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets: enter a number from 1 to 99.'**
  String get reservationErrTickets;

  /// No description provided for @staysExpenseCreate.
  ///
  /// In en, this message translates to:
  /// **'Create expense'**
  String get staysExpenseCreate;

  /// No description provided for @staysExpenseLinkExisting.
  ///
  /// In en, this message translates to:
  /// **'Link an existing expense'**
  String get staysExpenseLinkExisting;

  /// No description provided for @staysExpenseLinkedTitle.
  ///
  /// In en, this message translates to:
  /// **'Linked expense: {title}'**
  String staysExpenseLinkedTitle(String title);

  /// No description provided for @staysExpenseView.
  ///
  /// In en, this message translates to:
  /// **'View expense'**
  String get staysExpenseView;

  /// No description provided for @staysExpenseNotVisible.
  ///
  /// In en, this message translates to:
  /// **'Linked expense (not visible to you or deleted).'**
  String get staysExpenseNotVisible;

  /// No description provided for @staysExpenseLinked.
  ///
  /// In en, this message translates to:
  /// **'Expense linked to the accommodation.'**
  String get staysExpenseLinked;

  /// No description provided for @staysExpenseLinkError.
  ///
  /// In en, this message translates to:
  /// **'The expense was created but not linked to the accommodation. Use \"Link an existing expense\" to link it.'**
  String get staysExpenseLinkError;

  /// No description provided for @staysExpensePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a shared expense'**
  String get staysExpensePickTitle;

  /// No description provided for @staysExpensePickEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shared expense available.'**
  String get staysExpensePickEmpty;

  /// No description provided for @staysExpenseLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the expenses.'**
  String get staysExpenseLoadError;
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
