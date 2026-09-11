import 'package:cloud_firestore/cloud_firestore.dart';

/// デイリーチャレンジ モデル
class DailyChallenge {
  final String id;
  final String date; // YYYY-MM-DD
  final List<String> questionIds;
  final String difficulty; // easy/medium/hard
  final DateTime resetTime;
  final DateTime createdAt;

  const DailyChallenge({
    required this.id,
    required this.date,
    required this.questionIds,
    required this.difficulty,
    required this.resetTime,
    required this.createdAt,
  });

  /// JSON からのデシリアライズ
  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      questionIds: List<String>.from(json['questions'] as List? ?? []),
      difficulty: json['difficulty'] as String? ?? 'medium',
      resetTime: json['resetTime'] is Timestamp
          ? (json['resetTime'] as Timestamp).toDate()
          : DateTime.now().add(Duration(days: 1)),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'questions': questionIds,
    'difficulty': difficulty,
    'resetTime': Timestamp.fromDate(resetTime),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  /// チャレンジが期限切れかどうか
  bool get isExpired => DateTime.now().isAfter(resetTime);

  /// 問題数
  int get questionCount => questionIds.length;

  @override
  String toString() => 'DailyChallenge(id: $id, date: $date, questions: $questionCount, expired: $isExpired)';
}
