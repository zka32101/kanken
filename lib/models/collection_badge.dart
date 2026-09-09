class CollectionBadge {
  final String id;
  final String uid;
  final String level; // LEVEL_10 ~ LEVEL_5
  final DateTime unlockedAt;

  CollectionBadge({
    required this.id,
    required this.uid,
    required this.level,
    required this.unlockedAt,
  });

  factory CollectionBadge.fromJson(Map<String, dynamic> json) {
    return CollectionBadge(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      level: json['level'] ?? 'LEVEL_10',
      unlockedAt: json['unlockedAt'] != null
        ? DateTime.parse(json['unlockedAt'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'level': level,
      'unlockedAt': unlockedAt.toIso8601String(),
    };
  }
}
