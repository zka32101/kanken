import 'package:cloud_firestore/cloud_firestore.dart';

/// フレンド
class Friend {
  final String friendId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int level;
  final DateTime connectedAt;

  const Friend({
    required this.friendId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.level,
    required this.connectedAt,
  });

  Map<String, dynamic> toJson() => {
    'friendId': friendId,
    'userId': userId,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'level': level,
    'connectedAt': Timestamp.fromDate(connectedAt),
  };

  factory Friend.fromJson(Map<String, dynamic> json) {
    if (json['connectedAt'] is! Timestamp) {
      throw FormatException('Invalid connectedAt timestamp in friend');
    }
    return Friend(
      friendId: json['friendId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      level: json['level'] as int? ?? 0,
      connectedAt: (json['connectedAt'] as Timestamp).toDate(),
    );
  }
}

/// フレンド要求
class FriendRequest {
  final String requestId;
  final String fromUserId;
  final String toUserId;
  final String fromDisplayName;
  final String? fromAvatarUrl;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime? respondedAt;

  const FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromDisplayName,
    this.fromAvatarUrl,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'fromDisplayName': fromDisplayName,
    'fromAvatarUrl': fromAvatarUrl,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
  };

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    if (json['createdAt'] is! Timestamp) {
      throw FormatException('Invalid createdAt timestamp in friend request');
    }
    return FriendRequest(
      requestId: json['requestId'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      fromDisplayName: json['fromDisplayName'] as String,
      fromAvatarUrl: json['fromAvatarUrl'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      respondedAt: json['respondedAt'] is Timestamp
          ? (json['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

/// ユーザープロフィール（社交機能用）
class SocialUserProfile {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final int level;
  final int totalBattles;
  final double winRate;
  final int totalFriends;
  final DateTime lastOnline;

  const SocialUserProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.level,
    required this.totalBattles,
    required this.winRate,
    required this.totalFriends,
    required this.lastOnline,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'level': level,
    'totalBattles': totalBattles,
    'winRate': winRate,
    'totalFriends': totalFriends,
    'lastOnline': Timestamp.fromDate(lastOnline),
  };

  factory SocialUserProfile.fromJson(Map<String, dynamic> json) =>
      SocialUserProfile(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        bio: json['bio'] as String?,
        level: json['level'] as int? ?? 0,
        totalBattles: json['totalBattles'] as int? ?? 0,
        winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
        totalFriends: json['totalFriends'] as int? ?? 0,
        lastOnline: json['lastOnline'] is Timestamp
            ? (json['lastOnline'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
