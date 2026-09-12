import 'package:cloud_firestore/cloud_firestore.dart';

/// フレンド関係の状態
enum FriendStatus {
  friend,      // フレンド
  pending,     // リクエスト待ち
  requested,   // リクエスト送信済み
}

/// フレンド情報
class Friend {
  final String userId;
  final String userName;
  final int level;
  final int experience;
  final double accuracyRate;
  final int streak;
  final FriendStatus status;
  final DateTime addedAt;
  final DateTime? lastPlayedAt;

  const Friend({
    required this.userId,
    required this.userName,
    required this.level,
    required this.experience,
    required this.accuracyRate,
    required this.streak,
    required this.status,
    required this.addedAt,
    this.lastPlayedAt,
  });

  /// ステータス表示テキスト
  String getStatusLabel() {
    switch (status) {
      case FriendStatus.friend:
        return 'フレンド中';
      case FriendStatus.pending:
        return 'リクエスト待ち';
      case FriendStatus.requested:
        return 'リクエスト済み';
    }
  }

  /// ステータス表示アイコン
  String getStatusIcon() {
    switch (status) {
      case FriendStatus.friend:
        return '✅';
      case FriendStatus.pending:
        return '⏳';
      case FriendStatus.requested:
        return '📤';
    }
  }

  /// オンライン状態判定（30分以内なら活動中）
  bool get isOnline {
    if (lastPlayedAt == null) return false;
    final now = DateTime.now();
    return now.difference(lastPlayedAt!).inMinutes < 30;
  }

  /// JSON からのデシリアライズ
  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown',
      level: json['level'] as int? ?? 1,
      experience: json['experience'] as int? ?? 0,
      accuracyRate: (json['accuracyRate'] as num?)?.toDouble() ?? 0.0,
      streak: json['streak'] as int? ?? 0,
      status: _statusFromString(json['status'] as String? ?? 'friend'),
      addedAt: json['addedAt'] is Timestamp
          ? (json['addedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastPlayedAt: json['lastPlayedAt'] is Timestamp
          ? (json['lastPlayedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'level': level,
    'experience': experience,
    'accuracyRate': accuracyRate,
    'streak': streak,
    'status': _statusToString(status),
    'addedAt': Timestamp.fromDate(addedAt),
    'lastPlayedAt': lastPlayedAt != null ? Timestamp.fromDate(lastPlayedAt!) : null,
  };

  @override
  String toString() =>
      'Friend(userId: $userId, userName: $userName, status: $status, level: $level)';
}

/// ステータスを文字列に変換
String _statusToString(FriendStatus status) {
  switch (status) {
    case FriendStatus.friend:
      return 'friend';
    case FriendStatus.pending:
      return 'pending';
    case FriendStatus.requested:
      return 'requested';
  }
}

/// 文字列からステータスに変換
FriendStatus _statusFromString(String status) {
  switch (status) {
    case 'pending':
      return FriendStatus.pending;
    case 'requested':
      return FriendStatus.requested;
    default:
      return FriendStatus.friend;
  }
}

/// フレンドリクエスト
class FriendRequest {
  final String requestId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final DateTime createdAt;

  const FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.createdAt,
  });

  /// JSON からのデシリアライズ
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['requestId'] as String? ?? '',
      fromUserId: json['fromUserId'] as String? ?? '',
      fromUserName: json['fromUserName'] as String? ?? 'Unknown',
      toUserId: json['toUserId'] as String? ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'fromUserId': fromUserId,
    'fromUserName': fromUserName,
    'toUserId': toUserId,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
