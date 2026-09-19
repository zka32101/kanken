import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/friend_challenge.dart';

/// ユーザーが受け取ったチャレンジプロバイダー
final receivedChallengesProvider = FutureProvider<List<FriendChallenge>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('friendChallenges')
        .where('challengeeUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FriendChallenge.fromJson(doc.data()))
        .toList();
  } catch (e) {
    return [];
  }
});

/// ユーザーが送信したチャレンジプロバイダー
final sentChallengesProvider = FutureProvider<List<FriendChallenge>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('friendChallenges')
        .where('challengerUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FriendChallenge.fromJson(doc.data()))
        .toList();
  } catch (e) {
    return [];
  }
});

/// アクティブなチャレンジプロバイダー（待機中または進行中）
final activeChallengesProvider = FutureProvider<List<FriendChallenge>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('friendChallenges')
        .where('challengeeUserId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'accepted'])
        .orderBy('dueAt')
        .get();

    return snapshot.docs
        .map((doc) => FriendChallenge.fromJson(doc.data()))
        .toList();
  } catch (e) {
    return [];
  }
});

/// フレンドチャレンジを作成
Future<void> createChallenge({
  required String challengeeUserId,
  required String challengeeName,
  required int targetScore,
  required String description,
  int durationDays = 7,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';

  if (userId == null) return;

  try {
    final challengeId = const Uuid().v4();
    final dueAt = DateTime.now().add(Duration(days: durationDays));

    await FirebaseFirestore.instance
        .collection('friendChallenges')
        .doc(challengeId)
        .set({
          'challengeId': challengeId,
          'challengerUserId': userId,
          'challengerName': userName,
          'challengeeUserId': challengeeUserId,
          'changetesName': challengeeName,
          'status': 'pending',
          'targetScore': targetScore,
          'description': description,
          'createdAt': Timestamp.now(),
          'dueAt': Timestamp.fromDate(dueAt),
        });
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// チャレンジを受け入れる
Future<void> acceptChallenge(String challengeId) async {
  try {
    await FirebaseFirestore.instance
        .collection('friendChallenges')
        .doc(challengeId)
        .update({
          'status': 'accepted',
          'acceptedAt': Timestamp.now(),
        });
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// チャレンジを拒否する
Future<void> declineChallenge(String challengeId) async {
  try {
    await FirebaseFirestore.instance
        .collection('friendChallenges')
        .doc(challengeId)
        .update({
          'status': 'declined',
        });
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// チャレンジスコアを提出
Future<void> submitChallengeScore({
  required String challengeId,
  required int score,
  bool isChallenger = false,
}) async {
  try {
    final field = isChallenger ? 'challengerScore' : 'challengeeScore';

    await FirebaseFirestore.instance
        .collection('friendChallenges')
        .doc(challengeId)
        .update({
          field: score,
        });

    // 両者がスコアを提出したらチャレンジを完了
    final doc = await FirebaseFirestore.instance
        .collection('friendChallenges')
        .doc(challengeId)
        .get();

    final data = doc.data()!;
    if (data['challengerScore'] != null && data['challengeeScore'] != null) {
      await FirebaseFirestore.instance
          .collection('friendChallenges')
          .doc(challengeId)
          .update({
            'status': 'completed',
          });
    }
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// チャレンジを削除
Future<void> deleteChallenge(String challengeId) async {
  try {
    await FirebaseFirestore.instance
        .collection('friendChallenges')
        .doc(challengeId)
        .delete();
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}
