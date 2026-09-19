import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spaced_repetition_item.dart';
import '../models/notifications.dart';
import '../models/achievement.dart';

/// 今日復習すべきアイテム一覧プロバイダー
final dueReviewItemsProvider = FutureProvider<List<SpacedRepetitionItem>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('spacedRepetitionItems')
        .where('nextReviewDate', isLessThanOrEqualTo: Timestamp.now())
        .orderBy('nextReviewDate')
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => SpacedRepetitionItem.fromJson(doc.data()))
        .toList();
  } catch (e) {
    return [];
  }
});

/// 全ての間隔反復アイテムプロバイダー
final allSpacedRepetitionItemsProvider = FutureProvider<List<SpacedRepetitionItem>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('spacedRepetitionItems')
        .get();

    return snapshot.docs
        .map((doc) => SpacedRepetitionItem.fromJson(doc.data()))
        .toList();
  } catch (e) {
    return [];
  }
});

/// 復習セッション統計プロバイダー
final reviewSessionStatsProvider = FutureProvider<ReviewSessionStats>((ref) async {
  final allItems = await ref.watch(allSpacedRepetitionItemsProvider.future);
  final dueItems = await ref.watch(dueReviewItemsProvider.future);

  final masteredCount = allItems.where((i) => i.masteryLevel == 'マスター').length;
  final learningCount = allItems.where((i) => i.masteryLevel == '習得中').length;
  final newCount = allItems.where((i) => i.masteryLevel == '新規').length;

  final today = DateTime.now();
  final reviewedToday = allItems.where((i) =>
      i.lastReviewedAt.year == today.year &&
      i.lastReviewedAt.month == today.month &&
      i.lastReviewedAt.day == today.day).length;

  return ReviewSessionStats(
    totalDue: dueItems.length,
    reviewedToday: reviewedToday,
    masteredCount: masteredCount,
    learningCount: learningCount,
    newCount: newCount,
  );
});

/// 間違えた問題を間隔反復システムに追加（存在しない場合は新規作成）
Future<void> addToSpacedRepetition({
  required String questionId,
  required String kanji,
  required String category,
  required String question,
  required List<String> options,
  required String correctAnswer,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('spacedRepetitionItems')
        .doc(questionId);

    final existingDoc = await docRef.get();
    if (existingDoc.exists) {
      return; // 既に登録済み
    }

    final item = SpacedRepetitionItem(
      itemId: questionId,
      userId: userId,
      questionId: questionId,
      kanji: kanji,
      category: category,
      question: question,
      options: options,
      correctAnswer: correctAnswer,
      nextReviewDate: DateTime.now(),
      lastReviewedAt: DateTime.now(),
    );

    await docRef.set(item.toJson());
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// 復習リマインダー通知チェック（1日1回、期限アイテムがあれば通知）
final reviewReminderCheckProvider = FutureProvider<void>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final markerRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('reviewReminderMarkers')
        .doc(todayKey);

    final markerDoc = await markerRef.get();
    if (markerDoc.exists) return; // 本日は既にチェック済み

    await markerRef.set({'checkedAt': Timestamp.now()});

    final dueSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('spacedRepetitionItems')
        .where('nextReviewDate', isLessThanOrEqualTo: Timestamp.now())
        .limit(1)
        .get();

    if (dueSnapshot.docs.isEmpty) return;

    final countSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('spacedRepetitionItems')
        .where('nextReviewDate', isLessThanOrEqualTo: Timestamp.now())
        .count()
        .get();

    final dueCount = countSnapshot.count ?? 1;
    final notificationId = FirebaseFirestore.instance.collection('users').doc().id;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .set(
          AppNotification(
            notificationId: notificationId,
            userId: userId,
            type: NotificationType.reviewDue.value,
            title: '📚 復習の時間です',
            message: '$dueCount問の復習期限が来ています。忘れないうちに復習しましょう！',
            isRead: false,
            createdAt: DateTime.now(),
          ).toJson(),
        );
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
});

/// 復習結果を記録し、次回の間隔を計算して保存
/// quality: 0-5 (0-2=不正解, 3-5=正解)
Future<void> recordReviewResult({
  required SpacedRepetitionItem item,
  required int quality,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final updatedItem = item.calculateNext(quality);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('spacedRepetitionItems')
        .doc(item.itemId)
        .set(updatedItem.toJson());

    final justMastered = item.masteryLevel != 'マスター' && updatedItem.masteryLevel == 'マスター';
    if (justMastered) {
      await _incrementMasteredCountAndCheckAchievements(userId);
    }
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

const _reviewMasterAchievements = {
  10: ('review_master_10', '復習の達人', '間隔反復学習で10問マスター', '🔁', 75),
  50: ('review_master_50', '復習マスター', '間隔反復学習で50問マスター', '🔂', 200),
};

/// マスター済み問題数を更新し、達成したバッジを付与
Future<void> _incrementMasteredCountAndCheckAchievements(String userId) async {
  try {
    final statsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('reviewStats')
        .doc('summary');

    final newMasteredCount = await FirebaseFirestore.instance.runTransaction<int>((tx) async {
      final snapshot = await tx.get(statsRef);
      final current = (snapshot.data()?['masteredCount'] as int?) ?? 0;
      final updated = current + 1;
      tx.set(statsRef, {'masteredCount': updated}, SetOptions(merge: true));
      return updated;
    });

    final info = _reviewMasterAchievements[newMasteredCount];
    if (info == null) return;

    final achievementDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc(info.$1)
        .get();

    if (achievementDoc.exists && (achievementDoc.data()?['isUnlocked'] == true)) {
      return;
    }

    final achievement = Achievement(
      id: info.$1,
      name: info.$2,
      description: info.$3,
      icon: info.$4,
      type: AchievementType.review,
      points: info.$5,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc(info.$1)
        .set(achievement.toJson(), SetOptions(merge: true));

    final notificationId = FirebaseFirestore.instance.collection('users').doc().id;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .set(
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
