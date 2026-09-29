import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/learning_goal_provider.dart';
import '../services/index.dart';
import '../viewmodels/index.dart';

/// 特定の1字だけを手書き練習する場合に、その漢字の問題データを取得する。
/// 「漢字の学習」画面で選んだ漢字と、実際に練習する漢字がずれないよう、
/// グローバルな演習セッション（practiceQuestionsProvider）ではなく
/// 選択された漢字そのものをFirestoreから取得する。
final _singleKanjiQuestionProvider =
    FutureProvider.family<KanjiQuestion?, ({String level, String kanji})>(
        (ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getKanjiQuestion('${params.level}-${params.kanji}');
});

/// 手書き判定練習画面
/// [level]・[kanji]を指定した場合は、その1字のみを練習する
/// （「漢字の学習」画面からの「書く練習」用）。指定しない場合は
/// 現在の演習セッション（practiceQuestionsProvider）の問題を順に練習する。
class HandwritingPracticeScreen extends ConsumerStatefulWidget {
  final String? level;
  final String? kanji;

  const HandwritingPracticeScreen({Key? key, this.level, this.kanji})
      : super(key: key);

  @override
  ConsumerState<HandwritingPracticeScreen> createState() =>
      _HandwritingPracticeScreenState();
}

class _HandwritingPracticeScreenState
    extends ConsumerState<HandwritingPracticeScreen> {
  final List<List<double>> _strokePoints = [];
  bool _isDrawing = false;
  bool _singleKanjiDone = false;

  @override
  Widget build(BuildContext context) {
    if (widget.level != null && widget.kanji != null) {
      return _buildSingleKanjiScaffold(widget.level!, widget.kanji!);
    }
    return _buildSessionScaffold();
  }

  /// 「漢字の学習」画面から特定の1字を指定された場合
  Widget _buildSingleKanjiScaffold(String level, String kanji) {
    final questionAsync = ref.watch(
      _singleKanjiQuestionProvider((level: level, kanji: kanji)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('「$kanji」の書く練習'),
      ),
      body: _singleKanjiDone
          ? _buildCompletionScreen(null)
          : questionAsync.when(
              data: (question) {
                if (question == null) {
                  return Center(child: Text('「$kanji」の問題データが見つかりませんでした'));
                }
                return _buildHandwritingContent(
                  context,
                  ref,
                  question,
                  null,
                  onAnswered: () => setState(() => _singleKanjiDone = true),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('エラー: $err')),
            ),
    );
  }

  /// 演習セッションの問題を順に練習する（従来の動作）
  Widget _buildSessionScaffold() {
    final level = ref.watch(currentLevelProvider);
    final questions = ref.watch(practiceQuestionsProvider(level));
    final currentIndex = ref.watch(currentQuestionIndexProvider);
    final correctCount = ref.watch(correctCountProvider);

    return WillPopScope(
      onWillPop: () async {
        ref.read(practiceViewModelProvider.notifier).reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('手書き練習'),
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
              return _buildCompletionScreen(correctCount);
            }

            final question = qList[currentIndex].source;
            return _buildHandwritingContent(context, ref, question, correctCount);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('エラー: $err')),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(int? correctCount) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            correctCount != null ? '完了！\n正解数: $correctCount問' : '完了！',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (correctCount != null) {
                ref.read(practiceViewModelProvider.notifier).reset();
              }
              Navigator.pop(context);
            },
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    );
  }

  Widget _buildHandwritingContent(
    BuildContext context,
    WidgetRef ref,
    KanjiQuestion question,
    int? correctCount, {
    VoidCallback? onAnswered,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 進捗バー（演習セッション中のみ表示）
          if (correctCount != null) ...[
            LinearProgressIndicator(
              value: (ref.watch(currentQuestionIndexProvider) + 1) / 50,
            ),
            const SizedBox(height: 16),
          ],

          // 問題：読み方を書く
          Text(
            '「${question.kanji}」と書いてください',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 手書き入力エリア
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: GestureDetector(
                onPanDown: (_) {
                  setState(() => _isDrawing = true);
                },
                onPanUpdate: (details) {
                  if (_isDrawing) {
                    setState(() {
                      _strokePoints.add([
                        details.globalPosition.dx,
                        details.globalPosition.dy,
                      ]);
                    });
                  }
                },
                onPanEnd: (_) {
                  setState(() => _isDrawing = false);
                },
                child: CustomPaint(
                  painter: DrawingPainter(_strokePoints),
                  child: Container(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ボタン
          Row(
            children: [
              // クリアボタン
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('消す'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    setState(() => _strokePoints.clear());
                  },
                ),
              ),
              const SizedBox(width: 12),

              // 判定ボタン
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('判定'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _strokePoints.isEmpty
                      ? null
                      : () => _judgeHandwriting(
                            context,
                            ref,
                            question,
                            onAnswered: onAnswered,
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _judgeHandwriting(
    BuildContext context,
    WidgetRef ref,
    KanjiQuestion question, {
    VoidCallback? onAnswered,
  }) async {
    final handwritingService = ref.read(handwritingJudgeServiceProvider);

    // 手書き判定
    final judgement = await handwritingService.judgeHandwriting(
      strokePoints: _strokePoints,
      correctAnswer: {
        'kanji': question.kanji,
        'strokeCount': 8, // 仮：実装時に question データから取得
      },
    );

    // フィードバック表示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(judgement.message),
          backgroundColor:
              judgement.isCorrect ? Colors.green : Colors.red,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }

    if (onAnswered != null) {
      // 「漢字の学習」からの単発練習: グローバルな演習セッション
      // （practiceViewModelProvider）とは無関係な問題のため、そちらは
      // 更新せず、この1問分だけ答ログ・学習目標・苦手漢字分析を記録する。
      await _recordSingleKanjiAnswer(ref, question, judgement.isCorrect);
    } else {
      final practiceVM = ref.read(practiceViewModelProvider.notifier);
      await practiceVM.answerQuestion(judgement.isCorrect);
    }

    // 演出
    if (judgement.isCorrect) {
      await SoundEffectService().playCorrectSound();
      await HapticFeedbackService.lightTap();
    } else {
      await SoundEffectService().playIncorrectSound();
      await HapticFeedbackService.shake();
    }

    // 待機して次へ
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _strokePoints.clear());

    if (onAnswered != null) {
      onAnswered();
    } else {
      ref.read(practiceViewModelProvider.notifier).moveToNextQuestion();
    }
  }

  Future<void> _recordSingleKanjiAnswer(
    WidgetRef ref,
    KanjiQuestion question,
    bool isCorrect,
  ) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final user = await ref.read(currentUserProvider.future);
    final profileId = user?.profileId ?? 'default';

    await ref.read(firestoreServiceProvider).addAnswerLog(UserAnswerLog(
          id: '',
          uid: uid,
          profileId: profileId,
          questionId: question.id,
          isCorrect: isCorrect,
          mode: AnswerMode.handwriting,
          answeredAt: DateTime.now(),
        ));

    incrementDailyQuestionGoal(ref).catchError((_) {});

    if (!isCorrect) {
      ref
          .read(aiWeakAnalysisServiceProvider)
          .analyzeWeakKanjis(uid, profileId: profileId)
          .catchError((_) {});
    }
  }
}

/// 手書き画面用描画ペイント
class DrawingPainter extends CustomPainter {
  final List<List<double>> strokePoints;

  DrawingPainter(this.strokePoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < strokePoints.length - 1; i++) {
      final p1 = Offset(strokePoints[i][0], strokePoints[i][1]);
      final p2 = Offset(strokePoints[i + 1][0], strokePoints[i + 1][1]);
      canvas.drawLine(p1, p2, paint);
    }

    // 描画中の点を表示
    if (strokePoints.isNotEmpty) {
      canvas.drawCircle(
        Offset(strokePoints.last[0], strokePoints.last[1]),
        4,
        Paint()..color = Colors.black,
      );
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
