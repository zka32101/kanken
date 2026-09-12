import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/gamification_stats.dart';
import 'package:kanken/models/reward.dart';

void main() {
  group('GamificationNotifier ロジック テスト', () {
    test('正解時に統計更新', () {
      final initialStats = GamificationStats(
        userId: 'user123',
        level: 1,
        experience: 0,
        coins: 0,
        totalQuestions: 0,
        correctCount: 0,
        streak: 0,
        recordStreak: 0,
        accuracyRate: 0.0,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // 正解を記録
      final newTotalQuestions = initialStats.totalQuestions + 1;
      final newCorrectCount = initialStats.correctCount + 1;
      final newAccuracy = newCorrectCount / newTotalQuestions;
      final newExperience = initialStats.experience + 10;

      final updatedStats = initialStats.copyWith(
        totalQuestions: newTotalQuestions,
        correctCount: newCorrectCount,
        accuracyRate: newAccuracy,
        experience: newExperience,
      );

      expect(updatedStats.totalQuestions, 1);
      expect(updatedStats.correctCount, 1);
      expect(updatedStats.accuracyRate, 1.0);
      expect(updatedStats.experience, 10);
    });

    test('複数回の正解で累積計算', () {
      var stats = GamificationStats(
        userId: 'user123',
        level: 1,
        experience: 0,
        coins: 0,
        totalQuestions: 0,
        correctCount: 0,
        streak: 0,
        recordStreak: 0,
        accuracyRate: 0.0,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // 5回正解
      for (int i = 0; i < 5; i++) {
        final newTotal = stats.totalQuestions + 1;
        final newCorrect = stats.correctCount + 1;
        final newAccuracy = newCorrect / newTotal;
        final newExp = stats.experience + 10;

        stats = stats.copyWith(
          totalQuestions: newTotal,
          correctCount: newCorrect,
          accuracyRate: newAccuracy,
          experience: newExp,
        );
      }

      expect(stats.totalQuestions, 5);
      expect(stats.correctCount, 5);
      expect(stats.accuracyRate, 1.0);
      expect(stats.experience, 50);
    });

    test('正答率計算（混合）', () {
      var stats = GamificationStats(
        userId: 'user123',
        level: 1,
        experience: 0,
        coins: 0,
        totalQuestions: 0,
        correctCount: 0,
        streak: 0,
        recordStreak: 0,
        accuracyRate: 0.0,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // 10問中7問正解
      for (int i = 0; i < 10; i++) {
        final newTotal = stats.totalQuestions + 1;
        final isCorrect = i < 7;
        final newCorrect = stats.correctCount + (isCorrect ? 1 : 0);
        final newAccuracy = newCorrect / newTotal;

        stats = stats.copyWith(
          totalQuestions: newTotal,
          correctCount: newCorrect,
          accuracyRate: newAccuracy,
        );
      }

      expect(stats.totalQuestions, 10);
      expect(stats.correctCount, 7);
      expect(stats.accuracyRate, 0.7);
    });

    test('ストリーク更新', () {
      final initialStats = GamificationStats(
        userId: 'user123',
        level: 1,
        experience: 0,
        coins: 0,
        totalQuestions: 0,
        correctCount: 0,
        streak: 0,
        recordStreak: 3,
        accuracyRate: 0.0,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // ストリーク更新
      final updatedStats = initialStats.copyWith(
        streak: 5,
        recordStreak: 5, // 新記録
      );

      expect(updatedStats.streak, 5);
      expect(updatedStats.recordStreak, 5);
    });

    test('5日ごとのボーナス', () {
      var stats = GamificationStats(
        userId: 'user123',
        level: 1,
        experience: 0,
        coins: 0,
        totalQuestions: 0,
        correctCount: 0,
        streak: 0,
        recordStreak: 0,
        accuracyRate: 0.0,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // 5日ストリーク
      stats = stats.copyWith(streak: 5);
      var bonusExp = 0;
      if (stats.streak % 5 == 0) {
        bonusExp = 50;
      }

      expect(bonusExp, 50);

      // 10日ストリーク
      stats = stats.copyWith(
        streak: 10,
        experience: stats.experience + bonusExp,
      );
      bonusExp = 0;
      if (stats.streak % 5 == 0) {
        bonusExp = 50;
      }

      expect(bonusExp, 50);
    });

    test('コイン追加', () {
      final stats = GamificationStats(
        userId: 'user123',
        level: 1,
        experience: 0,
        coins: 50,
        totalQuestions: 0,
        correctCount: 0,
        streak: 0,
        recordStreak: 0,
        accuracyRate: 0.0,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final updatedStats = stats.copyWith(
        coins: stats.coins + 100,
      );

      expect(updatedStats.coins, 150);
    });
  });

  group('Reward ロジック テスト', () {
    test('正解時ご褒美は常に10 EXP', () {
      for (int i = 0; i < 5; i++) {
        final reward = Reward.correctAnswer();
        expect(reward.amount, 10);
      }
    });

    test('ストリークボーナスは5日ごと', () {
      final reward3 = Reward.streakBonus(3);
      expect(reward3.amount, 50); // 基本50

      final reward5 = Reward.streakBonus(5);
      expect(reward5.amount, 60); // 50 + 10

      final reward10 = Reward.streakBonus(10);
      expect(reward10.amount, 70); // 50 + 20
    });

    test('デイリーチャレンジボーナス', () {
      final reward = Reward.dailyChallengeComplete();
      expect(reward.amount, 100);
      expect(reward.message, contains('coins'));
    });
  });
}
