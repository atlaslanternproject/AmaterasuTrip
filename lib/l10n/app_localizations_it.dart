// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get settingsLanguage => 'Lingua';

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

  @override
  String get settingsProfile => 'Profilo';

  @override
  String get settingsNotifications => 'Notifiche';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsDataSync => 'Dati online/offline';

  @override
  String get settingsInformation => 'Informazioni';

  @override
  String get settingsPlaceholder => 'Questa sezione sarà disponibile prossimamente.';

  @override
  String settingsLanguageName(String languageCode) {
    String _temp0 = intl.Intl.selectLogic(
      languageCode,
      {
        'it': 'Italiano',
        'en': 'Inglese',
        'other': 'Lingua',
      },
    );
    return '$_temp0';
  }

  @override
  String get bottomBarHome => 'Home';

  @override
  String get bottomBarTrips => 'Viaggi';

  @override
  String get bottomBarSettings => 'Impostazioni';

  @override
  String get appName => 'Amaterasu Trip';

  @override
  String get loginCompleted => 'Login completato!';

  @override
  String get name => 'Nome:';

  @override
  String get noName => 'Nessun nome';

  @override
  String get email => 'Email:';

  @override
  String get noEmail => 'Nessuna email';

  @override
  String get uid => 'UID:';

  @override
  String get logoutTest => 'Logout test';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsAccountSubtitle => 'Gestisci il tuo account, password e dati';

  @override
  String get settingsLanguageSubtitle => 'Scegli la lingua dell\'app';

  @override
  String get settingsProfileSubtitle => 'Personalizza il tuo profilo';

  @override
  String get settingsNotificationsSubtitle => 'Gestisci le tue notifiche';

  @override
  String get settingsPrivacySubtitle => 'Controlla la tua privacy';

  @override
  String get settingsDataSyncSubtitle => 'Gestisci i dati e la sincronizzazione';

  @override
  String get settingsInformationSubtitle => 'Versione app, termini e altro';

  @override
  String get confirm => 'Conferma';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountEmailSubtitle => 'Gestisci il tuo indirizzo email';

  @override
  String get accountEmailCurrent => 'Indirizzo email';

  @override
  String get accountEmailVerified => 'Email verificata';

  @override
  String get accountEmailNotVerified => 'Email non verificata';

  @override
  String get accountEmailVerify => 'Verifica email';

  @override
  String get accountEmailResendVerification => 'Reinvia email di verifica';

  @override
  String get accountEmailChange => 'Modifica email';

  @override
  String get accountEmailNew => 'Nuovo indirizzo email';

  @override
  String get accountEmailConfirmChange => 'Conferma modifica email';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountPasswordSubtitle => 'Gestisci la tua password';

  @override
  String get accountPasswordChange => 'Cambia password';

  @override
  String get accountPasswordRecover => 'Recupera password';

  @override
  String get accountLinkedAccounts => 'Accessi collegati';

  @override
  String get accountLinkedAccountsSubtitle => 'Gestisci gli account collegati';

  @override
  String get accountLinkedGoogle => 'Google';

  @override
  String get accountLinkedOtherProviders => 'Altri provider';

  @override
  String get accountLinkedConnected => 'Collegato';

  @override
  String get accountLinkedNotConnected => 'Non collegato';

  @override
  String get accountSession => 'Sessione';

  @override
  String get accountSessionSubtitle => 'Gestisci gli accessi al tuo account';

  @override
  String get accountSessionActive => 'Sessioni attive';

  @override
  String get accountSessionSignOutAll => 'Disconnetti da tutti i dispositivi';

  @override
  String get accountDelete => 'Elimina account';

  @override
  String get accountDeleteDescription => 'L\'eliminazione dell\'account è definitiva e comporta la perdita dei dati associati.';

  @override
  String get accountDeleteConfirm => 'Conferma eliminazione account';

  @override
  String get accountLogout => 'Esci';

  @override
  String get accountEmailCurrentPassword => 'Password attuale';

  @override
  String get accountEmailVerificationSent => 'Email di verifica inviata. Controlla anche la cartella Spam o Posta indesiderata.';

  @override
  String get accountEmailChangeVerificationSent => 'Abbiamo inviato un\'email di verifica al nuovo indirizzo. Controlla anche la cartella Spam o Posta indesiderata.';

  @override
  String get accountEmailVerifiedDescription => 'Il tuo indirizzo email è verificato.';

  @override
  String get accountEmailChangeDescription => 'Modifica l\'indirizzo email associato al tuo account.';

  @override
  String get accountEmailUnavailable => 'Indirizzo email non disponibile';

  @override
  String get accountEmailErrorInvalidPassword => 'La password attuale non è corretta.';

  @override
  String get accountEmailErrorAlreadyInUse => 'Questo indirizzo email è già associato a un account.';

  @override
  String get accountEmailErrorInvalidEmail => 'Inserisci un indirizzo email valido.';

  @override
  String get accountEmailErrorRecentLogin => 'Per motivi di sicurezza, effettua nuovamente l\'accesso e riprova.';

  @override
  String get accountEmailErrorTooManyRequests => 'Sono state effettuate troppe richieste. Riprova più tardi.';

  @override
  String get accountEmailErrorUserNotFound => 'Non è stato possibile trovare l\'account.';

  @override
  String get accountEmailErrorGeneric => 'Non è stato possibile completare l\'operazione.';

  @override
  String get cancel => 'Annulla';

  @override
  String get accountEmailChangeLogoutWarning => 'Dopo aver modificato l\'indirizzo email, verrai disconnesso per motivi di sicurezza. Dovrai effettuare nuovamente l\'accesso con il nuovo indirizzo email.';

  @override
  String get accountEmailChangeContinue => 'Continua';

  @override
  String get accountLogoutTitle => 'Uscire da Amaterasu Trip?';

  @override
  String get accountLogoutDescription => 'La sessione verrà chiusa su questo dispositivo.';

  @override
  String get accountLogoutStay => 'Resta';

  @override
  String get accountLogoutConfirm => 'Esci';

  @override
  String get accountPasswordChangeDescription => 'Modifica la password associata al tuo account';

  @override
  String get accountPasswordRecoverSubtitle => 'Invia un\'email per reimpostare la password';

  @override
  String get accountPasswordCurrent => 'Password attuale';

  @override
  String get accountPasswordNew => 'Nuova password';

  @override
  String get accountPasswordConfirmNew => 'Conferma nuova password';

  @override
  String get accountPasswordConfirmChange => 'Cambia password';

  @override
  String get accountPasswordChanging => 'Modifica...';

  @override
  String get accountPasswordChanged => 'Password modificata correttamente.';

  @override
  String get accountPasswordSendReset => 'Invia email';

  @override
  String accountPasswordRecoverDescription(String email) {
    return 'Invieremo un\'email per reimpostare la password a $email.';
  }

  @override
  String get accountPasswordResetSent => 'Email per il recupero password inviata. Controlla la tua casella email e anche la cartella Spam o Posta indesiderata.';

  @override
  String get accountPasswordManagedByProvider => 'Questo account non utilizza una password Amaterasu Trip. La password è gestita dal provider con cui hai effettuato l\'accesso.';

  @override
  String get accountPasswordErrorEmptyFields => 'Compila tutti i campi.';

  @override
  String get accountPasswordErrorWeak => 'La nuova password deve contenere almeno 6 caratteri.';

  @override
  String get accountPasswordErrorMismatch => 'Le nuove password non coincidono.';

  @override
  String get accountPasswordErrorSamePassword => 'La nuova password deve essere diversa da quella attuale.';

  @override
  String get accountPasswordErrorWrongCurrent => 'La password attuale non è corretta.';

  @override
  String get accountPasswordErrorRecentLogin => 'Per motivi di sicurezza, effettua nuovamente l\'accesso e riprova.';

  @override
  String get accountPasswordErrorTooManyRequests => 'Sono state effettuate troppe richieste. Riprova più tardi.';

  @override
  String get accountPasswordErrorUserNotFound => 'Non è stato possibile trovare l\'account.';

  @override
  String get accountPasswordErrorNoEmail => 'Non è disponibile un indirizzo email per questo account.';

  @override
  String get accountPasswordErrorGeneric => 'Non è stato possibile completare l\'operazione.';

  @override
  String get accountDeleteIntro => 'Elimina definitivamente il tuo account Amaterasu.';

  @override
  String get accountDeleteWarning => 'Questa operazione è irreversibile. I dati associati all\'account verranno rimossi e non potranno essere recuperati.';

  @override
  String get accountDeleteButton => 'Elimina account';

  @override
  String get accountDeleteDialogTitle => 'Elimina account';

  @override
  String get accountDeleteDialogIntro => 'Stai per eliminare definitivamente il tuo account Amaterasu.';

  @override
  String get accountDeleteDialogData => 'Verranno eliminati i dati personali associati al tuo account e verrai rimosso dai viaggi e dai gruppi a cui appartieni.';

  @override
  String get accountDeleteDialogIrreversible => 'Questa operazione è irreversibile e i dati eliminati non potranno essere recuperati.';

  @override
  String get accountDeleteDialogConfirmation => 'Ho compreso che l\'eliminazione è definitiva.';

  @override
  String get accountDeleteLoading => 'Eliminazione account in corso…';

  @override
  String get accountDeleteCancel => 'Annulla';

  @override
  String get accountDeleteConfirmButton => 'Elimina definitivamente';

  @override
  String get accountDeleteReauthenticationTitle => 'Conferma la tua identità';

  @override
  String get accountDeleteReauthenticationPasswordDescription => 'Per continuare con l\'eliminazione dell\'account, inserisci la password attuale.';

  @override
  String get accountDeleteReauthenticationPasswordLabel => 'Password attuale';

  @override
  String get accountDeleteReauthenticationConfirm => 'Conferma';

  @override
  String get accountDeleteReauthenticationWrongPassword => 'La password inserita non è corretta.';

  @override
  String get accountDeleteReauthenticationCancelled => 'Verifica dell\'identità annullata.';

  @override
  String get accountDeleteReauthenticationGoogleMismatch => 'Devi utilizzare lo stesso account Google collegato ad Amaterasu.';

  @override
  String get accountDeleteReauthenticationFailed => 'Non è stato possibile verificare la tua identità. Riprova.';

  @override
  String get accountDeleteReauthenticationUnsupported => 'Questo metodo di accesso non è ancora supportato per la verifica dell\'identità.';

  @override
  String get accountDeleteError => 'Non è stato possibile completare l\'eliminazione dell\'account. Nessun ulteriore dato verrà eliminato. Riprova.';
}
