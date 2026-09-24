import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notifications.dart';
import '../viewmodels/user_viewmodel.dart' as user_vm;

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

/// 現在のプロフィールIDを取得
final _currentProfileIdProvider = Provider<String>((ref) {
  return ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );
});

/// users/{uid}/profiles/{profileId} 配下のドキュメント参照
DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('profiles')
      .doc(profileId);
}

/// ユーザーの未読通知を取得（プロフィール単位）
final unreadNotificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final profileId = ref.watch(_currentProfileIdProvider);
  final querySnapshot = await _profileDoc(userId, profileId)
      .collection('notifications')
      .where('isRead', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .get();

  return querySnapshot.docs
      .map((doc) => AppNotification.fromJson(doc.data()))
      .toList();
});

/// ユーザーのすべての通知を取得（プロフィール単位）
final allNotificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final profileId = ref.watch(_currentProfileIdProvider);
  final querySnapshot = await _profileDoc(userId, profileId)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .get();

  return querySnapshot.docs
      .map((doc) => AppNotification.fromJson(doc.data()))
      .toList();
});

/// 通知統計を取得（プロフィール単位）
final notificationStatsProvider =
    FutureProvider<NotificationStats?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final profileId = ref.watch(_currentProfileIdProvider);
  final doc = await _profileDoc(userId, profileId)
      .collection('notificationStats')
      .doc('summary')
      .get();

  if (!doc.exists) {
    return NotificationStats(
      userId: userId,
      unreadCount: 0,
      totalCount: 0,
      battleInviteCount: 0,
      friendRequestCount: 0,
      achievementCount: 0,
    );
  }

  return NotificationStats.fromJson(doc.data() ?? {});
});

/// 通知設定を取得（プロフィール単位）
final notificationSettingsProvider =
    FutureProvider<NotificationSettings?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final profileId = ref.watch(_currentProfileIdProvider);
  final doc = await _profileDoc(userId, profileId)
      .collection('notificationSettings')
      .doc('settings')
      .get();

  if (!doc.exists) {
    return NotificationSettings(
      userId: userId,
      updatedAt: DateTime.now(),
    );
  }

  return NotificationSettings.fromJson(doc.data() ?? {});
});

/// 通知 Notifier（プロフィール単位）
class NotificationNotifier extends StateNotifier<void> {
  final String? _userId;
  final String _profileId;

  NotificationNotifier(this._userId, this._profileId) : super(null);

  DocumentReference<Map<String, dynamic>> get _profileRef =>
      _profileDoc(_userId!, _profileId);

  /// 通知を作成
  Future<bool> createNotification({
    required String type,
    required String title,
    required String message,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    if (_userId == null) return false;

    try {
      final notificationsRef = _profileRef.collection('notifications');
      final notificationId = notificationsRef.doc().id;
      final notification = AppNotification(
        notificationId: notificationId,
        userId: _userId!,
        type: type,
        title: title,
        message: message,
        relatedId: relatedId,
        isRead: false,
        createdAt: DateTime.now(),
        data: data,
      );

      await notificationsRef.doc(notificationId).set(notification.toJson());

      // 統計を更新
      await _updateNotificationStats();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 通知を既読にする
  Future<bool> markAsRead(String notificationId) async {
    if (_userId == null) return false;

    try {
      await _profileRef
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // 統計を更新
      await _updateNotificationStats();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// すべての通知を既読にする
  Future<bool> markAllAsRead() async {
    if (_userId == null) return false;

    try {
      final querySnapshot = await _profileRef
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'isRead': true});
      }

      // 統計を更新
      await _updateNotificationStats();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 通知を削除
  Future<bool> deleteNotification(String notificationId) async {
    if (_userId == null) return false;

    try {
      await _profileRef.collection('notifications').doc(notificationId).delete();

      // 統計を更新
      await _updateNotificationStats();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 古い通知を削除（30日以上前）
  Future<bool> deleteOldNotifications() async {
    if (_userId == null) return false;

    try {
      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30));
      final querySnapshot = await _profileRef
          .collection('notifications')
          .where('createdAt',
              isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // 統計を更新
      await _updateNotificationStats();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 通知設定を更新
  Future<bool> updateNotificationSettings(
      NotificationSettings settings) async {
    if (_userId == null) return false;

    try {
      await _profileRef
          .collection('notificationSettings')
          .doc('settings')
          .set(settings.toJson());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 通知統計を更新（内部用）
  Future<void> _updateNotificationStats() async {
    if (_userId == null) return;

    try {
      final querySnapshot = await _profileRef.collection('notifications').get();

      final unreadCount = querySnapshot.docs
          .where((doc) => doc['isRead'] == false)
          .length;

      final battleInviteCount = querySnapshot.docs
          .where((doc) => doc['type'] == 'battle_invite')
          .length;

      final friendRequestCount = querySnapshot.docs
          .where((doc) => doc['type'] == 'friend_request')
          .length;

      final achievementCount = querySnapshot.docs
          .where((doc) => doc['type'] == 'achievement')
          .length;

      final stats = NotificationStats(
        userId: _userId!,
        unreadCount: unreadCount,
        totalCount: querySnapshot.docs.length,
        battleInviteCount: battleInviteCount,
        friendRequestCount: friendRequestCount,
        achievementCount: achievementCount,
      );

      await _profileRef
          .collection('notificationStats')
          .doc('summary')
          .set(stats.toJson());
    } catch (e) {
      // ignore errors in stats update
    }
  }
}

/// 通知 StateNotifierProvider
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, void>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final profileId = ref.watch(_currentProfileIdProvider);
  return NotificationNotifier(userId, profileId);
});
