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

// InterstitialAdManagerProvider
// アプリ全体で1つのインスタンスを共有し、演習・弱点モード・模試のどこから
// 呼んでも「セッション(演習1回分・模試の結果表示後)が終わるたびに1回」
// カウントし、Remote Config設定の頻度でインタースティシャルを表示する。
// 演習・模擬試験の最中には出さない(うかラボ共通方針)。
final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager();
  manager.preload();
  ref.onDispose(manager.dispose);
  return manager;
});

// 苦手集中モードの完了画面で、インタースティシャル表示を1回だけ
// トリガーするためのガード。画面に入り直すたびリセットされる
// (autoDispose)。
final weakKanjiSessionAdShownProvider = StateProvider.autoDispose<bool>((ref) => false);
