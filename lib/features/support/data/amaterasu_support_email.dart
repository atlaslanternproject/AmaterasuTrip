// Email di assistenza (Impostazioni > Assistenza), unico modo per
// contattarci: "Contatti" apre un'email vuota all'indirizzo di supporto.
// Lo stesso modulo prepara le email di segnalazione. Nessun dato salvato
// su Firebase: l'email parte dall'app di posta dell'utente.

import 'package:url_launcher/url_launcher.dart';

abstract final class AmaterasuSupportEmail {
  static const address = 'atlaslanternproject@gmail.com';

  /// An email to [address], with [subject] and [body] when given.
  static Uri uri({String? subject, String? body}) => Uri(
    scheme: 'mailto',
    path: address,
    query: [
      if (subject != null) 'subject=${Uri.encodeComponent(subject)}',
      if (body != null) 'body=${Uri.encodeComponent(body)}',
    ].join('&').ifEmptyNull,
  );

  /// Opens the mail app with an empty email to the support address.
  static Future<void> contact() async {
    await launchUrl(uri());
  }
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}
