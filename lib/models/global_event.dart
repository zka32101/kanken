import 'package:cloud_firestore/cloud_firestore.dart';

/// イベントステータス
enum EventStatus {
  upcoming,   // 開始前
  active,     // 実行中
  ended,      // 終了済み
}

/// イベントタイプ
enum EventType {
  daily,      // デイリーチャレンジ
  weekly,     // 週間イベント
  monthly,    // 月間イベント
  special,    // 特別イベント
}

/// グローバルイベント
class GlobalEvent {
  final String eventId;
  final String eventName;
  final String description;
  final EventType type;
  final EventStatus status;
  final DateTime startAt;
  final DateTime endAt;
  final String targetCategory;        // 対象カテゴリー
  final int targetScore;              // 目標スコア
  final int participantCount;         // 参加者数
  final Map<String, dynamic> rewards; // 報酬 {rank: coins/exp}
  final String bannerImageUrl;        // イベントバナー URL

  const GlobalEvent({
    required this.eventId,
    required this.eventName,
    required this.description,
    required this.type,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.targetCategory,
    required this.targetScore,
    required this.participantCount = 0,
    this.rewards = const {},
    this.bannerImageUrl = '',
  });

  /// イベント経過日数
  int get elapsedDays => DateTime.now().difference(startAt).inDays;

  /// イベント残り日数
  int get remainingDays => endAt.difference(DateTime.now()).inDays;

  /// イベント進捗率（0-100）
  int getProgressPercentage() {
    final total = endAt.difference(startAt).inDays;
    if (total <= 0) return 0;
    final elapsed = elapsedDays;
    return ((elapsed / total) * 100).toInt().clamp(0, 100);
  }

  /// イベント期間表示（日本語）
  String getPeriodLabel() {
    switch (type) {
      case EventType.daily:
        return '日替わり';
      case EventType.weekly:
        return '週間';
      case EventType.monthly:
        return '月間';
      case EventType.special:
        return '特別';
    }
  }

  /// ステータスラベル
  String getStatusLabel() {
    switch (status) {
      case EventStatus.upcoming:
        return '開始前';
      case EventStatus.active:
        return '実行中';
      case EventStatus.ended:
        return '終了';
    }
  }

  /// ステータス絵文字
  String getStatusEmoji() {
    switch (status) {
      case EventStatus.upcoming:
        return '⏳';
      case EventStatus.active:
        return '🔥';
      case EventStatus.ended:
        return '✅';
    }
  }

  /// イベント開始判定
  bool get isActive => status == EventStatus.active;

  /// イベント参加可能判定
  bool get canParticipate => status == EventStatus.active;

  /// 報酬を取得
  int getRewardForRank(int rank) {
    return rewards['rank_$rank'] as int? ?? 0;
  }

  /// JSON からのデシリアライズ
  factory GlobalEvent.fromJson(Map<String, dynamic> json) {
    return GlobalEvent(
      eventId: json['eventId'] as String? ?? '',
      eventName: json['eventName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: _typeFromString(json['type'] as String? ?? 'special'),
      status: _statusFromString(json['status'] as String? ?? 'upcoming'),
      startAt: json['startAt'] is Timestamp
          ? (json['startAt'] as Timestamp).toDate()
          : DateTime.now(),
      endAt: json['endAt'] is Timestamp
          ? (json['endAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 7)),
      targetCategory: json['targetCategory'] as String? ?? '',
      targetScore: json['targetScore'] as int? ?? 100,
      participantCount: json['participantCount'] as int? ?? 0,
      rewards: json['rewards'] as Map<String, dynamic>? ?? {},
      bannerImageUrl: json['bannerImageUrl'] as String? ?? '',
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'eventName': eventName,
    'description': description,
    'type': _typeToString(type),
    'status': _statusToString(status),
    'startAt': Timestamp.fromDate(startAt),
    'endAt': Timestamp.fromDate(endAt),
    'targetCategory': targetCategory,
    'targetScore': targetScore,
    'participantCount': participantCount,
    'rewards': rewards,
    'bannerImageUrl': bannerImageUrl,
  };

  @override
  String toString() =>
      'GlobalEvent(name: $eventName, type: ${getPeriodLabel()}, status: ${getStatusLabel()})';
}

/// イベントタイプを文字列に変換
String _typeToString(EventType type) {
  switch (type) {
    case EventType.daily:
      return 'daily';
    case EventType.weekly:
      return 'weekly';
    case EventType.monthly:
      return 'monthly';
    case EventType.special:
      return 'special';
  }
}

/// 文字列からイベントタイプに変換
EventType _typeFromString(String type) {
  switch (type) {
    case 'daily':
      return EventType.daily;
    case 'weekly':
      return EventType.weekly;
    case 'monthly':
      return EventType.monthly;
    case 'special':
      return EventType.special;
    default:
      return EventType.special;
  }
}

/// ステータスを文字列に変換
String _statusToString(EventStatus status) {
  switch (status) {
    case EventStatus.upcoming:
      return 'upcoming';
    case EventStatus.active:
      return 'active';
    case EventStatus.ended:
      return 'ended';
  }
}

/// 文字列からステータスに変換
EventStatus _statusFromString(String status) {
  switch (status) {
    case 'active':
      return EventStatus.active;
    case 'ended':
      return EventStatus.ended;
    default:
      return EventStatus.upcoming;
  }
}

/// イベント参加記録
class EventParticipation {
  final String participationId;
  final String eventId;
  final String userId;
  final String userName;
  final int currentScore;
  final bool isCompleted;
  final int rank;                // 参加者内の順位
  final int rewardCoins;         // 獲得コイン
  final DateTime joinedAt;
  final DateTime? completedAt;

  const EventParticipation({
    required this.participationId,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.currentScore,
    required this.isCompleted,
    required this.rank,
    required this.rewardCoins,
    required this.joinedAt,
    this.completedAt,
  });

  /// 目標達成判定
  bool isGoalAchieved(int targetScore) => currentScore >= targetScore;

  /// ランクメダル表示
  String getRankBadge() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '${rank}位';
    }
  }

  /// JSON からのデシリアライズ
  factory EventParticipation.fromJson(Map<String, dynamic> json) {
    return EventParticipation(
      participationId: json['participationId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown',
      currentScore: json['currentScore'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      rank: json['rank'] as int? ?? 0,
      rewardCoins: json['rewardCoins'] as int? ?? 0,
      joinedAt: json['joinedAt'] is Timestamp
          ? (json['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'participationId': participationId,
    'eventId': eventId,
    'userId': userId,
    'userName': userName,
    'currentScore': currentScore,
    'isCompleted': isCompleted,
    'rank': rank,
    'rewardCoins': rewardCoins,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
  };

  @override
  String toString() =>
      'EventParticipation(user: $userName, rank: $rank, score: $currentScore)';
}
