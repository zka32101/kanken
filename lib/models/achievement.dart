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
  social,          // ソーシャル
  review,          // 復習・間隔反復
  goal,            // 学習目標達成
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

    // カテゴリ習得バッジ（追加分）
    Achievement(
      id: 'category_stroke_master',
      name: '筆順マスター',
      description: '「筆順」で90%以上の正答率を達成',
      icon: '✍️',
      type: AchievementType.category,
      points: 75,
      isUnlocked: false,
    ),
    Achievement(
      id: 'category_writing_master',
      name: '書き取りマスター',
      description: '「書き取り」で90%以上の正答率を達成',
      icon: '📝',
      type: AchievementType.category,
      points: 75,
      isUnlocked: false,
    ),
    Achievement(
      id: 'category_usage_master',
      name: '使い方マスター',
      description: '「使い方」で90%以上の正答率を達成',
      icon: '🈶',
      type: AchievementType.category,
      points: 75,
      isUnlocked: false,
    ),

    // チャレンジバッジ
    Achievement(
      id: 'challenge_win_1',
      name: '初勝利',
      description: 'フレンドチャレンジで初めて勝利',
      icon: '🥊',
      type: AchievementType.challenge,
      points: 50,
      isUnlocked: false,
    ),
    Achievement(
      id: 'challenge_win_5',
      name: '連戦連勝',
      description: 'フレンドチャレンジで5勝達成',
      icon: '🏅',
      type: AchievementType.challenge,
      points: 150,
      isUnlocked: false,
    ),
    Achievement(
      id: 'challenge_win_10',
      name: 'チャンピオン',
      description: 'フレンドチャレンジで10勝達成',
      icon: '🏆',
      type: AchievementType.challenge,
      points: 300,
      isUnlocked: false,
    ),

    // ソーシャルバッジ
    Achievement(
      id: 'social_friends_5',
      name: '友達の輪',
      description: 'フレンドを5人追加',
      icon: '👫',
      type: AchievementType.social,
      points: 50,
      isUnlocked: false,
    ),
    Achievement(
      id: 'social_leaderboard_top10',
      name: 'トップランカー',
      description: 'リーダーボードでTOP10入り',
      icon: '📈',
      type: AchievementType.social,
      points: 150,
      isUnlocked: false,
    ),
    Achievement(
      id: 'social_leaderboard_top3',
      name: 'エリート',
      description: 'リーダーボードでTOP3入り',
      icon: '🥇',
      type: AchievementType.social,
      points: 300,
      isUnlocked: false,
    ),

    // 復習バッジ
    Achievement(
      id: 'review_master_10',
      name: '復習の達人',
      description: '間隔反復学習で10問マスター',
      icon: '🔁',
      type: AchievementType.review,
      points: 75,
      isUnlocked: false,
    ),
    Achievement(
      id: 'review_master_50',
      name: '復習マスター',
      description: '間隔反復学習で50問マスター',
      icon: '🔂',
      type: AchievementType.review,
      points: 200,
      isUnlocked: false,
    ),

    // 学習目標バッジ
    Achievement(
      id: 'goal_first',
      name: '目標達成',
      description: '学習目標を初めて達成',
      icon: '🚩',
      type: AchievementType.goal,
      points: 50,
      isUnlocked: false,
    ),
    Achievement(
      id: 'goal_5',
      name: 'ゴールゲッター',
      description: '学習目標を5個達成',
      icon: '🎌',
      type: AchievementType.goal,
      points: 200,
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
