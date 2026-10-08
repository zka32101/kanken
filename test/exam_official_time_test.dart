import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/mock_exam_modes.dart';

void main() {
  // 出典: 日本漢字能力検定協会
  //  検定時間 https://www.kanken.or.jp/kanken/individual/pbt/schedule/
  //  合格基準 https://www.kanken.or.jp/kanken/grades/overview/
  test('標準試験の時間は、公式の検定時間（8級以下40分・7級以上60分）', () {
    for (final level in [8, 9, 10]) {
      expect(ExamConfig.standard(level: level).timeLimit, 40, reason: '$level級');
    }
    for (final level in [1, 2, 3, 4, 5, 6, 7]) {
      expect(ExamConfig.standard(level: level).timeLimit, 60, reason: '$level級');
    }
  });

  test('標準試験の合格ラインは、公式の得点率の目安（1・2級と8〜10級80%・3〜7級70%）', () {
    for (final level in [1, 2, 8, 9, 10]) {
      expect(ExamConfig.officialPassPercent(level), 80, reason: '$level級');
      expect(ExamConfig.standard(level: level).passThreshold, 80);
    }
    for (final level in [3, 4, 5, 6, 7]) {
      expect(ExamConfig.officialPassPercent(level), 70, reason: '$level級');
      expect(ExamConfig.standard(level: level).passThreshold, 70);
    }
  });

  test('合否判定の境界値（ちょうどは合格・1問足りないと不合格）', () {
    final c3 = ExamConfig.standard(level: 3); // 70%
    expect(c3.isPass(14, 20), isTrue); // 70%ちょうど
    expect(c3.isPass(13, 20), isFalse);
    expect(c3.isPass(7, 10), isTrue);
    expect(c3.isPass(6, 10), isFalse);
    final c10 = ExamConfig.standard(level: 10); // 80%
    expect(c10.isPass(16, 20), isTrue);
    expect(c10.isPass(15, 20), isFalse);
    expect(c10.isPass(0, 0), isFalse); // 問題が無いときは合格にしない
  });
}
