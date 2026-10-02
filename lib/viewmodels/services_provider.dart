import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/index.dart';

// FirestoreServiceProvider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// AuthServiceProvider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// AIWeakAnalysisServiceProvider
final aiWeakAnalysisServiceProvider = Provider<AIWeakAnalysisService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AIWeakAnalysisService(firestoreService);
});

// HandwritingJudgeServiceProvider
final handwritingJudgeServiceProvider = Provider<HandwritingJudgeService>((ref) {
  return HandwritingJudgeService();
});

// 苦手集中モードの完了画面で、インタースティシャル表示を1回だけ
// トリガーするためのガード。画面に入り直すたびリセットされる
// (autoDispose)。
final weakKanjiSessionAdShownProvider = StateProvider.autoDispose<bool>((ref) => false);
