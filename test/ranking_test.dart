import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/user_ranking.dart';

void main() {
  group('UserRanking Model', () {
    test('ユーザーランキングの生成', () {
      final ranking = UserRanking(
        userId: 'user123',
        userName: '太郎',
        rank: 1,
        level: 10,
        experience: 5000,
        coins: 1000,
        accuracyRate: 0.95,
        streak: 15,
        lastPlayedAt: DateTime.now(),
      );

      expect(ranking.userId, 'user123');
      expect(ranking.userName, '太郎');
      expect(ranking.rank, 1);
      expect(ranking.level, 10);
      expect(ranking.experience, 5000);
      expect(ranking.coins, 1000);
      expect(ranking.accuracyRate, 0.95);
      expect(ranking.streak, 15);
    });

    test('ランクバッジ表示 (1位)', () {
      final ranking = UserRanking(
        userId: 'user1',
        userName: '1位ユーザー',
        rank: 1,
        level: 20,
        experience: 10000,
        coins: 5000,
        accuracyRate: 1.0,
        streak: 30,
        lastPlayedAt: DateTime.now(),
      );

      expect(ranking.getRankBadge(), '🥇');
    });

    test('ランクバッジ表示 (2位)', () {
      final ranking = UserRanking(
        userId: 'user2',
        userName: '2位ユーザー',
        rank: 2,
        level: 18,
        experience: 9000,
        coins: 4500,
        accuracyRate: 0.98,
        streak: 25,
        lastPlayedAt: DateTime.now(),
      );

      expect(ranking.getRankBadge(), '🥈');
    });

    test('ランクバッジ表示 (3位)', () {
      final ranking = UserRanking(
        userId: 'user3',
        userName: '3位ユーザー',
        rank: 3,
        level: 16,
        experience: 8000,
        coins: 4000,
        accuracyRate: 0.92,
        streak: 20,
        lastPlayedAt: DateTime.now(),
      );

      expect(ranking.getRankBadge(), '🥉');
    });

    test('ランクバッジ表示 (10位以降)', () {
      final ranking = UserRanking(
        userId: 'user10',
        userName: '10位ユーザー',
        rank: 10,
        level: 8,
        experience: 3500,
        coins: 1500,
        accuracyRate: 0.75,
        streak: 5,
        lastPlayedAt: DateTime.now(),
      );

      expect(ranking.getRankBadge(), '10位');
    });

    test('ランク表示テキスト (1位)', () {
      final ranking = UserRanking(
        userId: 'user1',
        userName: 'Champion',
        rank: 1,
        level: 20,
        experience: 10000,
        coins: 5000,
        accuracyRate: 1.0,
        streak: 30,
        lastPlayedAt: DateTime.now(),
      );

      expect(ranking.getRankLabel(), '1位 (金)');
    });

    test('ランク表示テキスト (2位)', () {
      final ranking = UserRanking(
        userId: 'user2',
        userName: 'Runner-up',
        rank: 2,
        level: 18,
        experience: 9000,
        coins: 4500,
        accuracyRate: 0.98,
        streak: 25,
        lastPlayedAt: DateTime.now(),
      );

      expect(ranking.getRankLabel(), '2位 (銀)');
    });

    test('ランク表示テキスト (3位)', () {
      final ranking = UserRanking(
        userId: 'user3',
        userName: 'Third',
        rank: 3,
        level: 16,
        experience: 8000,
        coins: 4000,
        accuracyRate: 0.92,
        streak: 20,
        lastPlayedAt: DateTime.now(),
      );

      expect(ranking.getRankLabel(), '3位 (銅)');
    });

    test('JSON シリアライズ・デシリアライズ', () {
      final original = UserRanking(
        userId: 'user123',
        userName: '太郎',
        rank: 5,
        level: 12,
        experience: 6000,
        coins: 2000,
        accuracyRate: 0.88,
        streak: 10,
        lastPlayedAt: DateTime.now(),
      );

      final json = original.toJson();
      final restored = UserRanking.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.userName, original.userName);
      expect(restored.rank, original.rank);
      expect(restored.level, original.level);
      expect(restored.experience, original.experience);
      expect(restored.coins, original.coins);
      expect(restored.accuracyRate, original.accuracyRate);
      expect(restored.streak, original.streak);
    });

    test('デフォルト値処理', () {
      final json = {
        'userId': 'user456',
        // 一部フィールドを省略
      };

      final ranking = UserRanking.fromJson(json);

      expect(ranking.userId, 'user456');
      expect(ranking.userName, 'Unknown');
      expect(ranking.rank, 0);
      expect(ranking.level, 1);
      expect(ranking.experience, 0);
      expect(ranking.coins, 0);
      expect(ranking.accuracyRate, 0.0);
      expect(ranking.streak, 0);
    });
  });

  group('RankingType Enum', () {
    test('ランキングタイプが定義されている', () {
      expect(RankingType.level, isNotNull);
      expect(RankingType.experience, isNotNull);
      expect(RankingType.accuracy, isNotNull);
      expect(RankingType.streak, isNotNull);
      expect(RankingType.coins, isNotNull);
    });
  });

  group('RankingPeriod Enum', () {
    test('期間タイプが定義されている', () {
      expect(RankingPeriod.weekly, isNotNull);
      expect(RankingPeriod.monthly, isNotNull);
      expect(RankingPeriod.allTime, isNotNull);
    });
  });

  group('RankingFilter', () {
    test('デフォルト設定でフィルターを生成', () {
      final filter = const RankingFilter();

      expect(filter.type, RankingType.level);
      expect(filter.period, RankingPeriod.allTime);
      expect(filter.limit, 100);
    });

    test('カスタム設定でフィルターを生成', () {
      final filter = const RankingFilter(
        type: RankingType.accuracy,
        period: RankingPeriod.weekly,
        limit: 50,
      );

      expect(filter.type, RankingType.accuracy);
      expect(filter.period, RankingPeriod.weekly);
      expect(filter.limit, 50);
    });

    test('複数のフィルターバリエーション', () {
      final filters = [
        const RankingFilter(type: RankingType.level),
        const RankingFilter(type: RankingType.experience),
        const RankingFilter(type: RankingType.accuracy),
        const RankingFilter(type: RankingType.streak),
        const RankingFilter(type: RankingType.coins),
      ];

      expect(filters.length, 5);
      expect(filters[0].type, RankingType.level);
      expect(filters[4].type, RankingType.coins);
    });
  });

  group('ランキング比較ロジック', () {
    test('複数ユーザーをレベル順にソート', () {
      final users = [
        UserRanking(
          userId: 'user1',
          userName: 'Alice',
          rank: 1,
          level: 15,
          experience: 7500,
          coins: 3000,
          accuracyRate: 0.90,
          streak: 12,
          lastPlayedAt: DateTime.now(),
        ),
        UserRanking(
          userId: 'user2',
          userName: 'Bob',
          rank: 2,
          level: 10,
          experience: 5000,
          coins: 2000,
          accuracyRate: 0.85,
          streak: 8,
          lastPlayedAt: DateTime.now(),
        ),
        UserRanking(
          userId: 'user3',
          userName: 'Charlie',
          rank: 3,
          level: 20,
          experience: 10000,
          coins: 5000,
          accuracyRate: 0.95,
          streak: 20,
          lastPlayedAt: DateTime.now(),
        ),
      ];

      // レベルでソート
      users.sort((a, b) => b.level.compareTo(a.level));

      expect(users[0].level, 20); // Charlie
      expect(users[1].level, 15); // Alice
      expect(users[2].level, 10); // Bob
    });

    test('正答率が高いユーザーを抽出', () {
      final users = [
        UserRanking(
          userId: 'user1',
          userName: 'Alice',
          rank: 1,
          level: 10,
          experience: 5000,
          coins: 2000,
          accuracyRate: 0.75,
          streak: 5,
          lastPlayedAt: DateTime.now(),
        ),
        UserRanking(
          userId: 'user2',
          userName: 'Bob',
          rank: 2,
          level: 8,
          experience: 4000,
          coins: 1500,
          accuracyRate: 0.95,
          streak: 3,
          lastPlayedAt: DateTime.now(),
        ),
      ];

      final highAccuracy = users
          .where((u) => u.accuracyRate >= 0.9)
          .toList();

      expect(highAccuracy.length, 1);
      expect(highAccuracy[0].userName, 'Bob');
      expect(highAccuracy[0].accuracyRate, 0.95);
    });
  });
}
