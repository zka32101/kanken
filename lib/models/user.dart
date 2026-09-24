class User {
  final String uid;
  final String displayName;
  final String currentLevel;
  final int streakCount;
  final DateTime createdAt;
  final DateTime? examDate; // 受験予定日（未設定ならnull）
  final bool rankingOptIn; // ランキング参加設定（デフォルト不参加）
  final int masteryThreshold; // この回数連続正解した問題は出題対象から外す

  User({
    required this.uid,
    this.displayName = '',
    required this.currentLevel,
    required this.streakCount,
    required this.createdAt,
    this.examDate,
    this.rankingOptIn = false,
    this.masteryThreshold = 3,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? '',
      currentLevel: json['currentLevel'] ?? 'LEVEL_10',
      streakCount: json['streakCount'] ?? 0,
      createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
      examDate: json['examDate'] != null
        ? DateTime.parse(json['examDate'])
        : null,
      rankingOptIn: json['rankingOptIn'] as bool? ?? false,
      masteryThreshold: json['masteryThreshold'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'currentLevel': currentLevel,
      'streakCount': streakCount,
      'createdAt': createdAt.toIso8601String(),
      'examDate': examDate?.toIso8601String(),
      'rankingOptIn': rankingOptIn,
      'masteryThreshold': masteryThreshold,
    };
  }

  User copyWith({
    String? uid,
    String? displayName,
    String? currentLevel,
    int? streakCount,
    DateTime? createdAt,
    DateTime? examDate,
    bool clearExamDate = false,
    bool? rankingOptIn,
    int? masteryThreshold,
  }) {
    return User(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      currentLevel: currentLevel ?? this.currentLevel,
      streakCount: streakCount ?? this.streakCount,
      createdAt: createdAt ?? this.createdAt,
      examDate: clearExamDate ? null : (examDate ?? this.examDate),
      rankingOptIn: rankingOptIn ?? this.rankingOptIn,
      masteryThreshold: masteryThreshold ?? this.masteryThreshold,
    );
  }
}
