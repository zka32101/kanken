import 'package:cloud_firestore/cloud_firestore.dart';

/// 対戦参加者
class BattleParticipant {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int currentScore;
  final int correctAnswers;
  final int level;
  final DateTime joinedAt;
  final bool isReady;
  final bool isFinished;

  const BattleParticipant({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.currentScore,
    required this.correctAnswers,
    required this.level,
    required this.joinedAt,
    required this.isReady,
    required this.isFinished,
  });

  /// JSON からのデシリアライズ
  factory BattleParticipant.fromJson(Map<String, dynamic> json) {
    return BattleParticipant(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      currentScore: json['currentScore'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      level: json['level'] as int? ?? 10,
      joinedAt: json['joinedAt'] is Timestamp
          ? (json['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isReady: json['isReady'] as bool? ?? false,
      isFinished: json['isFinished'] as bool? ?? false,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'currentScore': currentScore,
    'correctAnswers': correctAnswers,
    'level': level,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'isReady': isReady,
    'isFinished': isFinished,
  };
}

/// 対戦ルーム
class BattleRoom {
  final String roomId;
  final String creatorId;
  final String roomName;
  final int examLevel; // 10-5級
  final int maxParticipants;
  final List<BattleParticipant> participants;
  final String status; // waiting/playing/finished
  final int totalQuestions;
  final int timePerQuestionSeconds;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const BattleRoom({
    required this.roomId,
    required this.creatorId,
    required this.roomName,
    required this.examLevel,
    required this.maxParticipants,
    required this.participants,
    required this.status,
    required this.totalQuestions,
    required this.timePerQuestionSeconds,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  /// ルームが開始可能か判定
  bool canStart() {
    return status == 'waiting' && participants.length >= 2;
  }

  /// ルームが満員か判定
  bool isFull() {
    return participants.length >= maxParticipants;
  }

  /// 参加可能か判定
  bool canJoin() {
    return status == 'waiting' && !isFull();
  }

  /// プレイヤーをルームから取得
  BattleParticipant? getParticipant(String userId) {
    try {
      return participants.firstWhere((p) => p.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// JSON からのデシリアライズ
  factory BattleRoom.fromJson(Map<String, dynamic> json) {
    final participantsData = json['participants'] as List? ?? [];
    final participants = participantsData
        .map((p) => BattleParticipant.fromJson(p as Map<String, dynamic>))
        .toList();

    return BattleRoom(
      roomId: json['roomId'] as String? ?? '',
      creatorId: json['creatorId'] as String? ?? '',
      roomName: json['roomName'] as String? ?? '',
      examLevel: json['examLevel'] as int? ?? 10,
      maxParticipants: json['maxParticipants'] as int? ?? 2,
      participants: participants,
      status: json['status'] as String? ?? 'waiting',
      totalQuestions: json['totalQuestions'] as int? ?? 10,
      timePerQuestionSeconds: json['timePerQuestionSeconds'] as int? ?? 60,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      startedAt: json['startedAt'] is Timestamp
          ? (json['startedAt'] as Timestamp).toDate()
          : null,
      finishedAt: json['finishedAt'] is Timestamp
          ? (json['finishedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'creatorId': creatorId,
    'roomName': roomName,
    'examLevel': examLevel,
    'maxParticipants': maxParticipants,
    'participants': participants.map((p) => p.toJson()).toList(),
    'status': status,
    'totalQuestions': totalQuestions,
    'timePerQuestionSeconds': timePerQuestionSeconds,
    'createdAt': Timestamp.fromDate(createdAt),
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
  };
}

/// 対戦結果
class BattleResult {
  final String resultId;
  final String roomId;
  final String winnerId; // 最高スコアを獲得したユーザーID
  final List<BattleParticipant> finalParticipants;
  final int totalDurationSeconds;
  final DateTime completedAt;
  final Map<String, dynamic> statistics; // 詳細統計

  const BattleResult({
    required this.resultId,
    required this.roomId,
    required this.winnerId,
    required this.finalParticipants,
    required this.totalDurationSeconds,
    required this.completedAt,
    required this.statistics,
  });

  /// 1位のスコア取得
  int getFirstPlaceScore() {
    if (finalParticipants.isEmpty) return 0;
    return finalParticipants.first.currentScore;
  }

  /// ランキング取得（スコア順にソート）
  List<BattleParticipant> getRanking() {
    final sorted = List<BattleParticipant>.from(finalParticipants);
    sorted.sort((a, b) => b.currentScore.compareTo(a.currentScore));
    return sorted;
  }

  /// JSON からのデシリアライズ
  factory BattleResult.fromJson(Map<String, dynamic> json) {
    final participantsData = json['finalParticipants'] as List? ?? [];
    final participants = participantsData
        .map((p) => BattleParticipant.fromJson(p as Map<String, dynamic>))
        .toList();

    return BattleResult(
      resultId: json['resultId'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      winnerId: json['winnerId'] as String? ?? '',
      finalParticipants: participants,
      totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
      completedAt: json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp).toDate()
          : DateTime.now(),
      statistics: json['statistics'] as Map<String, dynamic>? ?? {},
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'resultId': resultId,
    'roomId': roomId,
    'winnerId': winnerId,
    'finalParticipants':
        finalParticipants.map((p) => p.toJson()).toList(),
    'totalDurationSeconds': totalDurationSeconds,
    'completedAt': Timestamp.fromDate(completedAt),
    'statistics': statistics,
  };
}

/// 対戦ルーム統計
class BattleRoomStats {
  final String userId;
  final int totalBattles;
  final int victories;
  final int defeats;
  final double averageScore;
  final int bestScore;
  final int highestRank; // 1位の回数

  const BattleRoomStats({
    required this.userId,
    required this.totalBattles,
    required this.victories,
    required this.defeats,
    required this.averageScore,
    required this.bestScore,
    required this.highestRank,
  });

  /// 勝率
  double getWinRate() {
    if (totalBattles == 0) return 0;
    return victories / totalBattles;
  }

  /// 勝敗レコード（例：10-5）
  String getRecord() {
    return '$victories-$defeats';
  }

  /// JSON からのデシリアライズ
  factory BattleRoomStats.fromJson(Map<String, dynamic> json) {
    return BattleRoomStats(
      userId: json['userId'] as String? ?? '',
      totalBattles: json['totalBattles'] as int? ?? 0,
      victories: json['victories'] as int? ?? 0,
      defeats: json['defeats'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      bestScore: json['bestScore'] as int? ?? 0,
      highestRank: json['highestRank'] as int? ?? 0,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalBattles': totalBattles,
    'victories': victories,
    'defeats': defeats,
    'averageScore': averageScore,
    'bestScore': bestScore,
    'highestRank': highestRank,
  };
}

/// リアルタイム対戦セッション
class BattleSession {
  final String sessionId;
  final String roomId;
  final int currentQuestionIndex;
  final Map<String, int> participantScores; // userId -> score
  final Map<String, int> participantCorrectAnswers; // userId -> correctAnswers
  final int elapsedSeconds;
  final bool isActive;

  const BattleSession({
    required this.sessionId,
    required this.roomId,
    required this.currentQuestionIndex,
    required this.participantScores,
    required this.participantCorrectAnswers,
    required this.elapsedSeconds,
    required this.isActive,
  });

  /// JSON からのデシリアライズ
  factory BattleSession.fromJson(Map<String, dynamic> json) {
    return BattleSession(
      sessionId: json['sessionId'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      participantScores:
          Map<String, int>.from(json['participantScores'] as Map? ?? {}),
      participantCorrectAnswers: Map<String, int>.from(
          json['participantCorrectAnswers'] as Map? ?? {}),
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'roomId': roomId,
    'currentQuestionIndex': currentQuestionIndex,
    'participantScores': participantScores,
    'participantCorrectAnswers': participantCorrectAnswers,
    'elapsedSeconds': elapsedSeconds,
    'isActive': isActive,
  };
}
