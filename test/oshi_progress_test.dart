import 'package:app_common_kit/app_common_kit.dart' show MascotStage;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/providers/oshi_provider.dart';
import 'package:kanken/services/oshi_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('oshiStageFor', () {
    test('回答が無い・総問題数が不明なら Lv1', () {
      expect(
        oshiStageFor(distinctAnswered: 0, totalQuestions: 100, correct: 0, answered: 0),
        MascotStage.lv1,
      );
      expect(
        oshiStageFor(distinctAnswered: 10, totalQuestions: 0, correct: 8, answered: 10),
        MascotStage.lv1,
      );
    });

    test('網羅率と正答率が上がると、段階は下がらず上がる', () {
      final low = oshiStageFor(
          distinctAnswered: 10, totalQuestions: 100, correct: 5, answered: 10);
      final high = oshiStageFor(
          distinctAnswered: 90, totalQuestions: 100, correct: 85, answered: 95);
      expect(high.level, greaterThanOrEqualTo(low.level));
      expect(high.level, greaterThan(MascotStage.lv1.level));
    });

    test('解いた種類が総数を超えても例外にならない', () {
      final s = oshiStageFor(
          distinctAnswered: 150, totalQuestions: 100, correct: 100, answered: 100);
      expect(s.level, inInclusiveRange(1, 5));
    });
  });

  group('OshiProgressStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('同じ問題は一度だけ数える', () async {
      await OshiProgressStore.markAnswered(
          profileId: 'p1', level: 'LEVEL_10', questionId: 'q1');
      await OshiProgressStore.markAnswered(
          profileId: 'p1', level: 'LEVEL_10', questionId: 'q1');
      await OshiProgressStore.markAnswered(
          profileId: 'p1', level: 'LEVEL_10', questionId: 'q2');
      expect(
        await OshiProgressStore.answeredCount(profileId: 'p1', level: 'LEVEL_10'),
        2,
      );
    });

    test('プロフィールと級で分けて数える', () async {
      await OshiProgressStore.markAnswered(
          profileId: 'p1', level: 'LEVEL_10', questionId: 'q1');
      await OshiProgressStore.markAnswered(
          profileId: 'p2', level: 'LEVEL_10', questionId: 'q1');
      await OshiProgressStore.markAnswered(
          profileId: 'p1', level: 'LEVEL_9', questionId: 'q1');
      expect(
        await OshiProgressStore.answeredCount(profileId: 'p1', level: 'LEVEL_10'),
        1,
      );
      expect(
        await OshiProgressStore.answeredCount(profileId: 'p2', level: 'LEVEL_10'),
        1,
      );
      expect(
        await OshiProgressStore.answeredCount(profileId: 'p1', level: 'LEVEL_9'),
        1,
      );
    });

    test('空のIDは記録しない', () async {
      await OshiProgressStore.markAnswered(
          profileId: 'p1', level: 'LEVEL_10', questionId: '');
      expect(
        await OshiProgressStore.answeredCount(profileId: 'p1', level: 'LEVEL_10'),
        0,
      );
    });
  });
}
