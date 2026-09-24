import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // User(プロフィール) operations
  //
  // 1つのFirebase Authアカウント(uid)の下に複数の学習者プロフィールを
  // 持たせるため、実データは users/{uid}/profiles/{profileId} に保存する。
  // ランキングのドキュメントIDもプロフィール単位で分けるため
  // "{uid}_{profileId}" の複合IDを使う。

  static String rankingDocId(String uid, String profileId) => '${uid}_$profileId';

  Future<User?> getUser(String uid, {String profileId = 'default'}) async {
    final doc = await _profileDoc(uid, profileId).get();
    if (!doc.exists) return null;
    return User.fromJson(doc.data()!);
  }

  /// uid配下の全プロフィール一覧を取得する
  Future<List<User>> getUserProfiles(String uid) async {
    final snapshot = await _profilesCollection(uid).get();
    return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
  }

  Future<void> deleteProfile(String uid, String profileId) async {
    await _profileDoc(uid, profileId).delete();
    await _removeFromRanking(uid, profileId);
  }

  Future<void> createUser(User user) async {
    await _profileDoc(user.uid, user.profileId)
        .set(user.toJson(), SetOptions(merge: true));
    if (user.rankingOptIn) {
      await _mirrorUserNameToRanking(user.uid, user.profileId, user.displayName);
    }
  }

  Future<void> updateUser(User user) async {
    await _profileDoc(user.uid, user.profileId)
        .set(user.toJson(), SetOptions(merge: true));
    if (user.rankingOptIn) {
      await _mirrorUserNameToRanking(user.uid, user.profileId, user.displayName);
    } else {
      // 参加をオフにした場合は既存のランキングエントリも削除する
      await _removeFromRanking(user.uid, user.profileId);
    }
  }

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
    return _profilesCollection(uid).doc(profileId);
  }

  CollectionReference<Map<String, dynamic>> _profilesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('profiles');
  }

  /// users/{uid}/profiles/{profileId} 本体（メール等を含みうる）は本人のみ
  /// 読み書き可能なため、ランキング表示に使うニックネームだけを
  /// rankings/{uid}_{profileId}（全員読み取り可）へミラーする。
  /// レベル・経験値・コイン等の統計は GamificationNotifier が別途同じドキュメントへ
  /// merge するので、ここでは触れない。ランキング参加設定(rankingOptIn)が
  /// オンのユーザーのみ呼び出すこと。
  Future<void> _mirrorUserNameToRanking(
    String uid,
    String profileId,
    String userName,
  ) async {
    await _firestore.collection('rankings').doc(rankingDocId(uid, profileId)).set(
      {'userId': uid, 'profileId': profileId, 'userName': userName},
      SetOptions(merge: true),
    );
  }

  /// ランキング参加をオフにしたユーザーのエントリを削除する
  Future<void> _removeFromRanking(String uid, String profileId) async {
    await _firestore.collection('rankings').doc(rankingDocId(uid, profileId)).delete();
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
  /// uidを指定すると、そのユーザーが「覚えた」問題(getMasteredQuestionIds参照)を
  /// 出題対象から除外する。
  Future<List<KanjiQuestion>> getQuestionsByLevel(
    String level, {
    int limit = 50,
    String? uid,
    String profileId = 'default',
    int masteryThreshold = 3,
  }) async {
    final snapshot = await _firestore
        .collection('questions')
        .where('level', isEqualTo: level)
        .limit(limit)
        .get();

    var questions = snapshot.docs
        .map((doc) => KanjiQuestion.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    if (uid != null) {
      final excludeIds = await getMasteredQuestionIds(
        uid,
        profileId: profileId,
        masteryThreshold: masteryThreshold,
      );
      if (excludeIds.isNotEmpty) {
        questions = questions.where((q) => !excludeIds.contains(q.id)).toList();
      }
    }

    return questions;
  }

  Future<KanjiQuestion?> getKanjiQuestion(String questionId) async {
    final doc = await _firestore.collection('questions').doc(questionId).get();
    if (!doc.exists) return null;
    return KanjiQuestion.fromJson({...doc.data()!, 'id': doc.id});
  }

  // Answer logging
  //
  // answerLogs には履歴として1件ずつ記録する一方、出題除外の判定に
  // 毎回全履歴を読むのは非効率なため、questionStats/{questionId} に
  // 連続正解数(correctStreak)を別途集計しておく。正解なら+1、
  // 不正解なら0にリセットする。「N問連続正解したら出題除外」
  // (User.masteryThreshold)の判定に使う。
  // いずれも users/{uid}/profiles/{profileId}/... 配下（プロフィール単位）。
  Future<void> addAnswerLog(UserAnswerLog log) async {
    final batch = _firestore.batch();
    final profileRef = _profileDoc(log.uid, log.profileId);

    final logRef = profileRef.collection('answerLogs').doc(log.id);
    batch.set(logRef, log.toJson());

    final statsRef = profileRef.collection('questionStats').doc(log.questionId);
    batch.set(
      statsRef,
      {
        'correctStreak': log.isCorrect ? FieldValue.increment(1) : 0,
        'lastAnsweredAt': log.answeredAt.toIso8601String(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<List<UserAnswerLog>> getUserAnswerLogs(
    String uid, {
    String profileId = 'default',
  }) async {
    final snapshot = await _profileDoc(uid, profileId)
        .collection('answerLogs')
        .orderBy('answeredAt', descending: true)
        .limit(200)
        .get();
    return snapshot.docs
        .map((doc) => UserAnswerLog.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
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

  // Learned kanji tracking（演習後にユーザーが手動でチェックする「覚えた」機能）
  // プロフィール単位（users/{uid}/profiles/{profileId}/learnedKanjis）
  Future<List<String>> getUserLearnedKanjis(
    String uid, {
    String profileId = 'default',
  }) async {
    final snapshot =
        await _profileDoc(uid, profileId).collection('learnedKanjis').get();
    return snapshot.docs
        .map((doc) => doc.data()['questionId'] as String? ?? doc.id)
        .toList();
  }

  Future<void> markAsLearned(
    String uid,
    String kanjiId, {
    String profileId = 'default',
  }) async {
    await _profileDoc(uid, profileId)
        .collection('learnedKanjis')
        .doc(kanjiId)
        .set({
      'uid': uid,
      'profileId': profileId,
      'questionId': kanjiId,
      'learnedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 「覚えた」チェックを取り消す
  Future<void> unmarkAsLearned(
    String uid,
    String kanjiId, {
    String profileId = 'default',
  }) async {
    await _profileDoc(uid, profileId)
        .collection('learnedKanjis')
        .doc(kanjiId)
        .delete();
  }

  /// 出題から除外すべき問題ID一覧
  /// （手動で「覚えた」チェックされた問題 + masteryThreshold回以上連続正解した問題）
  Future<Set<String>> getMasteredQuestionIds(
    String uid, {
    String profileId = 'default',
    int masteryThreshold = 3,
  }) async {
    final excludeIds = <String>{};
    final profileRef = _profileDoc(uid, profileId);

    final learnedSnapshot = await profileRef.collection('learnedKanjis').get();
    excludeIds.addAll(
      learnedSnapshot.docs.map((d) => d.data()['questionId'] as String? ?? d.id),
    );

    final statsSnapshot = await profileRef
        .collection('questionStats')
        .where('correctStreak', isGreaterThanOrEqualTo: masteryThreshold)
        .get();
    excludeIds.addAll(statsSnapshot.docs.map((d) => d.id));

    return excludeIds;
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
