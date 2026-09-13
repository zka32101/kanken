import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics.dart';
import '../providers/analytics_provider.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学習分析'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '成長'),
            Tab(text: '効率'),
            Tab(text: '目標'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrowthTab(),
          _buildEfficiencyTab(),
          _buildGoalsTab(),
        ],
      ),
    );
  }

  Widget _buildGrowthTab() {
    final analytics = ref.watch(userLearningAnalyticsProvider);
    final growthData = ref.watch(userGrowthDataProvider);
    final trends = ref.watch(userLearningTrendsProvider);

    return analytics.when(
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data != null) ...[
              // 統計サマリー
              _buildStatsCard(data),
              const SizedBox(height: 24),

              // 成長グラフ
              Text(
                '過去30日の成長',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              growthData.when(
                data: (growth) => _buildGrowthChart(growth),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('グラフ読み込みエラー'),
              ),
            ] else
              const Center(child: Text('データがありません')),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('エラーが発生しました')),
    );
  }

  Widget _buildStatsCard(LearningAnalytics data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '学習統計',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatItem(
                  '正答率',
                  '${data.accuracyPercentage.toStringAsFixed(1)}%',
                  Colors.blue,
                ),
                _buildStatItem(
                  '学習時間',
                  '${data.totalStudyMinutes}分',
                  Colors.green,
                ),
                _buildStatItem(
                  '正答数',
                  '${data.correctAnswers}',
                  Colors.purple,
                ),
                _buildStatItem(
                  '連続記録',
                  '${data.currentStreak}日',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(List<GrowthData> growthData) {
    if (growthData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'データがありません',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      );
    }

    // 最大値を取得して正規化
    final maxAccuracy =
        growthData.fold<double>(0, (max, g) => g.accuracy > max ? g.accuracy : max);
    final normalizedData = growthData
        .map((g) => (maxAccuracy > 0 ? g.accuracy / maxAccuracy : 0) * 100)
        .toList();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  normalizedData.length,
                  (index) => Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 4,
                        height: 150 * (normalizedData[index] / 100),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '正答率の推移',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyTab() {
    final efficiency = ref.watch(userStudyEfficiencyProvider);
    final trends = ref.watch(userLearningTrendsProvider);

    return efficiency.when(
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data != null) ...[
              // 効率スコア
              _buildEfficiencyCard(data),
              const SizedBox(height: 24),

              // トレンド分析
              Text(
                '分野別トレンド',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              trends.when(
                data: (trendList) => _buildTrendsList(trendList),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('トレンド読み込みエラー'),
              ),
            ] else
              const Center(child: Text('データがありません')),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('エラーが発生しました')),
    );
  }

  Widget _buildEfficiencyCard(StudyEfficiency data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '学習効率',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // 効率スコア
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '効率スコア',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.efficiencyScore.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.trending_up,
                    size: 48,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // メトリクス
            _buildMetricRow(
              '学習時間',
              '${data.minutesStudied}分',
            ),
            const Divider(),
            _buildMetricRow(
              '問題数',
              '${data.questionsCompleted}問',
            ),
            const Divider(),
            _buildMetricRow(
              '正答率',
              '${(data.accuracyRate * 100).toStringAsFixed(1)}%',
            ),
            const Divider(),
            _buildMetricRow(
              '分当たりの問題数',
              '${data.questionsPerMinute.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsList(List<LearningTrend> trends) {
    if (trends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'トレンドデータがありません',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      );
    }

    return Column(
      children: trends.map((trend) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trend.category,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTrendColor(trend.trend).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getTrendIcon(trend.trend),
                            size: 14,
                            color: _getTrendColor(trend.trend),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTrendLabel(trend.trend),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getTrendColor(trend.trend),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // トレンドバー
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: trend.averageTrend,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTrendColor(trend.trend),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '平均値: ${(trend.averageTrend * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      case 'stable':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      case 'stable':
        return Icons.trending_flat;
      default:
        return Icons.help;
    }
  }

  String _getTrendLabel(String trend) {
    switch (trend) {
      case 'up':
        return '上昇';
      case 'down':
        return '下降';
      case 'stable':
        return '安定';
      default:
        return '不明';
    }
  }

  Widget _buildGoalsTab() {
    final dashboardState = ref.watch(analyticsDashboardProvider);
    final goals = ref.watch(userLearningGoalsProvider);

    return goals.when(
      data: (goalList) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '学習目標',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (goalList.isEmpty)
              _buildEmptyGoalsState()
            else
              _buildGoalsList(goalList),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('新しい目標を設定'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showGoalDialog(context, ref),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('エラーが発生しました')),
    );
  }

  Widget _buildEmptyGoalsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '目標を設定して学習を頑張ろう！',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<LearningGoal> goals) {
    return Column(
      children: goals.map((goal) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGoalTypeLabel(goal.goalType),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${goal.type} - 目標: ${goal.targetValue}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.done),
                      onPressed: () {
                        ref
                            .read(analyticsDashboardProvider.notifier)
                            .completeGoal(goal.goalId);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 進捗バー
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goal.progress.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${goal.currentValue} / ${goal.targetValue}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getGoalTypeLabel(String goalType) {
    switch (goalType) {
      case 'accuracy':
        return '正答率';
      case 'questions':
        return '問題数';
      case 'time':
        return '学習時間';
      default:
        return '目標';
    }
  }

  Future<void> _showGoalDialog(BuildContext context, WidgetRef ref) async {
    String selectedType = 'daily';
    String selectedGoalType = 'accuracy';
    int targetValue = 80;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しい目標を設定'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('期間', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'daily', label: Text('日次')),
                        ButtonSegment(value: 'weekly', label: Text('週次')),
                        ButtonSegment(value: 'monthly', label: Text('月次')),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (value) {
                        setState(() => selectedType = value.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('目標種別',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'accuracy', label: Text('正答率')),
                        ButtonSegment(value: 'questions', label: Text('問題数')),
                        ButtonSegment(value: 'time', label: Text('時間')),
                      ],
                      selected: {selectedGoalType},
                      onSelectionChanged: (value) {
                        setState(() => selectedGoalType = value.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('目標値: $targetValue',
                        style: Theme.of(context).textTheme.labelMedium),
                    Slider(
                      value: targetValue.toDouble(),
                      min: 10,
                      max: 200,
                      divisions: 19,
                      onChanged: (value) {
                        setState(() => targetValue = value.toInt());
                      },
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
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(analyticsDashboardProvider.notifier).setGoal(
                    type: selectedType,
                    targetValue: targetValue,
                    goalType: selectedGoalType,
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('目標を設定しました')),
              );
            },
            child: const Text('設定'),
          ),
        ],
      ),
    );
  }
}
