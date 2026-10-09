import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/kanji_question.dart';

void main() {
  test('extraReadings を読み込み、allReadings に主たる読みと合わせて並ぶ', () {
    final q = KanjiQuestion.fromJson({
      'id': 'a',
      'level': 'LEVEL_10',
      'kanji': '生',
      'questionType': 'multipleChoice',
      'choices': ['生'],
      'correctAnswer': '生',
      'reading': 'せい',
      'example': '生活（せいかつ）',
      'extraReadings': [
        {'reading': 'い（きる）', 'example': '生きる（いきる）'},
      ],
    });
    expect(q.allReadings.map((r) => r.reading), ['せい', 'い（きる）']);
    expect(KanjiQuestion.fromJson(q.toJson()).extraReadings.length, 1);
  });

  test('extraReadings が無いデータでも読める', () {
    final q = KanjiQuestion.fromJson({'id': 'b', 'kanji': '一', 'reading': 'いち'});
    expect(q.extraReadings, isEmpty);
    expect(q.allReadings.length, 1);
  });
}
