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

/// ユーザーの学習目標
final userLearningGoalsProvider =
    FutureProvider<List<LearningGoal>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('learningGoals')
      .where('isCompleted', isEqualTo: false)
      .orderBy('deadline', descending: false)
      .get();

  return querySnapshot.docs
      .map((doc) => LearningGoal.fromJson(doc.data()))
      .toList();
});

/// 分析ダッシュボード状態
class AnalyticsDashboardState {
  final LearningAnalytics? analytics;
  final List<GrowthData> growthData;
  final List<LearningTrend> trends;
  final StudyEfficiency? efficiency;
  final List<LearningGoal> goals;

  const AnalyticsDashboardState({
    this.analytics,
    this.growthData = const [],
    this.trends = const [],
    this.efficiency,
    this.goals = const [],
  });

  AnalyticsDashboardState copyWith({
    LearningAnalytics? analytics,
    List<GrowthData>? growthData,
    List<LearningTrend>? trends,
    StudyEfficiency? efficiency,
    List<LearningGoal>? goals,
  }) =>
      AnalyticsDashboardState(
        analytics: analytics ?? this.analytics,
        growthData: growthData ?? this.growthData,
        trends: trends ?? this.trends,
        efficiency: efficiency ?? this.efficiency,
        goals: goals ?? this.goals,
      );
}

/// 分析ダッシュボード Notifier
class AnalyticsDashboardNotifier extends StateNotifier<AnalyticsDashboardState> {
  final FirebaseFirestore _firestore;
  final String? _userId;

  AnalyticsDashboardNotifier(this._firestore, this._userId)
      : super(const AnalyticsDashboardState());

  /// 学習目標を設定
  Future<void> setGoal({
    required String type, // 'daily', 'weekly', 'monthly'
    required int targetValue,
    required String goalType, // 'accuracy', 'questions', 'time'
  }) async {
    if (_userId == null) return;

    final deadline = _calculateDeadline(type);
    final goal = LearningGoal(
      goalId: _firestore.collection('users').doc().id,
      userId: _userId!,
      type: type,
      targetValue: targetValue,
      currentValue: 0,
      goalType: goalType,
      deadline: deadline,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('learningGoals')
        .doc(goal.goalId)
        .set(goal.toJson());

    state = state.copyWith(
      goals: [...state.goals, goal],
    );
  }

  /// 学習目標を更新
  Future<void> updateGoal(String goalId, int currentValue) async {
    if (_userId == null) return;

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('learningGoals')
        .doc(goalId)
        .update({'currentValue': currentValue});

    final updatedGoals = state.goals.map((goal) {
      if (goal.goalId == goalId) {
        return goal.copyWith(currentValue: currentValue);
      }
      return goal;
    }).toList();

    state = state.copyWith(goals: updatedGoals);
  }

  /// 学習目標を完了
  Future<void> completeGoal(String goalId) async {
    if (_userId == null) return;

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('learningGoals')
        .doc(goalId)
        .update({'isCompleted': true});

    state = state.copyWith(
      goals: state.goals.where((goal) => goal.goalId != goalId).toList(),
    );
  }

  /// 目標の期限を計算
  DateTime _calculateDeadline(String type) {
    final now = DateTime.now();
    switch (type) {
      case 'daily':
        return now.add(const Duration(days: 1));
      case 'weekly':
        return now.add(const Duration(days: 7));
      case 'monthly':
        return now.add(const Duration(days: 30));
      default:
        return now.add(const Duration(days: 1));
    }
  }

  LearningGoal copyWith(String goalId, {int? currentValue}) {
    final goal = state.goals.firstWhere(
      (g) => g.goalId == goalId,
      orElse: () => LearningGoal(
        goalId: '',
        userId: '',
        type: '',
        targetValue: 0,
        currentValue: 0,
        goalType: '',
        deadline: DateTime.now(),
        isCompleted: false,
        createdAt: DateTime.now(),
      ),
    );
    return goal;
  }
}

/// 分析ダッシュボード StateNotifierProvider
final analyticsDashboardProvider =
    StateNotifierProvider<AnalyticsDashboardNotifier, AnalyticsDashboardState>(
  (ref) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final userId = ref.watch(currentUserIdProvider);
    return AnalyticsDashboardNotifier(firestore, userId);
  },
);
