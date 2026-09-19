import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_goal.dart';
import '../providers/learning_goal_provider.dart';

class LearningGoalsScreen extends ConsumerWidget {
  const LearningGoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoalsAsync = ref.watch(activeLearningGoalsProvider);
    final achievedGoalsAsync = ref.watch(achievedLearningGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学習目標'),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGoalDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '設定中の目標',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          activeGoalsAsync.when(
            data: (goals) => _buildActiveGoalsList(goals, context, ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('エラー: $err')),
          ),
          const SizedBox(height: 24),
          Text(
            '達成した目標',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          achievedGoalsAsync.when(
            data: (goals) => _buildAchievedGoalsList(goals, context),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('エラー: $err')),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildActiveGoalsList(
    List<LearningGoal> goals,
    BuildContext context,
    WidgetRef ref,
  ) {
    if (goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '目標が設定されていません。右下のボタンから追加しましょう。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: goals.map((goal) => _buildGoalCard(goal, context, ref)).toList(),
    );
  }

  Widget _buildGoalCard(LearningGoal goal, BuildContext context, WidgetRef ref) {
    final progressColor = goal.progressRate >= 1.0
        ? Colors.green
        : goal.progressRate >= 0.5
            ? Colors.blue
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(goal.typeIcon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      goal.typeLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () async {
                    await deactivateLearningGoal(goal.goalId);
                    ref.invalidate(activeLearningGoalsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progressRate,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.currentValue} / ${goal.targetValue} ${goal.unit}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${goal.progressPercentage}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (goal.deadline != null) ...[
              const SizedBox(height: 4),
              Text(
                goal.isExpired ? '期限切れ' : '期限: ${_formatDate(goal.deadline!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: goal.isExpired ? Colors.red : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievedGoalsList(List<LearningGoal> goals, BuildContext context) {
    if (goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'まだ達成した目標はありません',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: goals.map((goal) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Text(goal.typeIcon, style: const TextStyle(fontSize: 24)),
            title: Text(
              goal.typeLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${goal.targetValue}${goal.unit}を達成'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _showCreateGoalDialog(BuildContext context, WidgetRef ref) {
    GoalType selectedType = GoalType.dailyQuestions;
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('新しい目標を設定'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('目標の種類', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<GoalType>(
                  value: selectedType,
                  isExpanded: true,
                  items: GoalType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getGoalTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '目標値 (${_getGoalTypeUnit(selectedType)})',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  targetController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final targetValue = int.tryParse(targetController.text);
                  if (targetValue == null || targetValue <= 0) return;

                  await createLearningGoal(
                    type: selectedType,
                    targetValue: targetValue,
                  );

                  ref.invalidate(activeLearningGoalsProvider);
                  targetController.dispose();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('作成'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getGoalTypeLabel(GoalType type) {
    switch (type) {
      case GoalType.weeklyStudyMinutes:
        return '⏱️ 週間学習時間';
      case GoalType.dailyQuestions:
        return '📝 日次問題数';
      case GoalType.accuracyRate:
        return '🎯 正答率目標';
      case GoalType.streakDays:
        return '🔥 連続学習日数';
      case GoalType.examScore:
        return '🏆 試験スコア目標';
    }
  }

  String _getGoalTypeUnit(GoalType type) {
    switch (type) {
      case GoalType.weeklyStudyMinutes:
        return '分';
      case GoalType.dailyQuestions:
        return '問';
      case GoalType.accuracyRate:
        return '%';
      case GoalType.streakDays:
        return '日';
      case GoalType.examScore:
        return '点';
    }
  }
}
