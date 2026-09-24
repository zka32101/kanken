#!/usr/bin/env node
/**
 * questions コレクション（漢字クイズ/デイリー練習用の問題データ）への投入スクリプト
 *
 * lib/data/seed_firestore.dart に用意されていた読み仮名・用例つきの
 * サンプルデータ(KanjiQuestionSeed)を、実際にアプリが参照する
 * questions コレクションへ投入する。KanjiQuestion.fromJson()
 * (lib/models/kanji_question.dart) が期待するフィールド構造に合わせてある。
 *
 * 事前準備:
 *   1. cd scripts && npm install
 *   2. Firebase Console > プロジェクトの設定 > サービスアカウント から
 *      秘密鍵(JSON)を新規生成してダウンロードする
 *
 * 使い方（scripts/ ディレクトリで実行）:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json node seed-kanji-questions.js
 *
 * 注意:
 *   現時点のデータ量は LEVEL_10:29問, LEVEL_9:8問, LEVEL_8/7/6:各1問,
 *   LEVEL_5:2問と級によって偏りがある(元データ lib/data/seed_firestore.dart
 *   の時点でこの分しか用意されていなかったため)。実運用では各級80〜120問
 *   程度への拡充が必要。
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
      "二",
      "十",
      "人"
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
      "一",
      "二",
      "三",
      "四"
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
      "二",
      "三",
      "四",
      "五"
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
      "三",
      "四",
      "五",
      "六"
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
      "四",
      "五",
      "六",
      "七"
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
      "五",
      "六",
      "七",
      "八"
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
      "六",
      "七",
      "八",
      "九"
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
      "七",
      "八",
      "九",
      "十"
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
      "八",
      "九",
      "十",
      "百"
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
      "九",
      "十",
      "百",
      "千"
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
      "入",
      "八",
      "二"
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
      "水",
      "木",
      "土"
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
      "火",
      "水",
      "木",
      "土"
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
      "火",
      "水",
      "木",
      "土"
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
      "火",
      "水",
      "木",
      "土"
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
      "木",
      "金",
      "土",
      "日"
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
      "月",
      "日",
      "年",
      "時"
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
      "月",
      "日",
      "年",
      "水"
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
      "月",
      "年",
      "日",
      "時"
    ],
    "correctAnswer": "年",
    "reading": "とし",
    "example": "来年（らいねん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-時",
    "level": "LEVEL_10",
    "kanji": "時",
    "questionType": "multipleChoice",
    "choices": [
      "年",
      "時",
      "間",
      "分"
    ],
    "correctAnswer": "時",
    "reading": "とき",
    "example": "時間（じかん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-父",
    "level": "LEVEL_10",
    "kanji": "父",
    "questionType": "multipleChoice",
    "choices": [
      "父",
      "母",
      "兄",
      "弟"
    ],
    "correctAnswer": "父",
    "reading": "ちち",
    "example": "父親（ちちおや）",
    "version": 1
  },
  {
    "id": "LEVEL_10-母",
    "level": "LEVEL_10",
    "kanji": "母",
    "questionType": "multipleChoice",
    "choices": [
      "父",
      "母",
      "姉",
      "妹"
    ],
    "correctAnswer": "母",
    "reading": "はは",
    "example": "母親（ははおや）",
    "version": 1
  },
  {
    "id": "LEVEL_10-兄",
    "level": "LEVEL_10",
    "kanji": "兄",
    "questionType": "multipleChoice",
    "choices": [
      "兄",
      "弟",
      "姉",
      "妹"
    ],
    "correctAnswer": "兄",
    "reading": "あに",
    "example": "兄さん（あにさん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-弟",
    "level": "LEVEL_10",
    "kanji": "弟",
    "questionType": "multipleChoice",
    "choices": [
      "兄",
      "弟",
      "姉",
      "妹"
    ],
    "correctAnswer": "弟",
    "reading": "おとうと",
    "example": "弟さん（おとうとさん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-姉",
    "level": "LEVEL_10",
    "kanji": "姉",
    "questionType": "multipleChoice",
    "choices": [
      "兄",
      "弟",
      "姉",
      "妹"
    ],
    "correctAnswer": "姉",
    "reading": "あね",
    "example": "姉さん（あねさん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-妹",
    "level": "LEVEL_10",
    "kanji": "妹",
    "questionType": "multipleChoice",
    "choices": [
      "兄",
      "弟",
      "姉",
      "妹"
    ],
    "correctAnswer": "妹",
    "reading": "いもうと",
    "example": "妹さん（いもうとさん）",
    "version": 1
  },
  {
    "id": "LEVEL_10-子",
    "level": "LEVEL_10",
    "kanji": "子",
    "questionType": "multipleChoice",
    "choices": [
      "子",
      "女",
      "男",
      "人"
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
      "子",
      "女",
      "男",
      "人"
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
      "子",
      "女",
      "男",
      "人"
    ],
    "correctAnswer": "男",
    "reading": "おとこ",
    "example": "男性（だんせい）",
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
    "reading": "おおきい",
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
    "reading": "ちいさい",
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
    "reading": "たかい",
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
    "reading": "たべもの",
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
  const batch = db.batch();
  const collection = db.collection('questions');

  for (const q of questions) {
    const ref = collection.doc(q.id);
    batch.set(ref, q);
  }

  await batch.commit();
  console.log(`✅ ${questions.length}件の問題を questions コレクションに投入しました。`);
}

main().catch((err) => {
  console.error('❌ 投入に失敗しました:', err);
  process.exit(1);
});
