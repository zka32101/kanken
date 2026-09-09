class ParentAccount {
  final String uid;
  final String linkedChildUid;
  final Map<String, dynamic> notifyPrefs; // 通知設定
  final DateTime createdAt;

  ParentAccount({
    required this.uid,
    required this.linkedChildUid,
    required this.notifyPrefs,
    required this.createdAt,
  });

  factory ParentAccount.fromJson(Map<String, dynamic> json) {
    return ParentAccount(
      uid: json['uid'] ?? '',
      linkedChildUid: json['linkedChildUid'] ?? '',
      notifyPrefs: json['notifyPrefs'] ?? {},
      createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'linkedChildUid': linkedChildUid,
      'notifyPrefs': notifyPrefs,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ParentAccount copyWith({
    String? uid,
    String? linkedChildUid,
    Map<String, dynamic>? notifyPrefs,
    DateTime? createdAt,
  }) {
    return ParentAccount(
      uid: uid ?? this.uid,
      linkedChildUid: linkedChildUid ?? this.linkedChildUid,
      notifyPrefs: notifyPrefs ?? this.notifyPrefs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
