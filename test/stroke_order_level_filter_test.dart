import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/screens/stroke_order_screen.dart';

/// 「漢字の学習」は選んだ級の漢字だけを出す（下の級・上の級を混ぜない）。
void main() {
  const levels = [
    'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3',
    'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1',
  ];

  test('どの級の一覧も、その級の配当漢字の部分集合（他の級の字を含まない）', () {
    for (final level in levels) {
      final own = LevelKanjiData.forLevel(level).toSet();
      final shown = strokeOrderKanjiForLevel(level);
      expect(shown.toSet().difference(own), isEmpty, reason: level);
      expect(shown.toSet().length, shown.length, reason: '$level に重複');
    }
  });

  test('小学校の級(10〜5級)は配当漢字がすべて出る', () {
    for (final level in levels.take(6)) {
      expect(strokeOrderKanjiForLevel(level).length,
          LevelKanjiData.forLevel(level).length, reason: level);
    }
  });

  test('書き順データの無い級(4級〜2級)は小学校の漢字で埋めず、空になる', () {
    for (final level in ['LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1']) {
      expect(strokeOrderKanjiForLevel(level), isEmpty, reason: level);
    }
    expect(strokeOrderKanjiForLevel('LEVEL_10'), isNot(contains('園')));
  });
}
