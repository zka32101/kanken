#!/usr/bin/env node
/**
 * questions コレクション（漢字クイズ/デイリー練習用の問題データ）への投入スクリプト
 *
 * LEVEL_10(小学1年配当漢字 80字)は文部科学省学習指導要領の配当漢字表に
 * 準拠して全字を網羅。LEVEL_9以下は lib/data/seed_firestore.dart に
 * 用意されていたサンプルデータを流用しており、まだ一部の字しか無い
 * (LEVEL_9:8問, LEVEL_8/7/6:各1問, LEVEL_5:2問)。今後級ごとに拡充が必要。
 *
 * KanjiQuestion.fromJson()(lib/models/kanji_question.dart) が期待する
 * フィールド構造に合わせてある。readingは送り仮名がある語を
 * 「ただ（しい）」のように括弧表記する(同ファイルのdocコメント参照)。
 *
 * 事前準備:
 *   1. cd scripts && npm install
 *   2. Firebase Console > プロジェクトの設定 > サービスアカウント から
 *      秘密鍵(JSON)を新規生成してダウンロードする
 *
 * 使い方（scripts/ ディレクトリで実行）:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json node seed-kanji-questions.js
 */

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('エラー: 環境変数 GOOGLE_APPLICATION_CREDENTIALS が設定されていません。');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

const questions = [
  {
    "id": "LEVEL_10-一",
    "level": "LEVEL_10",
    "kanji": "一",
    "questionType": "multipleChoice",
    "choices": [
      "一",
      "見",
      "金",
      "五"
    ],
    "correctAnswer": "一",
    "reading": "いち",
    "example": "一番目（いちばんめ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-二",
    "level": "LEVEL_10",
    "kanji": "二",
    "questionType": "multipleChoice",
    "choices": [
      "入",
      "水",
      "土",
      "二"
    ],
    "correctAnswer": "二",
    "reading": "に",
    "example": "二人（ふたり）",
    "version": 1
  },
  {
    "id": "LEVEL_10-三",
    "level": "LEVEL_10",
    "kanji": "三",
    "questionType": "multipleChoice",
    "choices": [
      "花",
      "三",
      "学",
      "水"
    ],
    "correctAnswer": "三",
    "reading": "さん",
    "example": "三月（さんがつ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-四",
    "level": "LEVEL_10",
    "kanji": "四",
    "questionType": "multipleChoice",
    "choices": [
      "入",
      "石",
      "貝",
      "四"
    ],
    "correctAnswer": "四",
    "reading": "し",
    "example": "四月（しがつ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-五",
    "level": "LEVEL_10",
    "kanji": "五",
    "questionType": "multipleChoice",
    "choices": [
      "五",
      "一",
      "男",
      "赤"
    ],
    "correctAnswer": "五",
    "reading": "ご",
    "example": "五月（ごがつ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-六",
    "level": "LEVEL_10",
    "kanji": "六",
    "questionType": "multipleChoice",
    "choices": [
      "土",
      "六",
      "車",
      "花"
    ],
    "correctAnswer": "六",
    "reading": "ろく",
    "example": "六月（ろくがつ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-七",
    "level": "LEVEL_10",
    "kanji": "七",
    "questionType": "multipleChoice",
    "choices": [
      "七",
      "手",
      "出",
      "力"
    ],
    "correctAnswer": "七",
    "reading": "しち",
    "example": "七月（しちがつ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-八",
    "level": "LEVEL_10",
    "kanji": "八",
    "questionType": "multipleChoice",
    "choices": [
      "八",
      "日",
      "森",
      "田"
    ],
    "correctAnswer": "八",
    "reading": "はち",
    "example": "八月（はちがつ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-九",
    "level": "LEVEL_10",
    "kanji": "九",
    "questionType": "multipleChoice",
    "choices": [
      "本",
      "王",
      "九",
      "小"
    ],
    "correctAnswer": "九",
    "reading": "きゅう",
    "example": "九月（くがつ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-十",
    "level": "LEVEL_10",
    "kanji": "十",
    "questionType": "multipleChoice",
    "choices": [
      "十",
      "学",
      "火",
      "校"
    ],
    "correctAnswer": "十",
    "reading": "じゅう",
    "example": "十月（じゅうがつ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-人",
    "level": "LEVEL_10",
    "kanji": "人",
    "questionType": "multipleChoice",
    "choices": [
      "人",
      "早",
      "小",
      "男"
    ],
    "correctAnswer": "人",
    "reading": "ひと",
    "example": "人間（にんげん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-火",
    "level": "LEVEL_10",
    "kanji": "火",
    "questionType": "multipleChoice",
    "choices": [
      "火",
      "犬",
      "力",
      "十"
    ],
    "correctAnswer": "火",
    "reading": "ひ",
    "example": "火曜日（かようび）",
    "version": 1
  },
  {
    "id": "LEVEL_10-水",
    "level": "LEVEL_10",
    "kanji": "水",
    "questionType": "multipleChoice",
    "choices": [
      "草",
      "男",
      "水",
      "森"
    ],
    "correctAnswer": "水",
    "reading": "みず",
    "example": "水曜日（すいようび）",
    "version": 1
  },
  {
    "id": "LEVEL_10-木",
    "level": "LEVEL_10",
    "kanji": "木",
    "questionType": "multipleChoice",
    "choices": [
      "木",
      "学",
      "八",
      "字"
    ],
    "correctAnswer": "木",
    "reading": "き",
    "example": "木曜日（もくようび）",
    "version": 1
  },
  {
    "id": "LEVEL_10-土",
    "level": "LEVEL_10",
    "kanji": "土",
    "questionType": "multipleChoice",
    "choices": [
      "土",
      "九",
      "犬",
      "花"
    ],
    "correctAnswer": "土",
    "reading": "つち",
    "example": "土曜日（どようび）",
    "version": 1
  },
  {
    "id": "LEVEL_10-金",
    "level": "LEVEL_10",
    "kanji": "金",
    "questionType": "multipleChoice",
    "choices": [
      "早",
      "金",
      "生",
      "子"
    ],
    "correctAnswer": "金",
    "reading": "かね",
    "example": "金曜日（きんようび）",
    "version": 1
  },
  {
    "id": "LEVEL_10-日",
    "level": "LEVEL_10",
    "kanji": "日",
    "questionType": "multipleChoice",
    "choices": [
      "百",
      "田",
      "空",
      "日"
    ],
    "correctAnswer": "日",
    "reading": "ひ",
    "example": "日曜日（にちようび）",
    "version": 1
  },
  {
    "id": "LEVEL_10-月",
    "level": "LEVEL_10",
    "kanji": "月",
    "questionType": "multipleChoice",
    "choices": [
      "貝",
      "年",
      "小",
      "月"
    ],
    "correctAnswer": "月",
    "reading": "つき",
    "example": "月曜日（げつようび）",
    "version": 1
  },
  {
    "id": "LEVEL_10-年",
    "level": "LEVEL_10",
    "kanji": "年",
    "questionType": "multipleChoice",
    "choices": [
      "女",
      "土",
      "男",
      "年"
    ],
    "correctAnswer": "年",
    "reading": "とし",
    "example": "来年（らいねん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-子",
    "level": "LEVEL_10",
    "kanji": "子",
    "questionType": "multipleChoice",
    "choices": [
      "正",
      "森",
      "立",
      "子"
    ],
    "correctAnswer": "子",
    "reading": "こ",
    "example": "子供（こども）",
    "version": 1
  },
  {
    "id": "LEVEL_10-女",
    "level": "LEVEL_10",
    "kanji": "女",
    "questionType": "multipleChoice",
    "choices": [
      "白",
      "二",
      "女",
      "土"
    ],
    "correctAnswer": "女",
    "reading": "おんな",
    "example": "女性（じょせい）",
    "version": 1
  },
  {
    "id": "LEVEL_10-男",
    "level": "LEVEL_10",
    "kanji": "男",
    "questionType": "multipleChoice",
    "choices": [
      "千",
      "土",
      "男",
      "校"
    ],
    "correctAnswer": "男",
    "reading": "おとこ",
    "example": "男性（だんせい）",
    "version": 1
  },
  {
    "id": "LEVEL_10-右",
    "level": "LEVEL_10",
    "kanji": "右",
    "questionType": "multipleChoice",
    "choices": [
      "右",
      "中",
      "雨",
      "空"
    ],
    "correctAnswer": "右",
    "reading": "みぎ",
    "example": "右手（みぎて）",
    "version": 1
  },
  {
    "id": "LEVEL_10-雨",
    "level": "LEVEL_10",
    "kanji": "雨",
    "questionType": "multipleChoice",
    "choices": [
      "音",
      "中",
      "雨",
      "力"
    ],
    "correctAnswer": "雨",
    "reading": "あめ",
    "example": "雨降り（あめふり）",
    "version": 1
  },
  {
    "id": "LEVEL_10-円",
    "level": "LEVEL_10",
    "kanji": "円",
    "questionType": "multipleChoice",
    "choices": [
      "円",
      "入",
      "天",
      "一"
    ],
    "correctAnswer": "円",
    "reading": "えん",
    "example": "百円（ひゃくえん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-王",
    "level": "LEVEL_10",
    "kanji": "王",
    "questionType": "multipleChoice",
    "choices": [
      "王",
      "山",
      "土",
      "小"
    ],
    "correctAnswer": "王",
    "reading": "おう",
    "example": "王様（おうさま）",
    "version": 1
  },
  {
    "id": "LEVEL_10-音",
    "level": "LEVEL_10",
    "kanji": "音",
    "questionType": "multipleChoice",
    "choices": [
      "人",
      "音",
      "大",
      "文"
    ],
    "correctAnswer": "音",
    "reading": "おと",
    "example": "足音（あしおと）",
    "version": 1
  },
  {
    "id": "LEVEL_10-下",
    "level": "LEVEL_10",
    "kanji": "下",
    "questionType": "multipleChoice",
    "choices": [
      "日",
      "白",
      "下",
      "足"
    ],
    "correctAnswer": "下",
    "reading": "した",
    "example": "下着（したぎ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-花",
    "level": "LEVEL_10",
    "kanji": "花",
    "questionType": "multipleChoice",
    "choices": [
      "下",
      "花",
      "入",
      "王"
    ],
    "correctAnswer": "花",
    "reading": "はな",
    "example": "花見（はなみ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-貝",
    "level": "LEVEL_10",
    "kanji": "貝",
    "questionType": "multipleChoice",
    "choices": [
      "町",
      "先",
      "貝",
      "川"
    ],
    "correctAnswer": "貝",
    "reading": "かい",
    "example": "貝殻（かいがら）",
    "version": 1
  },
  {
    "id": "LEVEL_10-学",
    "level": "LEVEL_10",
    "kanji": "学",
    "questionType": "multipleChoice",
    "choices": [
      "学",
      "九",
      "三",
      "車"
    ],
    "correctAnswer": "学",
    "reading": "がく",
    "example": "学校（がっこう）",
    "version": 1
  },
  {
    "id": "LEVEL_10-気",
    "level": "LEVEL_10",
    "kanji": "気",
    "questionType": "multipleChoice",
    "choices": [
      "気",
      "八",
      "一",
      "十"
    ],
    "correctAnswer": "気",
    "reading": "き",
    "example": "気分（きぶん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-休",
    "level": "LEVEL_10",
    "kanji": "休",
    "questionType": "multipleChoice",
    "choices": [
      "耳",
      "虫",
      "休",
      "十"
    ],
    "correctAnswer": "休",
    "reading": "やす（む）",
    "example": "休む（やすむ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-玉",
    "level": "LEVEL_10",
    "kanji": "玉",
    "questionType": "multipleChoice",
    "choices": [
      "日",
      "入",
      "下",
      "玉"
    ],
    "correctAnswer": "玉",
    "reading": "たま",
    "example": "玉入れ（たまいれ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-空",
    "level": "LEVEL_10",
    "kanji": "空",
    "questionType": "multipleChoice",
    "choices": [
      "空",
      "円",
      "水",
      "夕"
    ],
    "correctAnswer": "空",
    "reading": "そら",
    "example": "空色（そらいろ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-犬",
    "level": "LEVEL_10",
    "kanji": "犬",
    "questionType": "multipleChoice",
    "choices": [
      "赤",
      "出",
      "夕",
      "犬"
    ],
    "correctAnswer": "犬",
    "reading": "いぬ",
    "example": "子犬（こいぬ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-見",
    "level": "LEVEL_10",
    "kanji": "見",
    "questionType": "multipleChoice",
    "choices": [
      "八",
      "見",
      "水",
      "青"
    ],
    "correctAnswer": "見",
    "reading": "み（る）",
    "example": "見る（みる）",
    "version": 1
  },
  {
    "id": "LEVEL_10-口",
    "level": "LEVEL_10",
    "kanji": "口",
    "questionType": "multipleChoice",
    "choices": [
      "先",
      "円",
      "口",
      "田"
    ],
    "correctAnswer": "口",
    "reading": "くち",
    "example": "入り口（いりぐち）",
    "version": 1
  },
  {
    "id": "LEVEL_10-校",
    "level": "LEVEL_10",
    "kanji": "校",
    "questionType": "multipleChoice",
    "choices": [
      "気",
      "校",
      "草",
      "犬"
    ],
    "correctAnswer": "校",
    "reading": "こう",
    "example": "学校（がっこう）",
    "version": 1
  },
  {
    "id": "LEVEL_10-左",
    "level": "LEVEL_10",
    "kanji": "左",
    "questionType": "multipleChoice",
    "choices": [
      "入",
      "二",
      "左",
      "七"
    ],
    "correctAnswer": "左",
    "reading": "ひだり",
    "example": "左手（ひだりて）",
    "version": 1
  },
  {
    "id": "LEVEL_10-山",
    "level": "LEVEL_10",
    "kanji": "山",
    "questionType": "multipleChoice",
    "choices": [
      "村",
      "夕",
      "山",
      "大"
    ],
    "correctAnswer": "山",
    "reading": "やま",
    "example": "山登り（やまのぼり）",
    "version": 1
  },
  {
    "id": "LEVEL_10-糸",
    "level": "LEVEL_10",
    "kanji": "糸",
    "questionType": "multipleChoice",
    "choices": [
      "男",
      "一",
      "森",
      "糸"
    ],
    "correctAnswer": "糸",
    "reading": "いと",
    "example": "毛糸（けいと）",
    "version": 1
  },
  {
    "id": "LEVEL_10-字",
    "level": "LEVEL_10",
    "kanji": "字",
    "questionType": "multipleChoice",
    "choices": [
      "赤",
      "百",
      "見",
      "字"
    ],
    "correctAnswer": "字",
    "reading": "じ",
    "example": "文字（もじ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-耳",
    "level": "LEVEL_10",
    "kanji": "耳",
    "questionType": "multipleChoice",
    "choices": [
      "耳",
      "下",
      "八",
      "口"
    ],
    "correctAnswer": "耳",
    "reading": "みみ",
    "example": "耳たぶ（みみたぶ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-車",
    "level": "LEVEL_10",
    "kanji": "車",
    "questionType": "multipleChoice",
    "choices": [
      "七",
      "八",
      "名",
      "車"
    ],
    "correctAnswer": "車",
    "reading": "くるま",
    "example": "車いす（くるまいす）",
    "version": 1
  },
  {
    "id": "LEVEL_10-手",
    "level": "LEVEL_10",
    "kanji": "手",
    "questionType": "multipleChoice",
    "choices": [
      "手",
      "人",
      "八",
      "虫"
    ],
    "correctAnswer": "手",
    "reading": "て",
    "example": "手紙（てがみ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-出",
    "level": "LEVEL_10",
    "kanji": "出",
    "questionType": "multipleChoice",
    "choices": [
      "出",
      "学",
      "金",
      "青"
    ],
    "correctAnswer": "出",
    "reading": "で（る）",
    "example": "出口（でぐち）",
    "version": 1
  },
  {
    "id": "LEVEL_10-小",
    "level": "LEVEL_10",
    "kanji": "小",
    "questionType": "multipleChoice",
    "choices": [
      "小",
      "人",
      "石",
      "名"
    ],
    "correctAnswer": "小",
    "reading": "ちい（さい）",
    "example": "小さい（ちいさい）",
    "version": 1
  },
  {
    "id": "LEVEL_10-上",
    "level": "LEVEL_10",
    "kanji": "上",
    "questionType": "multipleChoice",
    "choices": [
      "玉",
      "学",
      "山",
      "上"
    ],
    "correctAnswer": "上",
    "reading": "うえ",
    "example": "机の上（つくえのうえ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-森",
    "level": "LEVEL_10",
    "kanji": "森",
    "questionType": "multipleChoice",
    "choices": [
      "十",
      "森",
      "山",
      "早"
    ],
    "correctAnswer": "森",
    "reading": "もり",
    "example": "森の中（もりのなか）",
    "version": 1
  },
  {
    "id": "LEVEL_10-正",
    "level": "LEVEL_10",
    "kanji": "正",
    "questionType": "multipleChoice",
    "choices": [
      "正",
      "田",
      "十",
      "下"
    ],
    "correctAnswer": "正",
    "reading": "ただ（しい）",
    "example": "正しい（ただしい）",
    "version": 1
  },
  {
    "id": "LEVEL_10-生",
    "level": "LEVEL_10",
    "kanji": "生",
    "questionType": "multipleChoice",
    "choices": [
      "生",
      "気",
      "九",
      "小"
    ],
    "correctAnswer": "生",
    "reading": "い（きる）",
    "example": "生きる（いきる）",
    "version": 1
  },
  {
    "id": "LEVEL_10-青",
    "level": "LEVEL_10",
    "kanji": "青",
    "questionType": "multipleChoice",
    "choices": [
      "青",
      "校",
      "林",
      "入"
    ],
    "correctAnswer": "青",
    "reading": "あお",
    "example": "青空（あおぞら）",
    "version": 1
  },
  {
    "id": "LEVEL_10-夕",
    "level": "LEVEL_10",
    "kanji": "夕",
    "questionType": "multipleChoice",
    "choices": [
      "月",
      "玉",
      "夕",
      "木"
    ],
    "correctAnswer": "夕",
    "reading": "ゆう",
    "example": "夕方（ゆうがた）",
    "version": 1
  },
  {
    "id": "LEVEL_10-石",
    "level": "LEVEL_10",
    "kanji": "石",
    "questionType": "multipleChoice",
    "choices": [
      "空",
      "石",
      "力",
      "見"
    ],
    "correctAnswer": "石",
    "reading": "いし",
    "example": "小石（こいし）",
    "version": 1
  },
  {
    "id": "LEVEL_10-赤",
    "level": "LEVEL_10",
    "kanji": "赤",
    "questionType": "multipleChoice",
    "choices": [
      "中",
      "音",
      "玉",
      "赤"
    ],
    "correctAnswer": "赤",
    "reading": "あか",
    "example": "赤色（あかいろ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-千",
    "level": "LEVEL_10",
    "kanji": "千",
    "questionType": "multipleChoice",
    "choices": [
      "犬",
      "石",
      "千",
      "火"
    ],
    "correctAnswer": "千",
    "reading": "せん",
    "example": "千円（せんえん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-川",
    "level": "LEVEL_10",
    "kanji": "川",
    "questionType": "multipleChoice",
    "choices": [
      "日",
      "玉",
      "女",
      "川"
    ],
    "correctAnswer": "川",
    "reading": "かわ",
    "example": "小川（おがわ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-先",
    "level": "LEVEL_10",
    "kanji": "先",
    "questionType": "multipleChoice",
    "choices": [
      "二",
      "先",
      "土",
      "百"
    ],
    "correctAnswer": "先",
    "reading": "さき",
    "example": "先に（さきに）",
    "version": 1
  },
  {
    "id": "LEVEL_10-早",
    "level": "LEVEL_10",
    "kanji": "早",
    "questionType": "multipleChoice",
    "choices": [
      "小",
      "入",
      "早",
      "五"
    ],
    "correctAnswer": "早",
    "reading": "はや（い）",
    "example": "早い（はやい）",
    "version": 1
  },
  {
    "id": "LEVEL_10-草",
    "level": "LEVEL_10",
    "kanji": "草",
    "questionType": "multipleChoice",
    "choices": [
      "出",
      "草",
      "左",
      "六"
    ],
    "correctAnswer": "草",
    "reading": "くさ",
    "example": "草花（くさばな）",
    "version": 1
  },
  {
    "id": "LEVEL_10-足",
    "level": "LEVEL_10",
    "kanji": "足",
    "questionType": "multipleChoice",
    "choices": [
      "木",
      "気",
      "手",
      "足"
    ],
    "correctAnswer": "足",
    "reading": "あし",
    "example": "足音（あしおと）",
    "version": 1
  },
  {
    "id": "LEVEL_10-村",
    "level": "LEVEL_10",
    "kanji": "村",
    "questionType": "multipleChoice",
    "choices": [
      "女",
      "右",
      "学",
      "村"
    ],
    "correctAnswer": "村",
    "reading": "むら",
    "example": "村人（むらびと）",
    "version": 1
  },
  {
    "id": "LEVEL_10-大",
    "level": "LEVEL_10",
    "kanji": "大",
    "questionType": "multipleChoice",
    "choices": [
      "青",
      "大",
      "字",
      "気"
    ],
    "correctAnswer": "大",
    "reading": "おお（きい）",
    "example": "大きい（おおきい）",
    "version": 1
  },
  {
    "id": "LEVEL_10-竹",
    "level": "LEVEL_10",
    "kanji": "竹",
    "questionType": "multipleChoice",
    "choices": [
      "草",
      "竹",
      "上",
      "五"
    ],
    "correctAnswer": "竹",
    "reading": "たけ",
    "example": "竹の子（たけのこ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-中",
    "level": "LEVEL_10",
    "kanji": "中",
    "questionType": "multipleChoice",
    "choices": [
      "中",
      "貝",
      "車",
      "左"
    ],
    "correctAnswer": "中",
    "reading": "なか",
    "example": "中身（なかみ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-虫",
    "level": "LEVEL_10",
    "kanji": "虫",
    "questionType": "multipleChoice",
    "choices": [
      "虫",
      "犬",
      "字",
      "生"
    ],
    "correctAnswer": "虫",
    "reading": "むし",
    "example": "虫かご（むしかご）",
    "version": 1
  },
  {
    "id": "LEVEL_10-町",
    "level": "LEVEL_10",
    "kanji": "町",
    "questionType": "multipleChoice",
    "choices": [
      "生",
      "町",
      "中",
      "田"
    ],
    "correctAnswer": "町",
    "reading": "まち",
    "example": "町のお祭り（まちのおまつり）",
    "version": 1
  },
  {
    "id": "LEVEL_10-天",
    "level": "LEVEL_10",
    "kanji": "天",
    "questionType": "multipleChoice",
    "choices": [
      "右",
      "天",
      "玉",
      "名"
    ],
    "correctAnswer": "天",
    "reading": "てん",
    "example": "天気（てんき）",
    "version": 1
  },
  {
    "id": "LEVEL_10-田",
    "level": "LEVEL_10",
    "kanji": "田",
    "questionType": "multipleChoice",
    "choices": [
      "田",
      "立",
      "赤",
      "車"
    ],
    "correctAnswer": "田",
    "reading": "た",
    "example": "田んぼ（たんぼ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-入",
    "level": "LEVEL_10",
    "kanji": "入",
    "questionType": "multipleChoice",
    "choices": [
      "入",
      "本",
      "森",
      "円"
    ],
    "correctAnswer": "入",
    "reading": "はい（る）",
    "example": "入る（はいる）",
    "version": 1
  },
  {
    "id": "LEVEL_10-白",
    "level": "LEVEL_10",
    "kanji": "白",
    "questionType": "multipleChoice",
    "choices": [
      "一",
      "天",
      "白",
      "虫"
    ],
    "correctAnswer": "白",
    "reading": "しろ",
    "example": "白色（しろいろ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-百",
    "level": "LEVEL_10",
    "kanji": "百",
    "questionType": "multipleChoice",
    "choices": [
      "百",
      "字",
      "山",
      "九"
    ],
    "correctAnswer": "百",
    "reading": "ひゃく",
    "example": "百円（ひゃくえん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-文",
    "level": "LEVEL_10",
    "kanji": "文",
    "questionType": "multipleChoice",
    "choices": [
      "竹",
      "文",
      "左",
      "青"
    ],
    "correctAnswer": "文",
    "reading": "ぶん",
    "example": "文章（ぶんしょう）",
    "version": 1
  },
  {
    "id": "LEVEL_10-本",
    "level": "LEVEL_10",
    "kanji": "本",
    "questionType": "multipleChoice",
    "choices": [
      "入",
      "日",
      "円",
      "本"
    ],
    "correctAnswer": "本",
    "reading": "ほん",
    "example": "絵本（えほん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-名",
    "level": "LEVEL_10",
    "kanji": "名",
    "questionType": "multipleChoice",
    "choices": [
      "名",
      "右",
      "林",
      "百"
    ],
    "correctAnswer": "名",
    "reading": "な",
    "example": "名前（なまえ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-目",
    "level": "LEVEL_10",
    "kanji": "目",
    "questionType": "multipleChoice",
    "choices": [
      "校",
      "見",
      "音",
      "目"
    ],
    "correctAnswer": "目",
    "reading": "め",
    "example": "目薬（めぐすり）",
    "version": 1
  },
  {
    "id": "LEVEL_10-立",
    "level": "LEVEL_10",
    "kanji": "立",
    "questionType": "multipleChoice",
    "choices": [
      "千",
      "早",
      "下",
      "立"
    ],
    "correctAnswer": "立",
    "reading": "た（つ）",
    "example": "立つ（たつ）",
    "version": 1
  },
  {
    "id": "LEVEL_10-力",
    "level": "LEVEL_10",
    "kanji": "力",
    "questionType": "multipleChoice",
    "choices": [
      "見",
      "力",
      "人",
      "中"
    ],
    "correctAnswer": "力",
    "reading": "ちから",
    "example": "力持ち（ちからもち）",
    "version": 1
  },
  {
    "id": "LEVEL_10-林",
    "level": "LEVEL_10",
    "kanji": "林",
    "questionType": "multipleChoice",
    "choices": [
      "林",
      "王",
      "左",
      "花"
    ],
    "correctAnswer": "林",
    "reading": "はやし",
    "example": "林の中（はやしのなか）",
    "version": 1
  },
  {
    "id": "LEVEL_9-学",
    "level": "LEVEL_9",
    "kanji": "学",
    "questionType": "multipleChoice",
    "choices": [
      "学",
      "教",
      "校",
      "先"
    ],
    "correctAnswer": "学",
    "reading": "がく",
    "example": "学校（がっこう）",
    "version": 1
  },
  {
    "id": "LEVEL_9-校",
    "level": "LEVEL_9",
    "kanji": "校",
    "questionType": "multipleChoice",
    "choices": [
      "学",
      "教",
      "校",
      "先"
    ],
    "correctAnswer": "校",
    "reading": "こう",
    "example": "学校（がっこう）",
    "version": 1
  },
  {
    "id": "LEVEL_9-先",
    "level": "LEVEL_9",
    "kanji": "先",
    "questionType": "multipleChoice",
    "choices": [
      "学",
      "教",
      "先",
      "生"
    ],
    "correctAnswer": "先",
    "reading": "さき",
    "example": "先生（せんせい）",
    "version": 1
  },
  {
    "id": "LEVEL_9-生",
    "level": "LEVEL_9",
    "kanji": "生",
    "questionType": "multipleChoice",
    "choices": [
      "学",
      "教",
      "先",
      "生"
    ],
    "correctAnswer": "生",
    "reading": "せい",
    "example": "先生（せんせい）",
    "version": 1
  },
  {
    "id": "LEVEL_9-大",
    "level": "LEVEL_9",
    "kanji": "大",
    "questionType": "multipleChoice",
    "choices": [
      "大",
      "小",
      "中",
      "高"
    ],
    "correctAnswer": "大",
    "reading": "おお（きい）",
    "example": "大きい（おおきい）",
    "version": 1
  },
  {
    "id": "LEVEL_9-小",
    "level": "LEVEL_9",
    "kanji": "小",
    "questionType": "multipleChoice",
    "choices": [
      "大",
      "小",
      "中",
      "高"
    ],
    "correctAnswer": "小",
    "reading": "ちい（さい）",
    "example": "小さい（ちいさい）",
    "version": 1
  },
  {
    "id": "LEVEL_9-中",
    "level": "LEVEL_9",
    "kanji": "中",
    "questionType": "multipleChoice",
    "choices": [
      "大",
      "小",
      "中",
      "高"
    ],
    "correctAnswer": "中",
    "reading": "なか",
    "example": "中学校（ちゅうがっこう）",
    "version": 1
  },
  {
    "id": "LEVEL_9-高",
    "level": "LEVEL_9",
    "kanji": "高",
    "questionType": "multipleChoice",
    "choices": [
      "大",
      "小",
      "中",
      "高"
    ],
    "correctAnswer": "高",
    "reading": "たか（い）",
    "example": "高い（たかい）",
    "version": 1
  },
  {
    "id": "LEVEL_8-食",
    "level": "LEVEL_8",
    "kanji": "食",
    "questionType": "multipleChoice",
    "choices": [
      "食",
      "飲",
      "水",
      "米"
    ],
    "correctAnswer": "食",
    "reading": "た（べる）",
    "example": "食事（しょくじ）",
    "version": 1
  },
  {
    "id": "LEVEL_7-漢",
    "level": "LEVEL_7",
    "kanji": "漢",
    "questionType": "multipleChoice",
    "choices": [
      "漢",
      "字",
      "検",
      "定"
    ],
    "correctAnswer": "漢",
    "reading": "かん",
    "example": "漢字（かんじ）",
    "version": 1
  },
  {
    "id": "LEVEL_6-字",
    "level": "LEVEL_6",
    "kanji": "字",
    "questionType": "multipleChoice",
    "choices": [
      "漢",
      "字",
      "検",
      "定"
    ],
    "correctAnswer": "字",
    "reading": "じ",
    "example": "文字（もじ）",
    "version": 1
  },
  {
    "id": "LEVEL_5-検",
    "level": "LEVEL_5",
    "kanji": "検",
    "questionType": "multipleChoice",
    "choices": [
      "漢",
      "字",
      "検",
      "定"
    ],
    "correctAnswer": "検",
    "reading": "けん",
    "example": "検査（けんさ）",
    "version": 1
  },
  {
    "id": "LEVEL_5-定",
    "level": "LEVEL_5",
    "kanji": "定",
    "questionType": "multipleChoice",
    "choices": [
      "漢",
      "字",
      "検",
      "定"
    ],
    "correctAnswer": "定",
    "reading": "てい",
    "example": "定義（ていぎ）",
    "version": 1
  }
];

async function main() {
  const collection = db.collection('questions');
  // Firestoreのbatchは1回500件までのため分割してコミットする
  const chunkSize = 400;
  for (let i = 0; i < questions.length; i += chunkSize) {
    const chunk = questions.slice(i, i + chunkSize);
    const batch = db.batch();
    for (const q of chunk) {
      batch.set(collection.doc(q.id), q);
    }
    await batch.commit();
    console.log(`✅ ${i + chunk.length}/${questions.length}件を投入しました。`);
  }
  console.log(`✅ 完了: 合計${questions.length}件を questions コレクションに投入しました。`);
}

main().catch((err) => {
  console.error('❌ 投入に失敗しました:', err);
  process.exit(1);
});
