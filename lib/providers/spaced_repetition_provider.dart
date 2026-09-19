import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spaced_repetition_item.dart';

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
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}
