/// 漢字の書き順データ（1画ごとにSVGパス文字列で表現）
///
/// 座標系は 100x100 の正方形（viewBox相当）を基準とする。
class StrokeOrderData {
  final String kanji;
  final List<String> strokePaths; // 各画のSVGパスデータ（書き順どおりに並ぶ）

  const StrokeOrderData({
    required this.kanji,
    required this.strokePaths,
  });

  int get strokeCount => strokePaths.length;
}
