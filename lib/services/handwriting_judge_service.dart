import 'dart:math';

/// 手書き判定サービス
/// ストローク座標と正解パターンの照合ロジック
///
/// 実際の字形一致判定（機械学習モデル等）は行わない。国語コレ
/// (drawing_canvas_screen.dart の _calculateScore()) と同様の
/// ヒューリスティック採点方式を採用する:
/// - ストローク数（画数の目安、最大25点）
/// - 中心位置（キャンバス中心からの距離、最大40点）
/// - サイズ（キャンバスに対する占有率、最大35点）
class HandwritingJudgeService {
  /// 合格とみなす点数（0-100）
  static const int passingScore = 60;

  /// ストロークデータから手書き入力を判定
  /// @param strokes: 手書きストローク座標群（キャンバス内のローカル座標）。
  ///   ストロークごとにリストを分けて渡す（ペンを離した箇所が正しくストロークの
  ///   区切りとして扱われる。距離ベースの推測分割は行わない）。
  /// @param correctAnswer: 正解の漢字パターンデータ（strokeCountを含む）
  /// @param canvasSize: 手書き入力エリアの [幅, 高さ]（ヒューリスティック採点の基準）
  /// @return 正解判定結果（0-100点のヒューリスティックスコア）
  Future<HandwritingJudgement> judgeHandwriting({
    required List<List<List<double>>> strokes,
    required Map<String, dynamic> correctAnswer,
    List<double>? canvasSize,
  }) async {
    try {
      final allPoints = strokes.expand((s) => s).toList();
      if (allPoints.isEmpty) {
        return HandwritingJudgement(
          isCorrect: false,
          confidence: 0.0,
          message: '入力がありません',
        );
      }

      final canvasW = (canvasSize != null && canvasSize.isNotEmpty) ? canvasSize[0] : 280.0;
      final canvasH = (canvasSize != null && canvasSize.length > 1) ? canvasSize[1] : 280.0;

      final score = _calculateScore(strokes, allPoints, canvasW, canvasH);
      final isCorrect = score >= passingScore;

      return HandwritingJudgement(
        isCorrect: isCorrect,
        confidence: score / 100,
        message: isCorrect ? '正解（$score点）' : 'もう一度書いてみましょう（$score点）',
      );
    } catch (e) {
      return HandwritingJudgement(
        isCorrect: false,
        confidence: 0.0,
        message: '判定エラー：${e.toString()}',
      );
    }
  }

  /// 採点ロジック（国語コレの _calculateScore() を移植）
  /// - ストローク数：1〜5画が理想（最大25点）
  /// - 中心位置：バウンディングボックス中心とキャンバス中心の距離が近いほど高得点（最大40点）
  /// - サイズ：キャンバスの20%〜55%を占めるのが理想（最大35点）
  int _calculateScore(
    List<List<List<double>>> strokes,
    List<List<double>> allPoints,
    double canvasW,
    double canvasH,
  ) {
    if (allPoints.isEmpty || strokes.isEmpty) return 0;

    double minX = allPoints.first[0], maxX = allPoints.first[0];
    double minY = allPoints.first[1], maxY = allPoints.first[1];
    for (final p in allPoints) {
      minX = min(minX, p[0]);
      maxX = max(maxX, p[0]);
      minY = min(minY, p[1]);
      maxY = max(maxY, p[1]);
    }

    final bbW = maxX - minX;
    final bbH = maxY - minY;
    final bbCx = (minX + maxX) / 2;
    final bbCy = (minY + maxY) / 2;

    // 1. ストローク数スコア（1-5画が理想）
    final sc = strokes.length;
    final int strokeScore;
    if (sc == 0) {
      strokeScore = 0;
    } else if (sc == 1) {
      strokeScore = 12;
    } else if (sc <= 5) {
      strokeScore = 25;
    } else if (sc <= 8) {
      strokeScore = (25 - (sc - 5) * 5).clamp(5, 25);
    } else {
      strokeScore = 5;
    }

    // 2. 中心位置スコア（中心から20%以内が理想）
    final dxRatio = ((bbCx - canvasW / 2) / canvasW).abs();
    final dyRatio = ((bbCy - canvasH / 2) / canvasH).abs();
    final centerDist = (dxRatio + dyRatio) / 2;
    final centerScore = (40 * (1 - centerDist * 4.0)).clamp(0.0, 40.0).round();

    // 3. サイズスコア（キャンバスの20%〜55%が理想）
    final wRatio = bbW / canvasW;
    final hRatio = bbH / canvasH;
    final sizeRatio = (wRatio + hRatio) / 2;
    final int sizeScore;
    if (sizeRatio < 0.08) {
      sizeScore = (sizeRatio * 100).round().clamp(0, 10);
    } else if (sizeRatio < 0.20) {
      sizeScore = (10 + (sizeRatio - 0.08) * 200).round().clamp(10, 35);
    } else if (sizeRatio <= 0.55) {
      final dist = (sizeRatio - 0.37).abs();
      sizeScore = (35 - dist * 80).clamp(10.0, 35.0).round();
    } else {
      sizeScore = (35 - (sizeRatio - 0.55) * 70).clamp(5.0, 35.0).round();
    }

    return (strokeScore + centerScore + sizeScore).clamp(0, 100);
  }
}

class HandwritingJudgement {
  final bool isCorrect;
  final double confidence; // 0.0 ~ 1.0
  final String message;

  HandwritingJudgement({
    required this.isCorrect,
    required this.confidence,
    required this.message,
  });
}
