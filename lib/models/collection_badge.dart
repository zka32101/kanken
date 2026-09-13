import 'package:cloud_firestore/cloud_firestore.dart';

/// バッジのレアリティ
enum BadgeRarity {
  common,      // 一般
  uncommon,    // レア
  rare,        // 超レア
  epic,        // エピック
  legendary,   // 伝説
}

/// バッジのカテゴリー
enum BadgeCategory {
  achievement, // 達成
  streak,      // ストリーク
  challenge,   // チャレンジ
  event,       // イベント
  special,     // スペシャル
}

/// コレクションバッジ
class CollectionBadge {
  final String badgeId;
  final String name;
  final String description;
  final BadgeRarity rarity;
  final BadgeCategory category;
  final String iconEmoji;
  final int requiredCount;          // 獲得に必要な条件値
  final String conditionText;       // 条件テキスト
  final bool isHidden;              // 隠しバッジ
  final int rewardCoins;            // 獲得時のコイン報酬
  final DateTime createdAt;

  const CollectionBadge({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.rarity,
    required this.category,
    required this.iconEmoji,
    required this.requiredCount,
    required this.conditionText,
    this.isHidden = false,
    this.rewardCoins = 0,
    required this.createdAt,
  });

  /// レアリティラベル（日本語）
  String getRarityLabel() {
    switch (rarity) {
      case BadgeRarity.common:
        return '一般';
      case BadgeRarity.uncommon:
        return 'レア';
      case BadgeRarity.rare:
        return '超レア';
      case BadgeRarity.epic:
        return 'エピック';
      case BadgeRarity.legendary:
        return '伝説';
    }
  }

  /// レアリティカラー
  int getRarityColor() {
    switch (rarity) {
      case BadgeRarity.common:
        return 0xFF9E9E9E; // 灰色
      case BadgeRarity.uncommon:
        return 0xFF4CAF50; // 緑
      case BadgeRarity.rare:
        return 0xFF2196F3; // 青
      case BadgeRarity.epic:
        return 0xFF9C27B0; // 紫
      case BadgeRarity.legendary:
        return 0xFFFFD700; // 金色
    }
  }

  /// カテゴリーラベル（日本語）
  String getCategoryLabel() {
    switch (category) {
      case BadgeCategory.achievement:
        return '達成';
      case BadgeCategory.streak:
        return 'ストリーク';
      case BadgeCategory.challenge:
        return 'チャレンジ';
      case BadgeCategory.event:
        return 'イベント';
      case BadgeCategory.special:
        return 'スペシャル';
    }
  }

  /// JSON からのデシリアライズ
  factory CollectionBadge.fromJson(Map<String, dynamic> json) {
    return CollectionBadge(
      badgeId: json['badgeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rarity: _rarityFromString(json['rarity'] as String? ?? 'common'),
      category: _categoryFromString(json['category'] as String? ?? 'achievement'),
      iconEmoji: json['iconEmoji'] as String? ?? '🎖️',
      requiredCount: json['requiredCount'] as int? ?? 0,
      conditionText: json['conditionText'] as String? ?? '',
      isHidden: json['isHidden'] as bool? ?? false,
      rewardCoins: json['rewardCoins'] as int? ?? 0,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'badgeId': badgeId,
    'name': name,
    'description': description,
    'rarity': _rarityToString(rarity),
    'category': _categoryToString(category),
    'iconEmoji': iconEmoji,
    'requiredCount': requiredCount,
    'conditionText': conditionText,
    'isHidden': isHidden,
    'rewardCoins': rewardCoins,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  @override
  String toString() =>
      'CollectionBadge(name: $name, rarity: ${getRarityLabel()}, category: ${getCategoryLabel()})';
}

/// ユーザーのバッジ取得記録
class UserBadgeProgress {
  final String progressId;
  final String userId;
  final String badgeId;
  final int currentCount;
  final bool isAcquired;
  final DateTime? acquiredAt;
  final DateTime lastUpdatedAt;

  const UserBadgeProgress({
    required this.progressId,
    required this.userId,
    required this.badgeId,
    required this.currentCount,
    required this.isAcquired,
    this.acquiredAt,
    required this.lastUpdatedAt,
  });

  /// 達成度（0.0 - 1.0）
  double getProgress(int requiredCount) {
    if (requiredCount <= 0) return 0;
    return (currentCount / requiredCount).clamp(0, 1);
  }

  /// 達成度パーセンテージ
  String getProgressPercentage(int requiredCount) {
    final progress = getProgress(requiredCount);
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  /// 達成可能判定
  bool canAcquire(int requiredCount) {
    return !isAcquired && currentCount >= requiredCount;
  }

  /// JSON からのデシリアライズ
  factory UserBadgeProgress.fromJson(Map<String, dynamic> json) {
    return UserBadgeProgress(
      progressId: json['progressId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      badgeId: json['badgeId'] as String? ?? '',
      currentCount: json['currentCount'] as int? ?? 0,
      isAcquired: json['isAcquired'] as bool? ?? false,
      acquiredAt: json['acquiredAt'] is Timestamp
          ? (json['acquiredAt'] as Timestamp).toDate()
          : null,
      lastUpdatedAt: json['lastUpdatedAt'] is Timestamp
          ? (json['lastUpdatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'progressId': progressId,
    'userId': userId,
    'badgeId': badgeId,
    'currentCount': currentCount,
    'isAcquired': isAcquired,
    'acquiredAt': acquiredAt != null ? Timestamp.fromDate(acquiredAt!) : null,
    'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
  };

  @override
  String toString() =>
      'UserBadgeProgress(badgeId: $badgeId, progress: $currentCount, acquired: $isAcquired)';
}

/// バッジコレクション統計
class BadgeCollectionStats {
  final int totalBadges;
  final int acquiredCount;
  final int hiddenBadges;
  final int acquiredHiddenCount;
  final List<UserBadgeProgress> allProgress;

  const BadgeCollectionStats({
    required this.totalBadges,
    required this.acquiredCount,
    required this.hiddenBadges,
    required this.acquiredHiddenCount,
    required this.allProgress,
  });

  /// コンプリート率（隠しバッジ含む）
  double getCompletionPercentage() {
    if (totalBadges <= 0) return 0;
    return acquiredCount / totalBadges;
  }

  /// コンプリート率（隠しバッジ除く）
  double getVisibleCompletionPercentage() {
    final visibleTotal = totalBadges - hiddenBadges;
    if (visibleTotal <= 0) return 0;
    return acquiredCount / visibleTotal;
  }

  /// 隠しバッジの発見率
  double getHiddenDiscoveryPercentage() {
    if (hiddenBadges <= 0) return 0;
    return acquiredHiddenCount / hiddenBadges;
  }

  /// ステータステキスト
  String getStatusText() {
    return '$acquiredCount / $totalBadges バッジ取得済み';
  }
}

/// レアリティを文字列に変換
String _rarityToString(BadgeRarity rarity) {
  switch (rarity) {
    case BadgeRarity.common:
      return 'common';
    case BadgeRarity.uncommon:
      return 'uncommon';
    case BadgeRarity.rare:
      return 'rare';
    case BadgeRarity.epic:
      return 'epic';
    case BadgeRarity.legendary:
      return 'legendary';
  }
}

/// 文字列からレアリティに変換
BadgeRarity _rarityFromString(String rarity) {
  switch (rarity) {
    case 'uncommon':
      return BadgeRarity.uncommon;
    case 'rare':
      return BadgeRarity.rare;
    case 'epic':
      return BadgeRarity.epic;
    case 'legendary':
      return BadgeRarity.legendary;
    default:
      return BadgeRarity.common;
  }
}

/// カテゴリーを文字列に変換
String _categoryToString(BadgeCategory category) {
  switch (category) {
    case BadgeCategory.achievement:
      return 'achievement';
    case BadgeCategory.streak:
      return 'streak';
    case BadgeCategory.challenge:
      return 'challenge';
    case BadgeCategory.event:
      return 'event';
    case BadgeCategory.special:
      return 'special';
  }
}

/// 文字列からカテゴリーに変換
BadgeCategory _categoryFromString(String category) {
  switch (category) {
    case 'streak':
      return BadgeCategory.streak;
    case 'challenge':
      return BadgeCategory.challenge;
    case 'event':
      return BadgeCategory.event;
    case 'special':
      return BadgeCategory.special;
    default:
      return BadgeCategory.achievement;
  }
}
