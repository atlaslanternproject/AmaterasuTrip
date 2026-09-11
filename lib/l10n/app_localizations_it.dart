// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get authWelcomeBack => 'Bentornato';

  @override
  String get authEmailOrUsernameHint => 'Immettere Email o Username';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authForgotPassword => 'Recupera password';

  @override
  String get authInsertEmail => 'Inserisci Email';

  @override
  String get authCancel => 'Annulla';

  @override
  String get authPasswordResetEmailSent => '📜 Abbiamo inviato una pergamena per recuperare la password. Controlla la tua casella email. Controlla anche la cartella Spam o Posta indesiderata se non la trovi!';

  @override
  String get authContinue => 'Continua';

  @override
  String get authForgotPasswordQuestion => 'Password dimenticata?';

  @override
  String get authStaySignedIn => 'Rimani connesso';

  @override
  String get authSigningIn => 'Accesso...';

  @override
  String get authSignIn => 'Accedi';

  @override
  String get authNoAccountRegister => 'Non hai un account? Registrati';

  @override
  String get authLoginErrorUserNotFound => 'Nessun viaggiatore trovato con queste credenziali.';

  @override
  String get authLoginErrorWrongPassword => 'La parola segreta non apre la porta del veivolo.';

  @override
  String get authLoginErrorInvalidEmail => 'Questa email non sembra valida.';

  @override
  String get authLoginErrorGeneric => 'Accesso negato. Riprova.';

  @override
  String get authCreateAccount => 'Crea il tuo account';

  @override
  String get authUsernameHint => 'Username';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authConfirmPasswordHint => 'Conferma password';

  @override
  String get authRegister => 'Registrati';

  @override
  String get authRegisterFillFields => '⚠️ Compila tutti i campi richiesti.';

  @override
  String get authRegisterPasswordsMismatch => '⚠️ Le due parole segrete non coincidono.';

  @override
  String get authRegisterEmailAlreadyInUse => '⚠️ Un viaggiatore è già registrato con questa pergamena.';

  @override
  String get authRegisterWeakPassword => '⚠️ La parola segreta è troppo debole.';

  @override
  String get authRegisterInvalidEmail => '⚠️ Il corvo non riesce a raggiungere questo indirizzo.';

  @override
  String get authRegisterGenericError => '⚠️ Impossibile completare la registrazione.';

  @override
  String get authAlreadyHaveAccountSignIn => 'Hai già un account? Accedi';

  @override
  String get authGoogleSignInError => 'Impossibile completare l\'accesso con Google.';

  @override
  String get authGoogleSigningIn => 'Accesso con Google...';

  @override
  String get authRetry => 'Riprova';

  @override
  String get authVerifyEmailNotVerified => '⚠️ La pergamena non risulta ancora firmata. Controlla la tua casella email. Controlla anche la cartella Spam o Posta indesiderata se non la trovi!';

  @override
  String get authVerifyEmailSent => '📜 Nuova pergamena inviata. Controlla la tua casella email. Controlla anche la cartella Spam o Posta indesiderata se non la trovi!';

  @override
  String get authVerifyEmailTitle => 'Verifica il tuo indirizzo email';

  @override
  String get authVerifyEmailDescription => 'Abbiamo inviato una email di verifica al tuo indirizzo.\n\nAprila e conferma il tuo account prima di entrare nella Taverna.\n\nSe non la trovi, controlla anche la cartella Spam o Posta indesiderata!';

  @override
  String get authVerifyEmailConfirmed => 'Ho verificato';

  @override
  String get authVerifyEmailResend => 'Reinvia email';

  @override
  String get createUsernameTitle => 'Crea Username';

  @override
  String get createUsernameSubtitle => 'Scegli il tuo nome viaggiatore';

  @override
  String get createUsernameContinue => 'Continua';

  @override
  String get createUsernameRequired => 'Inserisci un username';

  @override
  String get createUsernameGoogleUserNotFound => 'Utente Google non trovato. Riprova';

  @override
  String get createUsernameAlreadyTaken => 'Questo username è già in uso. Scegline un altro.';

  @override
  String get commonOr => 'oppure';

  @override
  String get commonDiscordSignIn => 'Accedi con Discord';

  @override
  String get commonGoogleSignIn => 'Accedi con Google';

  @override
  String get commonPassword => 'Password';

  @override
  String get homeLoginCompleted => 'Login completato!';

  @override
  String get homeGoogleUser => 'Utente Google';

  @override
  String get homeNoUid => 'No UID';

  @override
  String get homeName => 'Nome:';

  @override
  String get homeNoName => 'Nessun nome';

  @override
  String get homeEmail => 'Email:';

  @override
  String get homeNoEmail => 'Nessuna email';

  @override
  String get homeUid => 'UID:';

  @override
  String get homeLogoutTest => 'Logout test';
}
