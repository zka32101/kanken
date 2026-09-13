import 'package:cloud_firestore/cloud_firestore.dart';

/// 通知タイプ
enum NotificationType {
  battleInvite('battle_invite', 'オンライン対戦招待'),
  battleResult('battle_result', '対戦結果'),
  examResult('exam_result', '試験結果'),
  newBadge('new_badge', '新しいバッジ獲得'),
  friendRequest('friend_request', 'フレンド要求'),
  friendAccepted('friend_accepted', 'フレンド承認'),
  achievement('achievement', '実績達成'),
  dailyChallenge('daily_challenge', 'デイリーチャレンジ');

  final String value;
  final String label;

  const NotificationType(this.value, this.label);
}

/// 通知
class AppNotification {
  final String notificationId;
  final String userId;
  final String type; // NotificationType.value
  final String title;
  final String message;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'notificationId': notificationId,
    'userId': userId,
    'type': type,
    'title': title,
    'message': message,
    'relatedId': relatedId,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
    'data': data,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    if (json['createdAt'] is! Timestamp) {
      throw FormatException('Invalid createdAt timestamp in notification');
    }
    return AppNotification(
      notificationId: json['notificationId'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      relatedId: json['relatedId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// 通知設定
class NotificationSettings {
  final String userId;
  final bool battleInviteEnabled;
  final bool battleResultEnabled;
  final bool examResultEnabled;
  final bool badgeEnabled;
  final bool friendRequestEnabled;
  final bool achievementEnabled;
  final bool dailyChallengeEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final DateTime updatedAt;

  const NotificationSettings({
    required this.userId,
    this.battleInviteEnabled = true,
    this.battleResultEnabled = true,
    this.examResultEnabled = true,
    this.badgeEnabled = true,
    this.friendRequestEnabled = true,
    this.achievementEnabled = true,
    this.dailyChallengeEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'battleInviteEnabled': battleInviteEnabled,
    'battleResultEnabled': battleResultEnabled,
    'examResultEnabled': examResultEnabled,
    'badgeEnabled': badgeEnabled,
    'friendRequestEnabled': friendRequestEnabled,
    'achievementEnabled': achievementEnabled,
    'dailyChallengeEnabled': dailyChallengeEnabled,
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    if (json['updatedAt'] is! Timestamp) {
      throw FormatException('Invalid updatedAt timestamp in notification settings');
    }
    return NotificationSettings(
      userId: json['userId'] as String,
      battleInviteEnabled: json['battleInviteEnabled'] as bool? ?? true,
      battleResultEnabled: json['battleResultEnabled'] as bool? ?? true,
      examResultEnabled: json['examResultEnabled'] as bool? ?? true,
      badgeEnabled: json['badgeEnabled'] as bool? ?? true,
      friendRequestEnabled: json['friendRequestEnabled'] as bool? ?? true,
      achievementEnabled: json['achievementEnabled'] as bool? ?? true,
      dailyChallengeEnabled: json['dailyChallengeEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  NotificationSettings copyWith({
    bool? battleInviteEnabled,
    bool? battleResultEnabled,
    bool? examResultEnabled,
    bool? badgeEnabled,
    bool? friendRequestEnabled,
    bool? achievementEnabled,
    bool? dailyChallengeEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) =>
      NotificationSettings(
        userId: userId,
        battleInviteEnabled: battleInviteEnabled ?? this.battleInviteEnabled,
        battleResultEnabled: battleResultEnabled ?? this.battleResultEnabled,
        examResultEnabled: examResultEnabled ?? this.examResultEnabled,
        badgeEnabled: badgeEnabled ?? this.badgeEnabled,
        friendRequestEnabled:
            friendRequestEnabled ?? this.friendRequestEnabled,
        achievementEnabled: achievementEnabled ?? this.achievementEnabled,
        dailyChallengeEnabled:
            dailyChallengeEnabled ?? this.dailyChallengeEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        updatedAt: DateTime.now(),
      );
}

/// 通知統計
class NotificationStats {
  final String userId;
  final int unreadCount;
  final int totalCount;
  final int battleInviteCount;
  final int friendRequestCount;
  final int achievementCount;

  const NotificationStats({
    required this.userId,
    required this.unreadCount,
    required this.totalCount,
    required this.battleInviteCount,
    required this.friendRequestCount,
    required this.achievementCount,
  });

  bool get hasUnread => unreadCount > 0;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'unreadCount': unreadCount,
    'totalCount': totalCount,
    'battleInviteCount': battleInviteCount,
    'friendRequestCount': friendRequestCount,
    'achievementCount': achievementCount,
  };

  factory NotificationStats.fromJson(Map<String, dynamic> json) =>
      NotificationStats(
        userId: json['userId'] as String,
        unreadCount: json['unreadCount'] as int? ?? 0,
        totalCount: json['totalCount'] as int? ?? 0,
        battleInviteCount: json['battleInviteCount'] as int? ?? 0,
        friendRequestCount: json['friendRequestCount'] as int? ?? 0,
        achievementCount: json['achievementCount'] as int? ?? 0,
      );
}
