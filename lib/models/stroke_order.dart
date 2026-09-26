/// 漢字の書き順データ（1画ごとにSVGパス文字列で表現）
///
/// 座標系は [viewBox] x [viewBox] の正方形を基準とする
/// （KanjiVG由来のデータは109、手描き簡易データは100）。
class StrokeOrderData {
  final String kanji;
  final List<String> strokePaths; // 各画のSVGパスデータ（書き順どおりに並ぶ）
  final double viewBox;

  const StrokeOrderData({
    required this.kanji,
    required this.strokePaths,
    this.viewBox = 100,
  });

  int get strokeCount => strokePaths.length;
}
