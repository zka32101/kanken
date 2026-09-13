import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collection_badge.dart';
import '../providers/collection_badge_provider.dart';

class CollectionBadgeScreen extends ConsumerStatefulWidget {
  const CollectionBadgeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CollectionBadgeScreen> createState() =>
      _CollectionBadgeScreenState();
}

class _CollectionBadgeScreenState extends ConsumerState<CollectionBadgeScreen> {
  BadgeCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(badgeCollectionStatsProvider);
    final badgesAsync = ref.watch(allBadgesProvider);
    final progressAsync = ref.watch(userBadgeProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎖️ バッジコレクション'),
        centerTitle: true,
        backgroundColor: Colors.amber.shade50,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // コレクション統計カード
              _buildStatsCard(stats),
              const SizedBox(height: 20),

              // カテゴリーフィルター
              _buildCategoryFilter(),
              const SizedBox(height: 16),

              // バッジ一覧
              badgesAsync.when(
                data: (badges) => progressAsync.when(
                  data: (progress) =>
                      _buildBadgeGrid(badges, progress),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) =>
                      Center(child: Text('エラー: $error')),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('エラー: $error')),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  /// 統計カード
  Widget _buildStatsCard(BadgeCollectionStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 コレクション状態',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 統計タイル
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatTile(
                icon: '🎖️',
                label: '取得済み',
                value: '${stats.acquiredCount}',
              ),
              _buildStatTile(
                icon: '📚',
                label: '総数',
                value: '${stats.totalBadges}',
              ),
              _buildStatTile(
                icon: '🔒',
                label: '隠しバッジ',
                value: '${stats.acquiredHiddenCount}/${stats.hiddenBadges}',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // コンプリート率バー
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'コンプリート率',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(stats.getCompletionPercentage() * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: stats.getCompletionPercentage(),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 統計タイル
  Widget _buildStatTile({
    required String icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// カテゴリーフィルター
  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('すべて'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = null);
                }
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.amber.shade300,
              labelStyle: TextStyle(
                color: _selectedCategory == null ? Colors.white : Colors.black87,
                fontWeight: _selectedCategory == null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            for (final category in BadgeCategory.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_getCategoryLabel(category)),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.amber.shade300,
                  labelStyle: TextStyle(
                    color: _selectedCategory == category
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: _selectedCategory == category
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// バッジグリッド
  Widget _buildBadgeGrid(
    List<CollectionBadge> badges,
    List<UserBadgeProgress> progress,
  ) {
    final filtered = _selectedCategory == null
        ? badges
        : badges.where((b) => b.category == _selectedCategory).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'バッジがありません',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final badge = filtered[index];
          final badgeProgress = progress.firstWhere(
            (p) => p.badgeId == badge.badgeId,
            orElse: () => UserBadgeProgress(
              progressId: '',
              userId: '',
              badgeId: badge.badgeId,
              currentCount: 0,
              isAcquired: false,
              lastUpdatedAt: DateTime.now(),
            ),
          );

          return _buildBadgeTile(badge, badgeProgress);
        },
      ),
    );
  }

  /// バッジタイル
  Widget _buildBadgeTile(
    CollectionBadge badge,
    UserBadgeProgress progress,
  ) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(badge, progress),
      child: Container(
        decoration: BoxDecoration(
          color: progress.isAcquired
              ? Color(badge.getRarityColor()).withOpacity(0.2)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: progress.isAcquired
                ? Color(badge.getRarityColor()).withOpacity(0.5)
                : Colors.grey.shade300,
            width: progress.isAcquired ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge.iconEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (!progress.isAcquired)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade400,
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Positioned(
                top: 4,
                right: 4,
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// バッジ詳細ダイアログ
  void _showBadgeDetail(
    CollectionBadge badge,
    UserBadgeProgress progress,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Text(
              badge.iconEmoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(badge.name),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 説明
              Text(
                badge.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // レアリティ・カテゴリー
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'レアリティ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(badge.getRarityColor())
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge.getRarityLabel(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(badge.getRarityColor()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'カテゴリー',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge.getCategoryLabel(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 獲得条件
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '獲得条件',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.conditionText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 進捗
              if (!progress.isAcquired)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '進捗',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.getProgress(badge.requiredCount),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.currentCount} / ${badge.requiredCount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '取得済み',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (progress.acquiredAt != null)
                              Text(
                                '${progress.acquiredAt!.year}年${progress.acquiredAt!.month}月${progress.acquiredAt!.day}日',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// カテゴリーラベル取得
  String _getCategoryLabel(BadgeCategory category) {
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
}
