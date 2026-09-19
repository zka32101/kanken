import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/notifications.dart';

void main() {
  group('AppNotification Tests', () {
    test('AppNotification creates with valid data', () {
      final notification = AppNotification(
        id: 'notif-1',
        userId: 'user-1',
        title: 'Challenge Accepted',
        body: 'Your challenge was accepted!',
        type: 'challenge',
        isRead: false,
        createdAt: DateTime.now(),
        data: {'challengeId': 'challenge-1'},
      );

      expect(notification.id, equals('notif-1'));
      expect(notification.title, equals('Challenge Accepted'));
      expect(notification.type, equals('challenge'));
      expect(notification.isRead, isFalse);
    });

    test('AppNotification notification types', () {
      const validTypes = [
        'challenge',
        'achievement',
        'friend_request',
        'battle_invite',
        'level_up',
        'daily_bonus',
        'event',
      ];

      for (final type in validTypes) {
        final notification = AppNotification(
          id: 'notif-$type',
          userId: 'user-1',
          title: 'Test $type',
          body: 'Test notification',
          type: type,
          isRead: false,
          createdAt: DateTime.now(),
          data: {},
        );

        expect(validTypes.contains(notification.type), isTrue);
      }
    });

    test('AppNotification read status', () {
      final unreadNotif = AppNotification(
        id: 'notif-2',
        userId: 'user-1',
        title: 'Unread',
        body: 'Not read yet',
        type: 'achievement',
        isRead: false,
        createdAt: DateTime.now(),
        data: {},
      );

      expect(unreadNotif.isRead, isFalse);

      final readNotif = AppNotification(
        id: 'notif-3',
        userId: 'user-1',
        title: 'Read',
        body: 'Already read',
        type: 'achievement',
        isRead: true,
        createdAt: DateTime.now(),
        data: {},
      );

      expect(readNotif.isRead, isTrue);
    });

    test('AppNotification fromJson creates instance', () {
      final jsonData = {
        'id': 'notif-4',
        'userId': 'user-2',
        'title': 'New Friend',
        'body': 'You have a new friend request',
        'type': 'friend_request',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': {'senderId': 'user-3'},
      };

      final notification = AppNotification.fromJson(jsonData);

      expect(notification.id, equals('notif-4'));
      expect(notification.title, equals('New Friend'));
      expect(notification.type, equals('friend_request'));
    });

    test('AppNotification with additional data', () {
      final notification = AppNotification(
        id: 'notif-5',
        userId: 'user-1',
        title: 'Battle Result',
        body: 'You won the battle!',
        type: 'battle_invite',
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'battleId': 'battle-123',
          'opponentName': 'Alice',
          'reward': 500,
        },
      );

      expect(notification.data['battleId'], equals('battle-123'));
      expect(notification.data['reward'], equals(500));
    });

    test('AppNotification timestamp tracking', () {
      final now = DateTime.now();
      final notification = AppNotification(
        id: 'notif-6',
        userId: 'user-1',
        title: 'Event',
        body: 'Event notification',
        type: 'event',
        isRead: false,
        createdAt: now,
        data: {},
      );

      expect(notification.createdAt, equals(now));
      expect(notification.createdAt, isNotNull);
    });

    test('AppNotification priority levels', () {
      final criticalNotif = AppNotification(
        id: 'notif-7',
        userId: 'user-1',
        title: 'Level Up!',
        body: 'You reached level 50!',
        type: 'level_up',
        isRead: false,
        createdAt: DateTime.now(),
        data: {'level': 50},
      );

      final regularNotif = AppNotification(
        id: 'notif-8',
        userId: 'user-1',
        title: 'Daily Bonus',
        body: 'Claim your daily bonus',
        type: 'daily_bonus',
        isRead: false,
        createdAt: DateTime.now(),
        data: {'coins': 100},
      );

      expect(criticalNotif.type, equals('level_up'));
      expect(regularNotif.type, equals('daily_bonus'));
    });

    test('AppNotification filtering by type', () {
      final notifications = [
        AppNotification(
          id: 'notif-9',
          userId: 'user-1',
          title: 'Challenge 1',
          body: 'Challenge received',
          type: 'challenge',
          isRead: false,
          createdAt: DateTime.now(),
          data: {},
        ),
        AppNotification(
          id: 'notif-10',
          userId: 'user-1',
          title: 'Achievement',
          body: 'Achievement unlocked',
          type: 'achievement',
          isRead: false,
          createdAt: DateTime.now(),
          data: {},
        ),
        AppNotification(
          id: 'notif-11',
          userId: 'user-1',
          title: 'Challenge 2',
          body: 'Another challenge',
          type: 'challenge',
          isRead: false,
          createdAt: DateTime.now(),
          data: {},
        ),
      ];

      final challengeNotifs = notifications.where((n) => n.type == 'challenge').toList();
      expect(challengeNotifs.length, equals(2));
    });

    test('AppNotification unread count', () {
      final notifications = [
        AppNotification(
          id: 'notif-12',
          userId: 'user-1',
          title: 'Unread 1',
          body: 'Not read',
          type: 'challenge',
          isRead: false,
          createdAt: DateTime.now(),
          data: {},
        ),
        AppNotification(
          id: 'notif-13',
          userId: 'user-1',
          title: 'Read',
          body: 'Already read',
          type: 'challenge',
          isRead: true,
          createdAt: DateTime.now(),
          data: {},
        ),
        AppNotification(
          id: 'notif-14',
          userId: 'user-1',
          title: 'Unread 2',
          body: 'Not read',
          type: 'achievement',
          isRead: false,
          createdAt: DateTime.now(),
          data: {},
        ),
      ];

      final unreadCount = notifications.where((n) => !n.isRead).length;
      expect(unreadCount, equals(2));
    });

    test('AppNotification batch operations', () {
      final now = DateTime.now();
      final notifications = List.generate(10, (i) {
        return AppNotification(
          id: 'notif-batch-$i',
          userId: 'user-1',
          title: 'Notification $i',
          body: 'Batch notification $i',
          type: ['challenge', 'achievement', 'friend_request'][i % 3],
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
}
