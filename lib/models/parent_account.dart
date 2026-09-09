class ParentAccount {
  final String uid;
  final String linkedChildUid;
  final Map<String, dynamic> notifyPrefs; // 通知設定
  final DateTime createdAt;
  final List<String> childUserIds; // 連携している子どもアカウントのUID一覧

  ParentAccount({
    required this.uid,
    required this.linkedChildUid,
    required this.notifyPrefs,
    required this.createdAt,
    this.childUserIds = const [],
  });

  // 通知設定へのアクセサ
  bool get notifyOnCompletion => notifyPrefs['notifyOnCompletion'] ?? false;
  bool get notifyOnWeakDiscovered => notifyPrefs['notifyOnWeakDiscovered'] ?? false;
  bool get notifyOnStreakAtRisk => notifyPrefs['notifyOnStreakAtRisk'] ?? false;

  factory ParentAccount.fromJson(Map<String, dynamic> json) {
    return ParentAccount(
      uid: json['uid'] ?? '',
      linkedChildUid: json['linkedChildUid'] ?? '',
      notifyPrefs: json['notifyPrefs'] ?? {},
      createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
      childUserIds: List<String>.from(json['childUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'linkedChildUid': linkedChildUid,
      'notifyPrefs': notifyPrefs,
      'createdAt': createdAt.toIso8601String(),
      'childUserIds': childUserIds,
    };
  }

  ParentAccount copyWith({
    String? uid,
    String? linkedChildUid,
    Map<String, dynamic>? notifyPrefs,
    DateTime? createdAt,
    List<String>? childUserIds,
  }) {
    return ParentAccount(
      uid: uid ?? this.uid,
      linkedChildUid: linkedChildUid ?? this.linkedChildUid,
      notifyPrefs: notifyPrefs ?? this.notifyPrefs,
      createdAt: createdAt ?? this.createdAt,
      childUserIds: childUserIds ?? this.childUserIds,
    );
  }
}
