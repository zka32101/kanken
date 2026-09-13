import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/profile.dart';

void main() {
  group('UserProfile Tests', () {
    test('UserProfile can be created', () {
      final profile = UserProfile(
        userId: 'user1',
        displayName: '太郎',
        bio: '漢字学習中',
        level: 15,
        experience: 1200,
        totalBattles: 25,
        totalWins: 18,
        totalExamsCompleted: 10,
        bestExamScore: 0.95,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      expect(profile.userId, equals('user1'));
      expect(profile.level, equals(15));
      expect(profile.winRate, closeTo(0.72, 0.01));
    });

    test('JSON round-trip serialization', () {
      final original = UserProfile(
        userId: 'user1',
        displayName: '太郎',
        bio: null,
        level: 15,
        experience: 1200,
        totalBattles: 25,
        totalWins: 18,
        totalExamsCompleted: 10,
        bestExamScore: 0.95,
        createdAt: DateTime(2026, 9, 13),
        lastLogin: DateTime(2026, 9, 13),
      );

      final json = original.toJson();
      final fromJson = UserProfile.fromJson(json as Map<String, dynamic>);

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.level, equals(original.level));
      expect(fromJson.winRate, closeTo(original.winRate, 0.01));
    });
  });

  group('Achievement Tests', () {
    test('Achievement can be created', () {
      final achievement = Achievement(
        achievementId: 'ach1',
        userId: 'user1',
        name: '初心者',
        description: '最初のレベルに到達',
        rewardPoints: 100,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      expect(achievement.achievementId, equals('ach1'));
      expect(achievement.isUnlocked, isTrue);
      expect(achievement.rewardPoints, equals(100));
    });

    test('JSON round-trip serialization', () {
      final original = Achievement(
        achievementId: 'ach1',
        userId: 'user1',
        name: '初心者',
        description: '最初のレベルに到達',
        rewardPoints: 100,
        isUnlocked: true,
        unlockedAt: DateTime(2026, 9, 13),
      );

      final json = original.toJson();
      final fromJson = Achievement.fromJson(json as Map<String, dynamic>);

      expect(fromJson.achievementId, equals(original.achievementId));
      expect(fromJson.name, equals(original.name));
      expect(fromJson.isUnlocked, isTrue);
    });
  });

  group('LevelReward Tests', () {
    test('LevelReward can be created', () {
      final reward = LevelReward(
        level: 1,
        requiredExperience: 1000,
        rewardCoins: 100,
        rewardDiamonds: 10,
      );

      expect(reward.level, equals(1));
      expect(reward.requiredExperience, equals(1000));
      expect(reward.rewardCoins, equals(100));
    });

    test('JSON round-trip serialization', () {
      final original = LevelReward(
        level: 1,
        requiredExperience: 1000,
        rewardCoins: 100,
        rewardDiamonds: 10,
      );

      final json = original.toJson();
      final fromJson = LevelReward.fromJson(json as Map<String, dynamic>);

      expect(fromJson.level, equals(original.level));
      expect(fromJson.rewardCoins, equals(original.rewardCoins));
      expect(fromJson.rewardDiamonds, equals(original.rewardDiamonds));
    });
  });
}
