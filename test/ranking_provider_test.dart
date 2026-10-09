import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/user_ranking.dart';

UserRanking _make({
  String userId = 'user-1',
  String userName = 'Alice',
  int rank = 1,
  int level = 50,
  int experience = 10000,
  int coins = 500,
  double accuracyRate = 0.9,
  int streak = 25,
  DateTime? lastPlayedAt,
}) {
  return UserRanking(
    userId: userId,
    userName: userName,
    rank: rank,
    level: level,
    experience: experience,
    coins: coins,
    accuracyRate: accuracyRate,
    streak: streak,
    lastPlayedAt: lastPlayedAt ?? DateTime.now(),
  );
}

void main() {
  group('UserRanking Tests', () {
    test('UserRanking creates with valid data', () {
      final ranking = _make();

      expect(ranking.userId, equals('user-1'));
      expect(ranking.userName, equals('Alice'));
      expect(ranking.rank, equals(1));
      expect(ranking.experience, equals(10000));
    });

    test('UserRanking rank ordering', () {
      final rankings = [
        _make(rank: 1, experience: 10000, level: 50),
        _make(userId: 'user-2', userName: 'Bob', rank: 2, experience: 9500, level: 48),
        _make(userId: 'user-3', userName: 'Charlie', rank: 3, experience: 9000, level: 45),
      ];

      expect(rankings[0].rank, lessThan(rankings[1].rank));
      expect(rankings[0].experience, greaterThan(rankings[1].experience));
    });

    test('UserRanking getRankBadge / getRankLabel', () {
      expect(_make(rank: 1).getRankBadge(), equals('🥇'));
      expect(_make(rank: 2).getRankBadge(), equals('🥈'));
      expect(_make(rank: 3).getRankBadge(), equals('🥉'));
      expect(_make(rank: 10).getRankBadge(), equals('10位'));
      expect(_make(rank: 1).getRankLabel(), equals('1位 (金)'));
      expect(_make(rank: 2).getRankLabel(), equals('2位 (銀)'));
      expect(_make(rank: 3).getRankLabel(), equals('3位 (銅)'));
      expect(_make(rank: 10).getRankLabel(), equals('10位'));
    });

    test('UserRanking fromJson creates instance', () {
      final jsonData = {
        'userId': 'user-5',
        'userName': 'Eve',
        'rank': 5,
        'level': 35,
        'experience': 7500,
        'coins': 120,
        'accuracyRate': 0.7,
        'streak': 8,
        'lastPlayedAt': Timestamp.fromDate(DateTime(2026, 9, 13)),
      };

      final ranking = UserRanking.fromJson(jsonData);

      expect(ranking.userId, equals('user-5'));
      expect(ranking.userName, equals('Eve'));
      expect(ranking.rank, equals(5));
      expect(ranking.experience, equals(7500));
      expect(ranking.coins, equals(120));
      expect(ranking.accuracyRate, equals(0.7));
      expect(ranking.lastPlayedAt, equals(DateTime(2026, 9, 13)));
    });

    test('UserRanking fromJson: 欠損フィールドはデフォルト値', () {
      final ranking = UserRanking.fromJson({});

      expect(ranking.userId, equals(''));
      expect(ranking.userName, equals('Unknown'));
      expect(ranking.rank, equals(0));
      expect(ranking.level, equals(1));
      expect(ranking.accuracyRate, equals(0.0));
    });

    test('UserRanking JSON round-trip', () {
      final original = _make(lastPlayedAt: DateTime(2026, 9, 13, 8));

      final restored = UserRanking.fromJson(original.toJson());

      expect(restored.userId, equals(original.userId));
      expect(restored.rank, equals(original.rank));
      expect(restored.level, equals(original.level));
      expect(restored.experience, equals(original.experience));
      expect(restored.coins, equals(original.coins));
      expect(restored.accuracyRate, equals(original.accuracyRate));
      expect(restored.streak, equals(original.streak));
      expect(restored.lastPlayedAt, equals(original.lastPlayedAt));
    });

    test('UserRanking level progression', () {
      final newbie = _make(level: 1, experience: 100, rank: 1000);
      final veteran = _make(level: 100, experience: 50000, rank: 1);

      expect(veteran.level, greaterThan(newbie.level));
      expect(veteran.experience, greaterThan(newbie.experience));
    });

    test('UserRanking streak tracking', () {
      final noStreak = _make(streak: 0);
      final onStreak = _make(streak: 30);

      expect(onStreak.streak, greaterThan(noStreak.streak));
    });

    test('UserRanking recent activity', () {
      final now = DateTime.now();
      final active = _make(lastPlayedAt: now);
      final inactive = _make(lastPlayedAt: now.subtract(const Duration(days: 30)));

      final daysSinceActive = now.difference(active.lastPlayedAt).inDays;
      final daysSinceInactive = now.difference(inactive.lastPlayedAt).inDays;

      expect(daysSinceActive, lessThan(daysSinceInactive));
    });

    test('UserRanking top 10 leaderboard', () {
      final leaderboard = List.generate(10, (i) {
        return _make(
          userId: 'user-$i',
          userName: 'Player $i',
          rank: i + 1,
          experience: 10000 - (i * 500),
          level: 50 - (i * 2),
        );
      });

      expect(leaderboard.length, equals(10));
      expect(leaderboard.first.rank, equals(1));
      expect(leaderboard.last.rank, equals(10));
      expect(leaderboard[0].experience, greaterThan(leaderboard[9].experience));
    });
  });

  group('RankingFilter Tests', () {
    test('同じ値のフィルターは等価（Riverpod familyのキャッシュ判定用）', () {
      const a = RankingFilter(type: RankingType.experience, limit: 50);
      const b = RankingFilter(type: RankingType.experience, limit: 50);
      const c = RankingFilter(type: RankingType.streak, limit: 50);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('デフォルトはレベル順・全期間・100件', () {
      const f = RankingFilter();

      expect(f.type, equals(RankingType.level));
      expect(f.period, equals(RankingPeriod.allTime));
      expect(f.limit, equals(100));
    });
  });
}
