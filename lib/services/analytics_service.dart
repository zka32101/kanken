import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// KPI 計測サービス
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Aha Moment 到達イベント（初回3問正解）
  static Future<void> logAhaMomentReached({
    required String level,
  }) async {
    await _analytics.logEvent(
      name: 'aha_moment_reached',
      parameters: {
        'level': level,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 模擬試験完了イベント
  static Future<void> logMockExamCompleted({
    required String level,
    required int score,
    required bool passed,
    required int timeTakenSeconds,
  }) async {
    await _analytics.logEvent(
      name: 'mock_exam_completed',
      parameters: {
        'level': level,
        'score': score,
        'passed': passed,
        'time_taken_seconds': timeTakenSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 苦手集中トレーニング完了イベント
  static Future<void> logWeakKanjiPracticed({
    required String level,
    required int questionsCount,
  }) async {
    await _analytics.logEvent(
      name: 'weak_kanji_practiced',
      parameters: {
        'level': level,
        'questions_count': questionsCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// バッジ獲得イベント
  static Future<void> logBadgeUnlocked({
    required String level,
  }) async {
    await _analytics.logEvent(
      name: 'badge_unlocked',
      parameters: {
        'level': level,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 有料転換イベント
  static Future<void> logPaywallConverted({
    required String level,
    required double price,
  }) async {
    await _analytics.logEvent(
      name: 'paywall_converted',
      parameters: {
        'level': level,
        'price': price,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// カスタムイベント
  static Future<void> logCustomEvent(
    String eventName, {
    required Map<String, dynamic> parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }

  /// ユーザーID設定（リテンション追跡用）
  static Future<void> setUserId(String uid) async {
    // setUserId API has changed in firebase_analytics 10.7.0
    // Use setUserProperty instead
    await _analytics.setUserProperty(name: 'user_id', value: uid);
    await _crashlytics.setUserIdentifier(uid);
  }

  /// クラッシュログ記録
  static Future<void> recordException(
    dynamic exception,
    StackTrace stackTrace,
  ) async {
    await _crashlytics.recordError(exception, stackTrace);
  }

  /// Day1/7/30 リテンション判定用の初回起動イベント
  static Future<void> logAppOpen({required String userId}) async {
    await _analytics.logAppOpen();
  }
}
