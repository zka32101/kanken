import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/learning_recommendation.dart';
import '../models/weak_area.dart';
import 'weak_area_provider.dart';

part 'learning_plan_provider.g.dart';

/// 学習推奨プランを生成
@riverpod
Future<LearningPlan> learningPlan(LearningPlanRef ref) async {
  final analysis = await ref.watch(weakAreaAnalysisProvider.future);

  final recommendations = <LearningRecommendation>[];

  for (final weakArea in analysis.weakAreas) {
    // 優先度を決定（正答率に基づく）
    RecommendationPriority priority;
    if (weakArea.accuracyRate < 0.3) {
      priority = RecommendationPriority.critical;
    } else if (weakArea.accuracyRate < 0.5) {
      priority = RecommendationPriority.high;
    } else if (weakArea.accuracyRate < 0.7) {
      priority = RecommendationPriority.medium;
    } else {
      priority = RecommendationPriority.low;
    }

    // 難易度を決定
    DifficultyLevel difficulty;
    if (weakArea.totalAttempts < 5) {
      difficulty = DifficultyLevel.basic;
    } else if (weakArea.totalAttempts < 20) {
      difficulty = DifficultyLevel.standard;
    } else {
      difficulty = DifficultyLevel.advanced;
    }

    // 推奨理由を生成
    String reason;
    if (priority == RecommendationPriority.critical) {
      reason = '正答率が${weakArea.getAccuracyPercentage()}と低いため、基礎から復習が必要です。';
    } else if (priority == RecommendationPriority.high) {
      reason = '正答率が${weakArea.getAccuracyPercentage()}であり、継続的な学習が必要です。';
    } else {
      reason = '正答率が${weakArea.getAccuracyPercentage()}です。さらに深い理解のため応用問題に挑戦してください。';
    }

    // 推奨日数を計算（優先度と正答率から）
    int estimatedDays;
    switch (priority) {
      case RecommendationPriority.critical:
        estimatedDays = 14; // 2週間
        break;
      case RecommendationPriority.high:
        estimatedDays = 10; // 10日
        break;
      case RecommendationPriority.medium:
        estimatedDays = 7;  // 1週間
        break;
      case RecommendationPriority.low:
        estimatedDays = 5;  // 5日
        break;
    }

    final recommendation = LearningRecommendation(
      recommendationId: weakArea.categoryId,
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      targetCategoryId: weakArea.categoryId,
      targetCategoryName: weakArea.categoryName,
      priority: priority,
      difficulty: difficulty,
      reason: reason,
      recommendedDailyQuestions: weakArea.getRecommendedQuestionCount(),
      estimatedDaysToImprove: estimatedDays,
      createdAt: DateTime.now(),
    );

    recommendations.add(recommendation);
  }

  // 優先度でソート（critical → low）
  recommendations.sort((a, b) => b.priority.index.compareTo(a.priority.index));

  return LearningPlan(
    recommendations: recommendations,
    generatedAt: DateTime.now(),
  );
}

/// 学習推奨を取得（Firestore から）
@riverpod
Future<List<LearningRecommendation>> activeLearningRecommendations(
  ActiveLearningRecommendationsRef ref,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('learningRecommendations')
      .where('isCompleted', isEqualTo: false)
      .orderBy('priority')
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => LearningRecommendation.fromJson(doc.data()))
      .toList();
}

/// 完了した推奨を取得
@riverpod
Future<List<LearningRecommendation>> completedLearningRecommendations(
  CompletedLearningRecommendationsRef ref,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('learningRecommendations')
      .where('isCompleted', isEqualTo: true)
      .orderBy('completedAt', descending: true)
      .limit(10)
      .get();

  return snapshot.docs
      .map((doc) => LearningRecommendation.fromJson(doc.data()))
      .toList();
}

/// 学習推奨プロバイダー State
class LearningPlanState {
  final LearningPlan? currentPlan;
  final bool isLoading;
  final String? error;

  LearningPlanState({
    this.currentPlan,
    this.isLoading = false,
    this.error,
  });

  LearningPlanState copyWith({
    LearningPlan? currentPlan,
    bool? isLoading,
    String? error,
  }) {
    return LearningPlanState(
      currentPlan: currentPlan ?? this.currentPlan,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 学習推奨管理の StateNotifier
class LearningPlanNotifier extends StateNotifier<LearningPlanState> {
  LearningPlanNotifier() : super(LearningPlanState());

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 推奨を Firestore に保存
  Future<void> saveLearningPlan(LearningPlan plan) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final batch = _firestore.batch();

      for (final recommendation in plan.recommendations) {
        final docRef = _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('learningRecommendations')
            .doc(recommendation.recommendationId);

        batch.set(recommendation.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
      state = state.copyWith(currentPlan: plan, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '学習プランの保存に失敗しました: $e',
      );
    }
  }

  /// 推奨の進捗を更新
  Future<void> updateRecommendationProgress({
    required String recommendationId,
    required double progressAccuracy,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('learningRecommendations')
          .doc(recommendationId)
          .update({
        'progressAccuracy': progressAccuracy,
      });
    } catch (e) {
      state = state.copyWith(
        error: '進捗の更新に失敗しました: $e',
      );
    }
  }

  /// 推奨を完了
  Future<void> completeRecommendation(String recommendationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('learningRecommendations')
          .doc(recommendationId)
          .update({
        'isCompleted': true,
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      state = state.copyWith(
        error: '推奨の完了に失敗しました: $e',
      );
    }
  }

  /// 推奨を削除
  Future<void> deleteRecommendation(String recommendationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('learningRecommendations')
          .doc(recommendationId)
          .delete();
    } catch (e) {
      state = state.copyWith(
        error: '推奨の削除に失敗しました: $e',
      );
    }
  }
}

/// 学習推奨管理プロバイダー
@riverpod
StateNotifier<LearningPlanState> learningPlanNotifier(
  LearningPlanNotifierRef ref,
) {
  return LearningPlanNotifier();
}
