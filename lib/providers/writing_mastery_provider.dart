import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/user_viewmodel.dart' as user_vm;
import '../services/ukalab_paths.dart';

/// 「書く練習」で漢字ごとに「覚えた」チェックを付けられるようにするための
/// 状態管理（プロフィール単位、users/{uid}/profiles/{profileId}/masteredWritingKanjis/{kanji}）。
/// 判定ロジック（QuestionType.multipleChoice向けの`learnedKanjis`）とは別の
/// コレクションを使う。書く練習は特定のFirestore問題IDに紐づかず「漢字そのもの」を
/// キーにするため。

DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
  return FirebaseFirestore.instance
      .kanjiCollection('users')
      .doc(uid)
      .collection('profiles')
      .doc(profileId);
}

Future<String> _currentProfileId(Ref ref) async {
  final user = await ref.watch(user_vm.currentUserProvider.future);
  return user?.profileId ?? 'default';
}

/// 「書く練習」で覚えたとチェックされた漢字一覧（レベルを問わず全件）。
final masteredWritingKanjisProvider = FutureProvider<Set<String>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return {};

  try {
    final profileId = await _currentProfileId(ref);
    final snapshot = await _profileDoc(userId, profileId)
        .collection('masteredWritingKanjis')
        .get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  } catch (_) {
    return {};
  }
});

/// 漢字を「覚えた」としてマークする。
Future<void> markWritingKanjiMastered(WidgetRef ref, String kanji) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final profileId = (await ref.read(user_vm.currentUserProvider.future))?.profileId ?? 'default';
    await _profileDoc(userId, profileId)
        .collection('masteredWritingKanjis')
        .doc(kanji)
        .set({
      'kanji': kanji,
      'masteredAt': Timestamp.now(),
    });
    ref.invalidate(masteredWritingKanjisProvider);
  } catch (_) {
    // ネットワークエラー等は握りつぶす（覚えたチェックはベストエフォート）
  }
}

/// 「覚えた」チェックを取り消す。
Future<void> unmarkWritingKanjiMastered(WidgetRef ref, String kanji) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final profileId = (await ref.read(user_vm.currentUserProvider.future))?.profileId ?? 'default';
    await _profileDoc(userId, profileId)
        .collection('masteredWritingKanjis')
        .doc(kanji)
        .delete();
    ref.invalidate(masteredWritingKanjisProvider);
  } catch (_) {
    // ネットワークエラー等は握りつぶす
  }
}
