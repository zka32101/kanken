import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/multiplayer.dart';

part 'battle_provider.g.dart';

/// 利用可能なバトルルーム一覧を取得
@riverpod
Future<List<BattleRoom>> availableBattleRooms(
  AvailableBattleRoomsRef ref,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('battleRooms')
      .where('status', isEqualTo: 'waiting')
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => BattleRoom.fromJson(doc.data()))
      .toList();
}

/// ユーザーの対戦統計を取得
@riverpod
Future<BattleRoomStats> userBattleStats(UserBattleStatsRef ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return BattleRoomStats(
      userId: '',
      totalBattles: 0,
      victories: 0,
      defeats: 0,
      averageScore: 0.0,
      bestScore: 0,
      highestRank: 0,
    );
  }

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('battleStats')
      .doc('summary')
      .get();

  if (!snapshot.exists) {
    return BattleRoomStats(
      userId: userId,
      totalBattles: 0,
      victories: 0,
      defeats: 0,
      averageScore: 0.0,
      bestScore: 0,
      highestRank: 0,
    );
  }

  return BattleRoomStats.fromJson(snapshot.data() ?? {});
}

/// 対戦ルーム State
class BattleRoomState {
  final bool isLoading;
  final String? error;
  final BattleRoom? currentRoom;
  final BattleSession? currentSession;

  BattleRoomState({
    this.isLoading = false,
    this.error,
    this.currentRoom,
    this.currentSession,
  });

  BattleRoomState copyWith({
    bool? isLoading,
    String? error,
    BattleRoom? currentRoom,
    BattleSession? currentSession,
  }) {
    return BattleRoomState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentRoom: currentRoom ?? this.currentRoom,
      currentSession: currentSession ?? this.currentSession,
    );
  }
}

/// バトルルーム Notifier
class BattleRoomNotifier extends StateNotifier<BattleRoomState> {
  BattleRoomNotifier() : super(BattleRoomState());

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// ルームを作成
  Future<void> createRoom({
    required String roomName,
    required int examLevel,
    required int maxParticipants,
    required int totalQuestions,
    required int timePerQuestionSeconds,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('ユーザーがログインしていません');

      final displayName = _auth.currentUser?.displayName ?? 'ユーザー';

      final roomId = _firestore.collection('battleRooms').doc().id;

      final participant = BattleParticipant(
        userId: userId,
        displayName: displayName,
        avatarUrl: null,
        currentScore: 0,
        correctAnswers: 0,
        level: examLevel,
        joinedAt: DateTime.now(),
        isReady: true,
        isFinished: false,
      );

      final room = BattleRoom(
        roomId: roomId,
        creatorId: userId,
        roomName: roomName,
        examLevel: examLevel,
        maxParticipants: maxParticipants,
        participants: [participant],
        status: 'waiting',
        totalQuestions: totalQuestions,
        timePerQuestionSeconds: timePerQuestionSeconds,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('battleRooms')
          .doc(roomId)
          .set(room.toJson());

      state = state.copyWith(isLoading: false, currentRoom: room);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'ルーム作成失敗: $e',
      );
    }
  }

  /// ルームに参加
  Future<void> joinRoom({required String roomId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('ユーザーがログインしていません');

      final displayName = _auth.currentUser?.displayName ?? 'ユーザー';

      // ルーム情報を取得
      final roomSnapshot = await _firestore
          .collection('battleRooms')
          .doc(roomId)
          .get();

      if (!roomSnapshot.exists) {
        throw Exception('ルームが見つかりません');
      }

      final room = BattleRoom.fromJson(roomSnapshot.data() ?? {});

      // 参加可能か確認
      if (!room.canJoin()) {
        throw Exception('ルームに参加できません');
      }

      final participant = BattleParticipant(
        userId: userId,
        displayName: displayName,
        avatarUrl: null,
        currentScore: 0,
        correctAnswers: 0,
        level: room.examLevel,
        joinedAt: DateTime.now(),
        isReady: false,
        isFinished: false,
      );

      final updatedParticipants = [...room.participants, participant];

      await _firestore
          .collection('battleRooms')
          .doc(roomId)
          .update({
        'participants': updatedParticipants.map((p) => p.toJson()).toList(),
      });

      final updatedRoom = room.copyWith(
        participants: updatedParticipants,
      );

      state = state.copyWith(isLoading: false, currentRoom: updatedRoom);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '参加失敗: $e',
      );
    }
  }

  /// ルームを開始
  Future<void> startBattle({required String roomId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final roomSnapshot = await _firestore
          .collection('battleRooms')
          .doc(roomId)
          .get();

      final room = BattleRoom.fromJson(roomSnapshot.data() ?? {});

      if (!room.canStart()) {
        throw Exception('対戦を開始できません');
      }

      final sessionId =
          _firestore.collection('battleSessions').doc().id;

      final participantScores =
          Map.fromIterable(room.participants, key: (p) => p.userId, value: (p) => 0);
      final participantCorrectAnswers =
          Map.fromIterable(room.participants, key: (p) => p.userId, value: (p) => 0);

      final session = BattleSession(
        sessionId: sessionId,
        roomId: roomId,
        currentQuestionIndex: 0,
        participantScores: participantScores,
        participantCorrectAnswers: participantCorrectAnswers,
        elapsedSeconds: 0,
        isActive: true,
      );

      // セッションを作成
      await _firestore
          .collection('battleSessions')
          .doc(sessionId)
          .set(session.toJson());

      // ルームステータスを更新
      await _firestore.collection('battleRooms').doc(roomId).update({
        'status': 'playing',
        'startedAt': Timestamp.now(),
      });

      final updatedRoom = room.copyWith(
        status: 'playing',
        startedAt: DateTime.now(),
      );

      state = state.copyWith(
        isLoading: false,
        currentRoom: updatedRoom,
        currentSession: session,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '対戦開始失敗: $e',
      );
    }
  }

  /// 回答を記録
  Future<void> recordBattleAnswer({
    required String sessionId,
    required String userId,
    required bool isCorrect,
    required int pointsEarned,
  }) async {
    try {
      if (state.currentSession == null) return;

      final session = state.currentSession!;

      final updatedScores = Map<String, int>.from(session.participantScores);
      updatedScores[userId] = (updatedScores[userId] ?? 0) + pointsEarned;

      final updatedCorrectAnswers =
          Map<String, int>.from(session.participantCorrectAnswers);
      if (isCorrect) {
        updatedCorrectAnswers[userId] =
            (updatedCorrectAnswers[userId] ?? 0) + 1;
      }

      final updatedSession = BattleSession(
        sessionId: session.sessionId,
        roomId: session.roomId,
        currentQuestionIndex: session.currentQuestionIndex,
        participantScores: updatedScores,
        participantCorrectAnswers: updatedCorrectAnswers,
        elapsedSeconds: session.elapsedSeconds,
        isActive: session.isActive,
      );

      state = state.copyWith(currentSession: updatedSession);

      // Firestoreに記録
      await _firestore
          .collection('battleSessions')
          .doc(sessionId)
          .update({
        'participantScores': updatedScores,
        'participantCorrectAnswers': updatedCorrectAnswers,
      });
    } catch (e) {
      state = state.copyWith(error: '回答記録失敗: $e');
    }
  }

  /// 対戦を終了
  Future<BattleResult?> completeBattle({
    required String roomId,
    required String sessionId,
  }) async {
    try {
      if (state.currentRoom == null || state.currentSession == null) {
        return null;
      }

      final room = state.currentRoom!;
      final session = state.currentSession!;

      // 最終スコアで参加者を更新
      final finalParticipants = room.participants.map((p) {
        return p.copyWith(
          currentScore: session.participantScores[p.userId] ?? 0,
          correctAnswers: session.participantCorrectAnswers[p.userId] ?? 0,
          isFinished: true,
        );
      }).toList();

      // 1位を特定
      int maxScore = 0;
      String winnerId = '';
      for (var p in finalParticipants) {
        if (p.currentScore > maxScore) {
          maxScore = p.currentScore;
          winnerId = p.userId;
        }
      }

      final result = BattleResult(
        resultId: _firestore.collection('battleResults').doc().id,
        roomId: roomId,
        winnerId: winnerId,
        finalParticipants: finalParticipants,
        totalDurationSeconds:
            DateTime.now().difference(room.startedAt ?? DateTime.now()).inSeconds,
        completedAt: DateTime.now(),
        statistics: {},
      );

      // 結果をFirestoreに保存
      await _firestore
          .collection('battleResults')
          .doc(result.resultId)
          .set(result.toJson());

      // ルームを完了
      await _firestore.collection('battleRooms').doc(roomId).update({
        'status': 'finished',
        'finishedAt': Timestamp.now(),
        'participants': finalParticipants.map((p) => p.toJson()).toList(),
      });

      state = state.copyWith(
        currentRoom: null,
        currentSession: null,
      );

      return result;
    } catch (e) {
      state = state.copyWith(error: '対戦終了失敗: $e');
      return null;
    }
  }
}

/// バトルルーム Notifier Provider
@riverpod
StateNotifier<BattleRoomState> battleRoomNotifier(
  BattleRoomNotifierRef ref,
) {
  return BattleRoomNotifier();
}

/// BattleRoom copyWith ヘルパー
extension BattleRoomCopyWith on BattleRoom {
  BattleRoom copyWith({
    String? roomId,
    String? creatorId,
    String? roomName,
    int? examLevel,
    int? maxParticipants,
    List<BattleParticipant>? participants,
    String? status,
    int? totalQuestions,
    int? timePerQuestionSeconds,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return BattleRoom(
      roomId: roomId ?? this.roomId,
      creatorId: creatorId ?? this.creatorId,
      roomName: roomName ?? this.roomName,
      examLevel: examLevel ?? this.examLevel,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timePerQuestionSeconds:
          timePerQuestionSeconds ?? this.timePerQuestionSeconds,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}

/// BattleParticipant copyWith ヘルパー
extension BattleParticipantCopyWith on BattleParticipant {
  BattleParticipant copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? currentScore,
    int? correctAnswers,
    int? level,
    DateTime? joinedAt,
    bool? isReady,
    bool? isFinished,
  }) {
    return BattleParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentScore: currentScore ?? this.currentScore,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      level: level ?? this.level,
      joinedAt: joinedAt ?? this.joinedAt,
      isReady: isReady ?? this.isReady,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}
