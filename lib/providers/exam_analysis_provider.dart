import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mock_exam_modes.dart';
import '../providers/exam_session_provider.dart';

/// 試験分析結果
class ExamAnalysisResult {
  final Map<String, CategoryPerformance> categoryPerformance;
  final List<WeakPointRecommendation> weakPoints;
  final double overallAccuracy;
  final int elapsedSeconds;
  final ExamMode examMode;
  final DateTime analyzedAt;

  const ExamAnalysisResult({
    required this.categoryPerformance,
    required this.weakPoints,
    required this.overallAccuracy,
    required this.elapsedSeconds,
    required this.examMode,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
    'categoryPerformance': categoryPerformance.map(
      (k, v) => MapEntry(k, v.toJson()),
    ),
    'weakPoints': weakPoints.map((w) => w.toJson()).toList(),
    'overallAccuracy': overallAccuracy,
    'elapsedSeconds': elapsedSeconds,
    'examMode': examMode.toString(),
    'analyzedAt': analyzedAt.toIso8601String(),
  };
}

/// カテゴリ別パフォーマンス
class CategoryPerformance {
  final String category;
  final int correct;
  final int total;
  final double accuracy;
  final double averageTimePerQuestion;

  const CategoryPerformance({
    required this.category,
    required this.correct,
    required this.total,
    required this.accuracy,
    required this.averageTimePerQuestion,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'correct': correct,
    'total': total,
    'accuracy': accuracy,
    'averageTimePerQuestion': averageTimePerQuestion,
  };
}

/// 弱点推奨
class WeakPointRecommendation {
  final String category;
  final double accuracy;
  final String recommendation;
  final int priority; // 1 = 最優先, 3 = 低優先

  const WeakPointRecommendation({
    required this.category,
    required this.accuracy,
    required this.recommendation,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'accuracy': accuracy,
    'recommendation': recommendation,
    'priority': priority,
  };
}

/// 試験セッション分析プロバイダー
final examAnalysisProvider = FutureProvider.family<
    ExamAnalysisResult?,
    (ExamSessionState, int)
>((ref, params) async {
  final session = params.$1;
  final elapsedSeconds = params.$2;

  return _analyzeExamSession(session, elapsedSeconds);
});

/// ユーザーの弱点履歴プロバイダー
final userWeakPointHistoryProvider = FutureProvider<List<ExamAnalysisResult>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('examAnalyses')
        .orderBy('analyzedAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final categoryData = data['categoryPerformance'] as Map<String, dynamic>?;

      final categoryPerformance = <String, CategoryPerformance>{};
      categoryData?.forEach((k, v) {
        categoryPerformance[k] = CategoryPerformance(
          category: v['category'] ?? k,
          correct: v['correct'] ?? 0,
          total: v['total'] ?? 0,
          accuracy: (v['accuracy'] as num?)?.toDouble() ?? 0.0,
          averageTimePerQuestion: (v['averageTimePerQuestion'] as num?)?.toDouble() ?? 0.0,
        );
      });

      final weakPoints = (data['weakPoints'] as List?)?.map((w) {
        return WeakPointRecommendation(
          category: w['category'] ?? '',
          accuracy: (w['accuracy'] as num?)?.toDouble() ?? 0.0,
          recommendation: w['recommendation'] ?? '',
          priority: w['priority'] ?? 3,
        );
      }).toList() ?? [];

      return ExamAnalysisResult(
        categoryPerformance: categoryPerformance,
        weakPoints: weakPoints,
        overallAccuracy: (data['overallAccuracy'] as num?)?.toDouble() ?? 0.0,
        elapsedSeconds: data['elapsedSeconds'] ?? 0,
        examMode: _parseExamMode(data['examMode'] ?? ''),
        analyzedAt: DateTime.parse(data['analyzedAt'] ?? DateTime.now().toIso8601String()),
      );
    }).toList();
  } catch (e) {
    return [];
  }
});

/// カテゴリ別の累積パフォーマンス
final accumulatedCategoryPerformanceProvider = FutureProvider<
    Map<String, CategoryPerformance>
>((ref) async {
  final history = await ref.watch(userWeakPointHistoryProvider.future);
  if (history.isEmpty) return {};

  final accumulated = <String, CategoryPerformance>{};

  for (final analysis in history) {
    for (final entry in analysis.categoryPerformance.entries) {
      final category = entry.key;
      final perf = entry.value;

      if (accumulated.containsKey(category)) {
        final existing = accumulated[category]!;
        accumulated[category] = CategoryPerformance(
          category: category,
          correct: existing.correct + perf.correct,
          total: existing.total + perf.total,
          accuracy: existing.correct + perf.correct > 0
              ? (existing.correct + perf.correct) / (existing.total + perf.total)
              : 0.0,
          averageTimePerQuestion: (existing.averageTimePerQuestion + perf.averageTimePerQuestion) / 2,
        );
      } else {
        accumulated[category] = perf;
      }
    }
  }

  return accumulated;
});

/// 試験セッションを分析
Future<ExamAnalysisResult> _analyzeExamSession(
  ExamSessionState session,
  int elapsedSeconds,
) async {
  final categoryStats = <String, Map<String, dynamic>>{};

  // カテゴリ別の統計を計算
  for (int i = 0; i < session.questions.length; i++) {
    final question = session.questions[i];
    final category = question.category.toString().split('.').last;
    final isCorrect = session.userAnswers[i] == question.correctAnswer;

    if (!categoryStats.containsKey(category)) {
      categoryStats[category] = {
        'correct': 0,
        'total': 0,
        'totalTime': 0,
      };
    }

    categoryStats[category]!['total'] += 1;
    if (isCorrect) {
      categoryStats[category]!['correct'] += 1;
    }
  }

  // CategoryPerformanceを作成
  final categoryPerformance = <String, CategoryPerformance>{};
  int totalCorrect = 0;
  int totalQuestions = 0;

  categoryStats.forEach((category, stats) {
    final correct = stats['correct'] as int;
    final total = stats['total'] as int;
    final accuracy = total > 0 ? correct / total : 0.0;
    final avgTime = total > 0 ? elapsedSeconds / total : 0.0;

    categoryPerformance[category] = CategoryPerformance(
      category: category,
      correct: correct,
      total: total,
      accuracy: accuracy,
      averageTimePerQuestion: avgTime,
    );

    totalCorrect += correct;
    totalQuestions += total;
  });

  // 弱点を特定
  final weakPoints = <WeakPointRecommendation>[];
  categoryPerformance.forEach((category, perf) {
    if (perf.accuracy < 0.6) {
      weakPoints.add(
        WeakPointRecommendation(
          category: category,
          accuracy: perf.accuracy,
          recommendation: '「$category」は正答率${(perf.accuracy * 100).toStringAsFixed(1)}%です。重点的な復習が必要です。',
          priority: 1,
        ),
      );
    } else if (perf.accuracy < 0.8) {
      weakPoints.add(
        WeakPointRecommendation(
          category: category,
          accuracy: perf.accuracy,
          recommendation: '「$category」をさらに強化できます。追加練習をお勧めします。',
          priority: 2,
        ),
      );
    }
  });

  // 優先度順にソート
  weakPoints.sort((a, b) => a.priority.compareTo(b.priority));

  final overallAccuracy = totalQuestions > 0 ? totalCorrect / totalQuestions : 0.0;

  return ExamAnalysisResult(
    categoryPerformance: categoryPerformance,
    weakPoints: weakPoints,
    overallAccuracy: overallAccuracy,
    elapsedSeconds: elapsedSeconds,
    examMode: session.config.mode,
    analyzedAt: DateTime.now(),
  );
}

/// 試験分析結果をFirebaseに保存
Future<void> saveExamAnalysis(ExamAnalysisResult analysis) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('examAnalyses')
        .add(analysis.toJson());
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// ExamModeを文字列からパース
ExamMode _parseExamMode(String modeStr) {
  try {
    return ExamMode.values.firstWhere(
      (mode) => mode.toString() == modeStr,
    );
  } catch (e) {
    return ExamMode.standardExam;
  }
}
