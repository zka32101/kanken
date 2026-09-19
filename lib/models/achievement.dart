/// バッジ/アチーブメント
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementType type;
  final int points;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.points,
    required this.isUnlocked,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'type': type.toString(),
    'points': points,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      type: _parseAchievementType(json['type']),
      points: json['points'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
}

enum AchievementType {
  examScore,        // 試験成績
  streak,          // 連続学習
  category,        // カテゴリ習得
  milestone,       // マイルストーン
  challenge,       // チャレンジ完了
  speed,           // 速度
  accuracy,        // 正答率
}

/// アチーブメント定義
class AchievementDefinition {
  static final List<Achievement> allAchievements = [
    // 試験成績バッジ
    Achievement(
      id: 'exam_90plus',
      name: '優秀者',
      description: '90点以上の成績を獲得',
      icon: '⭐',
      type: AchievementType.examScore,
      points: 100,
      isUnlocked: false,
    ),
    Achievement(
      id: 'exam_80plus',
      name: '良好',
      description: '80点以上の成績を獲得',
      icon: '✨',
      type: AchievementType.examScore,
      points: 50,
      isUnlocked: false,
    ),
    Achievement(
      id: 'exam_perfect',
      name: '完璧',
      description: '100点を獲得',
      icon: '🏆',
      type: AchievementType.examScore,
      points: 200,
      isUnlocked: false,
    ),

    // 連続学習バッジ
    Achievement(
      id: 'streak_7',
      name: '1週間連続学習',
      description: '7日間連続で学習',
      icon: '🔥',
      type: AchievementType.streak,
      points: 50,
      isUnlocked: false,
    ),
    Achievement(
      id: 'streak_30',
      name: '1ヶ月連続学習',
      description: '30日間連続で学習',
      icon: '🌟',
      type: AchievementType.streak,
      points: 150,
      isUnlocked: false,
    ),
    Achievement(
      id: 'streak_100',
      name: '100日チャレンジ',
      description: '100日間連続で学習',
      icon: '💎',
      type: AchievementType.streak,
      points: 500,
      isUnlocked: false,
    ),

    // カテゴリ習得バッジ
    Achievement(
      id: 'category_reading_master',
      name: '読み方マスター',
      description: '「読み」で90%以上の正答率を達成',
      icon: '📖',
      type: AchievementType.category,
      points: 75,
      isUnlocked: false,
    ),
    Achievement(
      id: 'category_meaning_master',
      name: '意味マスター',
      description: '「意味」で90%以上の正答率を達成',
      icon: '📚',
      type: AchievementType.category,
      points: 75,
      isUnlocked: false,
    ),
    Achievement(
      id: 'category_all_master',
      name: 'グランドマスター',
      description: 'すべてのカテゴリで90%以上を達成',
      icon: '👑',
      type: AchievementType.category,
      points: 300,
      isUnlocked: false,
    ),

    // マイルストーン
    Achievement(
      id: 'exam_10',
      name: '10回受験者',
      description: '試験を10回受験',
      icon: '🎯',
      type: AchievementType.milestone,
      points: 50,
      isUnlocked: false,
    ),
    Achievement(
      id: 'exam_50',
      name: '50回受験者',
      description: '試験を50回受験',
      icon: '🚀',
      type: AchievementType.milestone,
      points: 150,
      isUnlocked: false,
    ),
    Achievement(
      id: 'exam_100',
      name: '100回受験者',
      description: '試験を100回受験',
      icon: '🌠',
      type: AchievementType.milestone,
      points: 300,
      isUnlocked: false,
    ),

    // 速度バッジ
    Achievement(
      id: 'speed_fast',
      name: 'スピードランナー',
      description: '30秒以内に問題を解く (10問以上)',
      icon: '⚡',
      type: AchievementType.speed,
      points: 75,
      isUnlocked: false,
    ),
    Achievement(
      id: 'speed_lightning',
      name: 'ライトニング',
      description: '平均20秒で問題を解く (50問以上)',
      icon: '⚡⚡',
      type: AchievementType.speed,
      points: 150,
      isUnlocked: false,
    ),

    // 正答率バッジ
    Achievement(
      id: 'accuracy_consistent',
      name: 'コンシステント',
      description: '3回連続で80%以上の正答率',
      icon: '🎖️',
      type: AchievementType.accuracy,
      points: 100,
      isUnlocked: false,
    ),
  ];

  static Achievement? getAchievementById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}

AchievementType _parseAchievementType(String? type) {
  if (type == null) return AchievementType.milestone;
  try {
    return AchievementType.values.firstWhere(
      (t) => t.toString() == type,
    );
  } catch (e) {
    return AchievementType.milestone;
  }
}
