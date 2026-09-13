import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile.dart';

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

/// 現在のユーザープロフィールを取得
final currentUserProfileProvider =
    FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final firestore = ref.watch(firebaseFirestoreProvider);
  final doc = await firestore.collection('users').doc(userId).get();

  if (!doc.exists) return null;

  return UserProfile.fromJson({
    'userId': userId,
    ...doc.data() ?? {},
  });
});

/// ユーザーの実績を取得
final userAchievementsProvider =
    FutureProvider<List<Achievement>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('achievements')
      .orderBy('isUnlocked', descending: true)
      .get();

  return querySnapshot.docs
      .map((doc) => Achievement.fromJson(doc.data()))
      .toList();
});

/// レベル報酬を取得
final levelRewardsProvider =
    FutureProvider<List<LevelReward>>((ref) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final querySnapshot = await firestore
      .collection('config')
      .doc('levelSystem')
      .collection('rewards')
      .orderBy('level', descending: false)
      .get();

  return querySnapshot.docs
      .map((doc) => LevelReward.fromJson(doc.data()))
      .toList();
});

/// プロフィール Notifier
class ProfileNotifier extends StateNotifier<void> {
  final FirebaseFirestore _firestore;
  final String? _userId;

  ProfileNotifier(this._firestore, this._userId) : super(null);

  /// プロフィールを更新
  Future<bool> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    if (_userId == null) return false;

    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .update(updates);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 経験値を追加
  Future<bool> addExperience(int points) async {
    if (_userId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({
        'experience': FieldValue.increment(points),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// レベルアップ
  Future<bool> levelUp() async {
    if (_userId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({
        'level': FieldValue.increment(1),
        'experience': 0,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 実績をアンロック
  Future<bool> unlockAchievement(String achievementId) async {
    if (_userId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('achievements')
          .doc(achievementId)
          .update({
        'isUnlocked': true,
        'unlockedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// プロフィール StateNotifierProvider
final profileProvider =
    StateNotifierProvider<ProfileNotifier, void>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final userId = ref.watch(currentUserIdProvider);
  return ProfileNotifier(firestore, userId);
});
