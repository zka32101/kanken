class MockExamResult {
  final String id;
  final String uid;
  final String examId;
  final int score;
  final bool passed;
  final DateTime takenAt;

  MockExamResult({
    required this.id,
    required this.uid,
    required this.examId,
    required this.score,
    required this.passed,
    required this.takenAt,
  });

  factory MockExamResult.fromJson(Map<String, dynamic> json) {
    return MockExamResult(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      examId: json['examId'] ?? '',
      score: json['score'] ?? 0,
      passed: json['passed'] ?? false,
      takenAt: json['takenAt'] != null
        ? DateTime.parse(json['takenAt'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'examId': examId,
      'score': score,
      'passed': passed,
      'takenAt': takenAt.toIso8601String(),
    };
  }

  int getScoreNeededToPass(int passScore) {
    return passScore - score;
  }
}
