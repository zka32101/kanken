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

// MockExamServiceProvider
final mockExamServiceProvider = Provider<MockExamService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return MockExamService(firestoreService);
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
