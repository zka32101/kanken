import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mock_exam_modes.dart';
import '../providers/mock_exam_enhanced_provider.dart';
import '../providers/firebase_provider.dart';

class MockExamModesScreen extends ConsumerWidget {
  const MockExamModesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模擬試験モード'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '試験モードを選択',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'あなたの学習目標に合わせて、最適な模擬試験モードを選択できます',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildModeCard(
              context,
              ref,
              title: '標準試験',
              subtitle: '50問 • 120分',
              description: '実際の試験に最も近い形式。全問題タイプをバランスよく出題します。',
              icon: Icons.description,
              color: Colors.blue,
              onTap: () => _startExam(context, ref, ExamConfig.standard(), currentUserId),
            ),
            const SizedBox(height: 12),
            _buildModeCard(
              context,
              ref,
              title: '速度試験',
              subtitle: '30問 • 60分',
              description: '時間圧力の中で解く力を養います。スキマ時間での学習に最適。',
              icon: Icons.timer,
              color: Colors.orange,
              onTap: () => _startExam(context, ref, ExamConfig.speed(), currentUserId),
            ),
            const SizedBox(height: 12),
            _buildModeCard(
              context,
              ref,
              title: '集中試験',
              subtitle: '20問 • 45分',
              description: '特定の分野に集中。カテゴリを選んで苦手を克服します。',
              icon: Icons.target,
              color: Colors.teal,
              onTap: () => _showCategorySelection(context, ref, currentUserId),
            ),
            const SizedBox(height: 12),
            _buildModeCard(
              context,
              ref,
              title: '弱点対策',
              subtitle: '30問 • 難易度高',
              description: 'あなたの苦手分野を重点的に出題。弱点を徹底克服。',
              icon: Icons.trending_up,
              color: Colors.red,
              onTap: () => _startExam(context, ref, ExamConfig.weakAreas(), currentUserId),
            ),
            const SizedBox(height: 12),
            _buildModeCard(
              context,
              ref,
              title: 'ランダム試験',
              subtitle: '40問 • 90分',
              description: 'すべての問題タイプをランダムに出題。予測不可能な難問に挑戦。',
              icon: Icons.shuffle,
              color: Colors.purple,
              onTap: () => _startExam(context, ref, ExamConfig.random(), currentUserId),
            ),
            const SizedBox(height: 12),
            _buildModeCard(
              context,
              ref,
              title: '段階式試験',
              subtitle: '60問 • 150分',
              description: '簡単から難しいへ。段階的に難易度が上がります。',
              icon: Colors.stacked_line_chart,
              color: Colors.indigo,
              onTap: () => _startExam(context, ref, ExamConfig.progressive(), currentUserId),
            ),
            const SizedBox(height: 32),
            _buildStatisticsSection(context, ref, currentUserId),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) {
    if (userId == null) {
      return const SizedBox.shrink();
    }

    final statsAsync = ref.watch(detailedExamStatisticsProvider(userId));

    return statsAsync.when(
      data: (stats) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'あなたの成績',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        '受験回数',
                        stats.totalExamsTaken.toString(),
                      ),
                      _buildStatItem(
                        '合格数',
                        stats.totalPassed.toString(),
                      ),
                      _buildStatItem(
                        '最高点',
                        '${stats.bestScore}点',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        '平均正答率',
                        '${(stats.averageAccuracy * 100).toStringAsFixed(1)}%',
                      ),
                      _buildStatItem(
                        '平均時間',
                        '${stats.averageTimePerQuestion.toStringAsFixed(1)}秒',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _startExam(
    BuildContext context,
    WidgetRef ref,
    ExamConfig config,
    String? userId,
  ) {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    // Navigate to exam with config
    // This will be integrated with your exam flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${config.mode.toString().split('.').last} を開始します'),
      ),
    );
  }

  void _showCategorySelection(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カテゴリを選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ExamCategory.values.length - 1, // Exclude 'mixed'
            itemBuilder: (context, index) {
              final category = ExamCategory.values[index];
              final categoryName = {
                ExamCategory.reading: '読み',
                ExamCategory.meaning: '意味',
                ExamCategory.stroke: '画数',
                ExamCategory.writing: '書き',
                ExamCategory.usage: '使い方',
                ExamCategory.mixed: '混合',
              }[category] ?? category.toString();

              return ListTile(
                title: Text(categoryName),
                onTap: () {
                  Navigator.pop(context);
                  _startExam(
                    context,
                    ref,
                    ExamConfig.focused(category: category),
                    userId,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
