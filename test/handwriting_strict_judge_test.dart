import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/stroke_order_sample_data.dart';
import 'package:kanken/services/handwriting_judge_service.dart';

List<List<List<double>>> _drawn(String kanji, {double scale = 3, double dx = 20, double dy = 40}) {
  final ref = StrokeOrderSampleData.getStrokeOrder(kanji)!;
  final polys = HandwritingJudgeService.referencePolylines(ref.strokePaths, ref.viewBox);
  return [
    for (final s in polys) [for (final p in s) [p.dx * scale + dx, p.dy * scale + dy]],
  ];
}

Future<HandwritingJudgement> _judge(List<List<List<double>>> strokes) =>
    HandwritingJudgeService().judgeHandwriting(
      strokes: strokes,
      correctAnswer: {'kanji': '百'},
      canvasSize: [360, 500],
    );

void main() {
  test('百の正しい書き方は70点以上で正解', () async {
    final j = await _judge(_drawn('百'));
    expect(j.isCorrect, isTrue);
    expect(j.confidence, greaterThanOrEqualTo(0.7));
    expect(j.message, startsWith('正解'));
  });

  test('「T」の形(横線+縦線)は不正解', () async {
    final j = await _judge([
      [
        [60.0, 100.0],
        [300.0, 100.0],
      ],
      [
        [180.0, 100.0],
        [180.0, 400.0],
      ],
    ]);
    expect(j.isCorrect, isFalse);
    expect(j.confidence, lessThan(0.7));
  });

  test('何も書いていないと不正解', () async {
    expect((await _judge(const [])).isCorrect, isFalse);
    expect((await _judge(const [[]])).isCorrect, isFalse);
  });

  test('ぐちゃぐちゃの落書きは不正解', () async {
    final rnd = Random(1);
    final scribble = [
      for (var s = 0; s < 6; s++)
        [for (var i = 0; i < 40; i++) [20 + rnd.nextDouble() * 320, 40 + rnd.nextDouble() * 400]],
    ];
    expect((await _judge(scribble)).isCorrect, isFalse);
    // 画数だけ合わせた短い線の寄せ集め
    final dots = [
      for (var s = 0; s < 6; s++)
        [
          [150.0 + s * 4, 200.0],
          [152.0 + s * 4, 204.0],
        ],
    ];
    expect((await _judge(dots)).isCorrect, isFalse);
  });

  test('一部の画だけ(半分書き漏れ)は不正解', () async {
    final full = _drawn('百');
    expect((await _judge(full.sublist(0, 3))).isCorrect, isFalse);
  });
}
