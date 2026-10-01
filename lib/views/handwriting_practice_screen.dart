import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/learning_goal_provider.dart';
import '../services/index.dart';
import '../viewmodels/services_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../providers/writing_mastery_provider.dart';

/// 手書き練習画面
/// 「漢字の学習」画面で選択中の1文字を対象に、手書き→判定を行う。
/// 判定に成功したら「覚えた」チェックを付けられる。
/// [level]を指定した場合（「漢字の学習」画面からの遷移）は、答案ログ・日次学習目標・
/// 苦手漢字分析もその級・漢字に対して記録する（漢字学習と書く練習のズレ修正）。
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
  final List<List<List<double>>> _strokes = [];
  bool _isDrawing = false;
  List<double> _canvasSize = [280, 280];
  HandwritingJudgement? _lastJudgement;
  bool _isJudging = false;

  @override
  Widget build(BuildContext context) {
    final kanji = widget.kanji;
    if (kanji == null || kanji.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('手書き練習')),
        body: const Center(child: Text('練習する漢字が指定されていません')),
      );
    }

    final masteredAsync = ref.watch(masteredWritingKanjisProvider);
    final isMastered = masteredAsync.valueOrNull?.contains(kanji) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('手書き練習'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '「$kanji」と書いてください',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (isMastered) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 手書き入力エリア
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _canvasSize = [constraints.maxWidth, constraints.maxHeight];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: GestureDetector(
                        onPanDown: (details) {
                          setState(() {
                            _isDrawing = true;
                            _strokes.add([
                              [details.localPosition.dx, details.localPosition.dy]
                            ]);
                          });
                        },
                        onPanUpdate: (details) {
                          if (_isDrawing && _strokes.isNotEmpty) {
                            setState(() {
                              _strokes.last.add([
                                details.localPosition.dx,
                                details.localPosition.dy,
                              ]);
                            });
                          }
                        },
                        onPanEnd: (_) {
                          setState(() => _isDrawing = false);
                        },
                        child: CustomPaint(
                          painter: DrawingPainter(_strokes),
                          child: Container(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              if (_lastJudgement != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _lastJudgement!.isCorrect ? Icons.circle : Icons.close,
                        color: _lastJudgement!.isCorrect ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _lastJudgement!.message,
                        style: TextStyle(
                          color: _lastJudgement!.isCorrect ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // ボタン
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('消す'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _strokes.clear();
                          _lastJudgement = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('判定'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: (_strokes.isEmpty || _isJudging)
                          ? null
                          : () => _judgeHandwriting(kanji),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 覚えたチェック
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Icon(
                    isMastered ? Icons.check_circle : Icons.check_circle_outline,
                    color: isMastered ? Colors.green : null,
                  ),
                  label: Text(isMastered ? '覚えた（タップで解除）' : 'これは覚えた！'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isMastered ? Colors.green : null,
                    side: isMastered ? const BorderSide(color: Colors.green) : null,
                  ),
                  onPressed: () async {
                    if (isMastered) {
                      await unmarkWritingKanjiMastered(ref, kanji);
                    } else {
                      await markWritingKanjiMastered(ref, kanji);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _judgeHandwriting(String kanji) async {
    setState(() => _isJudging = true);
    final handwritingService = ref.read(handwritingJudgeServiceProvider);

    final judgement = await handwritingService.judgeHandwriting(
      strokes: _strokes,
      correctAnswer: {'kanji': kanji},
      canvasSize: _canvasSize,
    );

    if (judgement.isCorrect) {
      await SoundEffectService().playCorrectSound();
      await HapticFeedbackService.lightTap();
    } else {
      await SoundEffectService().playIncorrectSound();
      await HapticFeedbackService.shake();
    }

    // 答案ログ・日次学習目標・苦手漢字分析を記録する（漢字学習画面からの
    // 「書く練習」もその他の演習モードと同様に学習記録・目標進捗に反映されるようにする）。
    _recordHandwritingAnswer(kanji, judgement.isCorrect).catchError((_) {});

    if (mounted) {
      setState(() {
        _lastJudgement = judgement;
        _isJudging = false;
      });
    }
  }

  Future<void> _recordHandwritingAnswer(String kanji, bool isCorrect) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final String level = widget.level ?? ref.read(currentLevelProvider);
    final user = await ref.read(currentUserProvider.future);
    final profileId = user?.profileId ?? 'default';

    await ref.read(firestoreServiceProvider).addAnswerLog(UserAnswerLog(
          id: '',
          uid: uid,
          profileId: profileId,
          questionId: '$level-$kanji',
          isCorrect: isCorrect,
          mode: AnswerMode.handwriting,
          answeredAt: DateTime.now(),
          level: level,
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
/// ストロークごとにリストを分けて保持し、ペンを離した箇所は線でつながないようにする
class DrawingPainter extends CustomPainter {
  final List<List<List<double>>> strokes;

  DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        final p1 = Offset(stroke[i][0], stroke[i][1]);
        final p2 = Offset(stroke[i + 1][0], stroke[i + 1][1]);
        canvas.drawLine(p1, p2, paint);
      }
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke.first[0], stroke.first[1]),
          1.5,
          paint,
        );
      }
    }

    // 描画中の点を表示
    if (strokes.isNotEmpty && strokes.last.isNotEmpty) {
      canvas.drawCircle(
        Offset(strokes.last.last[0], strokes.last.last[1]),
        4,
        Paint()..color = Colors.black,
      );
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
