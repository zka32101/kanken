import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // User operations
  Future<User?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return User.fromJson(doc.data()!);
  }

  Future<void> createUser(User user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toJson(), SetOptions(merge: true));
    await _mirrorUserNameToRanking(user.uid, user.displayName);
  }

  Future<void> updateUser(User user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toJson(), SetOptions(merge: true));
    await _mirrorUserNameToRanking(user.uid, user.displayName);
  }

  /// users/{uid} 本体（メール等を含みうる）は本人のみ読み書き可能なため、
  /// ランキング表示に使うニックネームだけを rankings/{uid}（全員読み取り可）へミラーする。
  /// レベル・経験値・コイン等の統計は GamificationNotifier が別途同じドキュメントへ
  /// merge するので、ここでは触れない。
  Future<void> _mirrorUserNameToRanking(String uid, String userName) async {
    await _firestore.collection('rankings').doc(uid).set(
      {'userId': uid, 'userName': userName},
      SetOptions(merge: true),
    );
  }

  // Kanji operations
  Future<List<Map<String, dynamic>>> getKanjiList(int gradeLevel) async {
    // Placeholder - will be implemented with database
    return [];
  }

  // Practice session operations
  Future<String> createPracticeSession(
    String userId,
    int gradeLevel,
    String sessionType,
  ) async {
    // Placeholder - will be implemented with database
    return '';
  }

  Future<void> savePracticeResult(
    String sessionId,
    int questionId,
    bool isCorrect,
    int timeSpent,
  ) async {
    // Placeholder - will be implemented with database
  }

  // Learning progress
  Future<Map<String, dynamic>> getUserProgress(String uid) async {
    // Placeholder - will be implemented with database
    return {};
  }

  Future<void> updateProgress(
    String userId,
    int kanjiId,
    bool mastered,
  ) async {
    // Placeholder - will be implemented with database
  }

  // Question operations
  Future<List<KanjiQuestion>> getQuestionsByLevel(String level, {int limit = 50}) async {
    final snapshot = await _firestore
        .collection('questions')
        .where('level', isEqualTo: level)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => KanjiQuestion.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<KanjiQuestion?> getKanjiQuestion(String questionId) async {
    final doc = await _firestore.collection('questions').doc(questionId).get();
    if (!doc.exists) return null;
    return KanjiQuestion.fromJson({...doc.data()!, 'id': doc.id});
  }

  // Answer logging
  Future<void> addAnswerLog(UserAnswerLog log) async {
    // Placeholder - will be implemented with database
  }

  Future<List<UserAnswerLog>> getUserAnswerLogs(String uid) async {
    // Placeholder - will be implemented with database
    return [];
  }

  // Weak kanji tracking
  Future<List<WeakKanjiList>> getWeakKanjiList(String uid) async {
    // Placeholder - will be implemented with database
    return [];
  }

  Future<List<String>> getUserWeakKanjis(String uid) async {
    // Placeholder - will be implemented with database
    return [];
  }

  Future<void> upsertWeakKanjiList(WeakKanjiList item) async {
    // Placeholder - will be implemented with database
  }

  // Learned kanji tracking
  Future<List<String>> getUserLearnedKanjis(String uid) async {
    // Placeholder - will be implemented with database
    return [];
  }

  Future<void> markAsLearned(String uid, String kanjiId) async {
    // Placeholder - will be implemented with database
  }

  // Mock exam operations
  Future<List<MockExam>> getMockExamsByLevel(String level) async {
    // Placeholder - will be implemented with database
    return [];
  }

  Future<MockExam?> getMockExam(String examId) async {
    // Placeholder - will be implemented with database
    return null;
  }

  Future<void> addMockExamResult(MockExamResult result) async {
    // Placeholder - will be implemented with database
  }

  Future<List<MockExamResult>> getUserMockExamResults(String uid) async {
    // Placeholder - will be implemented with database
    return [];
  }

  // Badge operations
  Future<void> addCollectionBadge(CollectionBadge badge) async {
    // Placeholder - will be implemented with database
  }

  Future<List<CollectionBadge>> getUserBadges(String uid) async {
    // Placeholder - will be implemented with database
    return [];
  }

  // Parent account operations
  Future<ParentAccount?> getParentAccount(String uid) async {
    // Placeholder - will be implemented with database
    return null;
  }
}
