import '../models/index.dart';
import 'firestore_service.dart';

class MockExamService {
  final FirestoreService _firestoreService;

  MockExamService(this._firestoreService);

  /// 指定レベルの模擬試験を取得
  Future<MockExam?> getMockExamForLevel(String level) async {
    final exams = await _firestoreService.getMockExamsByLevel(level);
    return exams.isNotEmpty ? exams.first : null;
  }

  /// 模擬試験結果を保存して、合否判定と次のアクションを返す
  Future<MockExamResultAnalysis> saveMockExamResult({
    required String uid,
    required String examId,
    required int score,
    required int passScore,
  }) async {
    final passed = score >= passScore;

    final result = MockExamResult(
      id: '', // Firestoreで自動生成
      uid: uid,
      examId: examId,
      score: score,
      passed: passed,
      takenAt: DateTime.now(),
    );

    await _firestoreService.addMockExamResult(result);

    // 合格時はバッジを追加
    if (passed) {
      final exam = await _firestoreService.getMockExam(examId);
      if (exam != null) {
        final badge = CollectionBadge(
          badgeId: 'exam_pass_${exam.level}_${DateTime.now().millisecondsSinceEpoch}',
          name: '${exam.level} 級 合格バッジ',
          description: '${exam.level} 級試験に合格しました',
          rarity: BadgeRarity.uncommon,
          category: BadgeCategory.achievement,
          iconEmoji: '🎖️',
          requiredCount: 1,
          conditionText: '${exam.level} 級試験に合格',
          isHidden: false,
          rewardCoins: 100,
          createdAt: DateTime.now(),
          level: 'LEVEL_${exam.level}',
        );
        await _firestoreService.addCollectionBadge(badge);
      }
    }

    return MockExamResultAnalysis(
      passed: passed,
      score: score,
      scoreNeededToPass: passScore - score,
    );
  }

  /// ユーザーの全模擬試験結果を取得
  Future<List<MockExamResult>> getUserResults(String uid) async {
    return await _firestoreService.getUserMockExamResults(uid);
  }
}

class MockExamResultAnalysis {
  final bool passed;
  final int score;
  final int scoreNeededToPass; // 合格まであと何点必要か

  MockExamResultAnalysis({
    required this.passed,
    required this.score,
    required this.scoreNeededToPass,
  });
}
