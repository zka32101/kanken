/// 熟語の構成問題（8級〜5級で出題される「二字熟語の成り立ち」）のデータ。
/// 漢検の実際の出題区分（ア〜エ）に沿った4パターンで分類する。
enum CompoundStructureType {
  /// ア: 似た意味の漢字を重ねたもの（例: 岩石）
  similarMeaning,

  /// イ: 反対や対になる意味の漢字を重ねたもの（例: 明暗）
  oppositeMeaning,

  /// ウ: 上の字が下の字を修飾しているもの（例: 洋画）
  modifier,

  /// エ: 下の字が上の字の目的語・補語になっているもの（例: 消火）
  verbObject,
}

const Map<CompoundStructureType, String> compoundStructureLabels = {
  CompoundStructureType.similarMeaning: '似た意味の漢字を重ねたもの',
  CompoundStructureType.oppositeMeaning: '反対や対になる意味の漢字を重ねたもの',
  CompoundStructureType.modifier: '上の字が下の字を修飾しているもの',
  CompoundStructureType.verbObject: '下の字が上の字の目的語・補語になっているもの',
};

class CompoundQuestion {
  final String level; // LEVEL_8 ~ LEVEL_5
  final String jukugo;
  final String reading;
  final CompoundStructureType structureType;

  const CompoundQuestion({
    required this.level,
    required this.jukugo,
    required this.reading,
    required this.structureType,
  });

  String get correctLabel => compoundStructureLabels[structureType]!;
}

class CompoundStructureData {
  CompoundStructureData._();

  static const List<CompoundQuestion> all = [
    // LEVEL_8（小学3年生程度）
    CompoundQuestion(level: 'LEVEL_8', jukugo: '岩石', reading: 'がんせき', structureType: CompoundStructureType.similarMeaning),
    CompoundQuestion(level: 'LEVEL_8', jukugo: '明暗', reading: 'めいあん', structureType: CompoundStructureType.oppositeMeaning),
    CompoundQuestion(level: 'LEVEL_8', jukugo: '洋画', reading: 'ようが', structureType: CompoundStructureType.modifier),
    CompoundQuestion(level: 'LEVEL_8', jukugo: '消火', reading: 'しょうか', structureType: CompoundStructureType.verbObject),
    CompoundQuestion(level: 'LEVEL_8', jukugo: '開店', reading: 'かいてん', structureType: CompoundStructureType.verbObject),
    CompoundQuestion(level: 'LEVEL_8', jukugo: '苦楽', reading: 'くらく', structureType: CompoundStructureType.oppositeMeaning),
    CompoundQuestion(level: 'LEVEL_8', jukugo: '森林', reading: 'しんりん', structureType: CompoundStructureType.similarMeaning),
    CompoundQuestion(level: 'LEVEL_8', jukugo: '乗車', reading: 'じょうしゃ', structureType: CompoundStructureType.verbObject),
    CompoundQuestion(level: 'LEVEL_8', jukugo: '曲線', reading: 'きょくせん', structureType: CompoundStructureType.modifier),
    CompoundQuestion(level: 'LEVEL_8', jukugo: '寒暑', reading: 'かんしょ', structureType: CompoundStructureType.oppositeMeaning),

    // LEVEL_7（小学4年生程度）
    CompoundQuestion(level: 'LEVEL_7', jukugo: '岸辺', reading: 'きしべ', structureType: CompoundStructureType.similarMeaning),
    CompoundQuestion(level: 'LEVEL_7', jukugo: '高低', reading: 'こうてい', structureType: CompoundStructureType.oppositeMeaning),
    CompoundQuestion(level: 'LEVEL_7', jukugo: '国旗', reading: 'こっき', structureType: CompoundStructureType.modifier),
    CompoundQuestion(level: 'LEVEL_7', jukugo: '着席', reading: 'ちゃくせき', structureType: CompoundStructureType.verbObject),
    CompoundQuestion(level: 'LEVEL_7', jukugo: '勝負', reading: 'しょうぶ', structureType: CompoundStructureType.oppositeMeaning),
    CompoundQuestion(level: 'LEVEL_7', jukugo: '温室', reading: 'おんしつ', structureType: CompoundStructureType.modifier),
    CompoundQuestion(level: 'LEVEL_7', jukugo: '開会', reading: 'かいかい', structureType: CompoundStructureType.verbObject),
    CompoundQuestion(level: 'LEVEL_7', jukugo: '開始', reading: 'かいし', structureType: CompoundStructureType.similarMeaning),
    CompoundQuestion(level: 'LEVEL_7', jukugo: '大小', reading: 'だいしょう', structureType: CompoundStructureType.oppositeMeaning),
    CompoundQuestion(level: 'LEVEL_7', jukugo: '帰国', reading: 'きこく', structureType: CompoundStructureType.verbObject),

    // LEVEL_6（小学5年生程度）
    CompoundQuestion(level: 'LEVEL_6', jukugo: '増減', reading: 'ぞうげん', structureType: CompoundStructureType.oppositeMeaning),
    CompoundQuestion(level: 'LEVEL_6', jukugo: '講演', reading: 'こうえん', structureType: CompoundStructureType.similarMeaning),
    CompoundQuestion(level: 'LEVEL_6', jukugo: '停止', reading: 'ていし', structureType: CompoundStructureType.similarMeaning),
    CompoundQuestion(level: 'LEVEL_6', jukugo: '遠近', reading: 'えんきん', structureType: CompoundStructureType.oppositeMeaning),
    CompoundQuestion(level: 'LEVEL_6', jukugo: '登山', reading: 'とざん', structureType: CompoundStructureType.verbObject),
    CompoundQuestion(level: 'LEVEL_6', jukugo: '減税', reading: 'げんぜい', structureType: CompoundStructureType.verbObject),
    CompoundQuestion(level: 'LEVEL_6', jukugo: '強弱', reading: 'きょうじゃく', structureType: CompoundStructureType.oppositeMeaning),
    CompoundQuestion(level: 'LEVEL_6', jukugo: '山脈', reading: 'さんみゃく', structureType: CompoundStructureType.modifier),
    CompoundQuestion(level: 'LEVEL_6', jukugo: '銅像', reading: 'どうぞう', structureType: CompoundStructureType.modifier),
    CompoundQuestion(level: 'LEVEL_6', jukugo: '均等', reading: 'きんとう', structureType: CompoundStructureType.similarMeaning),

    // LEVEL_5（小学6年生程度）
    CompoundQuestion(level: 'LEVEL_5', jukugo: '存亡', reading: 'そんぼう', structureType: CompoundStructureType.oppositeMeaning),
    CompoundQuestion(level: 'LEVEL_5', jukugo: '因果', reading: 'いんが', structureType: CompoundStructureType.oppositeMeaning),
    CompoundQuestion(level: 'LEVEL_5', jukugo: '収納', reading: 'しゅうのう', structureType: CompoundStructureType.similarMeaning),
    CompoundQuestion(level: 'LEVEL_5', jukugo: '温暖', reading: 'おんだん', structureType: CompoundStructureType.similarMeaning),
    CompoundQuestion(level: 'LEVEL_5', jukugo: '就職', reading: 'しゅうしょく', structureType: CompoundStructureType.verbObject),
    CompoundQuestion(level: 'LEVEL_5', jukugo: '登頂', reading: 'とうちょう', structureType: CompoundStructureType.verbObject),
    CompoundQuestion(level: 'LEVEL_5', jukugo: '郷土', reading: 'きょうど', structureType: CompoundStructureType.modifier),
    CompoundQuestion(level: 'LEVEL_5', jukugo: '幼虫', reading: 'ようちゅう', structureType: CompoundStructureType.modifier),
    CompoundQuestion(level: 'LEVEL_5', jukugo: '樹木', reading: 'じゅもく', structureType: CompoundStructureType.similarMeaning),
    CompoundQuestion(level: 'LEVEL_5', jukugo: '縦横', reading: 'じゅうおう', structureType: CompoundStructureType.oppositeMeaning),
  ];

  static List<CompoundQuestion> forLevel(String level) =>
      all.where((q) => q.level == level).toList();
}
