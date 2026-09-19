import 'package:cloud_firestore/cloud_firestore.dart';

/// フレンドチャレンジの状態
enum ChallengeStatus {
  pending,    // 待機中
  accepted,   // 受け入れられた
  completed,  // 完了
  declined,   // 拒否された
}

/// フレンドチャレンジ
class FriendChallenge {
  final String challengeId;
  final String challengerUserId;
  final String challengerName;
  final String challengeeUserId;
  final String changetesName;
  final ChallengeStatus status;
  final int targetScore;
  final String description;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime dueAt;
  final int? challengerScore;
  final int? challengeeScore;

  const FriendChallenge({
    required this.challengeId,
    required this.challengerUserId,
    required this.challengerName,
    required this.challengeeUserId,
    required this.changetesName,
    required this.status,
    required this.targetScore,
    required this.description,
    required this.createdAt,
    this.acceptedAt,
    required this.dueAt,
    this.challengerScore,
    this.challengeeScore,
  });

  /// チャレンジが期限切れか判定
  bool get isExpired => DateTime.now().isAfter(dueAt);

  /// チャレンジが完了したか判定
  bool get isFinished => status == ChallengeStatus.completed || status == ChallengeStatus.declined;

  /// 勝者を判定（スコアが高い方が勝者）
  String? getWinner() {
    if (challengerScore == null || challengeeScore == null) return null;
    if (challengerScore! > challengeeScore!) return challengerUserId;
    if (challengeeScore! > challengerScore!) return challengeeUserId;
    return null; // 同点
  }

  /// JSON からのデシリアライズ
  factory FriendChallenge.fromJson(Map<String, dynamic> json) {
    return FriendChallenge(
      challengeId: json['challengeId'] as String? ?? '',
      challengerUserId: json['challengerUserId'] as String? ?? '',
      challengerName: json['challengerName'] as String? ?? 'Unknown',
      challengeeUserId: json['challengeeUserId'] as String? ?? '',
      changetesName: json['changetesName'] as String? ?? 'Unknown',
      status: _statusFromString(json['status'] as String? ?? 'pending'),
      targetScore: json['targetScore'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      acceptedAt: json['acceptedAt'] is Timestamp
          ? (json['acceptedAt'] as Timestamp).toDate()
          : null,
      dueAt: json['dueAt'] is Timestamp
          ? (json['dueAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 7)),
      challengerScore: json['challengerScore'] as int?,
      challengeeScore: json['challengeeScore'] as int?,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'challengeId': challengeId,
    'challengerUserId': challengerUserId,
    'challengerName': challengerName,
    'challengeeUserId': challengeeUserId,
    'changetesName': changetesName,
    'status': _statusToString(status),
    'targetScore': targetScore,
    'description': description,
    'createdAt': Timestamp.fromDate(createdAt),
    'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    'dueAt': Timestamp.fromDate(dueAt),
    'challengerScore': challengerScore,
    'challengeeScore': challengeeScore,
  };
}

/// チャレンジステータスを文字列に変換
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

/// 文字列からチャレンジステータスに変換
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
