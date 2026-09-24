import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/analytics.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.currentUser?.uid;
});

/// ユーザーの学習分析データを取得
final userLearningAnalyticsProvider =
    FutureProvider<LearningAnalytics?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final firestore = ref.watch(firebaseFirestoreProvider);
  final doc = await firestore.collection('users').doc(userId).get();

  if (!doc.exists) return null;

  return LearningAnalytics.fromJson({
    'userId': userId,
    ...doc.data() ?? {},
  });
});

/// ユーザーの成長データ（過去30日）を取得
final userGrowthDataProvider =
    FutureProvider<List<GrowthData>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestore = ref.watch(firebaseFirestoreProvider);
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

  final querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('growthData')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
      .orderBy('date', descending: false)
      .get();

  return querySnapshot.docs
      .map((doc) => GrowthData.fromJson(doc.data()))
      .toList();
});

/// ユーザーの学習トレンド
final userLearningTrendsProvider =
    FutureProvider<List<LearningTrend>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('learningTrends')
      .orderBy('averageTrend', descending: true)
      .get();

  return querySnapshot.docs
      .map((doc) => LearningTrend.fromJson(doc.data()))
      .toList();
});

/// ユーザーの学習効率
final userStudyEfficiencyProvider =
    FutureProvider<StudyEfficiency?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final firestore = ref.watch(firebaseFirestoreProvider);
  final doc = await firestore
      .collection('users')
      .doc(userId)
      .collection('studyEfficiency')
      .doc('current')
      .get();

  if (!doc.exists) return null;

  return StudyEfficiency.fromJson(doc.data() ?? {});
});

// 学習目標(LearningGoal)の作成・一覧・達成管理は
// lib/providers/learning_goal_provider.dart + lib/models/learning_goal.dart
// (learning_goals_screen.dart が使う実装)に一本化した。
// 以前ここにあった userLearningGoalsProvider / AnalyticsDashboardState /
// AnalyticsDashboardNotifier / analyticsDashboardProvider は、
// 同じFirestoreコレクション(users/{uid}/learningGoals)を別スキーマの
// LearningGoal(lib/models/analytics.dart)で読み書きしており、
// 「学習目標を設定しても一覧に出てこない・保存したはずが消える」
// 不具合の原因になっていたため削除した。
