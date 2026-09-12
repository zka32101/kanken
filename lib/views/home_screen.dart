import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/index.dart';
import '../viewmodels/index.dart';
import '../services/index.dart';
import '../widgets/index.dart';
import '../router/app_router.dart';
import '../providers/ranking_provider.dart';
import '../providers/friend_provider.dart';
import '../models/user_ranking.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const List<String> levels = [
    'LEVEL_10', // 小1
    'LEVEL_9',  // 小2
    'LEVEL_8',  // 小3
    'LEVEL_7',  // 小4
    'LEVEL_6',  // 小5
    'LEVEL_5',  // 小6
  ];

  static const Map<String, String> levelNames = {
    'LEVEL_10': '10級（小1）',
    'LEVEL_9': '9級（小2）',
    'LEVEL_8': '8級（小3）',
    'LEVEL_7': '7級（小4）',
    'LEVEL_6': '6級（小5）',
    'LEVEL_5': '5級（小6）',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLevel = ref.watch(currentLevelProvider);
    final user = ref.watch(currentUserProvider);
    final weakKanjiCount = ref.watch(_weakKanjiCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('小学漢検チャレンジ'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ユーザー情報・進捗セクション
              _buildProgressCard(context, ref, user, weakKanjiCount),
              const SizedBox(height: 24),

              // ランキングセクション
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ランキング 🏆',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.goRanking(),
                    child: const Text('全て見る'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildRankingPreview(context, ref),
              const SizedBox(height: 24),

              // フレンドセクション
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'フレンド 👥',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.goFriends(),
                    child: const Text('全て見る'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildFriendPreview(context, ref),
              const SizedBox(height: 24),

              // 級選択セクション
              const Text(
                '受験級を選択',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildLevelGrid(context, ref, currentLevel),
              const SizedBox(height: 24),

              // 演習開始ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('演習を始める'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _navigateToPractice(context, ref);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<User?> user,
    AsyncValue<int> weakKanjiCount,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'あなたの進捗',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '🔥 ストリーク',
                  user.when(
                    data: (u) => '${u?.streakCount ?? 0}日',
                    loading: () => '-',
                    error: (_, __) => 'エラー',
                  ),
                ),
                _buildStatItem(
                  '⚠️ 苦手漢字',
                  weakKanjiCount.when(
                    data: (count) => '$count個',
                    loading: () => '-',
                    error: (_, __) => 'エラー',
                  ),
                ),
                _buildStatItem(
                  '🎯 合格級',
                  user.when(
                    data: (u) =>
                        levelNames[u?.currentLevel ?? 'LEVEL_10'] ??
                        'LEVEL_10',
                    loading: () => '-',
                    error: (_, __) => 'エラー',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLevelGrid(BuildContext context, WidgetRef ref, String currentLevel) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: levels.map((level) {
        final isSelected = level == currentLevel;
        return GestureDetector(
          onTap: () {
            ref.read(currentLevelProvider.notifier).state = level;
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey[100],
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                levelNames[level]?.split('（').first ?? level,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRankingPreview(BuildContext context, WidgetRef ref) {
    final filter = const RankingFilter(limit: 5);
    final rankingAsyncValue = ref.watch(rankingProvider(filter));

    return rankingAsyncValue.when(
      data: (rankings) {
        if (rankings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ランキングデータなし',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rankings.take(3).length,
            itemBuilder: (context, index) {
              final ranking = rankings[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      ranking.getRankBadge(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ranking.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Lv ${ranking.level} • ${(ranking.accuracyRate * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '🔥${ranking.streak}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 80,
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'ランキング取得エラー',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildFriendPreview(BuildContext context, WidgetRef ref) {
    final friendsAsyncValue = ref.watch(friendListProvider);

    return friendsAsyncValue.when(
      data: (friends) {
        if (friends.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'フレンドを追加しましょう',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: friends.take(3).length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: friend.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Lv ${friend.level} • ${(friend.accuracyRate * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      friend.getStatusIcon(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 80,
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'フレンド取得エラー',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  void _navigateToPractice(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PracticeScreen(),
      ),
    );
  }
}

// 苦手漢字数を取得するProvider
final _weakKanjiCountProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return 0;

  final aiWeakService = ref.watch(aiWeakAnalysisServiceProvider);
  return await aiWeakService.getWeakKanjiCount(uid);
});

// 練習画面
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(currentLevelProvider);
    final questions = ref.watch(practiceQuestionsProvider(level));
    final currentIndex = ref.watch(currentQuestionIndexProvider);
    final correctCount = ref.watch(correctCountProvider);
    final comboCount = ref.watch(comboCountProvider);
    final ahaMomentReached = ref.watch(ahaMomentReachedProvider);

    return WillPopScope(
      onWillPop: () async {
        ref.read(practiceViewModelProvider.notifier).reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('演習中'),
          leading: BackButton(
            onPressed: () {
              ref.read(practiceViewModelProvider.notifier).reset();
              Navigator.pop(context);
            },
          ),
        ),
        body: questions.when(
          data: (qList) {
            if (currentIndex >= qList.length) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 80, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      '完了！\n正解数: $correctCount問',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(practiceViewModelProvider.notifier).reset();
                        Navigator.pop(context);
                      },
                      child: const Text('ホームに戻る'),
                    ),
                  ],
                ),
              );
            }

            final question = qList[currentIndex];
            return _buildPracticeContent(
              context,
              ref,
              question,
              currentIndex,
              correctCount,
              comboCount,
              ahaMomentReached,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('エラー: $err')),
        ),
      ),
    );
  }

  Widget _buildPracticeContent(
    BuildContext context,
    WidgetRef ref,
    KanjiQuestion question,
    int currentIndex,
    int correctCount,
    int comboCount,
    bool ahaMomentReached,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 進捗バー
          LinearProgressIndicator(
            value: (currentIndex + 1) / 50,
          ),
          const SizedBox(height: 16),

          // 正解数・コンボ表示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('正解: $correctCount問', style: const TextStyle(fontSize: 14)),
              Text('コンボ: $comboCount', style: const TextStyle(fontSize: 14, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 24),

          // 漢字表示（大きく）
          Text(
            question.kanji,
            style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // 選択肢
          if (question.questionType == QuestionType.multipleChoice)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: question.choices.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final choice = entry.value;
                  final isCorrect = choice == question.correctAnswer;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          _handleAnswer(context, ref, isCorrect);
                        },
                        child: Text(choice),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('手書き判定（実装予定）'),
              ),
            ),

          // Aha Moment達成メッセージ
          if (ahaMomentReached)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  '🎉 初回3問正解達成！\n苦手分析を確認できるようになります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleAnswer(BuildContext context, WidgetRef ref, bool isCorrect) async {
    final practiceVM = ref.read(practiceViewModelProvider.notifier);
    final level = ref.read(currentLevelProvider);

    await practiceVM.answerQuestion(isCorrect);

    // 演出（Lottie + SE + ハプティクス）
    if (isCorrect) {
      // SE再生（正解）
      await SoundEffectService().playCorrectSound();
      // ハプティクス（軽いタップ）
      await HapticFeedbackService.lightTap();
      // 正解演出表示
      _showCorrectFeedback(context);
      // Analytics: 3問正解でAha Moment
      final ahaMoment = ref.read(ahaMomentReachedProvider);
      if (ahaMoment) {
        await AnalyticsService.logAhaMomentReached(level: level);
      }
    } else {
      // SE再生（不正解）
      await SoundEffectService().playIncorrectSound();
      // ハプティクス（シェイク）
      await HapticFeedbackService.shake();
      // 不正解演出表示
      _showIncorrectFeedback(context);
    }

    // 少し待ってから次の問題へ
    await Future.delayed(const Duration(milliseconds: 1500));
    practiceVM.moveToNextQuestion();
  }

  void _showCorrectFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ 正解！'),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showIncorrectFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ 不正解'),
        backgroundColor: Colors.red,
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
