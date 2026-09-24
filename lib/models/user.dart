class User {
  final String uid;
  // 1つのFirebase Authアカウント(uid)の下に複数の学習者プロフィールを
  // 持たせるためのID。users/{uid}/profiles/{profileId} に保存される。
  // 既定は 'default'（プロフィール機能を使わない既存ユーザーもこれで動く）。
  final String profileId;
  final String displayName;
  final String avatarIcon; // プロフィール識別用の絵文字アイコン
  final String currentLevel;
  final int streakCount;
  final DateTime createdAt;
  final DateTime? examDate; // 受験予定日（未設定ならnull）
  final bool rankingOptIn; // ランキング参加設定（デフォルト不参加）
  final int masteryThreshold; // この回数連続正解した問題は出題対象から外す

  User({
    required this.uid,
    this.profileId = 'default',
    this.displayName = '',
    this.avatarIcon = '🙂',
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
      profileId: json['profileId'] as String? ?? 'default',
      displayName: json['displayName'] ?? '',
      avatarIcon: json['avatarIcon'] as String? ?? '🙂',
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
      'profileId': profileId,
      'displayName': displayName,
      'avatarIcon': avatarIcon,
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
    String? profileId,
    String? displayName,
    String? avatarIcon,
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
      profileId: profileId ?? this.profileId,
      displayName: displayName ?? this.displayName,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      currentLevel: currentLevel ?? this.currentLevel,
      streakCount: streakCount ?? this.streakCount,
      createdAt: createdAt ?? this.createdAt,
      examDate: clearExamDate ? null : (examDate ?? this.examDate),
      rankingOptIn: rankingOptIn ?? this.rankingOptIn,
      masteryThreshold: masteryThreshold ?? this.masteryThreshold,
    );
  }
}
