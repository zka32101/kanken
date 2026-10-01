/// 級ごとの演習進捗（正答率・次の級までの距離の計算に使う）。
/// users/{uid}/profiles/{profileId}/levelStats/{level} に集計されたデータから作る。
class LevelProgress {
  final String level;
  final int correctCount;
  final int totalCount;

  const LevelProgress({
    required this.level,
    required this.correctCount,
    required this.totalCount,
  });

  factory LevelProgress.fromJson(String level, Map<String, dynamic> json) {
    return LevelProgress(
      level: level,
      correctCount: json['correctCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'correctCount': correctCount,
        'totalCount': totalCount,
      };

  static const empty = LevelProgress(level: '', correctCount: 0, totalCount: 0);

  /// 正答率（0.0〜1.0）
  double get accuracyRate => totalCount <= 0 ? 0.0 : correctCount / totalCount;

  // 「次の級」判定の基準値。
  // 「一定量の問題（kTargetQuestions問）に取り組み、正答率kPassThreshold以上」で
  // その級をクリアしたとみなす（漢検の実際の合格基準とは異なる、アプリ内の目安）。
  static const int kTargetQuestions = 20;
  static const double kPassThreshold = 0.8;

  /// この級をクリア（次の級に進める状態）とみなせるか
  bool get isCleared =>
      totalCount >= kTargetQuestions && accuracyRate >= kPassThreshold;

  /// 次の級まであと何問正解が必要か（0ならクリア済み）
  /// 「残りの出題は全問正解する」と仮定した上での目安値。
  int get remainingCorrectToClear {
    if (isCleared) return 0;
    final targetCorrect = (kTargetQuestions * kPassThreshold).ceil();
    final remainingForVolume = (kTargetQuestions - totalCount).clamp(0, kTargetQuestions);
    final remainingForAccuracy = (targetCorrect - correctCount).clamp(0, targetCorrect);
    return remainingForAccuracy > remainingForVolume
        ? remainingForAccuracy
        : remainingForVolume;
  }
}
