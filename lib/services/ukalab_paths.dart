import 'package:cloud_firestore/cloud_firestore.dart';

/// うかラボ共通 Firebase プロジェクト（ukalab-prod / ukalab-dev）での、この資格の examId。
/// このアプリの Firestore データはすべて `exams/<この値>/…` の下に置く
/// （app_common_kit/firebase/firestore.rules の examIds() と一致させること）。
const String ukalabExamId = 'kanji_kentei';

extension UkalabFirestore on FirebaseFirestore {
  /// このアプリ用のルート。`exams/kanji_kentei` ドキュメント。
  DocumentReference<Map<String, dynamic>> get kanjiRoot =>
      collection('exams').doc(ukalabExamId);

  /// `collection(name)` の代わりに使う。ルート直下のコレクションを
  /// `exams/kanji_kentei/<name>` に置く。
  CollectionReference<Map<String, dynamic>> kanjiCollection(String name) =>
      kanjiRoot.collection(name);
}
