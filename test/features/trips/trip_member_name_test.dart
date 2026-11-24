// Test automatico del nome mostrato per le persone: sempre lo username,
// il nome completo solo se lo username manca.
// Casi, ad esempio: "username first, full name only as a fallback".

import 'package:amaterasutrip/features/trips/models/trip_member.dart';
import 'package:amaterasutrip/features/trips/models/trip_member_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('username first, full name only as a fallback', () {
    TripMember member({String? username}) => TripMember.fromMap({
      'uid': 'u1',
      'role': 'traveler',
      'profile': {
        'username': ?username,
        'firstName': 'Tommaso',
        'lastName': 'Dal Santo',
      },
    });
    expect(tripMemberShownName(member(username: 'Yato')), 'Yato');
    expect(tripMemberShownName(member(username: ' ')), 'Tommaso Dal Santo');
    expect(tripMemberShownName(member()), 'Tommaso Dal Santo');
  });
}
