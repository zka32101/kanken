import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/notifications.dart';

AppNotification _make({
  String id = 'notif-1',
  String type = 'challenge_received',
  bool isRead = false,
  DateTime? createdAt,
  String? relatedId,
  Map<String, dynamic>? data,
}) {
  return AppNotification(
    notificationId: id,
    userId: 'user-1',
    type: type,
    title: 'Title $id',
    message: 'Message $id',
    relatedId: relatedId,
    isRead: isRead,
    createdAt: createdAt ?? DateTime.now(),
    data: data,
  );
}

void main() {
  group('AppNotification Tests', () {
    test('AppNotification creates with valid data', () {
      final notification = AppNotification(
        notificationId: 'notif-1',
        userId: 'user-1',
        type: NotificationType.challengeReceived.value,
        title: 'Challenge Accepted',
        message: 'Your challenge was accepted!',
        isRead: false,
        createdAt: DateTime.now(),
        data: {'challengeId': 'challenge-1'},
      );

      expect(notification.notificationId, equals('notif-1'));
      expect(notification.title, equals('Challenge Accepted'));
      expect(notification.type, equals('challenge_received'));
      expect(notification.isRead, isFalse);
    });

    test('NotificationType values are unique and labelled', () {
      final values = NotificationType.values.map((t) => t.value).toList();

      expect(values.toSet().length, equals(values.length));
      expect(NotificationType.friendRequest.value, equals('friend_request'));
      expect(NotificationType.friendRequest.label, equals('フレンド要求'));
      for (final t in NotificationType.values) {
        expect(t.label, isNotEmpty);
      }
    });

    test('AppNotification read status', () {
      expect(_make(id: 'notif-2').isRead, isFalse);
      expect(_make(id: 'notif-3', isRead: true).isRead, isTrue);
    });

    test('AppNotification fromJson creates instance', () {
      final jsonData = {
        'notificationId': 'notif-4',
        'userId': 'user-2',
        'title': 'New Friend',
        'message': 'You have a new friend request',
        'type': 'friend_request',
        'relatedId': 'req-1',
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 13)),
        'data': {'senderId': 'user-3'},
      };

      final notification = AppNotification.fromJson(jsonData);

      expect(notification.notificationId, equals('notif-4'));
      expect(notification.title, equals('New Friend'));
      expect(notification.type, equals('friend_request'));
      expect(notification.relatedId, equals('req-1'));
      expect(notification.createdAt, equals(DateTime(2026, 9, 13)));
      expect(notification.data!['senderId'], equals('user-3'));
    });

    test('AppNotification fromJson: isRead 欠損は未読扱い', () {
      final notification = AppNotification.fromJson({
        'notificationId': 'notif-5',
        'userId': 'user-1',
        'type': 'achievement',
        'title': 't',
        'message': 'm',
      });

      expect(notification.isRead, isFalse);
      expect(notification.relatedId, isNull);
      expect(notification.data, isNull);
    });

    test('AppNotification JSON round-trip', () {
      final original = _make(
        id: 'notif-6',
        type: 'battle_invite',
        isRead: true,
        createdAt: DateTime(2026, 9, 13, 10),
        relatedId: 'battle-123',
        data: {'opponentName': 'Alice', 'reward': 500},
      );

      final restored = AppNotification.fromJson(original.toJson());

      expect(restored.notificationId, equals(original.notificationId));
      expect(restored.userId, equals(original.userId));
      expect(restored.type, equals('battle_invite'));
      expect(restored.isRead, isTrue);
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.relatedId, equals('battle-123'));
      expect(restored.data!['reward'], equals(500));
    });

    test('AppNotification filtering by type', () {
      final notifications = [
        _make(id: 'notif-9', type: 'challenge_received'),
        _make(id: 'notif-10', type: 'achievement'),
        _make(id: 'notif-11', type: 'challenge_received'),
      ];

      final challengeNotifs =
          notifications.where((n) => n.type == 'challenge_received').toList();
      expect(challengeNotifs.length, equals(2));
    });

    test('AppNotification unread count', () {
      final notifications = [
        _make(id: 'notif-12'),
        _make(id: 'notif-13', isRead: true),
        _make(id: 'notif-14', type: 'achievement'),
      ];

      final unreadCount = notifications.where((n) => !n.isRead).length;
      expect(unreadCount, equals(2));
    });

    test('AppNotification batch operations', () {
      final now = DateTime.now();
      final types = ['challenge_received', 'achievement', 'friend_request'];
      final notifications = List.generate(10, (i) {
        return _make(
          id: 'notif-batch-$i',
          type: types[i % 3],
          isRead: i % 2 == 0,
          createdAt: now.subtract(Duration(hours: i)),
          data: {'index': i},
        );
      });

      expect(notifications.length, equals(10));
      expect(notifications.where((n) => n.isRead).length, equals(5));
      expect(notifications.where((n) => !n.isRead).length, equals(5));
    });
  });

  group('NotificationStats Tests', () {
    test('hasUnread reflects unreadCount', () {
      const none = NotificationStats(
        userId: 'user-1',
        unreadCount: 0,
        totalCount: 3,
        battleInviteCount: 0,
        friendRequestCount: 0,
        achievementCount: 0,
      );
      const some = NotificationStats(
        userId: 'user-1',
        unreadCount: 2,
        totalCount: 3,
        battleInviteCount: 1,
        friendRequestCount: 1,
        achievementCount: 0,
      );

      expect(none.hasUnread, isFalse);
      expect(some.hasUnread, isTrue);
    });
  });
}
