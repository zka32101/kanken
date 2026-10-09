import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/achievement.dart';
import 'package:kanken/models/reward.dart';
import 'package:kanken/models/user.dart';

void main() {
  group('User Tests', () {
    test('User can be created with defaults', () {
      final user = User(
        uid: 'user1',
        currentLevel: 'LEVEL_10',
        streakCount: 3,
        createdAt: DateTime.now(),
      );

      expect(user.uid, equals('user1'));
      expect(user.profileId, equals('default'));
      expect(user.rankingOptIn, isFalse);
      expect(user.masteryThreshold, equals(3));
      expect(user.examDate, isNull);
    });

    test('JSON round-trip serialization', () {
      final original = User(
        uid: 'user1',
        profileId: 'p2',
        displayName: '太郎',
        avatarIcon: '🐱',
        currentLevel: 'LEVEL_5',
        streakCount: 7,
        createdAt: DateTime(2026, 9, 13),
        examDate: DateTime(2026, 11, 1),
        rankingOptIn: true,
        masteryThreshold: 5,
        lastStudyDate: DateTime(2026, 9, 12),
      );

      final fromJson = User.fromJson(original.toJson());

      expect(fromJson.uid, equals(original.uid));
      expect(fromJson.profileId, equals('p2'));
      expect(fromJson.displayName, equals('太郎'));
      expect(fromJson.avatarIcon, equals('🐱'));
      expect(fromJson.currentLevel, equals('LEVEL_5'));
      expect(fromJson.examDate, equals(original.examDate));
      expect(fromJson.rankingOptIn, isTrue);
      expect(fromJson.masteryThreshold, equals(5));
      expect(fromJson.lastStudyDate, equals(original.lastStudyDate));
    });

    test('copyWith で値を変更でき clearExamDate で受験日を消せる', () {
      final user = User(
        uid: 'user1',
        currentLevel: 'LEVEL_10',
        streakCount: 0,
        createdAt: DateTime(2026, 9, 13),
        examDate: DateTime(2026, 11, 1),
      );

      expect(user.copyWith(streakCount: 4).streakCount, equals(4));
      expect(user.copyWith(streakCount: 4).examDate, equals(user.examDate));
      expect(user.copyWith(clearExamDate: true).examDate, isNull);
    });
  });

  group('Achievement Tests', () {
    test('Achievement can be created', () {
      final achievement = Achievement(
        id: 'ach1',
        name: '初心者',
        description: '最初のレベルに到達',
        icon: '⭐',
        type: AchievementType.milestone,
        points: 100,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      expect(achievement.id, equals('ach1'));
      expect(achievement.isUnlocked, isTrue);
      expect(achievement.points, equals(100));
    });

    test('JSON round-trip serialization', () {
      final original = Achievement(
        id: 'ach1',
        name: '初心者',
        description: '最初のレベルに到達',
        icon: '⭐',
        type: AchievementType.streak,
        points: 100,
        isUnlocked: true,
        unlockedAt: DateTime(2026, 9, 13),
      );

      final fromJson = Achievement.fromJson(original.toJson());

      expect(fromJson.id, equals(original.id));
      expect(fromJson.name, equals(original.name));
      expect(fromJson.type, equals(AchievementType.streak));
      expect(fromJson.isUnlocked, isTrue);
      expect(fromJson.unlockedAt, equals(original.unlockedAt));
    });

    test('定義済みアチーブメントのIDは重複せず検索できる', () {
      final ids = AchievementDefinition.allAchievements.map((a) => a.id);
      expect(ids.toSet().length, equals(ids.length));
      expect(AchievementDefinition.getAchievementById('streak_7'), isNotNull);
      expect(AchievementDefinition.getAchievementById('nonexistent'), isNull);
    });
  });

  group('Reward Tests', () {
    test('各ファクトリの種類と量が正しい', () {
      expect(Reward.correctAnswer().type, equals(RewardType.correctAnswer));
      expect(Reward.correctAnswer().amount, equals(10));
      expect(Reward.allCorrect().amount, equals(50));
      expect(Reward.dailyChallengeComplete().amount, equals(100));
      expect(Reward.levelUp(5).metadata, equals({'newLevel': 5}));
    });

    test('連続日数ボーナスは5日ごとに10加算される', () {
      expect(Reward.streakBonus(1).amount, equals(50));
      expect(Reward.streakBonus(5).amount, equals(60));
      expect(Reward.streakBonus(10).amount, equals(70));
    });

    test('JSON round-trip serialization', () {
      final original = Reward.streakBonus(7, id: 'r1');

      final fromJson = Reward.fromJson(original.toJson());

      expect(fromJson.id, equals('r1'));
      expect(fromJson.type, equals(RewardType.streakBonus));
      expect(fromJson.amount, equals(original.amount));
      expect(fromJson.message, equals(original.message));
      expect(fromJson.metadata, equals({'streak': 7}));
    });
  });
}
