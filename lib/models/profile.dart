import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザープロフィール
class UserProfile {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final int level;
  final int experience;
  final int totalBattles;
  final int totalWins;
  final int totalExamsCompleted;
  final double bestExamScore;
  final DateTime createdAt;
  final DateTime lastLogin;

  const UserProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.level,
    required this.experience,
    required this.totalBattles,
    required this.totalWins,
    required this.totalExamsCompleted,
    required this.bestExamScore,
    required this.createdAt,
    required this.lastLogin,
  });

  double get winRate =>
      totalBattles > 0 ? totalWins / totalBattles : 0.0;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'level': level,
    'experience': experience,
    'totalBattles': totalBattles,
    'totalWins': totalWins,
    'totalExamsCompleted': totalExamsCompleted,
    'bestExamScore': bestExamScore,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastLogin': Timestamp.fromDate(lastLogin),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    bio: json['bio'] as String?,
    level: json['level'] as int? ?? 1,
    experience: json['experience'] as int? ?? 0,
    totalBattles: json['totalBattles'] as int? ?? 0,
    totalWins: json['totalWins'] as int? ?? 0,
    totalExamsCompleted: json['totalExamsCompleted'] as int? ?? 0,
    bestExamScore: (json['bestExamScore'] as num?)?.toDouble() ?? 0.0,
    createdAt: json['createdAt'] is Timestamp
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    lastLogin: json['lastLogin'] is Timestamp
        ? (json['lastLogin'] as Timestamp).toDate()
        : DateTime.now(),
  );
}

/// 実績
class Achievement {
  final String achievementId;
  final String userId;
  final String name;
  final String description;
  final String? iconUrl;
  final int rewardPoints;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.achievementId,
    required this.userId,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.rewardPoints,
    required this.isUnlocked,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
    'achievementId': achievementId,
    'userId': userId,
    'name': name,
    'description': description,
    'iconUrl': iconUrl,
    'rewardPoints': rewardPoints,
    'isUnlocked': isUnlocked,
    'unlockedAt':
        unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    achievementId: json['achievementId'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    iconUrl: json['iconUrl'] as String?,
    rewardPoints: json['rewardPoints'] as int? ?? 0,
    isUnlocked: json['isUnlocked'] as bool? ?? false,
    unlockedAt: json['unlockedAt'] is Timestamp
        ? (json['unlockedAt'] as Timestamp).toDate()
        : null,
  );
}

/// レベルシステムの報酬
class LevelReward {
  final int level;
  final int requiredExperience;
  final int rewardCoins;
  final int rewardDiamonds;

  const LevelReward({
    required this.level,
    required this.requiredExperience,
    required this.rewardCoins,
    required this.rewardDiamonds,
  });

  Map<String, dynamic> toJson() => {
    'level': level,
    'requiredExperience': requiredExperience,
    'rewardCoins': rewardCoins,
    'rewardDiamonds': rewardDiamonds,
  };

  factory LevelReward.fromJson(Map<String, dynamic> json) => LevelReward(
    level: json['level'] as int,
    requiredExperience: json['requiredExperience'] as int? ?? 0,
    rewardCoins: json['rewardCoins'] as int? ?? 0,
    rewardDiamonds: json['rewardDiamonds'] as int? ?? 0,
  );
}
