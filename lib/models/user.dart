class User {
  final String uid;
  final String currentLevel;
  final int streakCount;
  final DateTime createdAt;

  User({
    required this.uid,
    required this.currentLevel,
    required this.streakCount,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      currentLevel: json['currentLevel'] ?? 'LEVEL_10',
      streakCount: json['streakCount'] ?? 0,
      createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'currentLevel': currentLevel,
      'streakCount': streakCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? uid,
    String? currentLevel,
    int? streakCount,
    DateTime? createdAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      currentLevel: currentLevel ?? this.currentLevel,
      streakCount: streakCount ?? this.streakCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
