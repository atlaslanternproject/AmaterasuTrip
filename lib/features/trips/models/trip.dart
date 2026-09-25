import 'package:cloud_firestore/cloud_firestore.dart';

enum TripStatus {
  active,
  closed,
}

class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.ownerUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String currency;
  final String ownerUid;
  final TripStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Trip.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final startDate = data['startDate'] as Timestamp?;
    final endDate = data['endDate'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;
    final updatedAt = data['updatedAt'] as Timestamp?;

    return Trip(
      id: id,
      name: data['name'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      startDate: startDate?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      endDate: endDate?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      currency: data['currency'] as String? ?? '',
      ownerUid: data['ownerUid'] as String? ?? '',
      status: _tripStatusFromString(data['status'] as String?),
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }
}

TripStatus _tripStatusFromString(String? value) {
  switch (value) {
    case 'closed':
      return TripStatus.closed;
    case 'active':
    default:
      return TripStatus.active;
  }
}