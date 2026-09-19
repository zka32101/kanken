class User {
  final String uid;
  final String displayName;
  final String currentLevel;
  final int streakCount;
  final DateTime createdAt;

  User({
    required this.uid,
    this.displayName = '',
    required this.currentLevel,
    required this.streakCount,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? '',
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
      'displayName': displayName,
      'currentLevel': currentLevel,
      'streakCount': streakCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? uid,
    String? displayName,
    String? currentLevel,
    int? streakCount,
    DateTime? createdAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      currentLevel: currentLevel ?? this.currentLevel,
      streakCount: streakCount ?? this.streakCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
