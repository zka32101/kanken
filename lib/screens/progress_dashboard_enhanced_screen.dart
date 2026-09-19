import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exam_analysis_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/learning_plan_generator_provider.dart';
import '../widgets/progress_visualization.dart';

class ProgressDashboardEnhancedScreen extends ConsumerWidget {
  const ProgressDashboardEnhancedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accumulatedAsync = ref.watch(accumulatedCategoryPerformanceProvider);
    final achievementStatsAsync = ref.watch(achievementStatsProvider);
    final learningPlanAsync = ref.watch(learningPlanGeneratorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学習進捗'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // サマリーカード
              _buildSummaryCards(
                context,
                accumulatedAsync,
                achievementStatsAsync,
              ),
              const SizedBox(height: 24),

              // カテゴリ別進捗
              _buildCategoryProgress(context, accumulatedAsync),
              const SizedBox(height: 24),

              // 週間学習目標
              _buildWeeklyGoal(context, learningPlanAsync),
              const SizedBox(height: 24),

              // アチーブメント統計
              _buildAchievementStats(context, achievementStatsAsync),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AsyncValue<Map<String, CategoryPerformance>> accumulated,
    AsyncValue<AchievementStats> stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '学習統計',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        accumulated.when(
          data: (data) {
            double totalAccuracy = 0.0;
            if (data.isNotEmpty) {
              totalAccuracy = data.values
                      .fold<double>(0.0, (sum, perf) => sum + perf.accuracy) /
                  data.length;
            }

            return stats.when(
              data: (achievementStats) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircularProgressIndicatorWidget(
                      progress: totalAccuracy,
                      label: '総合正答率',
                      value: '${(totalAccuracy * 100).toStringAsFixed(1)}%',
                      backgroundColor: Colors.blue,
                      progressColor: Colors.blue,
                    ),
                    CircularProgressIndicatorWidget(
                      progress: achievementStats.unlockedCount /
                          achievementStats.totalAchievements,
                      label: 'バッジ',
                      value: '${achievementStats.unlockedCount}',
                      backgroundColor: Colors.purple,
                      progressColor: Colors.purple,
                    ),
                    CircularProgressIndicatorWidget(
                      progress:
                          achievementStats.totalPoints > 0
                              ? (achievementStats.totalPoints / 2000)
                                  .clamp(0.0, 1.0)
                              : 0.0,
                      label: 'ポイント',
                      value: '${achievementStats.totalPoints}',
                      backgroundColor: Colors.green,
                      progressColor: Colors.green,
                    ),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const SizedBox.shrink(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCategoryProgress(
    BuildContext context,
    AsyncValue<Map<String, CategoryPerformance>> accumulated,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'カテゴリ別進捗',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        accumulated.when(
          data: (data) {
            if (data.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'まだ試験を受験していません',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              );
            }

            return Column(
              children: data.entries.map((entry) {
                final perf = entry.value;
                return CategoryProgressBar(
                  category: perf.category,
                  progress: perf.accuracy,
                  correctCount: perf.correct,
                  totalCount: perf.total,
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildWeeklyGoal(
    BuildContext context,
    AsyncValue<LearningPlan?> learningPlan,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '週間学習計画',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        learningPlan.when(
          data: (plan) {
            if (plan == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '学習計画がまだ生成されていません',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              );
            }

            // 今週の学習状況を仮定（実際にはFirebaseから取得）
            final targetMinutes = plan.currentWeekSchedule.totalMinutesPerWeek;
            final completedMinutes =
                (targetMinutes * 0.6).toInt(); // 仮の60%達成
            final daysActive = 4;
            const daysTarget = 7;

            return WeeklyGoalCard(
              targetMinutes: targetMinutes,
              completedMinutes: completedMinutes,
              daysActive: daysActive,
              daysTarget: daysTarget,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildAchievementStats(
    BuildContext context,
    AsyncValue<AchievementStats> stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'バッジ統計',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        stats.when(
          data: (achievementStats) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ProgressSpotlight(
                        title: '獲得済みバッジ',
                        value:
                            '${achievementStats.unlockedCount}/${achievementStats.totalAchievements}',
                        subtitle: 'コレクション',
                        icon: Icons.emoji_events,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ProgressSpotlight(
                        title: '合計ポイント',
                        value: '${achievementStats.totalPoints}',
                        subtitle: 'リワード',
                        icon: Icons.star,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (achievementStats.recentlyUnlocked.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '最近獲得したバッジ',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: achievementStats.recentlyUnlocked
                            .take(6)
                            .map((achievement) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.purple.shade200,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  achievement.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  achievement.name,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
