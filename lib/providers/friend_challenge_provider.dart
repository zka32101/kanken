import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/friend_challenge.dart';
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
/// challengeeCompositeId は相手の "{uid}_{profileId}" 複合ID
/// （Friend.userIdと同じ形式。friend_list_screen.dartから渡される）
Future<void> createChallenge(
  WidgetRef ref, {
  required String challengeeUserId,
  String challengeeProfileId = 'default',
  required String challengeeName,
  required int targetScore,
  required String description,
  int durationDays = 7,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final challenger = await ref.read(user_vm.currentUserProvider.future);
    final challengerProfileId = challenger?.profileId ?? 'default';
    final userName = challenger?.displayName ?? 'Unknown';

    final challengeId = const Uuid().v4();
    final dueAt = DateTime.now().add(Duration(days: durationDays));

    await FirebaseFirestore.instance
        .collection('friendChallenges')
        .doc(challengeId)
        .set({
          'challengeId': challengeId,
          'challengerUserId': userId,
          'challengerProfileId': challengerProfileId,
          'challengerName': userName,
          'challengeeUserId': challengeeUserId,
          'challengeeProfileId': challengeeProfileId,
          'changetesName': challengeeName,
          'status': 'pending',
          'targetScore': targetScore,
          'description': description,
          'createdAt': Timestamp.now(),
          'dueAt': Timestamp.fromDate(dueAt),
        });

    await _createChallengeReceivedNotification(
      challengeeUserId: challengeeUserId,
      challengeeProfileId: challengeeProfileId,
      challengerName: userName,
      targetScore: targetScore,
      challengeId: challengeId,
    );
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// チャレンジ受信通知を作成
Future<void> _createChallengeReceivedNotification({
  required String challengeeUserId,
  required String challengeeProfileId,
  required String challengerName,
  required int targetScore,
  required String challengeId,
}) async {
  try {
    final notificationsRef =
        _profileDoc(challengeeUserId, challengeeProfileId).collection('notifications');
    final notificationId = notificationsRef.doc().id;

    await notificationsRef.doc(notificationId).set(
          AppNotification(
            notificationId: notificationId,
            userId: challengeeUserId,
            type: NotificationType.challengeReceived.value,
            title: '🎯 新しいチャレンジ',
            message: '$challengerNameさんから目標スコア$targetScore点のチャレンジが届きました！',
            relatedId: challengeId,
            isRead: false,
            createdAt: DateTime.now(),
          ).toJson(),
        );
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

      final challenge = FriendChallenge.fromJson(data);
      final winnerId = challenge.getWinner();
      if (winnerId != null) {
        final winnerProfileId = winnerId == challenge.challengerUserId
            ? challenge.challengerProfileId
            : challenge.challengeeProfileId;
        await _incrementChallengeWinsAndCheckAchievements(winnerId, winnerProfileId);
      }
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

const _challengeWinAchievements = {
  1: ('challenge_win_1', '初勝利', 'フレンドチャレンジで初めて勝利', '🥊', 50),
  5: ('challenge_win_5', '連戦連勝', 'フレンドチャレンジで5勝達成', '🏅', 150),
  10: ('challenge_win_10', 'チャンピオン', 'フレンドチャレンジで10勝達成', '🏆', 300),
};

/// チャレンジ勝利数を更新し、達成したバッジを付与
Future<void> _incrementChallengeWinsAndCheckAchievements(
  String winnerId,
  String winnerProfileId,
) async {
  try {
    final profileRef = _profileDoc(winnerId, winnerProfileId);
    final statsRef = profileRef.collection('challengeStats').doc('summary');

    final newWins = await FirebaseFirestore.instance.runTransaction<int>((tx) async {
      final snapshot = await tx.get(statsRef);
      final currentWins = (snapshot.data()?['wins'] as int?) ?? 0;
      final updatedWins = currentWins + 1;
      tx.set(statsRef, {'wins': updatedWins}, SetOptions(merge: true));
      return updatedWins;
    });

    final info = _challengeWinAchievements[newWins];
    if (info == null) return;

    final achievementsRef = profileRef.collection('achievements');
    final achievementDoc = await achievementsRef.doc(info.$1).get();

    if (achievementDoc.exists && (achievementDoc.data()?['isUnlocked'] == true)) {
      return; // 既に獲得済み
    }

    final achievement = Achievement(
      id: info.$1,
      name: info.$2,
      description: info.$3,
      icon: info.$4,
      type: AchievementType.challenge,
      points: info.$5,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );

    await achievementsRef.doc(info.$1).set(achievement.toJson(), SetOptions(merge: true));

    final notificationsRef = profileRef.collection('notifications');
    final notificationId = notificationsRef.doc().id;
    await notificationsRef.doc(notificationId).set(
          AppNotification(
            notificationId: notificationId,
            userId: winnerId,
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
