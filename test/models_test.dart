import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kanken/models/daily_challenge.dart';
import 'package:kanken/models/gamification_stats.dart';
import 'package:kanken/models/reward.dart';

void main() {
  group('DailyChallenge Model', () {
    test('デイリーチャレンジの生成と JSON シリアライズ', () {
      final today = DateTime.now();
      final tomorrow = today.add(Duration(days: 1));

      final challenge = DailyChallenge(
        id: '2026-09-12',
        date: '2026-09-12',
        questionIds: ['q001', 'q002', 'q003'],
        difficulty: 'medium',
        resetTime: tomorrow,
        createdAt: today,
      );

      expect(challenge.id, '2026-09-12');
      expect(challenge.questionCount, 3);
      expect(challenge.isExpired, false);
      expect(challenge.difficulty, 'medium');
    });

    test('JSON からのデシリアライズ', () {
      final tomorrow = DateTime.now().add(Duration(days: 1));

      final json = {
        'id': '2026-09-12',
        'date': '2026-09-12',
        'questions': ['q001', 'q002'],
        'difficulty': 'hard',
        'resetTime': Timestamp.fromDate(tomorrow),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      final challenge = DailyChallenge.fromJson(json);

      expect(challenge.id, '2026-09-12');
      expect(challenge.questionIds.length, 2);
      expect(challenge.difficulty, 'hard');
    });

    test('期限切れ判定', () {
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final tomorrow = DateTime.now().add(Duration(days: 1));

      final expiredChallenge = DailyChallenge(
        id: 'expired',
        date: '2026-09-11',
        questionIds: [],
        difficulty: 'easy',
        resetTime: yesterday,
        createdAt: yesterday,
      );

      final validChallenge = DailyChallenge(
        id: 'valid',
        date: '2026-09-12',
        questionIds: [],
        difficulty: 'easy',
        resetTime: tomorrow,
        createdAt: DateTime.now(),
      );

      expect(expiredChallenge.isExpired, true);
      expect(validChallenge.isExpired, false);
    });
  });

  group('GamificationStats Model', () {
    test('ユーザー統計の初期化', () {
      final stats = GamificationStats(
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

      expect(stats.userId, 'user123');
      expect(stats.level, 1);
      expect(stats.getRank(), '新米受験生');
      expect(stats.expToNextLevel, 500);
    });

    test('ランク判定が正確', () {
      final level1 = GamificationStats(
        userId: 'user1',
        level: 1,
        experience: 100,
        coins: 0,
        totalQuestions: 0,
        correctCount: 0,
        streak: 0,
        recordStreak: 0,
        accuracyRate: 0.0,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final level5 = GamificationStats(
        userId: 'user5',
        level: 5,
        experience: 2500,
        coins: 0,
        totalQuestions: 0,
        correctCount: 0,
        streak: 0,
        recordStreak: 0,
        accuracyRate: 0.0,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final levelMax = GamificationStats(
        userId: 'userMax',
        level: 20,
        experience: 10000,
        coins: 0,
        totalQuestions: 0,
        correctCount: 0,
        streak: 0,
        recordStreak: 0,
        accuracyRate: 0.0,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(level1.getRank(), '新米受験生');
      expect(level5.getRank(), '中堅学生');
      expect(levelMax.getRank(), 'マスター');
    });

    test('正答率計算', () {
      final stats = GamificationStats(
        userId: 'user123',
        level: 1,
        experience: 0,
        coins: 0,
        totalQuestions: 10,
        correctCount: 7,
        streak: 0,
        recordStreak: 0,
        accuracyRate: 0.7,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(stats.accuracyRate, 0.7);
      expect(stats.totalQuestions, 10);
      expect(stats.correctCount, 7);
    });

    test('copyWith メソッド', () {
      final original = GamificationStats(
        userId: 'user123',
        level: 1,
        experience: 100,
        coins: 50,
        totalQuestions: 10,
        correctCount: 8,
        streak: 3,
        recordStreak: 5,
        accuracyRate: 0.8,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        level: 2,
        experience: 600,
        coins: 150,
      );

      expect(updated.level, 2);
      expect(updated.experience, 600);
      expect(updated.coins, 150);
      expect(updated.userId, 'user123'); // 変更されない
    });
  });

  group('Reward Model', () {
    test('正解時のご褒美', () {
      final reward = Reward.correctAnswer();

      expect(reward.type, RewardType.correctAnswer);
      expect(reward.amount, 10);
      expect(reward.message, '✨ +10 EXP');
    });

    test('連続日数ボーナス', () {
      final reward = Reward.streakBonus(5);

      expect(reward.type, RewardType.streakBonus);
      expect(reward.amount, 50); // 基本50 EXP
      expect(reward.message, contains('5日'));
    });

    test('デイリーチャレンジボーナス', () {
      final reward = Reward.dailyChallengeComplete();

      expect(reward.type, RewardType.dailyChallengeComplete);
      expect(reward.amount, 100);
      expect(reward.message, contains('100 coins'));
    });

    test('全問正解ボーナス', () {
      final reward = Reward.allCorrect();

      expect(reward.type, RewardType.allCorrect);
      expect(reward.amount, 50);
    });

    test('レベルアップボーナス', () {
      final reward = Reward.levelUp(5);

      expect(reward.type, RewardType.levelUp);
      expect(reward.amount, 0);
      expect(reward.message, contains('5'));
      expect(reward.metadata?['newLevel'], 5);
    });

    test('JSON シリアライズ・デシリアライズ', () {
      final original = Reward.streakBonus(7);
      final json = original.toJson();
      final restored = Reward.fromJson(json);

      expect(restored.type, original.type);
      expect(restored.amount, original.amount);
      expect(restored.message, original.message);
    });
  });
}
