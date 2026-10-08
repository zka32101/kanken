import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_info_data.dart';
import 'package:kanken/data/level_kanji_data.dart';

/// 漢字の学習画面に出す読み・用例データの検査。
void main() {
  const elementary = [
    'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5',
  ];
  final kanjiList = [for (final l in elementary) ...LevelKanjiData.forLevel(l)];
  final onYomi = RegExp(r'^[ァ-ヶー]+$');
  final kunYomi = RegExp(r'^[ぁ-ゟ]+(（[ぁ-ゟ]+）)?$');
  final example = RegExp(r'^[^（）]+（[ぁ-ゟァ-ヶー]+）$');

  test('10級〜5級の配当漢字(1,026字)すべてに読みと用例がある', () {
    expect(kanjiList.length, 1026);
    for (final k in kanjiList) {
      final info = KanjiInfoData.get(k);
      expect(info, isNotNull, reason: k);
      expect(info!.readings, isNotEmpty, reason: k);
      expect(info.examples.length, greaterThanOrEqualTo(2), reason: k);
    }
  });

  test('読みはカタカナ(音)かひらがな(訓、送り仮名は括弧)で、重複しない', () {
    for (final k in kanjiList) {
      final info = KanjiInfoData.get(k)!;
      expect(info.readings.toSet().length, info.readings.length, reason: k);
      for (final r in info.readings) {
        expect(onYomi.hasMatch(r) || kunYomi.hasMatch(r), isTrue, reason: '$k: $r');
      }
    }
  });

  test('用例は「語（よみ）」の形で、見出しの漢字を含み、重複しない', () {
    for (final k in kanjiList) {
      final info = KanjiInfoData.get(k)!;
      expect(info.examples.toSet().length, info.examples.length, reason: k);
      for (final e in info.examples) {
        expect(example.hasMatch(e), isTrue, reason: '$k: $e');
        expect(e.contains(k), isTrue, reason: '$k: $e');
      }
    }
  });

  test('音読みと訓読みの両方を持つ漢字が増えている(園=エン/その、日=ニチ/ひ)', () {
    expect(KanjiInfoData.get('園')!.readings, containsAll(['エン', 'その']));
    expect(KanjiInfoData.get('日')!.readings, containsAll(['ニチ', 'ジツ', 'ひ', 'か']));
    var both = 0;
    for (final k in kanjiList) {
      final r = KanjiInfoData.get(k)!.readings;
      if (r.any(onYomi.hasMatch) && r.any(kunYomi.hasMatch)) both++;
    }
    expect(both, greaterThan(700));
  });

  test('特別な読み・熟語での読みの用例が入っている', () {
    expect(KanjiInfoData.get('日')!.examples, containsAll(['今日（きょう）', '明日（あす）']));
    expect(KanjiInfoData.get('七')!.examples, contains('七夕（たなばた）'));
    expect(KanjiInfoData.get('土')!.examples, contains('土産（みやげ）'));
    expect(KanjiInfoData.get('眼')!.examples, contains('眼鏡（めがね）'));
  });
}
