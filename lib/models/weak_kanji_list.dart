class WeakKanjiList {
  final String id;
  final String uid;
  final String kanjiId;
  final int missCount;
  final DateTime lastMissedAt;
  final DateTime? masteredAt;

  WeakKanjiList({
    required this.id,
    required this.uid,
    required this.kanjiId,
    required this.missCount,
    required this.lastMissedAt,
    this.masteredAt,
  });

  factory WeakKanjiList.fromJson(Map<String, dynamic> json) {
    return WeakKanjiList(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      kanjiId: json['kanjiId'] ?? '',
      missCount: json['missCount'] ?? 0,
      lastMissedAt: json['lastMissedAt'] != null
        ? DateTime.parse(json['lastMissedAt'])
        : DateTime.now(),
      masteredAt: json['masteredAt'] != null
          ? DateTime.parse(json['masteredAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'kanjiId': kanjiId,
      'missCount': missCount,
      'lastMissedAt': lastMissedAt.toIso8601String(),
      if (masteredAt != null) 'masteredAt': masteredAt!.toIso8601String(),
    };
  }

  WeakKanjiList copyWith({
    String? id,
    String? uid,
    String? kanjiId,
    int? missCount,
    DateTime? lastMissedAt,
    DateTime? masteredAt,
  }) {
    return WeakKanjiList(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      kanjiId: kanjiId ?? this.kanjiId,
      missCount: missCount ?? this.missCount,
      lastMissedAt: lastMissedAt ?? this.lastMissedAt,
      masteredAt: masteredAt ?? this.masteredAt,
    );
  }
}
