import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification_stats.dart';
import '../models/reward.dart';
import '../viewmodels/user_viewmodel.dart' as user_vm;
import 'firebase_provider.dart';

/// ユーザーのゲーミフィケーション統計取得 provider
final gamificationStatsProvider = FutureProvider<GamificationStats>((ref) async {
  final firestore = ref.watch(firebaseProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  try {
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('current')
        .get();

    if (doc.exists && doc.data() != null) {
      return GamificationStats.fromJson({...doc.data()!, 'userId': userId});
    }

    // 統計が存在しない場合は初期値を返す
    return GamificationStats(
      userId: userId,
      level: 1,
      experience: 0,
      coins: 0,
      totalQuestions: 0,
      correctCount: 0,
      streak: 0,
      recordStreak: 0,
      accuracyRate: 0.0,
      lastPlayedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  } catch (e) {
    throw Exception('Failed to load gamification stats: $e');
  }
});

/// ゲーミフィケーション統計 StateNotifier
class GamificationNotifier extends StateNotifier<AsyncValue<GamificationStats>> {
  final FirebaseFirestore _firestore;
  final String _userId;
  final bool _rankingOptIn;

  GamificationNotifier(
    this._firestore,
    this._userId, {
    bool rankingOptIn = false,
  })  : _rankingOptIn = rankingOptIn,
        super(const AsyncValue.loading());

  /// 統計を読み込む
  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('stats')
          .doc('current')
          .get();

      if (doc.exists && doc.data() != null) {
        return GamificationStats.fromJson({...doc.data()!, 'userId': _userId});
      }

      return GamificationStats(
        userId: _userId,
        level: 1,
        experience: 0,
        coins: 0,
        totalQuestions: 0,
        correctCount: 0,
        streak: 0,
        recordStreak: 0,
        accuracyRate: 0.0,
        lastPlayedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    });
  }

  /// 統計を Firestore に保存する。
  /// users/{uid}/stats/current（本人のみ）には常に保存する。
  /// ランキング表示用の rankings/{uid}（全員読み取り可）への
  /// level/experience/coins/accuracyRate/streak ミラーは、
  /// ランキング参加設定(rankingOptIn)がオンのユーザーのみ行う。
  Future<void> _saveStats(GamificationStats stats) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('stats')
        .doc('current')
        .set(stats.toJson());

    if (!_rankingOptIn) return;

    await _firestore.collection('rankings').doc(_userId).set(
      {
        'userId': _userId,
        'level': stats.level,
        'experience': stats.experience,
        'coins': stats.coins,
        'accuracyRate': stats.accuracyRate,
        'streak': stats.streak,
        'lastPlayedAt': Timestamp.fromDate(stats.lastPlayedAt),
      },
      SetOptions(merge: true),
    );
  }

  /// 正解時に統計を更新
  Future<void> recordCorrectAnswer() async {
    state = await AsyncValue.guard(() async {
      final current = state.value;
      if (current == null) throw Exception('Stats not loaded');

      final newTotalQuestions = current.totalQuestions + 1;
      final newCorrectCount = current.correctCount + 1;
      final newAccuracy = newCorrectCount / newTotalQuestions;
      final newExperience = current.experience + 10; // +10 EXP
      final newLevel = (newExperience ~/ 500) + 1;

      final updatedStats = current.copyWith(
        totalQuestions: newTotalQuestions,
        correctCount: newCorrectCount,
        accuracyRate: newAccuracy,
        experience: newExperience,
        level: newLevel,
        lastPlayedAt: DateTime.now(),
      );

      await _saveStats(updatedStats);

      // ご褒美を記録
      await _recordReward(Reward.correctAnswer());

      return updatedStats;
    });
  }

  /// 不正解時に統計を更新
  Future<void> recordWrongAnswer() async {
    state = await AsyncValue.guard(() async {
      final current = state.value;
      if (current == null) throw Exception('Stats not loaded');

      final newTotalQuestions = current.totalQuestions + 1;
      final newAccuracy =
          current.correctCount / newTotalQuestions.clamp(1, double.infinity);

      final updatedStats = current.copyWith(
        totalQuestions: newTotalQuestions,
        accuracyRate: newAccuracy,
        lastPlayedAt: DateTime.now(),
      );

      await _saveStats(updatedStats);

      return updatedStats;
    });
  }

  /// ストリーク更新
  Future<void> updateStreak(int newStreak) async {
    state = await AsyncValue.guard(() async {
      final current = state.value;
      if (current == null) throw Exception('Stats not loaded');

      final recordStreak = newStreak > current.recordStreak ? newStreak : current.recordStreak;
      final bonus = newStreak % 5 == 0 ? 50 : 0; // 5日ごとに50 EXP

      var newExperience = current.experience;
      if (bonus > 0) {
        newExperience += bonus;
      }

      final updatedStats = current.copyWith(
        streak: newStreak,
        recordStreak: recordStreak,
        experience: newExperience,
      );

      await _saveStats(updatedStats);

      // ボーナスご褒美を記録
      if (bonus > 0) {
        await _recordReward(Reward.streakBonus(newStreak));
      }

      return updatedStats;
    });
  }

  /// コイン追加
  Future<void> addCoins(int amount) async {
    state = await AsyncValue.guard(() async {
      final current = state.value;
      if (current == null) throw Exception('Stats not loaded');

      final updatedStats =
          current.copyWith(coins: current.coins + amount);

      await _saveStats(updatedStats);

      return updatedStats;
    });
  }

  /// ご褒美を記録
  Future<void> _recordReward(Reward reward) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('rewards')
          .add(reward.toJson());
    } catch (e) {
      print('Failed to record reward: $e');
    }
  }
}

/// ゲーミフィケーション StateNotifier provider
final gamificationNotifierProvider = StateNotifierProvider.family<
    GamificationNotifier,
    AsyncValue<GamificationStats>,
    String>((ref, userId) {
  final firestore = ref.watch(firebaseProvider);
  return GamificationNotifier(firestore, userId);
});

/// 現在のユーザーの統計用 provider (userId 自動取得)
final currentGamificationNotifierProvider =
    StateNotifierProvider<GamificationNotifier, AsyncValue<GamificationStats>>((ref) {
  final firestore = ref.watch(firebaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  final rankingOptIn = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.rankingOptIn ?? false),
  );

  if (userId == null) {
    return GamificationNotifier(firestore, 'anonymous', rankingOptIn: rankingOptIn);
  }

  return GamificationNotifier(firestore, userId, rankingOptIn: rankingOptIn);
});
