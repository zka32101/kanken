import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/parent_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('ChildLearningStats Tests', () {
    test('ChildLearningStats can be created with all fields', () {
      final stats = ChildLearningStats(
        childId: 'child1',
        childName: '太郎',
        currentLevel: 15,
        totalQuestions: 500,
        correctAnswers: 450,
        accuracyRate: 0.9,
        streakDays: 7,
        longestStreak: 14,
        totalLearningMinutes: 480,
        lastLearningAt: DateTime(2026, 9, 13),
        badgesAcquired: 8,
        totalBadges: 20,
      );

      expect(stats.childId, equals('child1'));
      expect(stats.childName, equals('太郎'));
      expect(stats.currentLevel, equals(15));
      expect(stats.accuracyRate, equals(0.9));
    });

    test('getAccuracyPercentage returns formatted percentage', () {
      final stats = ChildLearningStats(
        childId: 'child1',
        childName: '太郎',
        currentLevel: 10,
        totalQuestions: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        streakDays: 3,
        longestStreak: 5,
        totalLearningMinutes: 150,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 2,
        totalBadges: 10,
      );

      expect(stats.getAccuracyPercentage(), equals('75.0%'));
    });

    test('getBadgeAcquisitionRate returns percentage', () {
      final stats = ChildLearningStats(
        childId: 'child1',
        childName: '太郎',
        currentLevel: 10,
        totalQuestions: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        streakDays: 3,
        longestStreak: 5,
        totalLearningMinutes: 150,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 5,
        totalBadges: 10,
      );

      expect(stats.getBadgeAcquisitionRate(), equals('50.0%'));
    });

    test('getBadgeAcquisitionRate handles zero total badges', () {
      final stats = ChildLearningStats(
        childId: 'child1',
        childName: '太郎',
        currentLevel: 10,
        totalQuestions: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        streakDays: 3,
        longestStreak: 5,
        totalLearningMinutes: 150,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 0,
        totalBadges: 0,
      );

      expect(stats.getBadgeAcquisitionRate(), equals('0%'));
    });

    test('isActiveLearner returns true when streakDays >= 3', () {
      final activeStats = ChildLearningStats(
        childId: 'child1',
        childName: '太郎',
        currentLevel: 10,
        totalQuestions: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        streakDays: 3,
        longestStreak: 5,
        totalLearningMinutes: 150,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 2,
        totalBadges: 10,
      );

      final inactiveStats = ChildLearningStats(
        childId: 'child2',
        childName: '花子',
        currentLevel: 10,
        totalQuestions: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        streakDays: 1,
        longestStreak: 5,
        totalLearningMinutes: 150,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 2,
        totalBadges: 10,
      );

      expect(activeStats.isActiveLearner(), isTrue);
      expect(inactiveStats.isActiveLearner(), isFalse);
    });

    test('getDaysSinceLastLearning calculates correctly', () {
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      final stats = ChildLearningStats(
        childId: 'child1',
        childName: '太郎',
        currentLevel: 10,
        totalQuestions: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        streakDays: 3,
        longestStreak: 5,
        totalLearningMinutes: 150,
        lastLearningAt: threeDaysAgo,
        badgesAcquired: 2,
        totalBadges: 10,
      );

      expect(stats.getDaysSinceLastLearning(), equals(3));
    });

    test('JSON round-trip serialization', () {
      final createdAt = DateTime(2026, 9, 13);
      final original = ChildLearningStats(
        childId: 'child1',
        childName: '太郎',
        currentLevel: 15,
        totalQuestions: 500,
        correctAnswers: 450,
        accuracyRate: 0.9,
        streakDays: 7,
        longestStreak: 14,
        totalLearningMinutes: 480,
        lastLearningAt: createdAt,
        badgesAcquired: 8,
        totalBadges: 20,
      );

      final json = original.toJson();
      final fromJson = ChildLearningStats.fromJson(json);

      expect(fromJson.childId, equals(original.childId));
      expect(fromJson.childName, equals(original.childName));
      expect(fromJson.currentLevel, equals(original.currentLevel));
      expect(fromJson.accuracyRate, equals(original.accuracyRate));
      expect(fromJson.streakDays, equals(original.streakDays));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = {
        'childId': 'child1',
        'childName': '太郎',
      };

      final stats = ChildLearningStats.fromJson(json);
      expect(stats.childId, equals('child1'));
      expect(stats.currentLevel, equals(10));
      expect(stats.totalQuestions, equals(0));
      expect(stats.accuracyRate, equals(0.0));
    });
  });

  group('LearningDataPoint Tests', () {
    test('LearningDataPoint can be created', () {
      final date = DateTime(2026, 9, 13);
      final point = LearningDataPoint(
        date: date,
        questionsAnswered: 20,
        correctAnswers: 18,
        accuracyRate: 0.9,
      );

      expect(point.date, equals(date));
      expect(point.questionsAnswered, equals(20));
      expect(point.correctAnswers, equals(18));
    });

    test('JSON round-trip serialization', () {
      final date = DateTime(2026, 9, 13);
      final original = LearningDataPoint(
        date: date,
        questionsAnswered: 20,
        correctAnswers: 18,
        accuracyRate: 0.9,
      );

      final json = original.toJson();
      final fromJson = LearningDataPoint.fromJson(json);

      expect(fromJson.questionsAnswered, equals(original.questionsAnswered));
      expect(fromJson.correctAnswers, equals(original.correctAnswers));
      expect(fromJson.accuracyRate, equals(original.accuracyRate));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = {
        'date': Timestamp.now(),
      };

      final point = LearningDataPoint.fromJson(json);
      expect(point.questionsAnswered, equals(0));
      expect(point.correctAnswers, equals(0));
      expect(point.accuracyRate, equals(0.0));
    });
  });

  group('ChildWeakArea Tests', () {
    test('ChildWeakArea can be created', () {
      final area = ChildWeakArea(
        categoryId: 'cat1',
        categoryName: '四字熟語',
        totalAttempts: 50,
        correctAnswers: 30,
        accuracyRate: 0.6,
        level: 'weak',
        lastAttemptAt: DateTime.now(),
      );

      expect(area.categoryId, equals('cat1'));
      expect(area.categoryName, equals('四字熟語'));
      expect(area.level, equals('weak'));
    });

    test('needsImprovement returns true for weak and veryWeak', () {
      final weakArea = ChildWeakArea(
        categoryId: 'cat1',
        categoryName: '四字熟語',
        totalAttempts: 50,
        correctAnswers: 30,
        accuracyRate: 0.6,
        level: 'weak',
        lastAttemptAt: DateTime.now(),
      );

      final veryWeakArea = ChildWeakArea(
        categoryId: 'cat2',
        categoryName: '読み方',
        totalAttempts: 50,
        correctAnswers: 20,
        accuracyRate: 0.4,
        level: 'veryWeak',
        lastAttemptAt: DateTime.now(),
      );

      final goodArea = ChildWeakArea(
        categoryId: 'cat3',
        categoryName: '意味',
        totalAttempts: 50,
        correctAnswers: 45,
        accuracyRate: 0.9,
        level: 'good',
        lastAttemptAt: DateTime.now(),
      );

      expect(weakArea.needsImprovement(), isTrue);
      expect(veryWeakArea.needsImprovement(), isTrue);
      expect(goodArea.needsImprovement(), isFalse);
    });

    test('getLevelLabel returns Japanese labels', () {
      final excellentArea = ChildWeakArea(
        categoryId: 'cat1',
        categoryName: '四字熟語',
        totalAttempts: 50,
        correctAnswers: 50,
        accuracyRate: 1.0,
        level: 'excellent',
        lastAttemptAt: DateTime.now(),
      );

      final goodArea = ChildWeakArea(
        categoryId: 'cat2',
        categoryName: '読み方',
        totalAttempts: 50,
        correctAnswers: 45,
        accuracyRate: 0.9,
        level: 'good',
        lastAttemptAt: DateTime.now(),
      );

      final normalArea = ChildWeakArea(
        categoryId: 'cat3',
        categoryName: '意味',
        totalAttempts: 50,
        correctAnswers: 35,
        accuracyRate: 0.7,
        level: 'normal',
        lastAttemptAt: DateTime.now(),
      );

      final weakArea = ChildWeakArea(
        categoryId: 'cat4',
        categoryName: '音読み',
        totalAttempts: 50,
        correctAnswers: 25,
        accuracyRate: 0.5,
        level: 'weak',
        lastAttemptAt: DateTime.now(),
      );

      final veryWeakArea = ChildWeakArea(
        categoryId: 'cat5',
        categoryName: '訓読み',
        totalAttempts: 50,
        correctAnswers: 10,
        accuracyRate: 0.2,
        level: 'veryWeak',
        lastAttemptAt: DateTime.now(),
      );

      expect(excellentArea.getLevelLabel(), equals('優秀'));
      expect(goodArea.getLevelLabel(), equals('良好'));
      expect(normalArea.getLevelLabel(), equals('普通'));
      expect(weakArea.getLevelLabel(), equals('要改善'));
      expect(veryWeakArea.getLevelLabel(), equals('要強化'));
    });

    test('JSON round-trip serialization', () {
      final lastAttempt = DateTime(2026, 9, 13);
      final original = ChildWeakArea(
        categoryId: 'cat1',
        categoryName: '四字熟語',
        totalAttempts: 50,
        correctAnswers: 30,
        accuracyRate: 0.6,
        level: 'weak',
        lastAttemptAt: lastAttempt,
      );

      final json = original.toJson();
      final fromJson = ChildWeakArea.fromJson(json);

      expect(fromJson.categoryId, equals(original.categoryId));
      expect(fromJson.categoryName, equals(original.categoryName));
      expect(fromJson.totalAttempts, equals(original.totalAttempts));
      expect(fromJson.level, equals(original.level));
    });
  });

  group('ParentDashboardStats Tests', () {
    test('getChildrenCount returns correct count', () {
      final stats1 = ChildLearningStats(
        childId: 'child1',
        childName: '太郎',
        currentLevel: 10,
        totalQuestions: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        streakDays: 3,
        longestStreak: 5,
        totalLearningMinutes: 150,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 2,
        totalBadges: 10,
      );

      final stats2 = ChildLearningStats(
        childId: 'child2',
        childName: '花子',
        currentLevel: 12,
        totalQuestions: 150,
        correctAnswers: 120,
        accuracyRate: 0.8,
        streakDays: 5,
        longestStreak: 10,
        totalLearningMinutes: 200,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 3,
        totalBadges: 10,
      );

      final dashboardStats = ParentDashboardStats(
        parentId: 'parent1',
        childrenStats: [stats1, stats2],
        learningGraphData: {},
        weakAreas: {},
      );

      expect(dashboardStats.getChildrenCount(), equals(2));
    });

    test('getAverageAccuracyRate calculates correctly', () {
      final stats1 = ChildLearningStats(
        childId: 'child1',
        childName: '太郎',
        currentLevel: 10,
        totalQuestions: 100,
        correctAnswers: 75,
        accuracyRate: 0.8,
        streakDays: 3,
        longestStreak: 5,
        totalLearningMinutes: 150,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 2,
        totalBadges: 10,
      );

      final stats2 = ChildLearningStats(
        childId: 'child2',
        childName: '花子',
        currentLevel: 12,
        totalQuestions: 150,
        correctAnswers: 120,
        accuracyRate: 0.6,
        streakDays: 5,
        longestStreak: 10,
        totalLearningMinutes: 200,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 3,
        totalBadges: 10,
      );

      final dashboardStats = ParentDashboardStats(
        parentId: 'parent1',
        childrenStats: [stats1, stats2],
        learningGraphData: {},
        weakAreas: {},
      );

      expect(dashboardStats.getAverageAccuracyRate(), equals(0.7));
    });

    test('getAverageAccuracyRate returns 0 for empty children', () {
      final dashboardStats = ParentDashboardStats(
        parentId: 'parent1',
        childrenStats: [],
        learningGraphData: {},
        weakAreas: {},
      );

      expect(dashboardStats.getAverageAccuracyRate(), equals(0.0));
    });

    test('getWeakAreasCount counts only weak and veryWeak areas', () {
      final weakAreas = {
        'child1': [
          ChildWeakArea(
            categoryId: 'cat1',
            categoryName: '四字熟語',
            totalAttempts: 50,
            correctAnswers: 30,
            accuracyRate: 0.6,
            level: 'weak',
            lastAttemptAt: DateTime.now(),
          ),
          ChildWeakArea(
            categoryId: 'cat2',
            categoryName: '読み方',
            totalAttempts: 50,
            correctAnswers: 20,
            accuracyRate: 0.4,
            level: 'veryWeak',
            lastAttemptAt: DateTime.now(),
          ),
          ChildWeakArea(
            categoryId: 'cat3',
            categoryName: '意味',
            totalAttempts: 50,
            correctAnswers: 45,
            accuracyRate: 0.9,
            level: 'good',
            lastAttemptAt: DateTime.now(),
          ),
        ],
      };

      final dashboardStats = ParentDashboardStats(
        parentId: 'parent1',
        childrenStats: [],
        learningGraphData: {},
        weakAreas: weakAreas,
      );

      expect(dashboardStats.getWeakAreasCount(), equals(2));
    });

    test('getTotalStreakDays sums all children streaks', () {
      final stats1 = ChildLearningStats(
        childId: 'child1',
        childName: '太郎',
        currentLevel: 10,
        totalQuestions: 100,
        correctAnswers: 75,
        accuracyRate: 0.75,
        streakDays: 5,
        longestStreak: 5,
        totalLearningMinutes: 150,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 2,
        totalBadges: 10,
      );

      final stats2 = ChildLearningStats(
        childId: 'child2',
        childName: '花子',
        currentLevel: 12,
        totalQuestions: 150,
        correctAnswers: 120,
        accuracyRate: 0.8,
        streakDays: 7,
        longestStreak: 10,
        totalLearningMinutes: 200,
        lastLearningAt: DateTime.now(),
        badgesAcquired: 3,
        totalBadges: 10,
      );

      final dashboardStats = ParentDashboardStats(
        parentId: 'parent1',
        childrenStats: [stats1, stats2],
        learningGraphData: {},
        weakAreas: {},
      );

      expect(dashboardStats.getTotalStreakDays(), equals(12));
    });
  });
}
