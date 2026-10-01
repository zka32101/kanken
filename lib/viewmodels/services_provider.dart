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
// 呼んでも「合計10問ごと」に1回インタースティシャルを表示する。
final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager(questionInterval: 10);
  manager.preload();
  ref.onDispose(manager.dispose);
  return manager;
});
