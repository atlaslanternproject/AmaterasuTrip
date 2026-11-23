// Una voce della lista valigia: cosa portare, per chi (un viaggiatore o
// tutti), quantità e messa in valigia sì/no.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';

class TripPackingItem implements TripSectionItem {
  const TripPackingItem({
    this.id = '',
    required this.tripId,
    required this.createdByUid,
    required this.name,
    this.personUid,
    this.quantity,
    this.packed = false,
  });

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String createdByUid;
  final String name;

  /// Traveler who packs it; null = for everyone.
  final String? personUid;
  final int? quantity;
  final bool packed;

  @override
  String? get expenseId => null;

  @override
  String get displayName => name;

  TripPackingItem toggled() => TripPackingItem(
    id: id,
    tripId: tripId,
    createdByUid: createdByUid,
    name: name,
    personUid: personUid,
    quantity: quantity,
    packed: !packed,
  );
}
