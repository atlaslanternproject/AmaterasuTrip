// Nome di una persona da mostrare nell'app: sempre lo USERNAME (es.
// "Yato"), mai nome e cognome. Stessa regola del budget
// (BudgetApi.travelers): solo se manca lo username si usa il nome.

import 'trip_member.dart';

/// Username of [member]; the full name only when there is no username.
String? tripMemberShownName(TripMember member) {
  final username = member.username?.trim() ?? '';
  if (username.isNotEmpty) return username;
  return member.displayName;
}
