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
  String get authPasswordResetEmailSent => 'ðŸ“œ Abbiamo inviato una pergamena per recuperare la password. Controlla la tua casella email. Controlla anche la cartella Spam o Posta indesiderata se non la trovi!';

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
  String get authRegisterFillFields => 'âš ï¸ Compila tutti i campi richiesti.';

  @override
  String get authRegisterPasswordsMismatch => 'âš ï¸ Le due parole segrete non coincidono.';

  @override
  String get authRegisterEmailAlreadyInUse => 'âš ï¸ Un viaggiatore Ã¨ giÃ  registrato con questa pergamena.';

  @override
  String get authRegisterWeakPassword => 'âš ï¸ La parola segreta Ã¨ troppo debole.';

  @override
  String get authRegisterInvalidEmail => 'âš ï¸ Il corvo non riesce a raggiungere questo indirizzo.';

  @override
  String get authRegisterGenericError => 'âš ï¸ Impossibile completare la registrazione.';

  @override
  String get authAlreadyHaveAccountSignIn => 'Hai giÃ  un account? Accedi';

  @override
  String get authGoogleSignInError => 'Impossibile completare l\'accesso con Google.';

  @override
  String get authGoogleSigningIn => 'Accesso con Google...';

  @override
  String get authRetry => 'Riprova';

  @override
  String get authVerifyEmailNotVerified => 'âš ï¸ La pergamena non risulta ancora firmata. Controlla la tua casella email. Controlla anche la cartella Spam o Posta indesiderata se non la trovi!';

  @override
  String get authVerifyEmailSent => 'ðŸ“œ Nuova pergamena inviata. Controlla la tua casella email. Controlla anche la cartella Spam o Posta indesiderata se non la trovi!';

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
  String get createUsernameAlreadyTaken => 'Questo username Ã¨ giÃ  in uso. Scegline un altro.';

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
  String get settingsPlaceholder => 'Questa sezione sarÃ  disponibile prossimamente.';

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
  String get accountDeleteDescription => 'L\'eliminazione dell\'account Ã¨ definitiva e comporta la perdita dei dati associati.';

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
  String get accountEmailVerifiedDescription => 'Il tuo indirizzo email Ã¨ verificato.';

  @override
  String get accountEmailChangeDescription => 'Modifica l\'indirizzo email associato al tuo account.';

  @override
  String get accountEmailUnavailable => 'Indirizzo email non disponibile';

  @override
  String get accountEmailErrorInvalidPassword => 'La password attuale non Ã¨ corretta.';

  @override
  String get accountEmailErrorAlreadyInUse => 'Questo indirizzo email Ã¨ giÃ  associato a un account.';

  @override
  String get accountEmailErrorInvalidEmail => 'Inserisci un indirizzo email valido.';

  @override
  String get accountEmailErrorRecentLogin => 'Per motivi di sicurezza, effettua nuovamente l\'accesso e riprova.';

  @override
  String get accountEmailErrorTooManyRequests => 'Sono state effettuate troppe richieste. Riprova piÃ¹ tardi.';

  @override
  String get accountEmailErrorUserNotFound => 'Non Ã¨ stato possibile trovare l\'account.';

  @override
  String get accountEmailErrorGeneric => 'Non Ã¨ stato possibile completare l\'operazione.';

  @override
  String get cancel => 'Annulla';

  @override
  String get accountEmailChangeLogoutWarning => 'Dopo aver modificato l\'indirizzo email, verrai disconnesso per motivi di sicurezza. Dovrai effettuare nuovamente l\'accesso con il nuovo indirizzo email.';

  @override
  String get accountEmailChangeContinue => 'Continua';

  @override
  String get accountLogoutTitle => 'Uscire da Amaterasu Trip?';

  @override
  String get accountLogoutDescription => 'La sessione verrÃ  chiusa su questo dispositivo.';

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
  String get accountPasswordManagedByProvider => 'Questo account non utilizza una password Amaterasu Trip. La password Ã¨ gestita dal provider con cui hai effettuato l\'accesso.';

  @override
  String get accountPasswordErrorEmptyFields => 'Compila tutti i campi.';

  @override
  String get accountPasswordErrorWeak => 'La nuova password deve contenere almeno 6 caratteri.';

  @override
  String get accountPasswordErrorMismatch => 'Le nuove password non coincidono.';

  @override
  String get accountPasswordErrorSamePassword => 'La nuova password deve essere diversa da quella attuale.';

  @override
  String get accountPasswordErrorWrongCurrent => 'La password attuale non Ã¨ corretta.';

  @override
  String get accountPasswordErrorRecentLogin => 'Per motivi di sicurezza, effettua nuovamente l\'accesso e riprova.';

  @override
  String get accountPasswordErrorTooManyRequests => 'Sono state effettuate troppe richieste. Riprova piÃ¹ tardi.';

  @override
  String get accountPasswordErrorUserNotFound => 'Non Ã¨ stato possibile trovare l\'account.';

  @override
  String get accountPasswordErrorNoEmail => 'Non Ã¨ disponibile un indirizzo email per questo account.';

  @override
  String get accountPasswordErrorGeneric => 'Non Ã¨ stato possibile completare l\'operazione.';

  @override
  String get accountDeleteIntro => 'Elimina definitivamente il tuo account Amaterasu.';

  @override
  String get accountDeleteWarning => 'Questa operazione Ã¨ irreversibile. I dati associati all\'account verranno rimossi e non potranno essere recuperati.';

  @override
  String get accountDeleteButton => 'Elimina account';

  @override
  String get accountDeleteDialogTitle => 'Elimina account';

  @override
  String get accountDeleteDialogIntro => 'Stai per eliminare definitivamente il tuo account Amaterasu.';

  @override
  String get accountDeleteDialogData => 'Verranno eliminati i dati personali associati al tuo account e verrai rimosso dai viaggi e dai gruppi a cui appartieni.';

  @override
  String get accountDeleteDialogIrreversible => 'Questa operazione Ã¨ irreversibile e i dati eliminati non potranno essere recuperati.';

  @override
  String get accountDeleteDialogConfirmation => 'Ho compreso che l\'eliminazione Ã¨ definitiva.';

  @override
  String get accountDeleteLoading => 'Eliminazione account in corsoâ€¦';

  @override
  String get accountDeleteCancel => 'Annulla';

  @override
  String get accountDeleteConfirmButton => 'Elimina definitivamente';

  @override
  String get accountDeleteReauthenticationTitle => 'Conferma la tua identitÃ ';

  @override
  String get accountDeleteReauthenticationPasswordDescription => 'Per continuare con l\'eliminazione dell\'account, inserisci la password attuale.';

  @override
  String get accountDeleteReauthenticationPasswordLabel => 'Password attuale';

  @override
  String get accountDeleteReauthenticationConfirm => 'Conferma';

  @override
  String get accountDeleteReauthenticationWrongPassword => 'La password inserita non Ã¨ corretta.';

  @override
  String get accountDeleteReauthenticationCancelled => 'Verifica dell\'identitÃ  annullata.';

  @override
  String get accountDeleteReauthenticationGoogleMismatch => 'Devi utilizzare lo stesso account Google collegato ad Amaterasu.';

  @override
  String get accountDeleteReauthenticationFailed => 'Non Ã¨ stato possibile verificare la tua identitÃ . Riprova.';

  @override
  String get accountDeleteReauthenticationUnsupported => 'Questo metodo di accesso non Ã¨ ancora supportato per la verifica dell\'identitÃ .';

  @override
  String get accountDeleteError => 'Non Ã¨ stato possibile completare l\'eliminazione dell\'account. Nessun ulteriore dato verrÃ  eliminato. Riprova.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyIntro => 'Consulta come Amaterasu gestisce i tuoi dati, i permessi dell\'app e le tue scelte relative alla privacy.';

  @override
  String get privacyDataTitle => 'Privacy Policy';

  @override
  String get privacyDataSubtitle => 'Scopri quali dati utilizza Amaterasu e come vengono gestiti.';

  @override
  String get privacyPermissionsTitle => 'Permessi';

  @override
  String get privacyPermissionsSubtitle => 'Informazioni sui permessi che l\'app puÃ² richiedere.';

  @override
  String get privacyConsentTitle => 'Consensi';

  @override
  String get privacyConsentSubtitle => 'Consulta come vengono gestiti i consensi e le funzionalitÃ  opzionali.';

  @override
  String get privacyExportTitle => 'Esportazione dei dati';

  @override
  String get privacyExportSubtitle => 'Informazioni sulla possibilitÃ  di ottenere una copia dei tuoi dati.';

  @override
  String get privacyPolicyOverviewTitle => 'Informazioni generali';

  @override
  String get privacyPolicyOverviewBody => 'Amaterasu Trip Ã¨ un\'applicazione dedicata all\'organizzazione e alla gestione dei viaggi. La presente informativa descrive quali dati possono essere trattati durante l\'utilizzo dell\'app e per quali finalitÃ .';

  @override
  String get privacyPolicyCollectedDataTitle => 'Dati trattati';

  @override
  String get privacyPolicyCollectedDataBody => 'Amaterasu puÃ² trattare dati necessari alla creazione e gestione dell\'account, come indirizzo email, identificativo utente, username e metodo di autenticazione. Alcune preferenze dell\'app, come la lingua e l\'opzione di accesso memorizzato, possono essere salvate localmente sul dispositivo.';

  @override
  String get privacyPolicyPurposeTitle => 'FinalitÃ  del trattamento';

  @override
  String get privacyPolicyPurposeBody => 'I dati vengono utilizzati esclusivamente per fornire le funzionalitÃ  dell\'app, autenticare l\'utente, mantenere il profilo Amaterasu, permettere la gestione dell\'account e garantire il corretto funzionamento dei servizi associati.';

  @override
  String get privacyPolicyFirebaseTitle => 'Firebase';

  @override
  String get privacyPolicyFirebaseBody => 'Amaterasu utilizza servizi Firebase di Google per funzioni come autenticazione e archiviazione dei dati dell\'account. I dati necessari al funzionamento di tali servizi possono essere trattati attraverso l\'infrastruttura Firebase secondo le condizioni e le politiche applicabili di Google.';

  @override
  String get privacyPolicyGoogleTitle => 'Accesso con Google';

  @override
  String get privacyPolicyGoogleBody => 'Se scegli di utilizzare Google per accedere ad Amaterasu, Google fornisce all\'app le informazioni necessarie per autenticare il tuo account. Amaterasu non riceve nÃ© conserva la password del tuo account Google.';

  @override
  String get privacyPolicyStorageTitle => 'Conservazione dei dati';

  @override
  String get privacyPolicyStorageBody => 'I dati associati all\'account vengono conservati finchÃ© l\'account Amaterasu rimane attivo o finchÃ© sono necessari per fornire i servizi richiesti. Alcune preferenze possono essere conservate localmente sul dispositivo.';

  @override
  String get privacyPolicyDeletionTitle => 'Eliminazione dell\'account';

  @override
  String get privacyPolicyDeletionBody => 'Puoi eliminare definitivamente il tuo account dalle impostazioni di Amaterasu. L\'eliminazione rimuove l\'account Firebase Authentication e i dati dell\'account attualmente associati al profilo Amaterasu. Quando verranno introdotte nuove funzionalitÃ  e nuove categorie di dati, questa informativa verrÃ  aggiornata di conseguenza.';

  @override
  String get privacyPolicySecurityTitle => 'Sicurezza';

  @override
  String get privacyPolicySecurityBody => 'Amaterasu adotta misure tecniche appropriate per limitare l\'accesso non autorizzato ai dati e utilizza i sistemi di autenticazione e sicurezza messi a disposizione dai servizi Firebase utilizzati dall\'app.';

  @override
  String get privacyPolicyChangesTitle => 'Modifiche alla Privacy Policy';

  @override
  String get privacyPolicyChangesBody => 'La presente informativa potrÃ  essere aggiornata quando Amaterasu introdurrÃ  nuove funzionalitÃ , servizi o categorie di dati. La versione aggiornata sarÃ  resa disponibile all\'interno dell\'app e attraverso la pagina pubblica della Privacy Policy.';

  @override
  String get privacyPolicyContactTitle => 'Contatti';

  @override
  String get privacyPolicyContactBody => 'Per richieste relative alla privacy o al trattamento dei dati puoi contattare il team Amaterasu attraverso i canali di supporto ufficiali indicati nell\'app.';

  @override
  String get privacyPermissionsIntro => 'Amaterasu richiede solamente i permessi necessari alle funzionalitÃ  che utilizzi. Alcuni permessi potranno essere introdotti quando saranno disponibili nuove funzioni.';

  @override
  String get privacyPermissionsNotificationsTitle => 'Notifiche';

  @override
  String get privacyPermissionsNotificationsBody => 'Amaterasu potrÃ  richiedere l\'autorizzazione alle notifiche per ricordarti prenotazioni, scadenze e informazioni relative ai tuoi viaggi. Il permesso potrÃ  essere revocato dalle impostazioni del dispositivo.';

  @override
  String get privacyPermissionsMediaTitle => 'Foto e contenuti multimediali';

  @override
  String get privacyPermissionsMediaBody => 'Quando saranno disponibili le funzionalitÃ  dedicate a foto, video e documenti di viaggio, Amaterasu potrÃ  richiedere l\'accesso ai contenuti selezionati dall\'utente. L\'app non accederÃ  ai contenuti senza un\'azione dell\'utente.';

  @override
  String get privacyPermissionsLocationTitle => 'Posizione';

  @override
  String get privacyPermissionsLocationBody => 'Amaterasu non utilizza attualmente la posizione del dispositivo. Qualora una futura funzione richiedesse l\'accesso alla posizione, il permesso verrÃ  richiesto esplicitamente prima dell\'utilizzo.';

  @override
  String get privacyConsentIntro => 'Le funzionalitÃ  necessarie al funzionamento dell\'account non richiedono consensi di marketing. Eventuali funzionalitÃ  opzionali che richiederanno un consenso specifico saranno presentate separatamente.';

  @override
  String get privacyConsentRequiredTitle => 'Servizi necessari';

  @override
  String get privacyConsentRequiredBody => 'L\'autenticazione e la gestione dell\'account utilizzano i dati necessari per fornire il servizio richiesto dall\'utente.';

  @override
  String get privacyConsentOptionalTitle => 'Consensi opzionali';

  @override
  String get privacyConsentOptionalBody => 'Amaterasu non utilizza attualmente consensi per pubblicitÃ  personalizzata, marketing o vendita di dati personali.';

  @override
  String get privacyConsentFutureTitle => 'FunzionalitÃ  future';

  @override
  String get privacyConsentFutureBody => 'Se in futuro verranno introdotti servizi che richiedono un consenso facoltativo, potrai accettarlo o rifiutarlo separatamente senza modificare i consensi giÃ  espressi.';

  @override
  String get privacyExportHeading => 'Una copia dei tuoi dati';

  @override
  String get privacyExportBody => 'La funzione di esportazione completa dei dati personali sarÃ  disponibile quando saranno implementate le funzionalitÃ  di gestione ed esportazione dei dati di viaggio. Non viene mostrato alcun comando di esportazione finchÃ© la funzione non sarÃ  realmente disponibile.';

  @override
  String get profileUsername => 'Username';

  @override
  String get profileFullName => 'Nome e Cognome';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileBio => 'Bio';

  @override
  String get profileEditTitle => 'Modifica profilo';

  @override
  String get profileFirstName => 'Nome';

  @override
  String get profileLastName => 'Cognome';

  @override
  String get profileBioHint => 'Racconta qualcosa di te';

  @override
  String get profileSave => 'Salva';

  @override
  String get profileSaving => 'Salvataggio...';

  @override
  String get profileSaveSuccess => 'Profilo aggiornato.';

  @override
  String get profileSaveError => 'Non Ã¨ stato possibile aggiornare il profilo.';

  @override
  String get profileBioTooLong => 'La bio puÃ² contenere al massimo 200 caratteri.';

  @override
  String get unsavedChangesTitle => 'Sicuro di voler uscire senza salvare?';

  @override
  String get unsavedChangesMessage => 'Hai delle modifiche non salvate.';

  @override
  String get unsavedChangesDiscard => 'Esci senza salvare';

  @override
  String get unsavedChangesSaveAndExit => 'Salva ed esci';

  @override
  String get unsavedChangesCancel => 'Annulla';

  @override
  String get profileChangeUsername => 'Cambia username';

  @override
  String get profileNewUsername => 'Nuovo username';

  @override
  String get profileUsernameRequired => 'Inserisci un username.';

  @override
  String get profileUsernameAlreadyInUse => 'Questo username Ã¨ giÃ  in uso.';

  @override
  String get profileUsernameChangeSuccess => 'Username aggiornato.';

  @override
  String get profileUsernameChangeError => 'Non Ã¨ stato possibile aggiornare lo username.';

  @override
  String get profileUsernameConfirm => 'Conferma modifica';

  @override
  String get profileUsernameChanging => 'Modifica in corso...';

  @override
  String get profileEmailReadOnly => 'L\'indirizzo email si modifica dalla sezione Account.';

  @override
  String get profilePhotoChange => 'Cambia foto profilo';

  @override
  String get profilePhotoCamera => 'Scatta una foto';

  @override
  String get profilePhotoGallery => 'Scegli dalla galleria';

  @override
  String get profilePhotoRemove => 'Rimuovi foto';

  @override
  String get profilePhotoPickerError => 'Non Ã¨ stato possibile selezionare la foto.';

  @override
  String get profilePhotoCameraPermissionDenied => 'Il permesso per usare la fotocamera Ã¨ stato negato.';

  @override
  String get profilePhotoCameraPermissionPermanentlyDenied => 'Il permesso per la fotocamera Ã¨ disattivato. Puoi abilitarlo dalle impostazioni dell\'app.';

  @override
  String get profilePhotoOpenSettings => 'Apri impostazioni';

  @override
  String get profilePhotoGalleryPermissionDenied => 'Il permesso per accedere alle foto Ã¨ stato negato.';

  @override
  String get profilePhotoGalleryPermissionPermanentlyDenied => 'Il permesso per accedere alle foto Ã¨ disattivato. Puoi abilitarlo dalle impostazioni dell\'app.';

  @override
  String get profilePhotoRemoveError => 'Impossibile rimuovere la foto profilo.';

  @override
  String get notificationsAppSection => 'Notifiche dell\'app';

  @override
  String get notificationsPush => 'Notifiche push';

  @override
  String get notificationsPushSubtitle => 'Attiva o disattiva le notifiche dell\'app';

  @override
  String get notificationsTripReminders => 'Promemoria viaggio';

  @override
  String get notificationsTripRemindersSubtitle => 'Ricevi promemoria relativi ai tuoi viaggi';

  @override
  String get notificationsItineraryReminders => 'Promemoria itinerario';

  @override
  String get notificationsItineraryRemindersSubtitle => 'Ricevi promemoria per attivitÃ , prenotazioni e tappe dell\'itinerario';

  @override
  String get notificationsTripUpdates => 'Aggiornamenti viaggio';

  @override
  String get notificationsTripUpdatesSubtitle => 'Ricevi notifiche quando vengono aggiornati i tuoi viaggi';

  @override
  String get notificationsGroupInvitations => 'Inviti ai gruppi';

  @override
  String get notificationsGroupInvitationsSubtitle => 'Ricevi notifiche quando vieni invitato a un viaggio';

  @override
  String get notificationsGroupActivity => 'AttivitÃ  dei gruppi';

  @override
  String get notificationsGroupActivitySubtitle => 'Ricevi notifiche sulle attivitÃ  dei gruppi di viaggio';

  @override
  String get notificationsAppUpdates => 'Aggiornamenti dell\'app';

  @override
  String get notificationsAppUpdatesSubtitle => 'Ricevi notifiche sulle novitÃ  e sugli aggiornamenti di Amaterasu Trip';

  @override
  String get notificationsImportantCommunications => 'Comunicazioni importanti';

  @override
  String get notificationsImportantCommunicationsSubtitle => 'Ricevi comunicazioni importanti relative al servizio';

  @override
  String get notificationsEmailSection => 'Comunicazioni email';

  @override
  String get notificationsEmailSubtitle => 'Gestisci le comunicazioni ricevute via email';

  @override
  String get notificationsAccountEmails => 'Comunicazioni relative all\'account';

  @override
  String get notificationsAccountEmailsSubtitle => 'Email necessarie per sicurezza, accesso e gestione dell\'account';

  @override
  String get notificationsServiceEmails => 'Comunicazioni di servizio';

  @override
  String get notificationsServiceEmailsSubtitle => 'Email necessarie per il funzionamento e l\'utilizzo del servizio';

  @override
  String get notificationsPromotionalEmails => 'Comunicazioni promozionali';

  @override
  String get notificationsPromotionalEmailsSubtitle => 'Ricevi novitÃ , iniziative e comunicazioni promozionali di Amaterasu Trip';

  @override
  String get informationApp => 'App';

  @override
  String get informationAppSubtitle => 'Versione, build e licenze';

  @override
  String get informationLegal => 'Legale';

  @override
  String get informationLegalSubtitle => 'Termini, privacy e informazioni legali';

  @override
  String get informationSupport => 'Supporto';

  @override
  String get informationSupportSubtitle => 'Assistenza, contatti e segnalazioni';

  @override
  String get informationCredits => 'Crediti';

  @override
  String get informationCreditsSubtitle => 'Credits, servizi e SDK utilizzati';

  @override
  String get informationAppName => 'Nome applicazione';

  @override
  String get informationVersion => 'Versione';

  @override
  String get informationBuild => 'Build';

  @override
  String get informationOpenSourceLicenses => 'Licenze open source';

  @override
  String get informationOpenSourceLicensesSubtitle => 'Visualizza le licenze dei software utilizzati';

  @override
  String get informationPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get informationPrivacyPolicySubtitle => 'Consulta l\'informativa sul trattamento dei dati personali';

  @override
  String get informationContactUs => 'Contattaci';

  @override
  String get informationReportProblem => 'Segnala un problema';

  @override
  String get informationReportProblemSubtitle => 'Invia una segnalazione al supporto';

  @override
  String get informationReportProblemSubject => 'Amaterasu Trip â€” Segnalazione problema';

  @override
  String informationReportProblemBody(String version, String build) {
    return 'Descrivi il problema:\n\n\n---\nAmaterasu Trip\nVersione: $version\nBuild: $build';
  }

  @override
  String get informationCreditsDevelopedBy => 'Sviluppato da';

  @override
  String get informationCreditsTeam => 'Atlas Lantern Team';

  @override
  String get informationCreditsTechnologies => 'Tecnologie e servizi';

  @override
  String get informationCreditsTechnologiesSubtitle => 'Tecnologie e servizi utilizzati da Amaterasu Trip';

  @override
  String get dataSyncSection => 'Sincronizzazione';

  @override
  String get dataSyncSectionSubtitle => 'Gestisci la sincronizzazione dei dati';

  @override
  String get dataStorageSection => 'Archiviazione';

  @override
  String get dataStorageSectionSubtitle => 'Gestisci i dati disponibili offline e lo spazio utilizzato';

  @override
  String get dataConnectionSection => 'Connessione';

  @override
  String get dataConnectionSectionSubtitle => 'Gestisci come Amaterasu utilizza la connessione';

  @override
  String get dataSyncEnabled => 'Sincronizzazione dati';

  @override
  String get dataSyncEnabledSubtitle => 'Consenti la sincronizzazione dei dati quando sei online';

  @override
  String get dataSyncNow => 'Sincronizza ora';

  @override
  String get dataSyncNowSubtitle => 'Sincronizza manualmente i dati in attesa';

  @override
  String get dataSyncLast => 'Ultima sincronizzazione';

  @override
  String get dataSyncNever => 'Mai';

  @override
  String get dataSyncStatus => 'Stato sincronizzazione';

  @override
  String get dataSyncStatusUnavailable => 'Non ancora disponibile';

  @override
  String get dataOfflineAvailable => 'Dati disponibili offline';

  @override
  String get dataOfflineAvailableSubtitle => 'Visualizza i contenuti salvati sul dispositivo';

  @override
  String get dataStorageUsed => 'Spazio utilizzato';

  @override
  String get dataStorageUsedUnavailable => 'Nessun dato offline disponibile';

  @override
  String get dataManageOffline => 'Gestisci dati offline';

  @override
  String get dataManageOfflineSubtitle => 'Gestisci i contenuti disponibili senza connessione';

  @override
  String get dataClearOffline => 'Cancella dati offline';

  @override
  String get dataClearOfflineSubtitle => 'Rimuovi dal dispositivo le copie offline giÃ  sincronizzate';

  @override
  String get dataWifiOnly => 'Sincronizza solo con Wi-Fi';

  @override
  String get dataWifiOnlySubtitle => 'Evita la sincronizzazione tramite rete mobile';

  @override
  String get dataMobileData => 'Usa dati mobili';

  @override
  String get dataMobileDataSubtitle => 'Consenti la sincronizzazione anche tramite rete mobile';

  @override
  String get dataAutomaticDownloads => 'Download automatici';

  @override
  String get dataAutomaticDownloadsSubtitle => 'Scarica automaticamente i contenuti disponibili offline';

  @override
  String get tripsTitle => 'I miei viaggi';

  @override
  String get tripsNewTrip => 'Nuovo viaggio';

  @override
  String get tripsInProgress => 'In corso';

  @override
  String get tripsUpcoming => 'In programma';

  @override
  String get tripsCompleted => 'Conclusi';

  @override
  String tripsDayProgress(int currentDay, int totalDays) {
    return 'Giorno $currentDay di $totalDays';
  }

  @override
  String tripsTodayActivities(int count) {
    return 'Oggi: $count attivitÃ ';
  }

  @override
  String tripsOrganisationProgress(int percentage) {
    return '$percentage% organizzato';
  }

  @override
  String get tripsCompletedStatus => 'Viaggio concluso';

  @override
  String get createTripTitle => 'Nuovo viaggio';

  @override
  String get createTripChangePhoto => 'Cambia foto';

  @override
  String get createTripName => 'Nome del viaggio';

  @override
  String get createTripNameHint => 'Es. Giappone 2027';

  @override
  String get createTripDestination => 'Destinazione';

  @override
  String get createTripDestinationHint => 'Scegli una destinazione';

  @override
  String get createTripDates => 'DATE';

  @override
  String get createTripDepartureDate => 'Partenza';

  @override
  String get createTripReturnDate => 'Ritorno';

  @override
  String get createTripCurrency => 'Valuta principale';

  @override
  String get createTripCurrencyHint => 'Scegli la valuta';

  @override
  String get createTripStorageSection => 'ARCHIVIO DEL VIAGGIO';

  @override
  String get createTripStorage => 'Configura archivio';

  @override
  String get createTripStorageSubtitle => 'Potrai collegare Google Drive, OneDrive o Dropbox.';

  @override
  String get createTripStorageLater => 'Configura dopo';

  @override
  String get createTripCreate => 'CREA VIAGGIO';

  @override
  String tripCreatedTitle(String tripName) {
    return '$tripName Ã¨ pronto!';
  }

  @override
  String get tripCreatedSubtitle => 'Il tuo viaggio Ã¨ stato creato. Invita i tuoi compagni di viaggio oppure entra e inizia a organizzarlo.';

  @override
  String get tripCreatedInviteTravellers => 'Invita viaggiatori';

  @override
  String get tripCreatedCopyLink => 'Copia link';

  @override
  String get tripCreatedShare => 'Condividi';

  @override
  String get tripCreatedEnterTrip => 'Entra nel viaggio';

  @override
  String get tripCreatedLinkCopied => 'Link di invito copiato';

  @override
  String get tripsUpcomingStatus => 'Viaggio in programma';

  @override
  String get tripNavTrips => 'Viaggi';

  @override
  String get tripNavItinerary => 'Itinerario';

  @override
  String get tripNavBucketList => 'Bucket List';

  @override
  String get tripNavMore => 'Altro';

  @override
  String get tripMoreTitle => 'Altro';

  @override
  String get tripMoreSubtitle => 'Tutto ciÃ² che riguarda il tuo viaggio';

  @override
  String get tripMoreRestaurants => 'Ristoranti';

  @override
  String get tripMoreRestaurantsSubtitle => 'Organizza ristoranti e posti dove mangiare';

  @override
  String get tripMoreHotels => 'Hotel e alloggi';

  @override
  String get tripMoreHotelsSubtitle => 'Gestisci hotel e sistemazioni';

  @override
  String get tripMoreShopping => 'Shopping';

  @override
  String get tripMoreShoppingSubtitle => 'Salva negozi e luoghi per gli acquisti';

  @override
  String get tripMoreTransport => 'Trasporti';

  @override
  String get tripMoreTransportSubtitle => 'Organizza gli spostamenti del viaggio';

  @override
  String get tripMoreBookings => 'Prenotazioni';

  @override
  String get tripMoreBookingsSubtitle => 'Biglietti, ingressi e prenotazioni';

  @override
  String get tripMoreSavedPlaces => 'Luoghi salvati';

  @override
  String get tripMoreSavedPlacesSubtitle => 'Raccogli i luoghi utili per il viaggio';

  @override
  String get tripMoreMemories => 'Ricordi';

  @override
  String get tripMoreMemoriesSubtitle => 'Foto, video e momenti del viaggio';

  @override
  String get tripMoreNotes => 'Note';

  @override
  String get tripMoreNotesSubtitle => 'Annotazioni e informazioni utili';

  @override
  String get tripMoreSettings => 'Impostazioni viaggio';

  @override
  String get tripMoreSettingsSubtitle => 'Gestisci informazioni, privacy e opzioni del viaggio';

  @override
  String get tripRestaurantsTitle => 'Ristoranti';

  @override
  String get tripHotelsTitle => 'Hotel e alloggi';

  @override
  String get tripShoppingTitle => 'Shopping';

  @override
  String get tripTransportTitle => 'Trasporti';

  @override
  String get tripBookingsTitle => 'Prenotazioni';

  @override
  String get tripSavedPlacesTitle => 'Luoghi salvati';

  @override
  String get tripMemoriesTitle => 'Ricordi';

  @override
  String get tripNotesTitle => 'Note';

  @override
  String get tripSettingsTitle => 'Impostazioni viaggio';

  @override
  String get tripSettingsSubtitle => 'Gestisci questo viaggio';

  @override
  String get tripSettingsInformation => 'Informazioni';

  @override
  String get tripSettingsInformationSubtitle => 'Nome, destinazione, date e dettagli del viaggio';

  @override
  String get tripSettingsTravellers => 'Viaggiatori';

  @override
  String get tripSettingsTravellersSubtitle => 'Gestisci partecipanti, inviti e ruoli';

  @override
  String get tripSettingsNotifications => 'Notifiche';

  @override
  String get tripSettingsNotificationsSubtitle => 'Gestisci le notifiche di questo viaggio';

  @override
  String get tripSettingsPrivacy => 'Privacy e condivisione';

  @override
  String get tripSettingsPrivacySubtitle => 'Gestisci visibilitÃ  e condivisione del viaggio';

  @override
  String get tripSettingsManagement => 'Gestione viaggio';

  @override
  String get tripSettingsManagementSubtitle => 'Archivia, duplica, esporta o elimina il viaggio';

  @override
  String get tripMapTitle => 'Mappa';

  @override
  String get tripExpensesTitle => 'Spese';

  @override
  String get tripTravellersTitle => 'Viaggiatori';

  @override
  String get tripTravellersSubtitle => 'Visualizza i partecipanti al viaggio';

  @override
  String get tripMapSubtitle => 'Visualizza e organizza i luoghi del viaggio';

  @override
  String get tripExpensesSubtitle => 'Gestisci spese, divisioni e rimborsi';

  @override
  String get tripOverviewItinerary => 'Itinerario';

  @override
  String get tripOverviewBucketListSubtitle => 'Raccogli ciò che vuoi vedere e fare';

  @override
  String get tripOverviewMore => 'Altro';

  @override
  String get tripOverviewExploreTitle => 'Organizza il viaggio';

  @override
  String get tripOverviewNotFound => 'Viaggio non trovato';

  @override
  String get tripOverviewTitle => 'Panoramica';

  @override
  String get tripOverviewNotFoundSubtitle => 'Questo viaggio non è disponibile.';

  @override
  String get tripOverviewError => 'Impossibile caricare il viaggio';

  @override
  String get tripOverviewMoreSubtitle => 'Mappa, spese, viaggiatori, prenotazioni e altro';

  @override
  String get tripOverviewItinerarySubtitle => 'Organizza giorni, tappe e attività';

  @override
  String get tripOverviewExploreSubtitle => 'Accedi alle sezioni principali del viaggio';

  @override
  String get tripOverviewBucketList => 'Bucket List';
}
