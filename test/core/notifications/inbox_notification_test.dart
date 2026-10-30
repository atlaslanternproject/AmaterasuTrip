import 'package:flutter_test/flutter_test.dart';
import 'package:amaterasutrip/core/notifications/inbox/inbox_notification.dart';

void main() {
  group('Inbox notification', () {
    final date = DateTime.utc(2027, 4, 12);

    test('new notification is unread and active', () {
      final item = InboxNotification(
        id: 'one',
        type: 'trip_update',
        category: 'trip_information_changes',
        title: 'Trip updated',
        body: 'A trip detail changed',
        createdAt: date,
      );

      expect(item.isRead, isFalse);
      expect(item.isArchived, isFalse);
      expect(item.isDeleted, isFalse);
    });

    test('read notification is recognized', () {
      final item = InboxNotification(
        id: 'two',
        type: 'trip_update',
        category: 'trip_information_changes',
        title: 'Trip updated',
        body: 'A trip detail changed',
        createdAt: date,
        readAt: date,
      );

      expect(item.isRead, isTrue);
    });

    test('archived notification is recognized', () {
      final item = InboxNotification(
        id: 'three',
        type: 'trip_update',
        category: 'trip_information_changes',
        title: 'Trip updated',
        body: 'A trip detail changed',
        createdAt: date,
        archivedAt: date,
      );

      expect(item.isArchived, isTrue);
    });

    test('soft deleted notification is recognized', () {
      final item = InboxNotification(
        id: 'four',
        type: 'trip_update',
        category: 'trip_information_changes',
        title: 'Trip updated',
        body: 'A trip detail changed',
        createdAt: date,
        deletedAt: date,
      );

      expect(item.isDeleted, isTrue);
    });
  });
}
