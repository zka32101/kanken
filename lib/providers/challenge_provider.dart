import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/challenge_invitation.dart';
import '../models/gamification_stats.dart';

part 'challenge_provider.g.dart';

/// アクティブなチャレンジ一覧を取得
@riverpod
Future<List<ChallengeInvitation>> activeChallenges(
  ActiveChallengesRef ref,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('challenges')
      .where('status', whereIn: ['pending', 'accepted'])
      .orderBy('expiresAt')
      .get();

  return snapshot.docs
      .map((doc) => ChallengeInvitation.fromJson(doc.data()))
      .toList();
}

/// ペンディングのチャレンジリクエスト（受信）
@riverpod
Future<List<ChallengeInvitation>> incomingChallenges(
  IncomingChallengesRef ref,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('challenges')
      .where('status', isEqualTo: 'pending')
      .where('toUserId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => ChallengeInvitation.fromJson(doc.data()))
      .toList();
}

/// 送信済みのチャレンジリクエスト（送信）
@riverpod
Future<List<ChallengeInvitation>> outgoingChallenges(
  OutgoingChallengesRef ref,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('challenges')
      .where('status', isEqualTo: 'pending')
      .where('fromUserId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => ChallengeInvitation.fromJson(doc.data()))
      .toList();
}

/// 完了済みのチャレンジ（勝敗判定済み）
@riverpod
Future<List<ChallengeInvitation>> completedChallenges(
  CompletedChallengesRef ref,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('challenges')
      .where('status', isEqualTo: 'completed')
      .orderBy('completedAt', descending: true)
      .limit(10)
      .get();

  return snapshot.docs
      .map((doc) => ChallengeInvitation.fromJson(doc.data()))
      .toList();
}

/// チャレンジプロバイダー State
class ChallengeState {
  final List<ChallengeInvitation> challenges;
  final bool isLoading;
  final String? error;

  ChallengeState({
    this.challenges = const [],
    this.isLoading = false,
    this.error,
  });

  ChallengeState copyWith({
    List<ChallengeInvitation>? challenges,
    bool? isLoading,
    String? error,
  }) {
    return ChallengeState(
      challenges: challenges ?? this.challenges,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// チャレンジ管理の StateNotifier
class ChallengeNotifier extends StateNotifier<ChallengeState> {
  ChallengeNotifier() : super(ChallengeState());

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// チャレンジを送信
  Future<void> sendChallenge({
    required String toUserId,
    required String toUserName,
    required String fromUserName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final invitationId = _firestore.collection('users').doc().id;
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));

      final invitation = ChallengeInvitation(
        invitationId: invitationId,
        fromUserId: currentUser.uid,
        fromUserName: fromUserName,
        toUserId: toUserId,
        toUserName: toUserName,
        status: ChallengeStatus.pending,
        createdAt: now,
        expiresAt: expiresAt,
      );

      // 送信者（自分）の challenges コレクションに保存
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('challenges')
          .doc(invitationId)
          .set(invitation.toJson());

      // 受信者の challenges コレクションにも保存
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('challenges')
          .doc(invitationId)
          .set(invitation.toJson());

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'チャレンジの送信に失敗しました: $e',
      );
    }
  }

  /// チャレンジを受け入れ
  Future<void> acceptChallenge({
    required String invitationId,
    required String fromUserId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      // ステータスを accepted に更新
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('challenges')
          .doc(invitationId)
          .update({'status': 'accepted'});

      // 送信者のドキュメントも更新
      await _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('challenges')
          .doc(invitationId)
          .update({'status': 'accepted'});

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'チャレンジの受け入れに失敗しました: $e',
      );
    }
  }

  /// チャレンジを拒否
  Future<void> declineChallenge({
    required String invitationId,
    required String fromUserId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      // ステータスを declined に更新
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('challenges')
          .doc(invitationId)
          .update({'status': 'declined'});

      // 送信者のドキュメントも更新
      await _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('challenges')
          .doc(invitationId)
          .update({'status': 'declined'});

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'チャレンジの拒否に失敗しました: $e',
      );
    }
  }

  /// スコアを記録（チャレンジを完了）
  Future<void> submitScore({
    required String invitationId,
    required String opponentUserId,
    required int myScore,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      // 自分がチャレンジを送信した側か受信した側か判定
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('challenges')
          .doc(invitationId)
          .get();

      if (!doc.exists) throw Exception('チャレンジが見つかりません');

      final data = doc.data()!;
      final isFromUser = data['fromUserId'] == currentUser.uid;

      // 自分のスコアを記録
      if (isFromUser) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('challenges')
            .doc(invitationId)
            .update({
          'fromScore': myScore,
          'status': 'completed',
          'completedAt': Timestamp.now(),
        });

        // 相手のドキュメントも同じスコアで更新
        await _firestore
            .collection('users')
            .doc(opponentUserId)
            .collection('challenges')
            .doc(invitationId)
            .update({
          'fromScore': myScore,
          'status': 'completed',
          'completedAt': Timestamp.now(),
        });
      } else {
        // 受信側なので toScore に記録
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('challenges')
            .doc(invitationId)
            .update({
          'toScore': myScore,
          'status': 'completed',
          'completedAt': Timestamp.now(),
        });

        // 相手のドキュメントも同じスコアで更新
        await _firestore
            .collection('users')
            .doc(opponentUserId)
            .collection('challenges')
            .doc(invitationId)
            .update({
          'toScore': myScore,
          'status': 'completed',
          'completedAt': Timestamp.now(),
        });
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'スコアの記録に失敗しました: $e',
      );
    }
  }

  /// 両方のスコアが揃ったか確認（winner 判定用）
  Future<bool> isChallengeComplete({
    required String invitationId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('challenges')
          .doc(invitationId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      return data['fromScore'] != null && data['toScore'] != null;
    } catch (e) {
      state = state.copyWith(error: 'チャレンジ状態の確認に失敗しました: $e');
      return false;
    }
  }

  /// チャレンジを削除
  Future<void> deleteChallenge({
    required String invitationId,
    required String opponentUserId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      // 自分の challenges から削除
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('challenges')
          .doc(invitationId)
          .delete();

      // 相手の challenges からも削除
      await _firestore
          .collection('users')
          .doc(opponentUserId)
          .collection('challenges')
          .doc(invitationId)
          .delete();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'チャレンジの削除に失敗しました: $e',
      );
    }
  }
}

/// チャレンジ管理プロバイダー
@riverpod
StateNotifier<ChallengeState> challengeNotifier(
  ChallengeNotifierRef ref,
) {
  return ChallengeNotifier();
}
