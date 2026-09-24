import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/learning_goal.dart';
import '../models/notifications.dart';
import '../models/achievement.dart';
import '../viewmodels/user_viewmodel.dart' as user_vm;

/// users/{uid}/profiles/{profileId} 配下のドキュメント参照
DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('profiles')
      .doc(profileId);
}

/// ユーザーのアクティブな学習目標一覧（プロフィール単位）
final activeLearningGoalsProvider = FutureProvider<List<LearningGoal>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final profileId = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );

  // ここで例外を握りつぶすと、Firestoreの複合インデックス未作成等の
  // 本物のエラーが「目標が0件」に見えてしまい原因追跡ができなくなるため、
  // 呼び出し元のFutureProvider.errorとしてそのまま伝播させる。
  final snapshot = await _profileDoc(userId, profileId)
      .collection('learningGoals')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => LearningGoal.fromJson(doc.data()))
      .toList();
});

/// ユーザーの達成済み学習目標一覧（プロフィール単位）
final achievedLearningGoalsProvider = FutureProvider<List<LearningGoal>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final profileId = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );

  final snapshot = await _profileDoc(userId, profileId)
      .collection('learningGoals')
      .where('isAchieved', isEqualTo: true)
      .orderBy('achievedAt', descending: true)
      .limit(20)
      .get();

  return snapshot.docs
      .map((doc) => LearningGoal.fromJson(doc.data()))
      .toList();
});

/// 学習目標を作成
Future<void> createLearningGoal(
  WidgetRef ref, {
  required GoalType type,
  required int targetValue,
  DateTime? deadline,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final profileId =
        (await ref.read(user_vm.currentUserProvider.future))?.profileId ?? 'default';
    final goalId = const Uuid().v4();

    final goal = LearningGoal(
      goalId: goalId,
      userId: userId,
      type: type,
      targetValue: targetValue,
      createdAt: DateTime.now(),
      deadline: deadline,
    );

    await _profileDoc(userId, profileId)
        .collection('learningGoals')
        .doc(goalId)
        .set(goal.toJson());
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// 学習目標の進捗を更新
Future<void> updateGoalProgress(
  WidgetRef ref, {
  required String goalId,
  required int newValue,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final profileId =
        (await ref.read(user_vm.currentUserProvider.future))?.profileId ?? 'default';
    final docRef =
        _profileDoc(userId, profileId).collection('learningGoals').doc(goalId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final goal = LearningGoal.fromJson(doc.data()!);
    final isNowAchieved = newValue >= goal.targetValue && !goal.isAchieved;

    await docRef.update({
      'currentValue': newValue,
      if (isNowAchieved) 'isAchieved': true,
      if (isNowAchieved) 'achievedAt': Timestamp.now(),
    });

    if (isNowAchieved) {
      await _createGoalAchievedNotification(userId, profileId, goal);
      await _incrementGoalAchievedCountAndCheckAchievements(userId, profileId);
    }
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

const _goalAchievedAchievements = {
  1: ('goal_first', '目標達成', '学習目標を初めて達成', '🚩', 50),
  5: ('goal_5', 'ゴールゲッター', '学習目標を5個達成', '🎌', 200),
};

/// 目標達成数を更新し、達成したバッジを付与
Future<void> _incrementGoalAchievedCountAndCheckAchievements(
  String userId,
  String profileId,
) async {
  try {
    final statsRef =
        _profileDoc(userId, profileId).collection('goalStats').doc('summary');

    final newAchievedCount = await FirebaseFirestore.instance.runTransaction<int>((tx) async {
      final snapshot = await tx.get(statsRef);
      final current = (snapshot.data()?['achievedCount'] as int?) ?? 0;
      final updated = current + 1;
      tx.set(statsRef, {'achievedCount': updated}, SetOptions(merge: true));
      return updated;
    });

    final info = _goalAchievedAchievements[newAchievedCount];
    if (info == null) return;

    final achievementsRef = _profileDoc(userId, profileId).collection('achievements');
    final achievementDoc = await achievementsRef.doc(info.$1).get();

    if (achievementDoc.exists && (achievementDoc.data()?['isUnlocked'] == true)) {
      return;
    }

    final achievement = Achievement(
      id: info.$1,
      name: info.$2,
      description: info.$3,
      icon: info.$4,
      type: AchievementType.goal,
      points: info.$5,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );

    await achievementsRef.doc(info.$1).set(achievement.toJson(), SetOptions(merge: true));

    final notificationsRef = _profileDoc(userId, profileId).collection('notifications');
    final notificationId = notificationsRef.doc().id;
    await notificationsRef.doc(notificationId).set(
          AppNotification(
            notificationId: notificationId,
            userId: userId,
            type: NotificationType.achievement.value,
            title: '🎉 新しいバッジを獲得！',
            message: '「${info.$2}」バッジを獲得しました！',
            relatedId: info.$1,
            isRead: false,
            createdAt: DateTime.now(),
          ).toJson(),
        );
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// 目標達成通知を作成
Future<void> _createGoalAchievedNotification(
  String userId,
  String profileId,
  LearningGoal goal,
) async {
  try {
    final notificationsRef = _profileDoc(userId, profileId).collection('notifications');
    final notificationId = notificationsRef.doc().id;

    await notificationsRef.doc(notificationId).set(
          AppNotification(
            notificationId: notificationId,
            userId: userId,
            type: NotificationType.goalAchieved.value,
            title: '🎉 目標達成！',
            message: '「${goal.typeLabel}」の目標（${goal.targetValue}${goal.unit}）を達成しました！',
            relatedId: goal.goalId,
            isRead: false,
            createdAt: DateTime.now(),
          ).toJson(),
        );
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// 学習目標を削除（非アクティブ化）
Future<void> deactivateLearningGoal(WidgetRef ref, String goalId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final profileId =
        (await ref.read(user_vm.currentUserProvider.future))?.profileId ?? 'default';
    await _profileDoc(userId, profileId)
        .collection('learningGoals')
        .doc(goalId)
        .update({'isActive': false});
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// 学習目標を完全に削除
Future<void> deleteLearningGoal(WidgetRef ref, String goalId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final profileId =
        (await ref.read(user_vm.currentUserProvider.future))?.profileId ?? 'default';
    await _profileDoc(userId, profileId)
        .collection('learningGoals')
        .doc(goalId)
        .delete();
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}
