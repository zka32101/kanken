import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/social.dart';

void main() {
  group('Friend Tests', () {
    test('Friend can be created', () {
      final friend = Friend(
        friendId: 'friend1',
        userId: 'user1',
        displayName: '太郎',
        avatarUrl: null,
        level: 10,
        connectedAt: DateTime.now(),
      );

      expect(friend.friendId, equals('friend1'));
      expect(friend.userId, equals('user1'));
      expect(friend.displayName, equals('太郎'));
      expect(friend.level, equals(10));
    });

    test('JSON round-trip serialization', () {
      final original = Friend(
        friendId: 'friend1',
        userId: 'user1',
        displayName: '太郎',
        avatarUrl: null,
        level: 10,
        connectedAt: DateTime(2026, 9, 13),
      );

      final json = original.toJson();
      final fromJson = Friend.fromJson(json as Map<String, dynamic>);

      expect(fromJson.friendId, equals(original.friendId));
      expect(fromJson.displayName, equals(original.displayName));
      expect(fromJson.level, equals(original.level));
    });
  });

  group('FriendRequest Tests', () {
    test('FriendRequest can be created', () {
      final request = FriendRequest(
        requestId: 'req1',
        fromUserId: 'user1',
        toUserId: 'user2',
        fromDisplayName: '太郎',
        fromAvatarUrl: null,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      expect(request.requestId, equals('req1'));
      expect(request.status, equals('pending'));
      expect(request.isPending, isTrue);
      expect(request.isAccepted, isFalse);
    });

    test('FriendRequest status properties work correctly', () {
      final pendingRequest = FriendRequest(
        requestId: 'req1',
        fromUserId: 'user1',
        toUserId: 'user2',
        fromDisplayName: '太郎',
        fromAvatarUrl: null,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final acceptedRequest = FriendRequest(
        requestId: 'req2',
        fromUserId: 'user1',
        toUserId: 'user2',
        fromDisplayName: '太郎',
        fromAvatarUrl: null,
        status: 'accepted',
        createdAt: DateTime.now(),
      );

      final rejectedRequest = FriendRequest(
        requestId: 'req3',
        fromUserId: 'user1',
        toUserId: 'user2',
        fromDisplayName: '太郎',
        fromAvatarUrl: null,
        status: 'rejected',
        createdAt: DateTime.now(),
      );

      expect(pendingRequest.isPending, isTrue);
      expect(acceptedRequest.isAccepted, isTrue);
      expect(rejectedRequest.isRejected, isTrue);
    });

    test('JSON round-trip serialization', () {
      final original = FriendRequest(
        requestId: 'req1',
        fromUserId: 'user1',
        toUserId: 'user2',
        fromDisplayName: '太郎',
        fromAvatarUrl: null,
        status: 'pending',
        createdAt: DateTime(2026, 9, 13),
      );

      final json = original.toJson();
      final fromJson = FriendRequest.fromJson(json as Map<String, dynamic>);

      expect(fromJson.requestId, equals(original.requestId));
      expect(fromJson.status, equals(original.status));
      expect(fromJson.isPending, isTrue);
    });
  });

  group('SocialUserProfile Tests', () {
    test('SocialUserProfile can be created', () {
      final profile = SocialUserProfile(
        userId: 'user1',
        displayName: '太郎',
        avatarUrl: null,
        bio: '漢字学習中',
        level: 15,
        totalBattles: 25,
        winRate: 0.72,
        totalFriends: 10,
        lastOnline: DateTime.now(),
      );

      expect(profile.userId, equals('user1'));
      expect(profile.displayName, equals('太郎'));
      expect(profile.level, equals(15));
      expect(profile.totalBattles, equals(25));
      expect(profile.winRate, equals(0.72));
    });

    test('JSON round-trip serialization', () {
      final original = SocialUserProfile(
        userId: 'user1',
        displayName: '太郎',
        avatarUrl: null,
        bio: '漢字学習中',
        level: 15,
        totalBattles: 25,
        winRate: 0.72,
        totalFriends: 10,
        lastOnline: DateTime(2026, 9, 13, 10, 30),
      );

      final json = original.toJson();
      final fromJson =
          SocialUserProfile.fromJson(json as Map<String, dynamic>);

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.displayName, equals(original.displayName));
      expect(fromJson.level, equals(original.level));
      expect(fromJson.winRate, equals(original.winRate));
      expect(fromJson.totalFriends, equals(original.totalFriends));
    });
  });
}
