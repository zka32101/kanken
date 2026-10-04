import 'package:app_common_kit/app_common_kit.dart'
    show MascotStage, MasteryInput, MasteryModel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/oshi_progress_store.dart';
import '../viewmodels/index.dart';
import 'level_progress_provider.dart';

/// 習得度から推しの成長段階を決める。
/// 網羅率＝解いた問題の種類÷級の総問題数、正答率＝その級の正答数÷回答数。
/// 回答がまだ無い、総問題数が分からないときは Lv1。
MascotStage oshiStageFor({
  required int distinctAnswered,
  required int totalQuestions,
  required int correct,
  required int answered,
}) {
  return MasteryModel.standard.stageOf(MasteryInput.fromCounts(
    distinctAnswered: distinctAnswered,
    totalQuestions: totalQuestions,
    correct: correct,
    answered: answered,
  ));
}

/// 選択中の級での習得度の材料（網羅率・正答率）。回答が無ければ 0。
/// 回答のたびに levelProgressProvider が更新されるので、それに追従する。
final oshiMasteryProvider = FutureProvider.autoDispose<MasteryInput>((ref) async {
  final level = ref.watch(currentLevelProvider);
  final user = await ref.watch(currentUserProvider.future);
  final stats = await ref.watch(levelProgressProvider.future);
  final progress = levelProgressFor(stats, level);
  final profileId = user?.profileId ?? 'default';

  final answered = await OshiProgressStore.answeredCount(
    profileId: profileId,
    level: level,
  );
  final total = await OshiProgressStore.totalQuestions(level);

  return MasteryInput.fromCounts(
    distinctAnswered: answered,
    totalQuestions: total,
    correct: progress.correctCount,
    answered: progress.totalCount,
  );
});

/// 選択中の級での推しの成長段階。
final oshiStageProvider = FutureProvider.autoDispose<MascotStage>((ref) async {
  final m = await ref.watch(oshiMasteryProvider.future);
  return MasteryModel.standard.stageOf(m);
});
