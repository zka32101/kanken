import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import 'services_provider.dart';
import 'user_viewmodel.dart';

// 現在の問題セット
final practiceQuestionsProvider =
    FutureProvider.family<List<KanjiQuestion>, String>((ref, level) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getQuestionsByLevel(level, limit: 50);
});

// 現在解いている問題インデックス
final currentQuestionIndexProvider = StateProvider<int>((ref) => 0);

// 現在の問題
final currentQuestionProvider = FutureProvider((ref) async {
  final level = ref.watch(currentLevelProvider);
  final questions = await ref.watch(practiceQuestionsProvider(level).future);
  final index = ref.watch(currentQuestionIndexProvider);

  if (index >= questions.length) return null;
  return questions[index];
});

// 正解数（セッション内）
final correctCountProvider = StateProvider<int>((ref) => 0);

// 回答済み問題数（セッション内）
final answeredCountProvider = StateProvider<int>((ref) => 0);

// 現在のコンボ数
final comboCountProvider = StateProvider<int>((ref) => 0);

// Aha Moment到達フラグ（初回3問正解）
final ahaMomentReachedProvider = StateProvider<bool>((ref) => false);

class PracticeViewModel extends StateNotifier<PracticeState> {
  final Ref ref;

  PracticeViewModel(this.ref)
      : super(const PracticeState(
          isLoading: false,
          currentQuestion: null,
          lastAnswerIsCorrect: null,
          isAnswering: false,
        ));

  Future<void> answerQuestion(bool isCorrect) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    state = state.copyWith(isAnswering: true);

    try {
      final questionAsync = ref.read(currentQuestionProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      // Handle AsyncValue<KanjiQuestion?>
      KanjiQuestion? question;
      if (questionAsync is AsyncData) {
        question = questionAsync.value;
      }

      if (question != null) {
        // 答ログを保存
        final log = UserAnswerLog(
          id: '',
          uid: uid,
          questionId: question.id,
          isCorrect: isCorrect,
          mode: AnswerMode.normal,
          answeredAt: DateTime.now(),
        );
        await firestoreService.addAnswerLog(log);

        // 状態を更新
        if (isCorrect) {
          ref.read(correctCountProvider.notifier).state++;
          ref.read(comboCountProvider.notifier).state++;
        } else {
          ref.read(comboCountProvider.notifier).state = 0;
        }

        ref.read(answeredCountProvider.notifier).state++;

        // Aha Moment判定：初回3問正解
        final correctCount = ref.read(correctCountProvider);
        if (correctCount >= 3 && !ref.read(ahaMomentReachedProvider)) {
          ref.read(ahaMomentReachedProvider.notifier).state = true;
          // Analytics event: aha_moment_reached
        }

        state = state.copyWith(
          lastAnswerIsCorrect: isCorrect,
          isAnswering: false,
        );

        // 次の問題へ遷移（自動は呼ばない、UIが制御）
      }
    } catch (e) {
      state = state.copyWith(isAnswering: false);
      rethrow;
    }
  }

  void moveToNextQuestion() {
    final currentIndex = ref.read(currentQuestionIndexProvider);
    ref.read(currentQuestionIndexProvider.notifier).state = currentIndex + 1;
    state = state.copyWith(lastAnswerIsCorrect: null);
  }

  void reset() {
    ref.read(currentQuestionIndexProvider.notifier).state = 0;
    ref.read(correctCountProvider.notifier).state = 0;
    ref.read(answeredCountProvider.notifier).state = 0;
    ref.read(comboCountProvider.notifier).state = 0;
    ref.read(ahaMomentReachedProvider.notifier).state = false;
    state = const PracticeState(
      isLoading: false,
      currentQuestion: null,
      lastAnswerIsCorrect: null,
      isAnswering: false,
    );
  }
}

class PracticeState {
  final bool isLoading;
  final KanjiQuestion? currentQuestion;
  final bool? lastAnswerIsCorrect;
  final bool isAnswering;

  const PracticeState({
    required this.isLoading,
    required this.currentQuestion,
    required this.lastAnswerIsCorrect,
    required this.isAnswering,
  });

  PracticeState copyWith({
    bool? isLoading,
    KanjiQuestion? currentQuestion,
    bool? lastAnswerIsCorrect,
    bool? isAnswering,
  }) {
    return PracticeState(
      isLoading: isLoading ?? this.isLoading,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      lastAnswerIsCorrect: lastAnswerIsCorrect ?? this.lastAnswerIsCorrect,
      isAnswering: isAnswering ?? this.isAnswering,
    );
  }
}

final practiceViewModelProvider =
    StateNotifierProvider<PracticeViewModel, PracticeState>((ref) {
  return PracticeViewModel(ref);
});
