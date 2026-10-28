import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/models/trip_organizational_profile.dart';

void main() {
  group('TripOrganizationalProfile', () {
    test('completo con tre risposte organizzative', () {
      const profile = TripOrganizationalProfile(
        hasEsimOrInternet: true,
        hasCheckedBaggage: false,
        hasCabinBaggage10Kg: true,
      );

      expect(profile.isComplete, isTrue);
      expect(profile.toMap().length, 3);
    });

    test('incompleto se manca una risposta', () {
      const profile = TripOrganizationalProfile(
        hasEsimOrInternet: true,
      );

      expect(profile.isComplete, isFalse);
    });

    test('ignora qualsiasi dato sanitario legacy', () {
      final profile = TripOrganizationalProfile.fromMap({
        'hasEsimOrInternet': true,
        'hasCheckedBaggage': false,
        'hasCabinBaggage10Kg': true,
        'allergies': 'DATO DA ESCLUDERE',
        'medicalAccessibilityInfo': 'DATO DA ESCLUDERE',
        'emergencyContactPhone': 'DATO DA ESCLUDERE',
      });

      final result = profile.toMap();

      expect(result.length, 3);
      expect(result.containsKey('allergies'), isFalse);
      expect(result.containsKey('medicalAccessibilityInfo'), isFalse);
      expect(result.containsKey('emergencyContactPhone'), isFalse);
    });

    test('valori non booleani non vengono accettati', () {
      final profile = TripOrganizationalProfile.fromMap({
        'hasEsimOrInternet': 'true',
        'hasCheckedBaggage': 1,
        'hasCabinBaggage10Kg': null,
      });

      expect(profile.isComplete, isFalse);
      expect(profile.hasEsimOrInternet, isNull);
      expect(profile.hasCheckedBaggage, isNull);
    });

    test('serializzazione e deserializzazione coerenti', () {
      const original = TripOrganizationalProfile(
        hasEsimOrInternet: false,
        hasCheckedBaggage: true,
        hasCabinBaggage10Kg: false,
      );

      final restored = TripOrganizationalProfile.fromMap(original.toMap());

      expect(restored.toMap(), original.toMap());
      expect(restored.isComplete, isTrue);
    });
  });
}