enum AnswerMode { normal, handwriting, weakKanjiFocus }

class UserAnswerLog {
  final String id;
  final String uid;
  final String profileId;
  final String questionId;
  final bool isCorrect;
  final AnswerMode mode;
  final DateTime answeredAt;

  UserAnswerLog({
    required this.id,
    required this.uid,
    this.profileId = 'default',
    required this.questionId,
    required this.isCorrect,
    required this.mode,
    required this.answeredAt,
  });

  factory UserAnswerLog.fromJson(Map<String, dynamic> json) {
    return UserAnswerLog(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      profileId: json['profileId'] as String? ?? 'default',
      questionId: json['questionId'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      mode: _parseAnswerMode(json['mode']),
      answeredAt: json['answeredAt'] != null
        ? DateTime.parse(json['answeredAt'])
        : DateTime.now(),
    );
  }

  static AnswerMode _parseAnswerMode(String? mode) {
    switch (mode) {
      case 'handwriting':
        return AnswerMode.handwriting;
      case 'weakKanjiFocus':
        return AnswerMode.weakKanjiFocus;
      default:
        return AnswerMode.normal;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'profileId': profileId,
      'questionId': questionId,
      'isCorrect': isCorrect,
      'mode': mode.toString().split('.').last,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }
}
