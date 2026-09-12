import 'package:cloud_firestore/cloud_firestore.dart';

/// チャレンジ招待ステータス
enum ChallengeStatus {
  pending,      // 待機中
  accepted,     // 受け入れ
  completed,    // 完了
  declined,     // 拒否
}

/// チャレンジ招待
class ChallengeInvitation {
  final String invitationId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final ChallengeStatus status;
  final int? fromScore;    // 招待者のスコア
  final int? toScore;      // 被招待者のスコア
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime expiresAt;  // 有効期限 (7日間)

  const ChallengeInvitation({
    required this.invitationId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.status,
    this.fromScore,
    this.toScore,
    required this.createdAt,
    this.completedAt,
    required this.expiresAt,
  });

  /// ステータス表示テキスト
  String getStatusLabel() {
    switch (status) {
      case ChallengeStatus.pending:
        return '待機中';
      case ChallengeStatus.accepted:
        return 'チャレンジ中';
      case ChallengeStatus.completed:
        return '完了';
      case ChallengeStatus.declined:
        return '拒否';
    }
  }

  /// 勝者判定
  String? getWinner() {
    if (fromScore == null || toScore == null) return null;
    if (fromScore! > toScore!) return fromUserId;
    if (toScore! > fromScore!) return toUserId;
    return null; // 同点
  }

  /// スコア差
  int? getScoreDifference() {
    if (fromScore == null || toScore == null) return null;
    return (fromScore! - toScore!).abs();
  }

  /// 有効期限切れ判定
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// JSON からのデシリアライズ
  factory ChallengeInvitation.fromJson(Map<String, dynamic> json) {
    return ChallengeInvitation(
      invitationId: json['invitationId'] as String? ?? '',
      fromUserId: json['fromUserId'] as String? ?? '',
      fromUserName: json['fromUserName'] as String? ?? 'Unknown',
      toUserId: json['toUserId'] as String? ?? '',
      toUserName: json['toUserName'] as String? ?? 'Unknown',
      status: _statusFromString(json['status'] as String? ?? 'pending'),
      fromScore: json['fromScore'] as int?,
      toScore: json['toScore'] as int?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      expiresAt: json['expiresAt'] is Timestamp
          ? (json['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 7)),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'invitationId': invitationId,
    'fromUserId': fromUserId,
    'fromUserName': fromUserName,
    'toUserId': toUserId,
    'toUserName': toUserName,
    'status': _statusToString(status),
    'fromScore': fromScore,
    'toScore': toScore,
    'createdAt': Timestamp.fromDate(createdAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'expiresAt': Timestamp.fromDate(expiresAt),
  };

  @override
  String toString() =>
      'ChallengeInvitation(from: $fromUserName, to: $toUserName, status: $status)';
}

/// ステータスを文字列に変換
String _statusToString(ChallengeStatus status) {
  switch (status) {
    case ChallengeStatus.pending:
      return 'pending';
    case ChallengeStatus.accepted:
      return 'accepted';
    case ChallengeStatus.completed:
      return 'completed';
    case ChallengeStatus.declined:
      return 'declined';
  }
}

/// 文字列からステータスに変換
ChallengeStatus _statusFromString(String status) {
  switch (status) {
    case 'accepted':
      return ChallengeStatus.accepted;
    case 'completed':
      return ChallengeStatus.completed;
    case 'declined':
      return ChallengeStatus.declined;
    default:
      return ChallengeStatus.pending;
  }
}
