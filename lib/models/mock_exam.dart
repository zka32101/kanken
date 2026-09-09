class MockExam {
  final String id;
  final String level; // LEVEL_10 ~ LEVEL_5
  final List<String> questionIds;
  final int timeLimitSec;
  final int passScore;

  MockExam({
    required this.id,
    required this.level,
    required this.questionIds,
    required this.timeLimitSec,
    required this.passScore,
  });

  factory MockExam.fromJson(Map<String, dynamic> json) {
    return MockExam(
      id: json['id'] ?? '',
      level: json['level'] ?? 'LEVEL_10',
      questionIds: List<String>.from(json['questionIds'] ?? []),
      timeLimitSec: json['timeLimitSec'] ?? 600,
      passScore: json['passScore'] ?? 80,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'questionIds': questionIds,
      'timeLimitSec': timeLimitSec,
      'passScore': passScore,
    };
  }
}
