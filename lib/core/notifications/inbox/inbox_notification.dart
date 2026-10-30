import 'package:cloud_firestore/cloud_firestore.dart';

class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.tripId,
    this.route,
    this.readAt,
    this.archivedAt,
    this.deletedAt,
  });

  final String id;
  final String type;
  final String category;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? tripId;
  final String? route;
  final DateTime? readAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;

  bool get isRead => readAt != null;
  bool get isArchived => archivedAt != null;
  bool get isDeleted => deletedAt != null;

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static String? _optionalString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }

  factory InboxNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();

    if (data == null) {
      throw const FormatException('Notification document missing');
    }

    final createdAt = _date(data['createdAt']);

    if (createdAt == null) {
      throw const FormatException('Notification timestamp missing');
    }

    String requiredString(String key) {
      final value = data[key];

      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Invalid notification field: $key');
      }

      return value;
    }

    return InboxNotification(
      id: snapshot.id,
      type: requiredString('type'),
      category: requiredString('category'),
      title: requiredString('title'),
      body: requiredString('body'),
      createdAt: createdAt,
      tripId: _optionalString(data['tripId']),
      route: _optionalString(data['route']),
      readAt: _date(data['readAt']),
      archivedAt: _date(data['archivedAt']),
      deletedAt: _date(data['deletedAt']),
    );
  }
}
