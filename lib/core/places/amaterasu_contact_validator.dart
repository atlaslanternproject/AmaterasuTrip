// Controllo base di telefono ed email dei luoghi (alloggi e altre sezioni),
// con gli stessi limiti e le stesse espressioni usati in firestore.rules.

abstract final class AmaterasuContactValidator {
  static const phoneMax = 40;
  static const emailMax = 254;

  // Same patterns as firestore.rules.
  static final _phone = RegExp(r'^[+]?[0-9 ()./-]{4,40}$');
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+[.][^\s@]+$');

  /// Digits, spaces, + ( ) . / - ; at most [phoneMax] characters.
  static bool isPhone(String value) =>
      value.length <= phoneMax && _phone.hasMatch(value);

  /// Basic check: something@domain.tld, at most [emailMax] characters.
  static bool isEmail(String value) =>
      value.length <= emailMax && _email.hasMatch(value);
}
