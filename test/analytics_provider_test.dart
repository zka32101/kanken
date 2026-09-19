import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/analytics.dart';

void main() {
  group('Analytics Provider Tests', () {
    test('LearningAnalytics can track daily progress', () {
      final analytics = LearningAnalytics(
        userId: 'test-user',
        totalQuestionsAnswered: 100,
        correctAnswers: 85,
        averageTimePerQuestion: 45.5,
        streakDays: 7,
        lastActivityDate: DateTime.now(),
      );

      expect(analytics.userId, equals('test-user'));
      expect(analytics.totalQuestionsAnswered, equals(100));
      expect(analytics.correctAnswers, equals(85));
      expect(analytics.streakDays, equals(7));
    });

    test('LearningAnalytics calculates accuracy rate', () {
      final analytics = LearningAnalytics(
        userId: 'test-user',
        totalQuestionsAnswered: 100,
        correctAnswers: 85,
        averageTimePerQuestion: 45.5,
        streakDays: 3,
        lastActivityDate: DateTime.now(),
      );

      final accuracyRate =
          (analytics.correctAnswers / analytics.totalQuestionsAnswered) * 100;
      expect(accuracyRate, equals(85.0));
    });

    test('LearningAnalytics tracks streak days', () {
      final today = DateTime.now();
      final analytics = LearningAnalytics(
        userId: 'test-user',
        totalQuestionsAnswered: 50,
        correctAnswers: 40,
        averageTimePerQuestion: 40.0,
        streakDays: 5,
        lastActivityDate: today,
      );

      expect(analytics.streakDays, equals(5));
      expect(analytics.lastActivityDate, equals(today));
    });

    test('LearningAnalytics measures average response time', () {
      final analytics = LearningAnalytics(
        userId: 'test-user',
        totalQuestionsAnswered: 200,
        correctAnswers: 150,
        averageTimePerQuestion: 32.8,
        streakDays: 10,
        lastActivityDate: DateTime.now(),
      );

      expect(analytics.averageTimePerQuestion, equals(32.8));
      expect(analytics.averageTimePerQuestion, lessThan(60.0));
    });

    test('LearningAnalytics handles new user (zero stats)', () {
      final analytics = LearningAnalytics(
        userId: 'new-user',
        totalQuestionsAnswered: 0,
        correctAnswers: 0,
        averageTimePerQuestion: 0.0,
        streakDays: 0,
        lastActivityDate: DateTime.now(),
      );

      expect(analytics.totalQuestionsAnswered, equals(0));
      expect(analytics.correctAnswers, equals(0));
      expect(analytics.streakDays, equals(0));
    });

    test('LearningAnalytics fromJson creates instance from map', () {
      final jsonData = {
        'userId': 'test-user-123',
        'totalQuestionsAnswered': 500,
        'correctAnswers': 425,
        'averageTimePerQuestion': 38.5,
        'streakDays': 15,
        'lastActivityDate': DateTime.now().toIso8601String(),
      };

      final analytics = LearningAnalytics.fromJson(jsonData);

      expect(analytics.userId, equals('test-user-123'));
      expect(analytics.totalQuestionsAnswered, equals(500));
      expect(analytics.correctAnswers, equals(425));
      expect(analytics.streakDays, equals(15));
    });

    test('LearningAnalytics toJson converts to map', () {
      final now = DateTime.now();
      final analytics = LearningAnalytics(
        userId: 'test-user',
        totalQuestionsAnswered: 100,
        correctAnswers: 85,
        averageTimePerQuestion: 45.5,
        streakDays: 7,
        lastActivityDate: now,
      );

      final json = analytics.toJson();

      expect(json['userId'], equals('test-user'));
      expect(json['totalQuestionsAnswered'], equals(100));
      expect(json['correctAnswers'], equals(85));
    });

    test('LearningAnalytics tracks improvement over time', () {
      final oldAnalytics = LearningAnalytics(
        userId: 'test-user',
        totalQuestionsAnswered: 100,
        correctAnswers: 70,
        averageTimePerQuestion: 50.0,
        streakDays: 3,
        lastActivityDate: DateTime.now().subtract(Duration(days: 7)),
      );

      final newAnalytics = LearningAnalytics(
        userId: 'test-user',
        totalQuestionsAnswered: 200,
        correctAnswers: 180,
        averageTimePerQuestion: 35.0,
        streakDays: 10,
        lastActivityDate: DateTime.now(),
      );

      final oldAccuracy = (oldAnalytics.correctAnswers / oldAnalytics.totalQuestionsAnswered);
      final newAccuracy = (newAnalytics.correctAnswers / newAnalytics.totalQuestionsAnswered);

      expect(newAccuracy, greaterThan(oldAccuracy));
      expect(newAnalytics.averageTimePerQuestion, lessThan(oldAnalytics.averageTimePerQuestion));
      expect(newAnalytics.streakDays, greaterThan(oldAnalytics.streakDays));
    });
  });
}
