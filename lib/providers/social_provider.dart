import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social.dart';

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

/// ユーザーのフレンドリストを取得
final userFriendsProvider = FutureProvider<List<Friend>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('friends')
      .orderBy('connectedAt', descending: true)
      .get();

  return querySnapshot.docs
      .map((doc) => Friend.fromJson(doc.data()))
      .toList();
});

/// ペンディング中のフレンド要求を取得
final pendingFriendRequestsProvider =
    FutureProvider<List<FriendRequest>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('friendRequests')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .get();

  return querySnapshot.docs
      .map((doc) => FriendRequest.fromJson(doc.data()))
      .toList();
});

/// 送信したフレンド要求を取得
final sentFriendRequestsProvider =
    FutureProvider<List<FriendRequest>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collectionGroup('friendRequests')
      .where('fromUserId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .get();

  return querySnapshot.docs
      .map((doc) => FriendRequest.fromJson(doc.data()))
      .toList();
});

/// 他のユーザーのプロフィールを取得
final userSocialProfileProvider =
    FutureProvider.family<SocialUserProfile?, String>((ref, userId) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final doc = await firestore.collection('users').doc(userId).get();

  if (!doc.exists) return null;

  return SocialUserProfile.fromJson({
    'userId': userId,
    ...doc.data() ?? {},
  });
});

/// ソーシャル Notifier
class SocialNotifier extends StateNotifier<void> {
  final FirebaseFirestore _firestore;
  final String? _userId;

  SocialNotifier(this._firestore, this._userId) : super(null);

  /// フレンド要求を送信
  Future<bool> sendFriendRequest(String toUserId) async {
    if (_userId == null) return false;

    try {
      final requestId = _firestore.collection('users').doc().id;
      final fromUserDoc = await _firestore.collection('users').doc(_userId).get();
      final fromDisplayName = fromUserDoc.data()?['displayName'] ?? 'ユーザー';
      final fromAvatarUrl = fromUserDoc.data()?['avatarUrl'] as String?;

      final request = FriendRequest(
        requestId: requestId,
        fromUserId: _userId!,
        toUserId: toUserId,
        fromDisplayName: fromDisplayName,
        fromAvatarUrl: fromAvatarUrl,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('friendRequests')
          .doc(requestId)
          .set(request.toJson());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// フレンド要求を承認
  Future<bool> acceptFriendRequest(FriendRequest request) async {
    if (_userId == null) return false;

    try {
      // リクエストを承認に更新
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('friendRequests')
          .doc(request.requestId)
          .update({
        'status': 'accepted',
        'respondedAt': Timestamp.now(),
      });

      // 相手をフレンドに追加（送信者と受信者の情報を取得）
      final fromUserDoc = await _firestore
          .collection('users')
          .doc(request.fromUserId)
          .get();
      final fromLevel = fromUserDoc.data()?['level'] as int? ?? 0;

      final toUserDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .get();
      final toDisplayName = toUserDoc.data()?['displayName'] ?? 'ユーザー';
      final toAvatarUrl = toUserDoc.data()?['avatarUrl'] as String?;
      final toLevel = toUserDoc.data()?['level'] as int? ?? 0;

      // 受信者のフレンドリストに送信者を追加
      final friend = Friend(
        friendId: request.fromUserId,
        userId: _userId!,
        displayName: request.fromDisplayName,
        avatarUrl: request.fromAvatarUrl,
        level: fromLevel,
        connectedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('friends')
          .doc(request.fromUserId)
          .set(friend.toJson());

      // 送信者のフレンドリストに受信者を追加
      final fromFriend = Friend(
        friendId: _userId!,
        userId: request.fromUserId,
        displayName: toDisplayName,
        avatarUrl: toAvatarUrl,
        level: toLevel,
        connectedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(request.fromUserId)
          .collection('friends')
          .doc(_userId)
          .set(fromFriend.toJson());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// フレンド要求を拒否
  Future<bool> rejectFriendRequest(FriendRequest request) async {
    if (_userId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('friendRequests')
          .doc(request.requestId)
          .update({
        'status': 'rejected',
        'respondedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// フレンドを削除
  Future<bool> removeFriend(String friendId) async {
    if (_userId == null) return false;

    try {
      // 自分のフレンドリストから削除
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('friends')
          .doc(friendId)
          .delete();

      // 相手のフレンドリストからも削除
      await _firestore
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(_userId)
          .delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// フレンド要求をキャンセル
  Future<bool> cancelFriendRequest(String toUserId) async {
    if (_userId == null) return false;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: _userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// ソーシャル StateNotifierProvider
final socialProvider = StateNotifierProvider<SocialNotifier, void>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final userId = ref.watch(currentUserIdProvider);
  return SocialNotifier(firestore, userId);
});
