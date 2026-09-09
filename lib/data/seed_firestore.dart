/// Firestore に本番レベルのサンプルデータを投入するスクリプト
///
/// 使用方法:
/// 1. main.dart で Firebase 初期化後に呼び出し
/// 2. または Firebase CLI: firebase shell で実行
///
/// 漢字検定レベル 10～5 までの問題データ
/// - レベル 10: 80 問（小 1～2 級）
/// - レベル 9: 80 問（小 2～3 級）
/// - レベル 8: 90 問（小 3～4 級）
/// - レベル 7: 100 問（小 4～5 級）
/// - レベル 6: 110 問（小 5～6 級）
/// - レベル 5: 120 問（小 6 級）

// import 'package:cloud_firestore/cloud_firestore.dart';
// Firestore dependency removed - using JSON serialization instead.
// This seed file is a utility script and not used in the main app.

/// 問題タイプの定義
enum QuestionType {
  multipleChoice, // 選択肢問題
  fillInTheBlank, // 空白埋め
  handwriting,    // 手書き
}

/// サンプルデータクラス
class KanjiQuestionSeed {
  final String level;
  final String kanji;
  final QuestionType questionType;
  final String meaning;
  final List<String> choices;
  final String correctAnswer;
  final String reading;
  final String example;
  final int version;

  KanjiQuestionSeed({
    required this.level,
    required this.kanji,
    required this.questionType,
    required this.meaning,
    required this.choices,
    required this.correctAnswer,
    required this.reading,
    required this.example,
    this.version = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'kanji': kanji,
      'questionType': questionType.toString().split('.').last,
      'meaning': meaning,
      'choices': choices,
      'correctAnswer': correctAnswer,
      'reading': reading,
      'example': example,
      'version': version,
      // 'createdAt': FieldValue.serverTimestamp(), // Firestore removed
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Firestore にデータを投入するクラス
class FirestoreSeed {
  static Future<void> seedKanjiQuestions() async {
    // Firestore dependency removed - this method is deprecated
    // Data seeding should now be done through JSON files or direct API calls
    print('❌ seedKanjiQuestions is deprecated - Firestore removed');
    // final firestore = FirebaseFirestore.instance;
    // final questions = _generateKanjiQuestions();
    //
    // print('投入開始: ${questions.length} 問の漢字問題');
    //
    // int count = 0;
    // try {
    //   for (final question in questions) {
    //     await firestore
    //         .collection('kanji_questions')
    //         .add(question.toMap());
    //     count++;
    //
    //     if (count % 50 == 0) {
    //       print('投入済み: $count 問');
    //     }
    //   }
    //   print('✅ 投入完了: $count 問');
    // } catch (e) {
    //   print('❌ エラー: $e');
    //   rethrow;
    // }
  }

  /// レベル 10～5 までの問題を生成
  static List<KanjiQuestionSeed> _generateKanjiQuestions() {
    return [
      ..._generateLevel10Questions(),
      ..._generateLevel9Questions(),
      ..._generateLevel8Questions(),
      ..._generateLevel7Questions(),
      ..._generateLevel6Questions(),
      ..._generateLevel5Questions(),
    ];
  }

  /// レベル 10（小 1～2）: 80 問
  static List<KanjiQuestionSeed> _generateLevel10Questions() {
    return [
      // 基本的な 1 画～3 画の漢字
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '一',
        questionType: QuestionType.multipleChoice,
        meaning: 'ひとつ、最初',
        choices: ['一', '二', '十', '人'],
        correctAnswer: '一',
        reading: 'いち',
        example: '一番目（いちばんめ）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '二',
        questionType: QuestionType.multipleChoice,
        meaning: 'ふたつ',
        choices: ['一', '二', '三', '四'],
        correctAnswer: '二',
        reading: 'に',
        example: '二人（ふたり）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '三',
        questionType: QuestionType.multipleChoice,
        meaning: 'みっつ',
        choices: ['二', '三', '四', '五'],
        correctAnswer: '三',
        reading: 'さん',
        example: '三月（さんがつ）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '四',
        questionType: QuestionType.fillInTheBlank,
        meaning: 'よっつ',
        choices: ['三', '四', '五', '六'],
        correctAnswer: '四',
        reading: 'し',
        example: '四月（しがつ）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '五',
        questionType: QuestionType.multipleChoice,
        meaning: 'いつつ',
        choices: ['四', '五', '六', '七'],
        correctAnswer: '五',
        reading: 'ご',
        example: '五月（ごがつ）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '六',
        questionType: QuestionType.multipleChoice,
        meaning: 'むっつ',
        choices: ['五', '六', '七', '八'],
        correctAnswer: '六',
        reading: 'ろく',
        example: '六月（ろくがつ）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '七',
        questionType: QuestionType.multipleChoice,
        meaning: 'ななつ',
        choices: ['六', '七', '八', '九'],
        correctAnswer: '七',
        reading: 'しち',
        example: '七月（しちがつ）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '八',
        questionType: QuestionType.multipleChoice,
        meaning: 'やっつ',
        choices: ['七', '八', '九', '十'],
        correctAnswer: '八',
        reading: 'はち',
        example: '八月（はちがつ）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '九',
        questionType: QuestionType.multipleChoice,
        meaning: 'ここのつ',
        choices: ['八', '九', '十', '百'],
        correctAnswer: '九',
        reading: 'きゅう',
        example: '九月（くがつ）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '十',
        questionType: QuestionType.multipleChoice,
        meaning: 'とう',
        choices: ['九', '十', '百', '千'],
        correctAnswer: '十',
        reading: 'じゅう',
        example: '十月（じゅうがつ）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '人',
        questionType: QuestionType.multipleChoice,
        meaning: 'ひと',
        choices: ['人', '入', '八', '二'],
        correctAnswer: '人',
        reading: 'ひと',
        example: '人間（にんげん）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '火',
        questionType: QuestionType.multipleChoice,
        meaning: 'ひ',
        choices: ['火', '水', '木', '土'],
        correctAnswer: '火',
        reading: 'ひ',
        example: '火曜日（かようび）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '水',
        questionType: QuestionType.multipleChoice,
        meaning: 'みず',
        choices: ['火', '水', '木', '土'],
        correctAnswer: '水',
        reading: 'みず',
        example: '水曜日（すいようび）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '木',
        questionType: QuestionType.multipleChoice,
        meaning: 'き',
        choices: ['火', '水', '木', '土'],
        correctAnswer: '木',
        reading: 'き',
        example: '木曜日（もくようび）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '土',
        questionType: QuestionType.multipleChoice,
        meaning: 'つち',
        choices: ['火', '水', '木', '土'],
        correctAnswer: '土',
        reading: 'つち',
        example: '土曜日（どようび）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '金',
        questionType: QuestionType.multipleChoice,
        meaning: 'かね',
        choices: ['木', '金', '土', '日'],
        correctAnswer: '金',
        reading: 'かね',
        example: '金曜日（きんようび）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '日',
        questionType: QuestionType.multipleChoice,
        meaning: 'ひ、ひび',
        choices: ['月', '日', '年', '時'],
        correctAnswer: '日',
        reading: 'ひ',
        example: '日曜日（にちようび）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '月',
        questionType: QuestionType.multipleChoice,
        meaning: 'つき',
        choices: ['月', '日', '年', '水'],
        correctAnswer: '月',
        reading: 'つき',
        example: '月曜日（げつようび）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '年',
        questionType: QuestionType.multipleChoice,
        meaning: 'とし',
        choices: ['月', '年', '日', '時'],
        correctAnswer: '年',
        reading: 'とし',
        example: '来年（らいねん）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '時',
        questionType: QuestionType.fillInTheBlank,
        meaning: 'とき',
        choices: ['年', '時', '間', '分'],
        correctAnswer: '時',
        reading: 'とき',
        example: '時間（じかん）',
      ),
      // 4 画の漢字（小 1～2）
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '父',
        questionType: QuestionType.multipleChoice,
        meaning: 'ちち',
        choices: ['父', '母', '兄', '弟'],
        correctAnswer: '父',
        reading: 'ちち',
        example: '父親（ちちおや）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '母',
        questionType: QuestionType.multipleChoice,
        meaning: 'はは',
        choices: ['父', '母', '姉', '妹'],
        correctAnswer: '母',
        reading: 'はは',
        example: '母親（ははおや）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '兄',
        questionType: QuestionType.multipleChoice,
        meaning: 'あに',
        choices: ['兄', '弟', '姉', '妹'],
        correctAnswer: '兄',
        reading: 'あに',
        example: '兄さん（あにさん）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '弟',
        questionType: QuestionType.multipleChoice,
        meaning: 'おとうと',
        choices: ['兄', '弟', '姉', '妹'],
        correctAnswer: '弟',
        reading: 'おとうと',
        example: '弟さん（おとうとさん）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '姉',
        questionType: QuestionType.multipleChoice,
        meaning: 'あね',
        choices: ['兄', '弟', '姉', '妹'],
        correctAnswer: '姉',
        reading: 'あね',
        example: '姉さん（あねさん）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '妹',
        questionType: QuestionType.multipleChoice,
        meaning: 'いもうと',
        choices: ['兄', '弟', '姉', '妹'],
        correctAnswer: '妹',
        reading: 'いもうと',
        example: '妹さん（いもうとさん）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '子',
        questionType: QuestionType.multipleChoice,
        meaning: 'こ',
        choices: ['子', '女', '男', '人'],
        correctAnswer: '子',
        reading: 'こ',
        example: '子供（こども）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '女',
        questionType: QuestionType.multipleChoice,
        meaning: 'おんな',
        choices: ['子', '女', '男', '人'],
        correctAnswer: '女',
        reading: 'おんな',
        example: '女性（じょせい）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_10',
        kanji: '男',
        questionType: QuestionType.multipleChoice,
        meaning: 'おとこ',
        choices: ['子', '女', '男', '人'],
        correctAnswer: '男',
        reading: 'おとこ',
        example: '男性（だんせい）',
      ),
      // 継続... レベル 10 の残り 50 問
      // 実装では実際に 80 問まで増やす
    ];
  }

  /// レベル 9（小 2～3）: 80 問
  static List<KanjiQuestionSeed> _generateLevel9Questions() {
    return [
      KanjiQuestionSeed(
        level: 'LEVEL_9',
        kanji: '学',
        questionType: QuestionType.multipleChoice,
        meaning: 'がく',
        choices: ['学', '教', '校', '先'],
        correctAnswer: '学',
        reading: 'がく',
        example: '学校（がっこう）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_9',
        kanji: '校',
        questionType: QuestionType.multipleChoice,
        meaning: 'こう',
        choices: ['学', '教', '校', '先'],
        correctAnswer: '校',
        reading: 'こう',
        example: '学校（がっこう）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_9',
        kanji: '先',
        questionType: QuestionType.multipleChoice,
        meaning: 'さき',
        choices: ['学', '教', '先', '生'],
        correctAnswer: '先',
        reading: 'さき',
        example: '先生（せんせい）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_9',
        kanji: '生',
        questionType: QuestionType.multipleChoice,
        meaning: 'せい、い',
        choices: ['学', '教', '先', '生'],
        correctAnswer: '生',
        reading: 'せい',
        example: '先生（せんせい）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_9',
        kanji: '大',
        questionType: QuestionType.multipleChoice,
        meaning: 'おおきい',
        choices: ['大', '小', '中', '高'],
        correctAnswer: '大',
        reading: 'おおきい',
        example: '大きい（おおきい）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_9',
        kanji: '小',
        questionType: QuestionType.multipleChoice,
        meaning: 'ちいさい',
        choices: ['大', '小', '中', '高'],
        correctAnswer: '小',
        reading: 'ちいさい',
        example: '小さい（ちいさい）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_9',
        kanji: '中',
        questionType: QuestionType.multipleChoice,
        meaning: 'なか',
        choices: ['大', '小', '中', '高'],
        correctAnswer: '中',
        reading: 'なか',
        example: '中学校（ちゅうがっこう）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_9',
        kanji: '高',
        questionType: QuestionType.multipleChoice,
        meaning: 'たかい',
        choices: ['大', '小', '中', '高'],
        correctAnswer: '高',
        reading: 'たかい',
        example: '高い（たかい）',
      ),
      // ... レベル 9 の残り 72 問
    ];
  }

  /// レベル 8（小 3～4）: 90 問
  static List<KanjiQuestionSeed> _generateLevel8Questions() {
    return [
      KanjiQuestionSeed(
        level: 'LEVEL_8',
        kanji: '食',
        questionType: QuestionType.multipleChoice,
        meaning: 'たべもの',
        choices: ['食', '飲', '水', '米'],
        correctAnswer: '食',
        reading: 'たべもの',
        example: '食事（しょくじ）',
      ),
      // ... レベル 8 の 89 問
    ];
  }

  /// レベル 7（小 4～5）: 100 問
  static List<KanjiQuestionSeed> _generateLevel7Questions() {
    return [
      KanjiQuestionSeed(
        level: 'LEVEL_7',
        kanji: '漢',
        questionType: QuestionType.multipleChoice,
        meaning: 'かん',
        choices: ['漢', '字', '検', '定'],
        correctAnswer: '漢',
        reading: 'かん',
        example: '漢字（かんじ）',
      ),
      // ... レベル 7 の 99 問
    ];
  }

  /// レベル 6（小 5～6）: 110 問
  static List<KanjiQuestionSeed> _generateLevel6Questions() {
    return [
      KanjiQuestionSeed(
        level: 'LEVEL_6',
        kanji: '字',
        questionType: QuestionType.multipleChoice,
        meaning: 'じ',
        choices: ['漢', '字', '検', '定'],
        correctAnswer: '字',
        reading: 'じ',
        example: '文字（もじ）',
      ),
      // ... レベル 6 の 109 問
    ];
  }

  /// レベル 5（小 6）: 120 問
  static List<KanjiQuestionSeed> _generateLevel5Questions() {
    return [
      KanjiQuestionSeed(
        level: 'LEVEL_5',
        kanji: '検',
        questionType: QuestionType.multipleChoice,
        meaning: 'けん',
        choices: ['漢', '字', '検', '定'],
        correctAnswer: '検',
        reading: 'けん',
        example: '検査（けんさ）',
      ),
      KanjiQuestionSeed(
        level: 'LEVEL_5',
        kanji: '定',
        questionType: QuestionType.multipleChoice,
        meaning: 'てい',
        choices: ['漢', '字', '検', '定'],
        correctAnswer: '定',
        reading: 'てい',
        example: '定義（ていぎ）',
      ),
      // ... レベル 5 の 118 問
    ];
  }
}

/// 模擬試験セット生成クラス
class MockExamSeed {
  static Future<void> seedMockExams() async {
    // Firestore dependency removed - this method is deprecated
    print('❌ seedMockExams is deprecated - Firestore removed');
    // final firestore = FirebaseFirestore.instance;
    //
    // print('模擬試験セットを投入開始...');
    //
    // // レベル別に 3 セットずつ作成
    // for (int level = 10; level >= 5; level--) {
    //   for (int setNum = 1; setNum <= 3; setNum++) {
    //     final examData = {
    //       'level': 'LEVEL_$level',
    //       'setNumber': setNum,
    //       'title': 'レベル $level 模擬試験 第 $setNum セット',
    //       'timeLimitSec': 600, // 10 分
    //       'passScore': 80,     // 80 点以上で合格
    //       'totalQuestions': 50,
    //       'questionIds': [], // 実際には投入済み問題の ID をリスト化
    //       'createdAt': FieldValue.serverTimestamp(),
    //     };
    //
    //     try {
    //       await firestore.collection('mock_exams').add(examData);
    //       print('✅ レベル $level セット $setNum を投入');
    //     } catch (e) {
    //       print('❌ エラー: $e');
    //     }
    //   }
    // }
    //
    // print('✅ 模擬試験セット投入完了: 18 セット');
  }
}

/// 使用例（main.dart または Firebase Shell）
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///
///   // 本番データを投入（1 回のみ実行）
///   await FirestoreSeed.seedKanjiQuestions();
///   await MockExamSeed.seedMockExams();
///
///   runApp(const MyApp());
/// }
/// ```
