import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

void main() {
  test('un membro riceve le tre risposte organizzative', () {
    final member = TripMember.fromMap({
      'uid': 'traveler-b',
      'role': 'traveler',
      'travellerProfileCompleted': false,
      'organizationalProfile': {
        'hasEsimOrInternet': true,
        'hasCheckedBaggage': false,
        'hasCabinBaggage10Kg': true,
      },
    });

    expect(member.organizationalProfile, isNotNull);
    expect(member.organizationalProfile!.isComplete, isTrue);
    expect(member.organizationalProfile!.hasEsimOrInternet, isTrue);
    expect(member.organizationalProfile!.hasCheckedBaggage, isFalse);
    expect(member.organizationalProfile!.hasCabinBaggage10Kg, isTrue);
  });

  test('un membro senza risposte mantiene il proprio ruolo', () {
    final member = TripMember.fromMap({
      'uid': 'owner-a',
      'role': 'admin',
      'travellerProfileCompleted': false,
    });

    expect(member.uid, 'owner-a');
    expect(member.isAdmin, isTrue);
    expect(member.organizationalProfile, isNull);
  });

  test('il modello organizzativo ignora i campi sanitari', () {
    final member = TripMember.fromMap({
      'uid': 'traveler-c',
      'role': 'traveler',
      'travellerProfileCompleted': false,
      'organizationalProfile': {
        'hasEsimOrInternet': true,
        'hasCheckedBaggage': true,
        'hasCabinBaggage10Kg': false,
        'allergies': 'NON CONDIVIDERE',
        'emergencyContactPhone': 'NON CONDIVIDERE',
      },
    });

    final sanitized = member.organizationalProfile!.toMap();

    expect(sanitized.length, 3);
    expect(sanitized.containsKey('allergies'), isFalse);
    expect(sanitized.containsKey('emergencyContactPhone'), isFalse);
  });
}
