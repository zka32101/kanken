import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/mock_exam.dart';

part 'mock_exam_provider.g.dart';

/// 試験問題を取得（指定した級）
@riverpod
Future<List<ExamQuestion>> examQuestions(
  ExamQuestionsRef ref,
  int examLevel,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('examQuestions')
      .where('level', isEqualTo: examLevel)
      .limit(50)
      .get();

  return snapshot.docs
      .map((doc) => ExamQuestion.fromJson(doc.data()))
      .toList();
}

/// ユーザーの試験結果を取得
@riverpod
Future<List<ExamResult>> userExamResults(UserExamResultsRef ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('examResults')
      .orderBy('completedAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => ExamResult.fromJson(doc.data()))
      .toList();
}

/// ユーザーの試験統計を取得
@riverpod
Future<ExamStatistics> userExamStatistics(UserExamStatisticsRef ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return ExamStatistics(
      userId: '',
      totalExamsTaken: 0,
      totalPassed: 0,
      averageAccuracy: 0.0,
      bestScore: 0,
      worstScore: 0,
      levelStatistics: {},
    );
  }

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('examStatistics')
      .doc('summary')
      .get();

  if (!snapshot.exists) {
    return ExamStatistics(
      userId: userId,
      totalExamsTaken: 0,
      totalPassed: 0,
      averageAccuracy: 0.0,
      bestScore: 0,
      worstScore: 0,
      levelStatistics: {},
    );
  }

  return ExamStatistics.fromJson(snapshot.data() ?? {});
}

/// 試験セッション State
class ExamSessionState {
  final bool isLoading;
  final String? error;
  final ExamSession? currentSession;
  final bool isTimeUp;

  ExamSessionState({
    this.isLoading = false,
    this.error,
    this.currentSession,
    this.isTimeUp = false,
  });

  ExamSessionState copyWith({
    bool? isLoading,
    String? error,
    ExamSession? currentSession,
    bool? isTimeUp,
  }) {
    return ExamSessionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentSession: currentSession ?? this.currentSession,
      isTimeUp: isTimeUp ?? this.isTimeUp,
    );
  }
}

/// 試験セッション Notifier
class ExamSessionNotifier extends StateNotifier<ExamSessionState> {
  ExamSessionNotifier() : super(ExamSessionState());

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 試験セッションを開始
  Future<void> startExam({
    required int examLevel,
    required List<ExamQuestion> questions,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('ユーザーがログインしていません');

      final sessionId = _firestore.collection('examSessions').doc().id;

      final session = ExamSession(
        sessionId: sessionId,
        userId: userId,
        examLevel: examLevel,
        questions: questions,
        currentQuestionIndex: 0,
        userAnswers: [],
        startedAt: DateTime.now(),
        totalTimeSeconds: 1800, // 30分
        elapsedSeconds: 0,
        isCompleted: false,
      );

      // Firestoreに試験セッションを保存
      await _firestore
          .collection('examSessions')
          .doc(sessionId)
          .set(session.toJson());

      state = state.copyWith(isLoading: false, currentSession: session);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'セッション開始失敗: $e',
      );
    }
  }

  /// 回答を記録
  Future<void> recordAnswer({
    required int questionIndex,
    required String selectedAnswer,
  }) async {
    try {
      if (state.currentSession == null) return;

      final session = state.currentSession!;
      final question = session.questions[questionIndex];
      final isCorrect = selectedAnswer == question.correctAnswer;

      final answer = UserAnswer(
        questionIndex: questionIndex,
        selectedAnswer: selectedAnswer,
        isCorrect: isCorrect,
        timeSpent: 30, // 平均30秒
      );

      final updatedAnswers = [...session.userAnswers, answer];

      // セッションを更新
      final updatedSession = ExamSession(
        sessionId: session.sessionId,
        userId: session.userId,
        examLevel: session.examLevel,
        questions: session.questions,
        currentQuestionIndex: questionIndex + 1,
        userAnswers: updatedAnswers,
        startedAt: session.startedAt,
        totalTimeSeconds: session.totalTimeSeconds,
        elapsedSeconds:
            DateTime.now().difference(session.startedAt).inSeconds,
        isCompleted:
            questionIndex + 1 >= session.questions.length ||
            session.isTimeUp(),
      );

      state = state.copyWith(currentSession: updatedSession);

      // Firestoreに回答を保存
      await _firestore
          .collection('examSessions')
          .doc(session.sessionId)
          .update({
        'userAnswers': updatedAnswers.map((a) => a.toJson()).toList(),
        'currentQuestionIndex': questionIndex + 1,
        'elapsedSeconds': updatedSession.elapsedSeconds,
        'isCompleted': updatedSession.isCompleted,
      });
    } catch (e) {
      state = state.copyWith(error: '回答記録失敗: $e');
    }
  }

  /// 試験を終了して結果を生成
  Future<ExamResult?> completeExam() async {
    try {
      if (state.currentSession == null) return null;

      final session = state.currentSession!;
      final correctCount = session.userAnswers
          .where((a) => a.isCorrect)
          .length;
      final totalTime =
          DateTime.now().difference(session.startedAt).inSeconds;

      final result = ExamResult(
        resultId: _firestore.collection('examResults').doc().id,
        userId: session.userId,
        examSessionId: session.sessionId,
        examLevel: session.examLevel,
        totalQuestions: session.questions.length,
        correctAnswers: correctCount,
        accuracyRate: correctCount / session.questions.length,
        totalTimeSeconds: totalTime,
        answers: session.userAnswers,
        completedAt: DateTime.now(),
        isPassed: (correctCount / session.questions.length) >= 0.6,
        estimatedRank: 0,
        categoryScores: {},
      );

      // 結果をFirestoreに保存
      await _firestore
          .collection('users')
          .doc(session.userId)
          .collection('examResults')
          .doc(result.resultId)
          .set(result.toJson());

      // セッションを完了
      await _firestore
          .collection('examSessions')
          .doc(session.sessionId)
          .update({'isCompleted': true});

      state = state.copyWith(
        currentSession: null,
        isLoading: false,
      );

      return result;
    } catch (e) {
      state = state.copyWith(error: '試験終了失敗: $e');
      return null;
    }
  }

  /// 試験を中止
  Future<void> abandonExam() async {
    try {
      if (state.currentSession == null) return;

      final session = state.currentSession!;
      await _firestore
          .collection('examSessions')
          .doc(session.sessionId)
          .delete();

      state = state.copyWith(currentSession: null);
    } catch (e) {
      state = state.copyWith(error: '試験中止失敗: $e');
    }
  }

  /// タイマーで経過時間を更新
  void updateElapsedTime(int seconds) {
    if (state.currentSession == null) return;

    final session = state.currentSession!;
    final isTimeUp = seconds >= session.totalTimeSeconds;

    final updatedSession = ExamSession(
      sessionId: session.sessionId,
      userId: session.userId,
      examLevel: session.examLevel,
      questions: session.questions,
      currentQuestionIndex: session.currentQuestionIndex,
      userAnswers: session.userAnswers,
      startedAt: session.startedAt,
      totalTimeSeconds: session.totalTimeSeconds,
      elapsedSeconds: seconds,
      isCompleted: session.isCompleted || isTimeUp,
    );

    state = state.copyWith(
      currentSession: updatedSession,
      isTimeUp: isTimeUp,
    );
  }
}

/// 試験セッション Notifier Provider
@riverpod
StateNotifier<ExamSessionState> examSessionNotifier(
  ExamSessionNotifierRef ref,
) {
  return ExamSessionNotifier();
}
