/// Informazioni esclusivamente organizzative del viaggiatore.
///
/// Non contiene dati sanitari, contatti di emergenza,
/// informazioni mediche o chiavi crittografiche.
class TripOrganizationalProfile {
  const TripOrganizationalProfile({
    this.hasEsimOrInternet,
    this.hasCheckedBaggage,
    this.hasCabinBaggage10Kg,
  });

  final bool? hasEsimOrInternet;
  final bool? hasCheckedBaggage;
  final bool? hasCabinBaggage10Kg;

  bool get isComplete =>
      hasEsimOrInternet != null &&
      hasCheckedBaggage != null &&
      hasCabinBaggage10Kg != null;

  factory TripOrganizationalProfile.fromMap(dynamic raw) {
    if (raw is! Map) {
      return const TripOrganizationalProfile();
    }

    bool? readBool(String key) {
      final value = raw[key];
      return value is bool ? value : null;
    }

    return TripOrganizationalProfile(
      hasEsimOrInternet: readBool('hasEsimOrInternet'),
      hasCheckedBaggage: readBool('hasCheckedBaggage'),
      hasCabinBaggage10Kg: readBool('hasCabinBaggage10Kg'),
    );
  }

  Map<String, dynamic> toMap() => {
    'hasEsimOrInternet': hasEsimOrInternet,
    'hasCheckedBaggage': hasCheckedBaggage,
    'hasCabinBaggage10Kg': hasCabinBaggage10Kg,
  };
}