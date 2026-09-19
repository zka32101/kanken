import '../models/stroke_order.dart';

/// 書き順サンプルデータ（小学校低学年の基礎漢字）
///
/// 座標は 0-100 の正方形を基準にした簡略化ストロークで、
/// 正式な書道規範ではなく学習アプリでの分かりやすさを優先した近似データ。
/// 将来的にはKanjiVG等の専門データセットへの置き換えを想定する。
class StrokeOrderSampleData {
  StrokeOrderSampleData._();

  static final Map<String, StrokeOrderData> _data = {
    '一': const StrokeOrderData(
      kanji: '一',
      strokePaths: ['M20,50 L80,50'],
    ),
    '二': const StrokeOrderData(
      kanji: '二',
      strokePaths: [
        'M25,35 L75,35',
        'M20,65 L80,65',
      ],
    ),
    '三': const StrokeOrderData(
      kanji: '三',
      strokePaths: [
        'M25,25 L75,25',
        'M20,50 L80,50',
        'M25,75 L75,75',
      ],
    ),
    '十': const StrokeOrderData(
      kanji: '十',
      strokePaths: [
        'M20,50 L80,50',
        'M50,20 L50,80',
      ],
    ),
    '上': const StrokeOrderData(
      kanji: '上',
      strokePaths: [
        'M35,30 L35,50',
        'M20,75 L80,75',
        'M65,45 L65,75',
      ],
    ),
    '下': const StrokeOrderData(
      kanji: '下',
      strokePaths: [
        'M20,30 L80,30',
        'M50,30 L50,60',
        'M60,70 L67,80',
      ],
    ),
    '大': const StrokeOrderData(
      kanji: '大',
      strokePaths: [
        'M20,35 L80,35',
        'M50,35 L25,80',
        'M50,35 L75,80',
      ],
    ),
    '小': const StrokeOrderData(
      kanji: '小',
      strokePaths: [
        'M50,25 L50,55',
        'M35,55 L25,80',
        'M65,55 L75,80',
      ],
    ),
    '人': const StrokeOrderData(
      kanji: '人',
      strokePaths: [
        'M50,20 L25,80',
        'M50,45 L75,80',
      ],
    ),
    '口': const StrokeOrderData(
      kanji: '口',
      strokePaths: [
        'M25,25 L25,75',
        'M25,25 L75,25 L75,75',
        'M25,75 L75,75',
      ],
    ),
    '山': const StrokeOrderData(
      kanji: '山',
      strokePaths: [
        'M50,20 L50,80',
        'M25,45 L25,80',
        'M75,45 L75,80',
      ],
    ),
    '川': const StrokeOrderData(
      kanji: '川',
      strokePaths: [
        'M25,30 Q20,55 25,80',
        'M50,35 L50,75',
        'M75,25 Q80,55 78,82',
      ],
    ),
    '木': const StrokeOrderData(
      kanji: '木',
      strokePaths: [
        'M20,35 L80,35',
        'M50,15 L50,80',
        'M50,50 L20,80',
        'M50,50 L80,80',
      ],
    ),
    '日': const StrokeOrderData(
      kanji: '日',
      strokePaths: [
        'M30,20 L30,80',
        'M30,20 L70,20 L70,80',
        'M30,50 L70,50',
        'M30,80 L70,80',
      ],
    ),
    '月': const StrokeOrderData(
      kanji: '月',
      strokePaths: [
        'M35,20 L28,80',
        'M35,20 L70,20 L70,85',
        'M35,45 L62,45',
        'M35,62 L62,62',
      ],
    ),
    '田': const StrokeOrderData(
      kanji: '田',
      strokePaths: [
        'M25,20 L25,80',
        'M25,20 L75,20 L75,80',
        'M50,20 L50,80',
        'M25,50 L75,50',
        'M25,80 L75,80',
      ],
    ),
    '土': const StrokeOrderData(
      kanji: '土',
      strokePaths: [
        'M35,35 L65,35',
        'M50,20 L50,80',
        'M20,80 L80,80',
      ],
    ),
    '女': const StrokeOrderData(
      kanji: '女',
      strokePaths: [
        'M35,25 Q30,35 50,40',
        'M50,40 L25,75',
        'M40,55 L75,75',
      ],
    ),
    '子': const StrokeOrderData(
      kanji: '子',
      strokePaths: [
        'M35,25 Q25,35 40,45 Q55,50 65,35',
        'M50,45 L50,75',
        'M25,60 L75,60',
      ],
    ),
    '力': const StrokeOrderData(
      kanji: '力',
      strokePaths: [
        'M35,25 Q30,55 20,75',
        'M45,45 L65,80',
      ],
    ),
  };

  /// 書き順データが用意されている漢字一覧
  static List<String> get availableKanji => _data.keys.toList();

  /// 指定した漢字の書き順データを取得（無ければnull）
  static StrokeOrderData? getStrokeOrder(String kanji) => _data[kanji];

  /// 書き順データがあるか判定
  static bool hasStrokeOrder(String kanji) => _data.containsKey(kanji);
}
