import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/category_label.dart';
import 'package:kanken/models/mock_exam_modes.dart';
import 'package:kanken/providers/exam_session_provider.dart';
import 'package:kanken/screens/mock_exam_enhanced_screen.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

void main() {
  test('模擬試験カテゴリ・練習モードの内部名は、すべて日本語名に変換される', () {
    for (final c in ExamCategory.values) {
      expect(categoryLabel(c.name), isNot(c.name), reason: c.name);
    }
    for (final m in PracticeMode.values) {
      expect(categoryLabel(m.name), isNot(m.name), reason: m.name);
    }
    expect(categoryLabel('stroke'), '画数');
    expect(categoryLabel('unknown_x'), 'unknown_x');
  });

  testWidgets('模擬試験画面は、画数の問題でも内部名(stroke)を出さず、オーバーフローしない', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    const q = EnhancedExamQuestion(
      questionId: 'q1',
      kanji: '森',
      questionType: 'stroke',
      question: '「森」の画数は？',
      options: ['10', '11', '12', '13'],
      correctAnswer: '12',
      explanation: '',
      level: 10,
      difficulty: ExamDifficulty.medium,
      category: ExamCategory.stroke,
      averageTimeSeconds: 10,
      correctnessRate: 0,
      userAttempts: 0,
      commonMistakes: [],
    );
    final config = ExamConfig.standard(level: 10);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        examModeQuestionsProvider.overrideWith((ref) async => [q]),
      ],
      child: MaterialApp(home: MockExamEnhancedScreen(config: config)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('【画数】'), findsOneWidget);
    expect(find.textContaining('stroke'), findsNothing);
    expect(tester.takeException(), isNull); // BOTTOM OVERFLOWED などが無い
    // タイマー(AnimationController)を止める
    await tester.pumpWidget(const SizedBox());
  });
}
