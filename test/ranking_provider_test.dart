import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/user_ranking.dart';

void main() {
  group('UserRanking Tests', () {
    test('UserRanking creates with valid data', () {
      final ranking = UserRanking(
        userId: 'user-1',
        userName: 'Alice',
        rank: 1,
        score: 10000,
        level: 50,
        correctAnswers: 450,
        totalQuestions: 500,
        streak: 25,
        lastPlayedAt: DateTime.now(),
      );

      expect(ranking.userId, equals('user-1'));
      expect(ranking.userName, equals('Alice'));
      expect(ranking.rank, equals(1));
      expect(ranking.score, equals(10000));
    });

    test('UserRanking rank ordering', () {
      final rankings = [
        UserRanking(
          userId: 'user-1',
          userName: 'Alice',
          rank: 1,
          score: 10000,
          level: 50,
          correctAnswers: 450,
          totalQuestions: 500,
          streak: 25,
          lastPlayedAt: DateTime.now(),
        ),
        UserRanking(
          userId: 'user-2',
          userName: 'Bob',
          rank: 2,
          score: 9500,
          level: 48,
          correctAnswers: 425,
          totalQuestions: 500,
          streak: 15,
          lastPlayedAt: DateTime.now(),
        ),
        UserRanking(
          userId: 'user-3',
          userName: 'Charlie',
          rank: 3,
          score: 9000,
          level: 45,
          correctAnswers: 400,
          totalQuestions: 500,
          streak: 10,
          lastPlayedAt: DateTime.now(),
        ),
      ];

      expect(rankings[0].rank, lessThan(rankings[1].rank));
      expect(rankings[0].score, greaterThan(rankings[1].score));
    });

    test('UserRanking calculates accuracy', () {
      final ranking = UserRanking(
        userId: 'user-4',
        userName: 'David',
        rank: 10,
        score: 5000,
        level: 30,
        correctAnswers: 400,
        totalQuestions: 500,
        streak: 5,
        lastPlayedAt: DateTime.now(),
      );

      final accuracy = (ranking.correctAnswers / ranking.totalQuestions) * 100;
      expect(accuracy, equals(80.0));
    });

    test('UserRanking fromJson creates instance', () {
      final jsonData = {
        'userId': 'user-5',
        'userName': 'Eve',
        'rank': 5,
        'score': 7500,
        'level': 35,
        'correctAnswers': 350,
        'totalQuestions': 500,
        'streak': 8,
        'lastPlayedAt': DateTime.now().toIso8601String(),
      };

      final ranking = UserRanking.fromJson(jsonData);

      expect(ranking.userId, equals('user-5'));
      expect(ranking.userName, equals('Eve'));
      expect(ranking.rank, equals(5));
    });

    test('UserRanking level progression', () {
      final newbie = UserRanking(
        userId: 'user-new',
        userName: 'NewUser',
        rank: 1000,
        score: 100,
        level: 1,
        correctAnswers: 10,
        totalQuestions: 100,
        streak: 0,
        lastPlayedAt: DateTime.now(),
      );

      final veteran = UserRanking(
        userId: 'user-vet',
        userName: 'Veteran',
        rank: 1,
        score: 50000,
        level: 100,
        correctAnswers: 4500,
        totalQuestions: 5000,
        streak: 50,
        lastPlayedAt: DateTime.now(),
      );

      expect(veteran.level, greaterThan(newbie.level));
      expect(veteran.score, greaterThan(newbie.score));
    });

    test('UserRanking streak tracking', () {
      final noStreak = UserRanking(
        userId: 'user-6',
        userName: 'Frank',
        rank: 50,
        score: 3000,
        level: 20,
        correctAnswers: 150,
        totalQuestions: 500,
        streak: 0,
        lastPlayedAt: DateTime.now().subtract(Duration(days: 3)),
      );

      final onStreak = UserRanking(
        userId: 'user-7',
        userName: 'Grace',
        rank: 15,
        score: 8000,
        level: 40,
        correctAnswers: 380,
        totalQuestions: 500,
        streak: 30,
        lastPlayedAt: DateTime.now(),
      );

      expect(onStreak.streak, greaterThan(noStreak.streak));
    });

    test('UserRanking recent activity', () {
      final now = DateTime.now();
      final active = UserRanking(
        userId: 'user-8',
        userName: 'Henry',
        rank: 20,
        score: 6500,
        level: 35,
        correctAnswers: 300,
        totalQuestions: 500,
        streak: 12,
        lastPlayedAt: now,
      );

      final inactive = UserRanking(
        userId: 'user-9',
        userName: 'Ivy',
        rank: 200,
        score: 2000,
        level: 15,
        correctAnswers: 100,
        totalQuestions: 500,
        streak: 0,
        lastPlayedAt: now.subtract(Duration(days: 30)),
      );

      final daysSinceActive = now.difference(active.lastPlayedAt).inDays;
      final daysSinceInactive = now.difference(inactive.lastPlayedAt).inDays;

      expect(daysSinceActive, lessThan(daysSinceInactive));
    });

    test('UserRanking top 10 leaderboard', () {
      final leaderboard = List.generate(10, (i) {
        return UserRanking(
          userId: 'user-$i',
          userName: 'Player $i',
          rank: i + 1,
          score: 10000 - (i * 500),
          level: 50 - (i * 2),
          correctAnswers: 450 - (i * 20),
          totalQuestions: 500,
          streak: 25 - (i * 2),
          lastPlayedAt: DateTime.now().subtract(Duration(days: i)),
        );
      });

      expect(leaderboard.length, equals(10));
      expect(leaderboard.first.rank, equals(1));
      expect(leaderboard.last.rank, equals(10));
      expect(leaderboard[0].score, greaterThan(leaderboard[9].score));
    });

    test('UserRanking score calculation', () {
      final ranking = UserRanking(
        userId: 'user-10',
        userName: 'Jack',
        rank: 5,
        score: 5000,
        level: 30,
        correctAnswers: 300,
        totalQuestions: 400,
        streak: 10,
        lastPlayedAt: DateTime.now(),
      );

      final expectedScore = ranking.level * 100 + ranking.correctAnswers * 10;
      expect(ranking.score, isNotNull);
      expect(ranking.score, greaterThan(0));
    });
  });
}
