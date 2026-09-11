import 'package:cloud_firestore/cloud_firestore.dart';

/// ご褒美の種類
enum RewardType {
  correctAnswer,        // 正解時
  streakBonus,         // 連続日数ボーナス
  dailyChallengeComplete, // デイリーチャレンジ完了
  allCorrect,          // 全問正解
  levelUp,             // レベルアップ
}

/// ユーザーが獲得するご褒美
class Reward {
  final String id;
  final RewardType type;
  final int amount; // EXP または coins
  final String message;
  final DateTime earnedAt;
  final Map<String, dynamic>? metadata;

  const Reward({
    required this.id,
    required this.type,
    required this.amount,
    required this.message,
    required this.earnedAt,
    this.metadata,
  });

  /// 正解時のご褒美
  factory Reward.correctAnswer({String? id}) {
    return Reward(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: RewardType.correctAnswer,
      amount: 10,
      message: '✨ +10 EXP',
      earnedAt: DateTime.now(),
    );
  }

  /// 連続日数ボーナス
  factory Reward.streakBonus(int streak, {String? id}) {
    final bonus = (streak ~/ 5) * 10 + 50; // 5日ごとに10 EXP追加
    return Reward(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: RewardType.streakBonus,
      amount: bonus,
      message: '🔥 連続$streak日！ +$bonus EXP',
      earnedAt: DateTime.now(),
      metadata: {'streak': streak},
    );
  }

  /// デイリーチャレンジ完了ボーナス
  factory Reward.dailyChallengeComplete({String? id}) {
    return Reward(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: RewardType.dailyChallengeComplete,
      amount: 100,
      message: '🎉 デイリーチャレンジ完了！ +100 coins',
      earnedAt: DateTime.now(),
    );
  }

  /// 全問正解ボーナス
  factory Reward.allCorrect({String? id}) {
    return Reward(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: RewardType.allCorrect,
      amount: 50,
      message: '⭐ 全問正解！ +50 EXP',
      earnedAt: DateTime.now(),
    );
  }

  /// レベルアップボーナス
  factory Reward.levelUp(int newLevel, {String? id}) {
    return Reward(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: RewardType.levelUp,
      amount: 0,
      message: '🎊 レベル $newLevel に昇格！',
      earnedAt: DateTime.now(),
      metadata: {'newLevel': newLevel},
    );
  }

  /// JSON からのデシリアライズ
  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String? ?? '',
      type: RewardType.values[json['type'] as int? ?? 0],
      amount: json['amount'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      earnedAt: json['earnedAt'] is Timestamp
          ? (json['earnedAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'amount': amount,
    'message': message,
    'earnedAt': Timestamp.fromDate(earnedAt),
    if (metadata != null) 'metadata': metadata,
  };

  @override
  String toString() => 'Reward(type: ${type.name}, amount: $amount, message: $message)';
}
