/// 漢字の読み方（音読み・訓読み複数）・用例（漢字の学習画面などで表示する簡易辞書）。
/// readings は音読み（カタカナ）・訓読み（ひらがな、送り仮名は「た（べる）」のように
/// 括弧表記）を並べたもの。examples はそれぞれの読み方に対応する用例。
class KanjiInfo {
  final List<String> readings;
  final List<String> examples;

  const KanjiInfo({required this.readings, required this.examples});

  /// scripts/seed-kanji-questions.js の reading/example フィールドと
  /// 揃えるための、代表的な1つの読み方・用例（先頭の要素）
  String get primaryReading => readings.first;
  String get primaryExample => examples.first;
}

class KanjiInfoData {
  KanjiInfoData._();

  static const Map<String, KanjiInfo> _data = {
    '一': KanjiInfo(readings: ['イチ', 'イツ', 'ひと（つ）'], examples: ['一番目（いちばんめ）', '一つ（ひとつ）']),
    '二': KanjiInfo(readings: ['ニ', 'ふた（つ）'], examples: ['二人（ふたり）', '二月（にがつ）']),
    '三': KanjiInfo(readings: ['サン', 'み（つ）'], examples: ['三月（さんがつ）', '三つ（みっつ）']),
    '四': KanjiInfo(readings: ['シ', 'よん', 'よ（つ）'], examples: ['四月（しがつ）', '四つ（よっつ）']),
    '五': KanjiInfo(readings: ['ゴ', 'いつ（つ）'], examples: ['五月（ごがつ）', '五つ（いつつ）']),
    '六': KanjiInfo(readings: ['ロク', 'む（つ）'], examples: ['六月（ろくがつ）', '六つ（むっつ）']),
    '七': KanjiInfo(readings: ['シチ', 'なな（つ）'], examples: ['七月（しちがつ）', '七つ（ななつ）']),
    '八': KanjiInfo(readings: ['ハチ', 'や（つ）'], examples: ['八月（はちがつ）', '八つ（やっつ）']),
    '九': KanjiInfo(readings: ['キュウ', 'ク', 'ここの（つ）'], examples: ['九月（くがつ）', '九つ（ここのつ）']),
    '十': KanjiInfo(readings: ['ジュウ', 'とお'], examples: ['十月（じゅうがつ）', '十日（とおか）']),
    '人': KanjiInfo(readings: ['ジン', 'ニン', 'ひと'], examples: ['人間（にんげん）', '三人（さんにん）']),
    '火': KanjiInfo(readings: ['カ', 'ひ'], examples: ['火曜日（かようび）', '花火（はなび）']),
    '水': KanjiInfo(readings: ['スイ', 'みず'], examples: ['水曜日（すいようび）', '水色（みずいろ）']),
    '木': KanjiInfo(readings: ['モク', 'ボク', 'き', 'こ'], examples: ['木曜日（もくようび）', '木立（こだち）']),
    '土': KanjiInfo(readings: ['ド', 'ト', 'つち'], examples: ['土曜日（どようび）', '土地（とち）']),
    '金': KanjiInfo(readings: ['キン', 'コン', 'かね'], examples: ['金曜日（きんようび）', 'お金（おかね）']),
    '日': KanjiInfo(readings: ['ニチ', 'ジツ', 'ひ', 'か'], examples: ['日曜日（にちようび）', '三日（みっか）']),
    '月': KanjiInfo(readings: ['ゲツ', 'ガツ', 'つき'], examples: ['月曜日（げつようび）', '一月（いちがつ）']),
    '年': KanjiInfo(readings: ['ネン', 'とし'], examples: ['来年（らいねん）', '今年（ことし）']),
    '子': KanjiInfo(readings: ['シ', 'ス', 'こ'], examples: ['子供（こども）', '男子（だんし）']),
    '女': KanjiInfo(readings: ['ジョ', 'ニョ', 'おんな'], examples: ['女性（じょせい）', '女の子（おんなのこ）']),
    '男': KanjiInfo(readings: ['ダン', 'ナン', 'おとこ'], examples: ['男性（だんせい）', '男の子（おとこのこ）']),
    '右': KanjiInfo(readings: ['ウ', 'ユウ', 'みぎ'], examples: ['右手（みぎて）', '左右（さゆう）']),
    '雨': KanjiInfo(readings: ['ウ', 'あめ', 'あま'], examples: ['雨降り（あめふり）', '雨具（あまぐ）']),
    '円': KanjiInfo(readings: ['エン', 'まる（い）'], examples: ['百円（ひゃくえん）', '円い（まるい）']),
    '王': KanjiInfo(readings: ['オウ'], examples: ['王様（おうさま）', '王国（おうこく）']),
    '音': KanjiInfo(readings: ['オン', 'イン', 'おと', 'ね'], examples: ['足音（あしおと）', '音楽（おんがく）']),
    '下': KanjiInfo(readings: ['カ', 'ゲ', 'した', 'さ（げる）', 'くだ（る）'], examples: ['下着（したぎ）', '下車（げしゃ）']),
    '花': KanjiInfo(readings: ['カ', 'はな'], examples: ['花見（はなみ）', '花火（はなび）']),
    '貝': KanjiInfo(readings: ['かい'], examples: ['貝殻（かいがら）', '貝拾い（かいひろい）']),
    '学': KanjiInfo(readings: ['ガク', 'まな（ぶ）'], examples: ['学校（がっこう）', '学ぶ（まなぶ）']),
    '気': KanjiInfo(readings: ['キ', 'ケ'], examples: ['気分（きぶん）', '天気（てんき）']),
    '休': KanjiInfo(readings: ['キュウ', 'やす（む）'], examples: ['休む（やすむ）', '休日（きゅうじつ）']),
    '玉': KanjiInfo(readings: ['ギョク', 'たま'], examples: ['玉入れ（たまいれ）', '玉ねぎ（たまねぎ）']),
    '空': KanjiInfo(readings: ['クウ', 'そら', 'あ（く）', 'から'], examples: ['空色（そらいろ）', '空手（からて）']),
    '犬': KanjiInfo(readings: ['ケン', 'いぬ'], examples: ['子犬（こいぬ）', '番犬（ばんけん）']),
    '見': KanjiInfo(readings: ['ケン', 'み（る）'], examples: ['見る（みる）', '意見（いけん）']),
    '口': KanjiInfo(readings: ['コウ', 'ク', 'くち'], examples: ['入り口（いりぐち）', '口調（くちょう）']),
    '校': KanjiInfo(readings: ['コウ'], examples: ['学校（がっこう）', '校庭（こうてい）']),
    '左': KanjiInfo(readings: ['サ', 'ひだり'], examples: ['左手（ひだりて）', '左右（さゆう）']),
    '山': KanjiInfo(readings: ['サン', 'やま'], examples: ['山登り（やまのぼり）', '火山（かざん）']),
    '糸': KanjiInfo(readings: ['シ', 'いと'], examples: ['毛糸（けいと）', '糸口（いとぐち）']),
    '字': KanjiInfo(readings: ['ジ'], examples: ['文字（もじ）', '字体（じたい）']),
    '耳': KanjiInfo(readings: ['ジ', 'みみ'], examples: ['耳たぶ（みみたぶ）', '耳鼻科（じびか）']),
    '車': KanjiInfo(readings: ['シャ', 'くるま'], examples: ['車いす（くるまいす）', '電車（でんしゃ）']),
    '手': KanjiInfo(readings: ['シュ', 'て'], examples: ['手紙（てがみ）', '選手（せんしゅ）']),
    '出': KanjiInfo(readings: ['シュツ', 'で（る）', 'だ（す）'], examples: ['出口（でぐち）', '出発（しゅっぱつ）']),
    '小': KanjiInfo(readings: ['ショウ', 'ちい（さい）', 'こ', 'お'], examples: ['小さい（ちいさい）', '小学校（しょうがっこう）']),
    '上': KanjiInfo(readings: ['ジョウ', 'うえ', 'あ（げる）', 'のぼ（る）'], examples: ['机の上（つくえのうえ）', '上手（じょうず）']),
    '森': KanjiInfo(readings: ['シン', 'もり'], examples: ['森の中（もりのなか）', '森林（しんりん）']),
    '正': KanjiInfo(readings: ['セイ', 'ショウ', 'ただ（しい）', 'まさ'], examples: ['正しい（ただしい）', '正月（しょうがつ）']),
    '生': KanjiInfo(readings: ['セイ', 'ショウ', 'い（きる）', 'う（まれる）', 'なま'], examples: ['生きる（いきる）', '先生（せんせい）']),
    '青': KanjiInfo(readings: ['セイ', 'あお（い）'], examples: ['青空（あおぞら）', '青年（せいねん）']),
    '夕': KanjiInfo(readings: ['セキ', 'ゆう'], examples: ['夕方（ゆうがた）', '七夕（たなばた）']),
    '石': KanjiInfo(readings: ['セキ', 'シャク', 'いし'], examples: ['小石（こいし）', '石油（せきゆ）']),
    '赤': KanjiInfo(readings: ['セキ', 'あか（い）'], examples: ['赤色（あかいろ）', '赤道（せきどう）']),
    '千': KanjiInfo(readings: ['セン', 'ち'], examples: ['千円（せんえん）', '千歳（ちとせ）']),
    '川': KanjiInfo(readings: ['セン', 'かわ'], examples: ['小川（おがわ）', '河川（かせん）']),
    '先': KanjiInfo(readings: ['セン', 'さき'], examples: ['先に（さきに）', '先生（せんせい）']),
    '早': KanjiInfo(readings: ['ソウ', 'はや（い）'], examples: ['早い（はやい）', '早朝（そうちょう）']),
    '草': KanjiInfo(readings: ['ソウ', 'くさ'], examples: ['草花（くさばな）', '草原（そうげん）']),
    '足': KanjiInfo(readings: ['ソク', 'あし', 'た（りる）'], examples: ['足音（あしおと）', '満足（まんぞく）']),
    '村': KanjiInfo(readings: ['ソン', 'むら'], examples: ['村人（むらびと）', '農村（のうそん）']),
    '大': KanjiInfo(readings: ['ダイ', 'タイ', 'おお（きい）'], examples: ['大きい（おおきい）', '大切（たいせつ）']),
    '竹': KanjiInfo(readings: ['チク', 'たけ'], examples: ['竹の子（たけのこ）', '竹林（ちくりん）']),
    '中': KanjiInfo(readings: ['チュウ', 'なか'], examples: ['中身（なかみ）', '中学校（ちゅうがっこう）']),
    '虫': KanjiInfo(readings: ['チュウ', 'むし'], examples: ['虫かご（むしかご）', '昆虫（こんちゅう）']),
    '町': KanjiInfo(readings: ['チョウ', 'まち'], examples: ['町のお祭り（まちのおまつり）', '町長（ちょうちょう）']),
    '天': KanjiInfo(readings: ['テン'], examples: ['天気（てんき）', '天国（てんごく）']),
    '田': KanjiInfo(readings: ['デン', 'た'], examples: ['田んぼ（たんぼ）', '田畑（たはた）']),
    '入': KanjiInfo(readings: ['ニュウ', 'はい（る）', 'い（れる）'], examples: ['入る（はいる）', '入学（にゅうがく）']),
    '白': KanjiInfo(readings: ['ハク', 'ビャク', 'しろ（い）'], examples: ['白色（しろいろ）', '白鳥（はくちょう）']),
    '百': KanjiInfo(readings: ['ヒャク'], examples: ['百円（ひゃくえん）', '百人（ひゃくにん）']),
    '文': KanjiInfo(readings: ['ブン', 'モン'], examples: ['文章（ぶんしょう）', '文字（もじ）']),
    '本': KanjiInfo(readings: ['ホン', 'もと'], examples: ['絵本（えほん）', '本当（ほんとう）']),
    '名': KanjiInfo(readings: ['メイ', 'ミョウ', 'な'], examples: ['名前（なまえ）', '有名（ゆうめい）']),
    '目': KanjiInfo(readings: ['モク', 'め'], examples: ['目薬（めぐすり）', '目的（もくてき）']),
    '立': KanjiInfo(readings: ['リツ', 'た（つ）'], examples: ['立つ（たつ）', '独立（どくりつ）']),
    '力': KanjiInfo(readings: ['リョク', 'リキ', 'ちから'], examples: ['力持ち（ちからもち）', '努力（どりょく）']),
    '林': KanjiInfo(readings: ['リン', 'はやし'], examples: ['林の中（はやしのなか）', '森林（しんりん）']),
    '高': KanjiInfo(readings: ['コウ', 'たか（い）'], examples: ['高い（たかい）', '高校（こうこう）']),
    '食': KanjiInfo(readings: ['ショク', 'た（べる）', 'く（う）'], examples: ['食事（しょくじ）', '食べる（たべる）']),
    '漢': KanjiInfo(readings: ['カン'], examples: ['漢字（かんじ）', '漢方（かんぽう）']),
    '検': KanjiInfo(readings: ['ケン'], examples: ['検査（けんさ）', '検定（けんてい）']),
    '定': KanjiInfo(readings: ['テイ', 'ジョウ', 'さだ（める）'], examples: ['定義（ていぎ）', '予定（よてい）']),
  };

  static KanjiInfo? get(String kanji) => _data[kanji];
}
