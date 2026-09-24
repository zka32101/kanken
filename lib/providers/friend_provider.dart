import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanken/models/friend.dart';
import 'package:kanken/models/achievement.dart';
import 'package:kanken/models/notifications.dart';
import 'package:kanken/services/firestore_service.dart';
import 'package:kanken/viewmodels/services_provider.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart' as user_vm;
import 'firebase_provider.dart';

/// users/{uid}/profiles/{profileId} 配下のドキュメント参照
DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('profiles')
      .doc(profileId);
}

/// 現在のプロフィールのフレンドリストプロバイダー
final friendListProvider = FutureProvider<List<Friend>>((ref) async {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];

  final profileId = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );

  try {
    final snapshot = await _profileDoc(currentUserId, profileId)
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

  final profileId = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );

  try {
    final snapshot = await _profileDoc(currentUserId, profileId)
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

  final profileId = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );

  try {
    final snapshot = await _profileDoc(currentUserId, profileId)
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
  final currentUserId = ref.watch(currentUserIdProvider);
  final profileId = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );
  final displayName = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.displayName ?? 'Unknown'),
  );
  final firestoreService = ref.watch(firestoreServiceProvider);

  return FriendNotifier(currentUserId, profileId, displayName, firestoreService);
});

/// フレンド管理ロジック
///
/// フレンドは「アカウント(uid)」ではなく「プロフィール」単位の関係として
/// 扱うため、相手の識別には FirestoreService.rankingDocId() と同じ
/// "{uid}_{profileId}" 複合IDを使う（Friend.userId / FriendRequest.
/// fromUserId・toUserId も同様）。
class FriendNotifier extends StateNotifier<AsyncValue<void>> {
  FriendNotifier(
    this._currentUserId,
    this._profileId,
    this._displayName,
    this._firestoreService,
  ) : super(const AsyncValue.data(null));

  final String? _currentUserId;
  final String _profileId;
  final String _displayName;
  final FirestoreService _firestoreService;

  String get _myCompositeId =>
      FirestoreService.rankingDocId(_currentUserId!, _profileId);

  /// フレンドリクエスト送信（targetCompositeIdは相手の "{uid}_{profileId}"）
  Future<void> sendFriendRequest(String targetCompositeId) async {
    if (_currentUserId == null) return;

    state = const AsyncValue.loading();

    try {
      final target = FirestoreService.parseCompositeProfileId(targetCompositeId);
      // 相手の users/{uid}/profiles/{profileId} 本体は本人のみ読み書き可能なため、
      // 公開ミラーの profileDirectory から検索する（getUser()は使えない）。
      final targetProfile = await _firestoreService.findProfileByCompositeId(targetCompositeId);
      if (targetProfile == null) {
        throw Exception('指定されたフレンドIDのプロフィールが見つかりません');
      }
      final targetDisplayName = targetProfile['displayName'] as String? ?? 'Unknown';

      final requestId = FirebaseFirestore.instance.collection('users').doc().id;

      // 送信側: friends に「リクエスト送信済み」として追加
      await _profileDoc(_currentUserId!, _profileId)
          .collection('friends')
          .doc(targetCompositeId)
          .set({
        'userId': targetCompositeId,
        'userName': targetDisplayName,
        'level': 1,
        'experience': 0,
        'accuracyRate': 0.0,
        'streak': 0,
        'status': 'requested',
        'addedAt': FieldValue.serverTimestamp(),
      });

      // 受信側: 受け取るリクエストに追加
      await _profileDoc(target.uid, target.profileId)
          .collection('friendRequests')
          .doc(requestId)
          .set({
        'requestId': requestId,
        'fromUserId': _myCompositeId,
        'fromUserName': _displayName,
        'toUserId': targetCompositeId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
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
      final from = FirestoreService.parseCompositeProfileId(request.fromUserId);

      // 受信側(自分): friend に追加
      await _profileDoc(_currentUserId!, _profileId)
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
      await _profileDoc(from.uid, from.profileId)
          .collection('friends')
          .doc(_myCompositeId)
          .update({'status': 'friend'});

      // リクエスト削除
      await _profileDoc(_currentUserId!, _profileId)
          .collection('friendRequests')
          .doc(request.requestId)
          .delete();

      await _checkFriendCountAchievement(_currentUserId!, _profileId);

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
      final from = FirestoreService.parseCompositeProfileId(request.fromUserId);

      // 送信側から削除
      await _profileDoc(from.uid, from.profileId)
          .collection('friends')
          .doc(_myCompositeId)
          .delete();

      // リクエスト削除
      await _profileDoc(_currentUserId!, _profileId)
          .collection('friendRequests')
          .doc(request.requestId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// フレンド削除（送信済みリクエストのキャンセルにも使う）
  Future<void> removeFriend(String friendCompositeId) async {
    if (_currentUserId == null) return;

    state = const AsyncValue.loading();

    try {
      final friend = FirestoreService.parseCompositeProfileId(friendCompositeId);

      // 両側から削除
      await _profileDoc(_currentUserId!, _profileId)
          .collection('friends')
          .doc(friendCompositeId)
          .delete();

      await _profileDoc(friend.uid, friend.profileId)
          .collection('friends')
          .doc(_myCompositeId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// フレンド数に応じたバッジ達成をチェック
Future<void> _checkFriendCountAchievement(String uid, String profileId) async {
  try {
    const achievementId = 'social_friends_5';
    final profileRef = _profileDoc(uid, profileId);

    final achievementDoc =
        await profileRef.collection('achievements').doc(achievementId).get();

    if (achievementDoc.exists && (achievementDoc.data()?['isUnlocked'] == true)) {
      return;
    }

    final countSnapshot = await profileRef
        .collection('friends')
        .where('status', isEqualTo: 'friend')
        .count()
        .get();

    if ((countSnapshot.count ?? 0) < 5) return;

    final achievement = Achievement(
      id: achievementId,
      name: '友達の輪',
      description: 'フレンドを5人追加',
      icon: '👫',
      type: AchievementType.social,
      points: 50,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );

    await profileRef
        .collection('achievements')
        .doc(achievementId)
        .set(achievement.toJson(), SetOptions(merge: true));

    final notificationsRef = profileRef.collection('notifications');
    final notificationId = notificationsRef.doc().id;
    await notificationsRef.doc(notificationId).set(
          AppNotification(
            notificationId: notificationId,
            userId: uid,
            type: NotificationType.achievement.value,
            title: '🎉 新しいバッジを獲得！',
            message: '「友達の輪」バッジを獲得しました！',
            relatedId: achievementId,
            isRead: false,
            createdAt: DateTime.now(),
          ).toJson(),
        );
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}
