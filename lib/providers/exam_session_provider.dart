import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mock_exam_modes.dart';
import 'mock_exam_enhanced_provider.dart';
import 'firebase_provider.dart';

/// この級・条件に該当する試験問題がまだ用意されていない場合の例外。
/// Firestoreのエラーではなく「データ未整備」であることをUI側が
/// 区別して分かりやすいメッセージを出せるようにする。
class NoExamQuestionsException implements Exception {
  final int level;
  const NoExamQuestionsException(this.level);

  @override
  String toString() => 'No exam questions available for level $level';
}

/// 現在の試験モード設定
final currentExamConfigProvider =
    StateProvider<ExamConfig?>((ref) => ExamConfig.standard());

/// 現在選択されている試験モードの名前
final currentExamModeNameProvider = Provider<String>((ref) {
  final config = ref.watch(currentExamConfigProvider);
  if (config == null) return '';

  final modeNames = {
    ExamMode.standardExam: '標準試験',
    ExamMode.speedExam: '速度試験',
    ExamMode.focusedExam: '集中試験',
    ExamMode.weakAreasExam: '弱点対策',
    ExamMode.randomExam: 'ランダム試験',
    ExamMode.progressiveExam: '段階式試験',
  };

  return modeNames[config.mode] ?? '試験';
});

/// 選択された試験モードの問題を取得
final examModeQuestionsProvider =
    FutureProvider<List<EnhancedExamQuestion>>((ref) async {
  final config = ref.watch(currentExamConfigProvider);
  if (config == null) {
    throw Exception('No exam config selected');
  }

  final userId = ref.watch(currentUserIdProvider);

  // モードに応じて適切なプロバイダーを使用
  switch (config.mode) {
    case ExamMode.standardExam:
    case ExamMode.speedExam:
    case ExamMode.focusedExam:
    case ExamMode.randomExam:
      // enhancedExamQuestionsProvider を使用
      return ref.watch(enhancedExamQuestionsProvider(config)).when(
        data: (questions) => questions,
        loading: () => throw Exception('Loading questions'),
        error: (err, stack) => throw err,
      );

    case ExamMode.weakAreasExam:
      if (userId == null) throw Exception('User not authenticated');
      // weakAreaQuestionsProvider を使用
      return ref.watch(weakAreaQuestionsProvider(
        (userId: userId, examLevel: config.targetLevel),
      )).when(
        data: (questions) => questions,
        loading: () => throw Exception('Loading questions'),
        error: (err, stack) => throw err,
      );

    case ExamMode.progressiveExam:
      // progressiveExamQuestionsProvider を使用
      return ref.watch(progressiveExamQuestionsProvider(config.targetLevel)).when(
        data: (questions) => questions,
        loading: () => throw Exception('Loading questions'),
        error: (err, stack) => throw err,
      );
  }
});

/// 試験セッションの状態を管理
class ExamSessionState {
  final ExamConfig config;
  final List<EnhancedExamQuestion> questions;
  final int currentQuestionIndex;
  final int elapsedSeconds;
  final Map<int, String> userAnswers; // questionIndex -> selected answer

  const ExamSessionState({
    required this.config,
    required this.questions,
    this.currentQuestionIndex = 0,
    this.elapsedSeconds = 0,
    this.userAnswers = const {},
  });

  /// 残り時間を秒で返す
  int getRemainingTime() {
    final totalSeconds = config.timeLimit * 60;
    return (totalSeconds - elapsedSeconds).clamp(0, totalSeconds);
  }

  /// 進捗率を0-1で返す
  double getProgressPercentage() {
    if (questions.isEmpty) return 0;
    return (currentQuestionIndex + 1) / questions.length;
  }

  /// 現在の問題を返す
  EnhancedExamQuestion? getCurrentQuestion() {
    if (currentQuestionIndex >= questions.length) return null;
    return questions[currentQuestionIndex];
  }

  /// 正解数を計算
  int getCorrectAnswerCount() {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i].correctAnswer) {
        count++;
      }
    }
    return count;
  }

  /// 正答率を計算（0-1）
  double getAccuracyRate() {
    if (questions.isEmpty) return 0;
    return getCorrectAnswerCount() / questions.length;
  }

  ExamSessionState copyWith({
    ExamConfig? config,
    List<EnhancedExamQuestion>? questions,
    int? currentQuestionIndex,
    int? elapsedSeconds,
    Map<int, String>? userAnswers,
  }) {
    return ExamSessionState(
      config: config ?? this.config,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      userAnswers: userAnswers ?? this.userAnswers,
    );
  }
}

/// 試験セッションプロバイダー
final examSessionProvider =
    StateNotifierProvider<ExamSessionNotifier, ExamSessionState?>((ref) {
  return ExamSessionNotifier(ref);
});

class ExamSessionNotifier extends StateNotifier<ExamSessionState?> {
  final Ref ref;

  ExamSessionNotifier(this.ref) : super(null);

  /// 試験を開始
  Future<void> startExam(ExamConfig config) async {
    try {
      // 問題を取得
      final questions = await ref.read(examModeQuestionsProvider.future);

      if (questions.isEmpty) {
        throw NoExamQuestionsException(config.targetLevel);
      }

      state = ExamSessionState(
        config: config,
        questions: questions,
        currentQuestionIndex: 0,
        elapsedSeconds: 0,
        userAnswers: {},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 回答を記録
  void recordAnswer(int questionIndex, String answer) {
    if (state == null) return;

    final newAnswers = Map<int, String>.from(state!.userAnswers);
    newAnswers[questionIndex] = answer;

    state = state!.copyWith(userAnswers: newAnswers);
  }

  /// 次の問題へ
  void moveToNextQuestion() {
    if (state == null) return;
    state = state!.copyWith(
      currentQuestionIndex: (state!.currentQuestionIndex + 1)
          .clamp(0, state!.questions.length),
    );
  }

  /// 前の問題へ
  void moveToPreviousQuestion() {
    if (state == null) return;
    state = state!.copyWith(
      currentQuestionIndex:
          (state!.currentQuestionIndex - 1).clamp(0, state!.questions.length - 1),
    );
  }

  /// 経過時間を更新
  void updateElapsedTime(int seconds) {
    if (state == null) return;
    state = state!.copyWith(elapsedSeconds: seconds);
  }

  /// 試験を終了
  void endExam() {
    state = null;
  }

  /// 試験をリセット
  void reset() {
    state = null;
  }
}
