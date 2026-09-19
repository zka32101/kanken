import 'package:cloud_firestore/cloud_firestore.dart';

/// 間隔反復学習アイテム（SM-2アルゴリズムベース）
class SpacedRepetitionItem {
  final String itemId;
  final String userId;
  final String questionId;
  final String kanji;
  final String category;
  final String question;        // 問題文
  final List<String> options;   // 選択肢
  final String correctAnswer;
  final double easeFactor;      // 易しさ係数（初期値2.5）
  final int intervalDays;       // 次回復習までの間隔（日）
  final int repetitions;        // 連続正解回数
  final DateTime nextReviewDate;
  final DateTime lastReviewedAt;
  final int totalReviews;
  final int correctReviews;

  const SpacedRepetitionItem({
    required this.itemId,
    required this.userId,
    required this.questionId,
    required this.kanji,
    required this.category,
    this.question = '',
    this.options = const [],
    this.correctAnswer = '',
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.repetitions = 0,
    required this.nextReviewDate,
    required this.lastReviewedAt,
    this.totalReviews = 0,
    this.correctReviews = 0,
  });

  /// 復習期限が来ているか判定
  bool get isDue => DateTime.now().isAfter(nextReviewDate) ||
      DateTime.now().isAtSameMomentAs(nextReviewDate);

  /// 習熟度（正答率）
  double get masteryRate => totalReviews > 0 ? correctReviews / totalReviews : 0.0;

  /// 習熟レベル判定
  String get masteryLevel {
    if (repetitions == 0) return '新規';
    if (masteryRate >= 0.9 && repetitions >= 5) return 'マスター';
    if (masteryRate >= 0.7) return '習得中';
    return '要復習';
  }

  /// SM-2アルゴリズムに基づく次回復習情報の計算
  /// quality: 0-5 (0-2=不正解, 3-5=正解、5に近いほど簡単だった)
  SpacedRepetitionItem calculateNext(int quality) {
    double newEaseFactor = easeFactor;
    int newRepetitions = repetitions;
    int newIntervalDays = intervalDays;

    if (quality < 3) {
      // 不正解の場合はリセット
      newRepetitions = 0;
      newIntervalDays = 1;
    } else {
      // 正解の場合
      newRepetitions = repetitions + 1;

      if (newRepetitions == 1) {
        newIntervalDays = 1;
      } else if (newRepetitions == 2) {
        newIntervalDays = 6;
      } else {
        newIntervalDays = (intervalDays * easeFactor).round();
      }

      // 易しさ係数の更新
      newEaseFactor = easeFactor +
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (newEaseFactor < 1.3) newEaseFactor = 1.3;
    }

    return SpacedRepetitionItem(
      itemId: itemId,
      userId: userId,
      questionId: questionId,
      kanji: kanji,
      category: category,
      question: question,
      options: options,
      correctAnswer: correctAnswer,
      easeFactor: newEaseFactor,
      intervalDays: newIntervalDays,
      repetitions: newRepetitions,
      nextReviewDate: DateTime.now().add(Duration(days: newIntervalDays)),
      lastReviewedAt: DateTime.now(),
      totalReviews: totalReviews + 1,
      correctReviews: quality >= 3 ? correctReviews + 1 : correctReviews,
    );
  }

  /// JSON からのデシリアライズ
  factory SpacedRepetitionItem.fromJson(Map<String, dynamic> json) {
    return SpacedRepetitionItem(
      itemId: json['itemId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      kanji: json['kanji'] as String? ?? '',
      category: json['category'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: List<String>.from(json['options'] as List? ?? []),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: json['intervalDays'] as int? ?? 1,
      repetitions: json['repetitions'] as int? ?? 0,
      nextReviewDate: json['nextReviewDate'] is Timestamp
          ? (json['nextReviewDate'] as Timestamp).toDate()
          : DateTime.now(),
      lastReviewedAt: json['lastReviewedAt'] is Timestamp
          ? (json['lastReviewedAt'] as Timestamp).toDate()
          : DateTime.now(),
      totalReviews: json['totalReviews'] as int? ?? 0,
      correctReviews: json['correctReviews'] as int? ?? 0,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'userId': userId,
    'questionId': questionId,
    'kanji': kanji,
    'category': category,
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'easeFactor': easeFactor,
    'intervalDays': intervalDays,
    'repetitions': repetitions,
    'nextReviewDate': Timestamp.fromDate(nextReviewDate),
    'lastReviewedAt': Timestamp.fromDate(lastReviewedAt),
    'totalReviews': totalReviews,
    'correctReviews': correctReviews,
  };
}

/// 復習セッションの統計
class ReviewSessionStats {
  final int totalDue;
  final int reviewedToday;
  final int masteredCount;
  final int learningCount;
  final int newCount;

  const ReviewSessionStats({
    required this.totalDue,
    required this.reviewedToday,
    required this.masteredCount,
    required this.learningCount,
    required this.newCount,
  });
}
