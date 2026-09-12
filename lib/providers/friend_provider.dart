import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanken/models/friend.dart';
import 'firebase_provider.dart';

/// フレンドリストプロバイダー
final friendListProvider = FutureProvider<List<Friend>>((ref) async {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];

  final firestore = ref.watch(firebaseProvider);

  try {
    final snapshot = await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .where('status', isEqualTo: 'friend')
        .get();

    final friends = snapshot.docs
        .map((doc) => Friend.fromJson(doc.data()))
        .toList();

    // レベル順でソート
    friends.sort((a, b) => b.level.compareTo(a.level));

    return friends;
  } catch (e) {
    throw Exception('フレンド一覧取得エラー: $e');
  }
});

/// ペンディングリクエストプロバイダー（受け取ったリクエスト）
final incomingRequestsProvider = FutureProvider<List<FriendRequest>>((ref) async {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];

  final firestore = ref.watch(firebaseProvider);

  try {
    final snapshot = await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friendRequests')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FriendRequest.fromJson(doc.data()))
        .toList();
  } catch (e) {
    throw Exception('フレンドリクエスト取得エラー: $e');
  }
});

/// 送信済みリクエストプロバイダー
final outgoingRequestsProvider = FutureProvider<List<Friend>>((ref) async {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];

  final firestore = ref.watch(firebaseProvider);

  try {
    final snapshot = await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .where('status', isEqualTo: 'requested')
        .get();

    return snapshot.docs
        .map((doc) => Friend.fromJson(doc.data()))
        .toList();
  } catch (e) {
    throw Exception('送信済みリクエスト取得エラー: $e');
  }
});

/// フレンドマネージャープロバイダー
final friendNotifierProvider = StateNotifierProvider<FriendNotifier, AsyncValue<void>>((ref) {
  final firestore = ref.watch(firebaseProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  return FriendNotifier(firestore, currentUserId);
});

/// フレンド管理ロジック
class FriendNotifier extends StateNotifier<AsyncValue<void>> {
  FriendNotifier(this._firestore, this._currentUserId)
      : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore;
  final String? _currentUserId;

  /// フレンドリクエスト送信
  Future<void> sendFriendRequest(String targetUserId, String targetUserName) async {
    if (_currentUserId == null) return;

    state = const AsyncValue.loading();

    try {
      final requestId = _firestore.collection('users').doc().id;

      // 送信側: requests に追加
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(targetUserId)
          .set({
        'userId': targetUserId,
        'userName': targetUserName,
        'level': 1,
        'experience': 0,
        'accuracyRate': 0.0,
        'streak': 0,
        'status': 'requested',
        'addedAt': FieldValue.serverTimestamp(),
      });

      // 受信側: 受け取るリクエストに追加
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      final currentUserName = (currentUserDoc.data()?['profile']?['name'] as String?) ?? 'Unknown';

      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(requestId)
          .set({
        'requestId': requestId,
        'fromUserId': _currentUserId,
        'fromUserName': currentUserName,
        'toUserId': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// フレンドリクエスト承認
  Future<void> acceptFriendRequest(
    FriendRequest request,
    Friend friendData,
  ) async {
    if (_currentUserId == null) return;

    state = const AsyncValue.loading();

    try {
      // 受信側: friend に追加
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(request.fromUserId)
          .set({
        'userId': request.fromUserId,
        'userName': request.fromUserName,
        'level': friendData.level,
        'experience': friendData.experience,
        'accuracyRate': friendData.accuracyRate,
        'streak': friendData.streak,
        'status': 'friend',
        'addedAt': FieldValue.serverTimestamp(),
        'lastPlayedAt': friendData.lastPlayedAt != null
            ? Timestamp.fromDate(friendData.lastPlayedAt!)
            : null,
      });

      // 送信側: status を更新
      await _firestore
          .collection('users')
          .doc(request.fromUserId)
          .collection('friends')
          .doc(_currentUserId)
          .update({'status': 'friend'});

      // リクエスト削除
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friendRequests')
          .doc(request.requestId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// フレンドリクエスト拒否
  Future<void> rejectFriendRequest(FriendRequest request) async {
    if (_currentUserId == null) return;

    state = const AsyncValue.loading();

    try {
      // 送信側から削除
      await _firestore
          .collection('users')
          .doc(request.fromUserId)
          .collection('friends')
          .doc(_currentUserId)
          .delete();

      // リクエスト削除
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friendRequests')
          .doc(request.requestId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// フレンド削除
  Future<void> removeFriend(String friendUserId) async {
    if (_currentUserId == null) return;

    state = const AsyncValue.loading();

    try {
      // 両側から削除
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendUserId)
          .delete();

      await _firestore
          .collection('users')
          .doc(friendUserId)
          .collection('friends')
          .doc(_currentUserId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
