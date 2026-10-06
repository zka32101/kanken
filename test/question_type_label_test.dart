import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/screens/mock_exam_enhanced_screen.dart';

void main() {
  test('出題形式は、内部名ではなく日本語で表示する', () {
    expect(questionTypeLabel('reading'), '読み');
    expect(questionTypeLabel('meaning'), '意味');
    expect(questionTypeLabel('stroke'), '画数');
    expect(questionTypeLabel('writing'), '書き取り');
    expect(questionTypeLabel('usage'), '使い方');
    // 知らない値は、そのまま出す（落とさない）。
    expect(questionTypeLabel('other'), 'other');
  });
}
