import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/friend.dart';

void main() {
  Friend makeFriend({
    FriendStatus status = FriendStatus.friend,
    DateTime? lastPlayedAt,
  }) =>
      Friend(
        userId: 'user1_default',
        userName: '太郎',
        level: 10,
        experience: 500,
        accuracyRate: 0.8,
        streak: 3,
        status: status,
        addedAt: DateTime(2026, 9, 13),
        lastPlayedAt: lastPlayedAt,
      );

  group('Friend Tests', () {
    test('Friend can be created', () {
      final friend = makeFriend();

      expect(friend.userId, equals('user1_default'));
      expect(friend.userName, equals('太郎'));
      expect(friend.level, equals(10));
      expect(friend.getStatusLabel(), equals('フレンド中'));
    });

    test('ステータス表示がステータスごとに切り替わる', () {
      expect(makeFriend(status: FriendStatus.pending).getStatusLabel(),
          equals('リクエスト待ち'));
      expect(makeFriend(status: FriendStatus.requested).getStatusLabel(),
          equals('リクエスト済み'));
      expect(makeFriend().getStatusIcon(), equals('✅'));
      expect(makeFriend(status: FriendStatus.pending).getStatusIcon(),
          equals('⏳'));
      expect(makeFriend(status: FriendStatus.requested).getStatusIcon(),
          equals('📤'));
    });

    test('isOnline は30分以内の活動で true', () {
      expect(makeFriend().isOnline, isFalse);
      expect(
          makeFriend(
                  lastPlayedAt:
                      DateTime.now().subtract(const Duration(minutes: 5)))
              .isOnline,
          isTrue);
      expect(
          makeFriend(
                  lastPlayedAt:
                      DateTime.now().subtract(const Duration(minutes: 31)))
              .isOnline,
          isFalse);
    });

    test('JSON round-trip serialization', () {
      final original = makeFriend(
        status: FriendStatus.pending,
        lastPlayedAt: DateTime(2026, 9, 14),
      );

      final fromJson = Friend.fromJson(original.toJson());

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.userName, equals(original.userName));
      expect(fromJson.level, equals(original.level));
      expect(fromJson.accuracyRate, equals(original.accuracyRate));
      expect(fromJson.status, equals(FriendStatus.pending));
      expect(fromJson.addedAt, equals(original.addedAt));
      expect(fromJson.lastPlayedAt, equals(original.lastPlayedAt));
    });

    test('欠損フィールドはデフォルト値で補われる', () {
      final f = Friend.fromJson({});
      expect(f.userId, equals(''));
      expect(f.userName, equals('Unknown'));
      expect(f.level, equals(1));
      expect(f.status, equals(FriendStatus.friend));
      expect(f.lastPlayedAt, isNull);
    });
  });

  group('FriendRequest Tests', () {
    test('FriendRequest can be created', () {
      final request = FriendRequest(
        requestId: 'req1',
        fromUserId: 'user1_default',
        fromUserName: '太郎',
        toUserId: 'user2_default',
        createdAt: DateTime.now(),
      );

      expect(request.requestId, equals('req1'));
      expect(request.fromUserName, equals('太郎'));
      expect(request.toUserId, equals('user2_default'));
    });

    test('JSON round-trip serialization', () {
      final original = FriendRequest(
        requestId: 'req1',
        fromUserId: 'user1_default',
        fromUserName: '太郎',
        toUserId: 'user2_default',
        createdAt: DateTime(2026, 9, 13),
      );

      final fromJson = FriendRequest.fromJson(original.toJson());

      expect(fromJson.requestId, equals(original.requestId));
      expect(fromJson.fromUserId, equals(original.fromUserId));
      expect(fromJson.fromUserName, equals(original.fromUserName));
      expect(fromJson.toUserId, equals(original.toUserId));
      expect(fromJson.createdAt, equals(original.createdAt));
    });
  });
}
