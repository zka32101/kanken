import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/mock_exam_modes.dart';

void main() {
  test('標準試験の時間は、公式の検定時間（8級以下40分・7級以上60分）', () {
    for (final level in [8, 9, 10]) {
      expect(ExamConfig.standard(level: level).timeLimit, 40, reason: '$level級');
    }
    for (final level in [1, 2, 3, 4, 5, 6, 7]) {
      expect(ExamConfig.standard(level: level).timeLimit, 60, reason: '$level級');
    }
  });
}
