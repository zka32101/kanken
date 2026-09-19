import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/learning_goal.dart';

/// ユーザーのアクティブな学習目標一覧
final activeLearningGoalsProvider = FutureProvider<List<LearningGoal>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('learningGoals')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LearningGoal.fromJson(doc.data()))
        .toList();
  } catch (e) {
    return [];
  }
});

/// ユーザーの達成済み学習目標一覧
final achievedLearningGoalsProvider = FutureProvider<List<LearningGoal>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('learningGoals')
        .where('isAchieved', isEqualTo: true)
        .orderBy('achievedAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => LearningGoal.fromJson(doc.data()))
        .toList();
  } catch (e) {
    return [];
  }
});

/// 学習目標を作成
Future<void> createLearningGoal({
  required GoalType type,
  required int targetValue,
  DateTime? deadline,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final goalId = const Uuid().v4();

    final goal = LearningGoal(
      goalId: goalId,
      userId: userId,
      type: type,
      targetValue: targetValue,
      createdAt: DateTime.now(),
      deadline: deadline,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('learningGoals')
        .doc(goalId)
        .set(goal.toJson());
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// 学習目標の進捗を更新
Future<void> updateGoalProgress({
  required String goalId,
  required int newValue,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('learningGoals')
        .doc(goalId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final goal = LearningGoal.fromJson(doc.data()!);
    final isNowAchieved = newValue >= goal.targetValue && !goal.isAchieved;

    await docRef.update({
      'currentValue': newValue,
      if (isNowAchieved) 'isAchieved': true,
      if (isNowAchieved) 'achievedAt': Timestamp.now(),
    });
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// 学習目標を削除（非アクティブ化）
Future<void> deactivateLearningGoal(String goalId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('learningGoals')
        .doc(goalId)
        .update({'isActive': false});
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// 学習目標を完全に削除
Future<void> deleteLearningGoal(String goalId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('learningGoals')
        .doc(goalId)
        .delete();
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}
