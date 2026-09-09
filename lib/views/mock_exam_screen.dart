import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/index.dart';
import '../services/index.dart';
import '../viewmodels/index.dart';
import '../widgets/index.dart';

/// 模擬試験画面
class MockExamScreen extends ConsumerStatefulWidget {
  final String level;

  const MockExamScreen({
    Key? key,
    required this.level,
  }) : super(key: key);

  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends ConsumerState<MockExamScreen> {
  late Timer _timer;
  int _secondsRemaining = 600; // 10分間（本来は MockExam.timeLimitSec）
  bool _isTimeExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _isTimeExpired = true;
          _timer.cancel();
          _showTimeExpired();
        }
      });
    });
  }

  void _showTimeExpired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('時間終了！自動採点します。'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(practiceQuestionsProvider(widget.level));
    final currentIndex = ref.watch(currentQuestionIndexProvider);

    return WillPopScope(
      onWillPop: () async {
        _timer.cancel();
        ref.read(practiceViewModelProvider.notifier).reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('模擬試験'),
          backgroundColor: Colors.deepPurple,
          actions: [
            // タイマー表示
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _secondsRemaining < 60 ? Colors.red : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatTime(_secondsRemaining),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _secondsRemaining < 60 ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: questions.when(
          data: (qList) {
            // タイムアップ時は結果画面へ
            if (_isTimeExpired && currentIndex < qList.length) {
              return _buildSubmitPrompt(context, ref, currentIndex, qList.length);
            }

            if (currentIndex >= qList.length) {
              return _buildResultScreen(context, ref, qList.length);
            }

            final question = qList[currentIndex];
            return _buildExamContent(
              context,
              ref,
              question,
              currentIndex,
              qList.length,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('エラー: $err')),
        ),
      ),
    );
  }

  Widget _buildExamContent(
    BuildContext context,
    WidgetRef ref,
    KanjiQuestion question,
    int currentIndex,
    int totalQuestions,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 問題番号
            Text(
              '問 ${currentIndex + 1}/${totalQuestions}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 漢字表示
            Text(
              question.kanji,
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // 選択肢
            if (question.questionType == QuestionType.multipleChoice)
              Column(
                children: question.choices.map((choice) {
                  final isCorrect = choice == question.correctAnswer;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepPurple[50],
                          foregroundColor: Colors.black,
                          side: BorderSide(color: Colors.deepPurple[200]!),
                        ),
                        onPressed: _isTimeExpired
                            ? null
                            : () => _handleAnswer(context, ref, isCorrect),
                        child: Text(choice),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // タイムアップ警告
            if (_secondsRemaining < 60)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ 残り時間が少なくなっています！',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitPrompt(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
    int totalQuestions,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 80, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            '時間終了！\n(${currentIndex}/${totalQuestions} 問解答)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _submitExam(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              '採点する',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(
    BuildContext context,
    WidgetRef ref,
    int totalQuestions,
  ) {
    final correctCount = ref.watch(correctCountProvider);
    final passScore = 80; // 仮：MockExam.passScore から取得
    final score = (correctCount * 100) ~/ totalQuestions;
    final passed = score >= passScore;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 結果アイコン
              Icon(
                passed ? Icons.star : Icons.cancel,
                size: 120,
                color: passed ? Colors.amber : Colors.red,
              ),
              const SizedBox(height: 24),

              // 結果テキスト
              Text(
                passed ? '合格！' : '不合格',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: passed ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),

              // スコア表示
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$score 点',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '正解: $correctCount/$totalQuestions 問',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 不合格時：「あと◯点」表示
              if (!passed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'あと',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${passScore - score}点',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Text(
                        '合格できます',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // ボタン
              if (passed)
                ElevatedButton(
                  onPressed: () => _handlePassedExam(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'バッジを確認',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _navigateToWeakMode(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    '苦手集中で復習',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  ref.read(practiceViewModelProvider.notifier).reset();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text(
                  'ホームに戻る',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleAnswer(
    BuildContext context,
    WidgetRef ref,
    bool isCorrect,
  ) async {
    final practiceVM = ref.read(practiceViewModelProvider.notifier);

    await practiceVM.answerQuestion(isCorrect);

    if (isCorrect) {
      await SoundEffectService().playCorrectSound();
      await HapticFeedbackService.lightTap();
    } else {
      await SoundEffectService().playIncorrectSound();
      await HapticFeedbackService.shake();
    }

    await Future.delayed(const Duration(milliseconds: 800));
    practiceVM.moveToNextQuestion();
  }

  Future<void> _submitExam(BuildContext context, WidgetRef ref) async {
    // 採点完了
    ref.read(practiceViewModelProvider.notifier).moveToNextQuestion();
  }

  void _handlePassedExam(BuildContext context, WidgetRef ref) {
    // 合格演出＋バッジ画面へ遷移
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          color: Colors.amber[400],
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 120, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                '🎉 新しいバッジを獲得！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(practiceViewModelProvider.notifier).reset();
                  Navigator.pop(context);
                },
                child: const Text('ホームに戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToWeakMode(BuildContext context, WidgetRef ref) {
    ref.read(practiceViewModelProvider.notifier).reset();
    Navigator.pop(context);
    // WeakKanjiModeScreen へ遷移
  }
}
