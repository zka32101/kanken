import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/global_event.dart';

part 'event_provider.g.dart';

/// アクティブなイベント一覧を取得
@riverpod
Future<List<GlobalEvent>> activeEvents(ActiveEventsRef ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('events')
      .where('status', isEqualTo: 'active')
      .orderBy('endAt')
      .get();

  return snapshot.docs
      .map((doc) => GlobalEvent.fromJson(doc.data()))
      .toList();
}

/// 開始前のイベント一覧を取得
@riverpod
Future<List<GlobalEvent>> upcomingEvents(UpcomingEventsRef ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('events')
      .where('status', isEqualTo: 'upcoming')
      .orderBy('startAt')
      .get();

  return snapshot.docs
      .map((doc) => GlobalEvent.fromJson(doc.data()))
      .toList();
}

/// 終了したイベント一覧を取得
@riverpod
Future<List<GlobalEvent>> pastEvents(PastEventsRef ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('events')
      .where('status', isEqualTo: 'ended')
      .orderBy('endAt', descending: true)
      .limit(10)
      .get();

  return snapshot.docs
      .map((doc) => GlobalEvent.fromJson(doc.data()))
      .toList();
}

/// イベント参加情報を取得
@riverpod
Future<List<EventParticipation>> eventParticipants(
  EventParticipantsRef ref,
  String eventId,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('events')
      .doc(eventId)
      .collection('participants')
      .orderBy('rank')
      .get();

  return snapshot.docs
      .map((doc) => EventParticipation.fromJson(doc.data()))
      .toList();
}

/// ユーザーのイベント参加記録を取得
@riverpod
Future<List<EventParticipation>> userEventParticipations(
  UserEventParticipationsRef ref,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('eventParticipations')
      .orderBy('joinedAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => EventParticipation.fromJson(doc.data()))
      .toList();
}

/// イベント管理 State
class EventState {
  final List<GlobalEvent> events;
  final bool isLoading;
  final String? error;

  EventState({
    this.events = const [],
    this.isLoading = false,
    this.error,
  });

  EventState copyWith({
    List<GlobalEvent>? events,
    bool? isLoading,
    String? error,
  }) {
    return EventState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// イベント管理の StateNotifier
class EventNotifier extends StateNotifier<EventState> {
  EventNotifier() : super(EventState());

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// イベントに参加
  Future<void> joinEvent({
    required String eventId,
    required GlobalEvent event,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final participationId =
          _firestore.collection('events').doc(eventId).collection('participants').doc().id;

      final participation = EventParticipation(
        participationId: participationId,
        eventId: eventId,
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'Unknown',
        currentScore: 0,
        isCompleted: false,
        rank: event.participantCount + 1,
        rewardCoins: 0,
        joinedAt: DateTime.now(),
      );

      // イベントの participants コレクションに追加
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .doc(participationId)
          .set(participation.toJson());

      // ユーザーの eventParticipations コレクションにも追加
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('eventParticipations')
          .doc(participationId)
          .set(participation.toJson());

      // イベントの参加者数を増やす
      await _firestore.collection('events').doc(eventId).update({
        'participantCount': FieldValue.increment(1),
      });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'イベント参加に失敗しました: $e',
      );
    }
  }

  /// イベント内でスコアを更新
  Future<void> updateEventScore({
    required String eventId,
    required String participationId,
    required int newScore,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      // イベントの participants コレクションを更新
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .doc(participationId)
          .update({'currentScore': newScore});

      // ユーザーの eventParticipations も更新
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('eventParticipations')
          .doc(participationId)
          .update({'currentScore': newScore});
    } catch (e) {
      state = state.copyWith(
        error: 'スコア更新に失敗しました: $e',
      );
    }
  }

  /// イベント完了
  Future<void> completeEvent({
    required String eventId,
    required String participationId,
    required int finalScore,
    required int rewardCoins,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      // イベントの participants コレクションを更新
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .doc(participationId)
          .update({
        'currentScore': finalScore,
        'isCompleted': true,
        'rewardCoins': rewardCoins,
        'completedAt': Timestamp.now(),
      });

      // ユーザーの eventParticipations も更新
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('eventParticipations')
          .doc(participationId)
          .update({
        'currentScore': finalScore,
        'isCompleted': true,
        'rewardCoins': rewardCoins,
        'completedAt': Timestamp.now(),
      });

      // ユーザーのコインを加算（gamification_stats と同期）
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'coins': FieldValue.increment(rewardCoins),
      });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'イベント完了処理に失敗しました: $e',
      );
    }
  }

  /// イベント離脱
  Future<void> quitEvent({
    required String eventId,
    required String participationId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      // イベントの participants コレクションから削除
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .doc(participationId)
          .delete();

      // ユーザーの eventParticipations からも削除
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('eventParticipations')
          .doc(participationId)
          .delete();

      // イベントの参加者数を減らす
      await _firestore.collection('events').doc(eventId).update({
        'participantCount': FieldValue.increment(-1),
      });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'イベント離脱に失敗しました: $e',
      );
    }
  }
}

/// イベント管理プロバイダー
@riverpod
StateNotifier<EventState> eventNotifier(
  EventNotifierRef ref,
) {
  return EventNotifier();
}
