import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/analytics.dart';

LearningAnalytics _make({
  String userId = 'test-user',
  int totalStudyMinutes = 120,
  double averageAccuracy = 0.85,
  int totalQuestionsAttempted = 100,
  int correctAnswers = 85,
  int currentStreak = 7,
  int longestStreak = 10,
  DateTime? lastStudyDate,
  Map<String, int> categoryStats = const {'読み': 40, '書き': 60},
}) =>
    LearningAnalytics(
      userId: userId,
      totalStudyMinutes: totalStudyMinutes,
      averageAccuracy: averageAccuracy,
      totalQuestionsAttempted: totalQuestionsAttempted,
      correctAnswers: correctAnswers,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastStudyDate: lastStudyDate ?? DateTime.now(),
      categoryStats: categoryStats,
    );

void main() {
  group('Analytics Provider Tests', () {
    test('LearningAnalytics can track daily progress', () {
      final analytics = _make();

      expect(analytics.userId, equals('test-user'));
      expect(analytics.totalQuestionsAttempted, equals(100));
      expect(analytics.correctAnswers, equals(85));
      expect(analytics.currentStreak, equals(7));
    });

    test('LearningAnalytics calculates accuracy rate', () {
      final analytics = _make();

      final accuracyRate =
          (analytics.correctAnswers / analytics.totalQuestionsAttempted) * 100;
      expect(accuracyRate, equals(85.0));
      expect(analytics.accuracyPercentage, closeTo(85.0, 1e-9));
    });

    test('LearningAnalytics tracks streak days', () {
      final today = DateTime.now();
      final analytics = _make(
        currentStreak: 5,
        longestStreak: 12,
        lastStudyDate: today,
      );

      expect(analytics.currentStreak, equals(5));
      expect(analytics.longestStreak, equals(12));
      expect(analytics.lastStudyDate, equals(today));
    });

    test('LearningAnalytics keeps total study minutes', () {
      final analytics = _make(totalStudyMinutes: 328);

      expect(analytics.totalStudyMinutes, equals(328));
      expect(analytics.totalStudyMinutes, greaterThan(0));
    });

    test('LearningAnalytics handles new user (zero stats)', () {
      final analytics = _make(
        userId: 'new-user',
        totalStudyMinutes: 0,
        averageAccuracy: 0.0,
        totalQuestionsAttempted: 0,
        correctAnswers: 0,
        currentStreak: 0,
        longestStreak: 0,
        categoryStats: const {},
      );

      expect(analytics.totalQuestionsAttempted, equals(0));
      expect(analytics.correctAnswers, equals(0));
      expect(analytics.currentStreak, equals(0));
      expect(analytics.categoryStats, isEmpty);
    });

    test('LearningAnalytics fromJson creates instance from map', () {
      final jsonData = {
        'userId': 'test-user-123',
        'totalStudyMinutes': 300,
        'averageAccuracy': 0.85,
        'totalQuestionsAttempted': 500,
        'correctAnswers': 425,
        'currentStreak': 15,
        'longestStreak': 20,
        'lastStudyDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'categoryStats': {'読み': 100},
      };

      final analytics = LearningAnalytics.fromJson(jsonData);

      expect(analytics.userId, equals('test-user-123'));
      expect(analytics.totalQuestionsAttempted, equals(500));
      expect(analytics.correctAnswers, equals(425));
      expect(analytics.currentStreak, equals(15));
      expect(analytics.lastStudyDate, equals(DateTime(2026, 1, 1)));
      expect(analytics.categoryStats['読み'], equals(100));
    });

    test('LearningAnalytics fromJson falls back to defaults', () {
      final analytics = LearningAnalytics.fromJson({'userId': 'u'});

      expect(analytics.totalQuestionsAttempted, equals(0));
      expect(analytics.averageAccuracy, equals(0.0));
      expect(analytics.categoryStats, isEmpty);
    });

    test('LearningAnalytics toJson converts to map', () {
      final now = DateTime.now();
      final json = _make(lastStudyDate: now).toJson();

      expect(json['userId'], equals('test-user'));
      expect(json['totalQuestionsAttempted'], equals(100));
      expect(json['correctAnswers'], equals(85));
      expect(json['lastStudyDate'], isA<Timestamp>());
    });

    test('LearningAnalytics tracks improvement over time', () {
      final oldAnalytics = _make(
        totalQuestionsAttempted: 100,
        correctAnswers: 70,
        currentStreak: 3,
        lastStudyDate: DateTime.now().subtract(const Duration(days: 7)),
      );
      final newAnalytics = _make(
        totalQuestionsAttempted: 200,
        correctAnswers: 180,
        currentStreak: 10,
      );

      final oldAccuracy =
          oldAnalytics.correctAnswers / oldAnalytics.totalQuestionsAttempted;
      final newAccuracy =
          newAnalytics.correctAnswers / newAnalytics.totalQuestionsAttempted;

      expect(newAccuracy, greaterThan(oldAccuracy));
      expect(newAnalytics.currentStreak, greaterThan(oldAnalytics.currentStreak));
    });
  });
}
