import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/mock_exam_modes.dart';

void main() {
  group('ExamConfig Tests', () {
    test('Standard exam configuration', () {
      final config = ExamConfig.standard();

      // 既定は3級: 公式の検定時間60分・合格の目安70%
      expect(config.questionCount, equals(20));
      expect(config.timeLimit, equals(60));
      expect(config.mode, equals(ExamMode.standardExam));
      expect(config.difficulty, equals(ExamDifficulty.medium));
      expect(config.passThreshold, equals(70));
    });

    test('Official time limit and pass percent depend on level', () {
      // 8級以下(8・9・10級)は40分、7級以上は60分
      expect(ExamConfig.officialMinutes(10), equals(40));
      expect(ExamConfig.officialMinutes(8), equals(40));
      expect(ExamConfig.officialMinutes(7), equals(60));
      expect(ExamConfig.officialMinutes(1), equals(60));

      // 1・2級と8〜10級は80%、3〜7級は70%
      for (final level in [1, 2, 8, 9, 10]) {
        expect(ExamConfig.officialPassPercent(level), equals(80));
      }
      for (final level in [3, 4, 5, 6, 7]) {
        expect(ExamConfig.officialPassPercent(level), equals(70));
      }

      final kyu10 = ExamConfig.standard(level: 10);
      expect(kyu10.timeLimit, equals(40));
      expect(kyu10.passThreshold, equals(80));
      expect(ExamConfig.speed(level: 2).passThreshold, equals(80));
    });

    test('isPass compares integers and accepts the exact boundary', () {
      final config = ExamConfig.standard(level: 3); // 70%

      expect(config.isPass(14, 20), isTrue); // ちょうど70%
      expect(config.isPass(13, 20), isFalse);
      expect(config.isPass(0, 0), isFalse);
    });

    test('Speed exam configuration', () {
      final config = ExamConfig.speed();

      expect(config.questionCount, equals(20));
      expect(config.timeLimit, equals(60));
      expect(config.mode, equals(ExamMode.speedExam));
    });

    test('Focused exam configuration', () {
      final config = ExamConfig.focused(category: ExamCategory.reading);

      // 1級・1カテゴリあたり用意できる問題は5問のみ
      expect(config.questionCount, equals(5));
      expect(config.timeLimit, equals(45));
      expect(config.mode, equals(ExamMode.focusedExam));
      expect(config.categories.length, equals(1));
      expect(config.categories.first, equals(ExamCategory.reading));
    });

    test('Weak areas exam configuration', () {
      final config = ExamConfig.weakAreas();

      expect(config.questionCount, equals(20));
      expect(config.mode, equals(ExamMode.weakAreasExam));
      expect(config.difficulty, equals(ExamDifficulty.medium));
    });

    test('Random exam configuration', () {
      final config = ExamConfig.random();

      expect(config.questionCount, equals(20));
      expect(config.mode, equals(ExamMode.randomExam));
      expect(config.randomizeOrder, isTrue);
    });

    test('Progressive exam configuration', () {
      final config = ExamConfig.progressive();

      expect(config.questionCount, equals(20));
      expect(config.mode, equals(ExamMode.progressiveExam));
      expect(config.timeLimit, equals(150));
    });

    test('ExamConfig serialization', () {
      final config = ExamConfig.standard(level: 2);
      final json = config.toJson();

      expect(json['questionCount'], equals(20));
      expect(json['targetLevel'], equals(2));
      expect(json['timeLimit'], equals(60));
      expect(json['passThreshold'], equals(80));
      expect(json['mode'], contains('standardExam'));
    });

    test('ExamConfig deserialization', () {
      final jsonData = {
        'questionCount': 50,
        'timeLimit': 120,
        'mode': 'ExamMode.standardExam',
        'difficulty': 'ExamDifficulty.medium',
        'categories': ['ExamCategory.reading', 'ExamCategory.meaning'],
        'targetLevel': 3,
        'showExplanations': true,
        'allowReview': true,
        'randomizeOrder': true,
        'passThreshold': 60,
      };

      final config = ExamConfig.fromJson(jsonData);

      expect(config.questionCount, equals(50));
      expect(config.targetLevel, equals(3));
      expect(config.categories.length, equals(2));
    });

    test('Custom exam configuration', () {
      final config = ExamConfig(
        questionCount: 100,
        timeLimit: 180,
        mode: ExamMode.progressiveExam,
        difficulty: ExamDifficulty.hard,
        categories: [ExamCategory.reading, ExamCategory.writing],
        targetLevel: 1,
        showExplanations: false,
        passThreshold: 70,
      );

      expect(config.questionCount, equals(100));
      expect(config.timeLimit, equals(180));
      expect(config.showExplanations, isFalse);
      expect(config.passThreshold, equals(70));
    });
  });

  group('ExamMode Tests', () {
    test('All exam modes are available', () {
      expect(ExamMode.standardExam, isNotNull);
      expect(ExamMode.speedExam, isNotNull);
      expect(ExamMode.focusedExam, isNotNull);
      expect(ExamMode.weakAreasExam, isNotNull);
      expect(ExamMode.randomExam, isNotNull);
      expect(ExamMode.progressiveExam, isNotNull);
    });

    test('Exam modes have different characteristics', () {
      final standardConfig = ExamConfig.standard();
      final speedConfig = ExamConfig.speed();
      final progressiveConfig = ExamConfig.progressive();

      // 標準は公式時間(3級は60分)でスピードと同じ、段階式は一番長い
      expect(standardConfig.timeLimit, greaterThanOrEqualTo(speedConfig.timeLimit));
      expect(progressiveConfig.timeLimit, greaterThan(speedConfig.timeLimit));
      expect(ExamConfig.focused(category: ExamCategory.reading).questionCount,
        lessThan(standardConfig.questionCount));
    });
  });

  group('ExamDifficulty Tests', () {
    test('All difficulty levels exist', () {
      expect(ExamDifficulty.easy, isNotNull);
      expect(ExamDifficulty.medium, isNotNull);
      expect(ExamDifficulty.hard, isNotNull);
      expect(ExamDifficulty.veryHard, isNotNull);
    });

    test('Difficulty levels can be ordered', () {
      const difficultyOrder = [
        ExamDifficulty.easy,
        ExamDifficulty.medium,
        ExamDifficulty.hard,
        ExamDifficulty.veryHard,
      ];

      expect(difficultyOrder.length, equals(4));
    });
  });

  group('ExamCategory Tests', () {
    test('All categories are defined', () {
      expect(ExamCategory.reading, isNotNull);
      expect(ExamCategory.meaning, isNotNull);
      expect(ExamCategory.stroke, isNotNull);
      expect(ExamCategory.writing, isNotNull);
      expect(ExamCategory.usage, isNotNull);
      expect(ExamCategory.mixed, isNotNull);
    });

    test('Focused exams can target specific categories', () {
      final readingExam = ExamConfig.focused(category: ExamCategory.reading);
      final writingExam = ExamConfig.focused(category: ExamCategory.writing);
      final meaningExam = ExamConfig.focused(category: ExamCategory.meaning);

      expect(readingExam.categories.first, equals(ExamCategory.reading));
      expect(writingExam.categories.first, equals(ExamCategory.writing));
      expect(meaningExam.categories.first, equals(ExamCategory.meaning));
    });
  });

  group('EnhancedExamQuestion Tests', () {
    test('Enhanced question with full metadata', () {
      final question = EnhancedExamQuestion(
        questionId: 'q-1',
        kanji: '漢',
        questionType: 'reading',
        question: 'Read this kanji',
        options: ['かん', 'かんじ', 'から', 'は'],
        correctAnswer: 'かん',
        explanation: 'This is the correct reading',
        level: 3,
        difficulty: ExamDifficulty.medium,
        category: ExamCategory.reading,
        averageTimeSeconds: 15.5,
        correctnessRate: 0.85,
        userAttempts: 5,
        commonMistakes: ['かんじ'],
        additionalTip: 'Remember the common reading',
      );

      expect(question.questionId, equals('q-1'));
      expect(question.difficulty, equals(ExamDifficulty.medium));
      expect(question.correctnessRate, equals(0.85));
      expect(question.commonMistakes.length, equals(1));
    });

    test('Enhanced question serialization', () {
      final question = EnhancedExamQuestion(
        questionId: 'q-2',
        kanji: '検',
        questionType: 'meaning',
        question: 'What does this mean?',
        options: ['check', 'verify', 'measure', 'test'],
        correctAnswer: 'check',
        explanation: 'Primary meaning is check or verify',
        level: 2,
        difficulty: ExamDifficulty.hard,
        category: ExamCategory.meaning,
        averageTimeSeconds: 20.0,
        correctnessRate: 0.75,
        userAttempts: 3,
        commonMistakes: ['measure'],
      );

      final json = question.toJson();

      expect(json['questionId'], equals('q-2'));
      expect(json['difficulty'], contains('hard'));
      expect(json['category'], contains('meaning'));
    });

    test('Enhanced question deserialization', () {
      final jsonData = {
        'questionId': 'q-3',
        'kanji': '定',
        'questionType': 'stroke',
        'question': 'How many strokes?',
        'options': ['5', '6', '7', '8'],
        'correctAnswer': '8',
        'explanation': '定 has 8 strokes',
        'level': 3,
        'difficulty': 'ExamDifficulty.easy',
        'category': 'ExamCategory.stroke',
        'averageTimeSeconds': 10.5,
        'correctnessRate': 0.95,
        'userAttempts': 10,
        'commonMistakes': ['7', '9'],
        'additionalTip': 'Count carefully',
      };

      final question = EnhancedExamQuestion.fromJson(jsonData);

      expect(question.questionId, equals('q-3'));
      expect(question.category, equals(ExamCategory.stroke));
      expect(question.userAttempts, equals(10));
    });

    test('Question difficulty progression', () {
      final easyQ = EnhancedExamQuestion(
        questionId: 'easy-1',
        kanji: '日',
        questionType: 'reading',
        question: 'Easy question',
        options: ['ひ', 'にち', 'か', 'ね'],
        correctAnswer: 'ひ',
        explanation: '',
        level: 10,
        difficulty: ExamDifficulty.easy,
        category: ExamCategory.reading,
        averageTimeSeconds: 5.0,
        correctnessRate: 0.98,
        userAttempts: 20,
        commonMistakes: [],
      );

      final hardQ = EnhancedExamQuestion(
        questionId: 'hard-1',
        kanji: '譲',
        questionType: 'reading',
        question: 'Hard question',
        options: ['じょう', 'ゆずる', 'ゆずって', 'じゃう'],
        correctAnswer: 'ゆずる',
        explanation: '',
        level: 2,
        difficulty: ExamDifficulty.veryHard,
        category: ExamCategory.reading,
        averageTimeSeconds: 40.0,
        correctnessRate: 0.45,
        userAttempts: 2,
        commonMistakes: ['じょう'],
      );

      expect(hardQ.difficulty.toString(),
        isNot(easyQ.difficulty.toString()));
      expect(hardQ.correctnessRate, lessThan(easyQ.correctnessRate));
      expect(hardQ.averageTimeSeconds,
        greaterThan(easyQ.averageTimeSeconds));
    });
  });
}
