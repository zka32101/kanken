import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/weak_area.dart';

part 'weak_area_provider.g.dart';

/// 苦手分野分析を取得
@riverpod
Future<WeakAreaAnalysis> weakAreaAnalysis(WeakAreaAnalysisRef ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return WeakAreaAnalysis(
      allAreas: [],
      overallAccuracy: 0.0,
      analyzedAt: DateTime.now(),
    );
  }

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('weakAreas')
      .orderBy('accuracyRate')
      .get();

  final allAreas = snapshot.docs
      .map((doc) => WeakArea.fromJson(doc.data()))
      .toList();

  // 全体正答率を計算
  int totalAttempts = 0;
  int totalCorrect = 0;
  for (final area in allAreas) {
    totalAttempts += area.totalAttempts;
    totalCorrect += area.correctAnswers;
  }
  final overallAccuracy = totalAttempts > 0 ? totalCorrect / totalAttempts : 0.0;

  return WeakAreaAnalysis(
    allAreas: allAreas,
    overallAccuracy: overallAccuracy,
    analyzedAt: DateTime.now(),
  );
}

/// 苦手分野のみを取得
@riverpod
Future<List<WeakArea>> weakAreas(WeakAreasRef ref) async {
  final analysis = await ref.watch(weakAreaAnalysisProvider.future);
  return analysis.weakAreas;
}

/// 最も苦手な分野を取得
@riverpod
Future<WeakArea?> worstWeakArea(WorstWeakAreaRef ref) async {
  final analysis = await ref.watch(weakAreaAnalysisProvider.future);
  return analysis.getWorstArea();
}

/// 苦手分野プロバイダー StateNotifier
class WeakAreaState {
  final List<WeakArea> areas;
  final bool isLoading;
  final String? error;

  WeakAreaState({
    this.areas = const [],
    this.isLoading = false,
    this.error,
  });

  WeakAreaState copyWith({
    List<WeakArea>? areas,
    bool? isLoading,
    String? error,
  }) {
    return WeakAreaState(
      areas: areas ?? this.areas,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 苦手分野管理の StateNotifier
class WeakAreaNotifier extends StateNotifier<WeakAreaState> {
  WeakAreaNotifier() : super(WeakAreaState());

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 苦手分野を更新（正答率・出題数を追加）
  Future<void> updateWeakArea({
    required String categoryId,
    required String categoryName,
    required bool isCorrect,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final docRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('weakAreas')
          .doc(categoryId);

      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        final totalAttempts = (data['totalAttempts'] as int?) ?? 0;
        final correctAnswers = (data['correctAnswers'] as int?) ?? 0;

        final newTotal = totalAttempts + 1;
        final newCorrect = isCorrect ? correctAnswers + 1 : correctAnswers;
        final newAccuracy = newCorrect / newTotal;

        await docRef.update({
          'totalAttempts': newTotal,
          'correctAnswers': newCorrect,
          'accuracyRate': newAccuracy,
          'lastAttemptAt': Timestamp.now(),
        });
      } else {
        // 新規作成
        final newWeakArea = WeakArea(
          categoryId: categoryId,
          categoryName: categoryName,
          totalAttempts: 1,
          correctAnswers: isCorrect ? 1 : 0,
          accuracyRate: isCorrect ? 1.0 : 0.0,
          level: isCorrect ? WeakLevel.excellent : WeakLevel.veryWeak,
          recentStreakDays: isCorrect ? 1 : 0,
          lastAttemptAt: DateTime.now(),
        );

        await docRef.set(newWeakArea.toJson());
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '苦手分野の更新に失敗しました: $e',
      );
    }
  }

  /// 苦手な漢字を追加
  Future<void> addProblematicKanji({
    required String categoryId,
    required String kanjiId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final docRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('weakAreas')
          .doc(categoryId);

      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final kanjiList =
            List<String>.from(data['problematicKanjiIds'] as List? ?? []);

        if (!kanjiList.contains(kanjiId)) {
          kanjiList.add(kanjiId);
          await docRef.update({
            'problematicKanjiIds': kanjiList,
          });
        }
      }
    } catch (e) {
      state = state.copyWith(
        error: '苦手な漢字の追加に失敗しました: $e',
      );
    }
  }

  /// 苦手分野をリセット
  Future<void> resetWeakArea(String categoryId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('weakAreas')
          .doc(categoryId)
          .delete();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '苦手分野のリセットに失敗しました: $e',
      );
    }
  }
}

/// 苦手分野管理プロバイダー
@riverpod
StateNotifier<WeakAreaState> weakAreaNotifier(
  WeakAreaNotifierRef ref,
) {
  return WeakAreaNotifier();
}
