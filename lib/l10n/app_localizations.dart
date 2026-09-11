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
