import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/mock_exam.dart';
import '../providers/mock_exam_provider.dart';

class MockExamScreen extends ConsumerStatefulWidget {
  const MockExamScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends ConsumerState<MockExamScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: const Duration(hours: 1),
      vsync: this,
    )..forward();

    // Timer を開始
    _timerController.addListener(() {
      setState(() {
        _elapsedSeconds =
            (_timerController.value * 3600).toInt(); // 最大1時間
      });
      ref
          .read(examSessionNotifierProvider.notifier)
          .updateElapsedTime(_elapsedSeconds);
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(examSessionNotifierProvider);

    if (sessionState.currentSession == null) {
      return _buildLevelSelection(context);
    }

    final session = sessionState.currentSession!;
    final currentQuestion = session.getCurrentQuestion();
    final selectedAnswers = <int, String>{};
    for (var answer in session.userAnswers) {
      selectedAnswers[answer.questionIndex] = answer.selectedAnswer;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('模擬試験'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '残り時間',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    _formatTime(session.getRemainingTime()),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: session.getRemainingTime() < 300
                              ? Colors.red
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 進捗バー
              LinearProgressIndicator(
                value: session.getProgressPercentage(),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                '問題 ${session.currentQuestionIndex} / ${session.questions.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              // 問題表示
              if (currentQuestion != null) ...[
                // 漢字表示
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '【${currentQuestion.questionType}】',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentQuestion.kanji,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 問題文
                Text(
                  currentQuestion.question,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),

                // 選択肢
                ..._buildOptions(
                  context,
                  currentQuestion,
                  selectedAnswers[session.currentQuestionIndex],
                ),
              ] else ...[
                // すべての問題が完了
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        'すべての問題に回答しました',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('試験を終了'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _completeExam(context),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ボタン
              if (currentQuestion != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (session.currentQuestionIndex > 0)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('戻る'),
                        onPressed: () {
                          // 前の問題に戻る実装
                        },
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('次へ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: selectedAnswers
                              .containsKey(session.currentQuestionIndex)
                          ? () {
                              if (session.currentQuestionIndex + 1 >=
                                  session.questions.length) {
                                _completeExam(context);
                              }
                            }
                          : null,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelection(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模擬試験'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '受験する級を選択',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ..._buildLevelButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLevelButtons(BuildContext context) {
    final levels = [
      (10, '10級（小1）'),
      (9, '9級（小2）'),
      (8, '8級（小3）'),
      (7, '7級（小4）'),
      (6, '6級（小5）'),
      (5, '5級（小6）'),
    ];

    return levels.map((level) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue.shade400,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _startExam(context, level.$1),
            child: Text(level.$2),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildOptions(
    BuildContext context,
    ExamQuestion question,
    String? selectedAnswer,
  ) {
    return question.options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      final isSelected = selectedAnswer == option;
      final isCorrect = option == question.correctAnswer;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _selectAnswer(option),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? isCorrect
                      ? Colors.green.shade100
                      : Colors.red.shade100
                  : Colors.grey.shade100,
              border: Border.all(
                color: isSelected
                    ? isCorrect
                        ? Colors.green
                        : Colors.red
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? isCorrect
                            ? Colors.green
                            : Colors.red
                        : Colors.grey.shade300,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (isSelected && isCorrect)
                  const Icon(Icons.check, color: Colors.green),
                if (isSelected && !isCorrect)
                  const Icon(Icons.close, color: Colors.red),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _startExam(BuildContext context, int level) async {
    // 試験開始
    final notifier = ref.read(examSessionNotifierProvider.notifier);
    // TODO: 実装
  }

  void _selectAnswer(String answer) {
    final session = ref.read(examSessionNotifierProvider).currentSession;
    if (session != null) {
      ref
          .read(examSessionNotifierProvider.notifier)
          .recordAnswer(
            questionIndex: session.currentQuestionIndex,
            selectedAnswer: answer,
          );
    }
  }

  Future<void> _completeExam(BuildContext context) async {
    final notifier = ref.read(examSessionNotifierProvider.notifier);
    final result = await notifier.completeExam();

    if (result != null && mounted) {
      context.push('/exam-result', extra: result);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
