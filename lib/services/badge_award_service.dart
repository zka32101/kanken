import '../models/index.dart';
import '../providers/level_progress_provider.dart';
import '../viewmodels/services_provider.dart';
import '../viewmodels/user_viewmodel.dart';

/// 級クリア（演習での正答率達成）バッジのID。
/// mock_exam_result_screen.dart が付与する 'exam_pass_$level' とは別IDだが、
/// どちらも CollectionBadge.level に級名を持つため、コレクション画面では
/// 「どちらかを獲得していればその級はクリア済み」として表示される。
String practiceLevelBadgeId(String level) => 'practice_pass_$level';

/// 演習の正答率集計（levelStats）が合格基準（LevelProgress.isCleared）に
/// 達しているのに、まだその級のバッジを獲得していなければ付与する。
/// 新規にバッジを獲得した場合のみ true を返す（呼び出し側でお祝い演出を出す）。
// WidgetRef(ConsumerWidget)とRef(StateNotifier等)の両方から呼び出せるよう、
// 具象型を指定せずダックタイピングで受け取る（両者ともread/refresh等の
// シグネチャは共通だが、riverpod 2.x では共通の親クラスを持たないため）。
Future<bool> checkAndAwardLevelClearBadge(dynamic ref, String level) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null) return false;

  try {
    final stats = await ref.refresh(levelProgressProvider.future);
    final progress = levelProgressFor(stats, level);
    if (!progress.isCleared) return false;

    final firestoreService = ref.read(firestoreServiceProvider);
    final existingBadges = await firestoreService.getUserBadges(uid);
    final alreadyCleared = existingBadges.any((b) => b.level == level);
    if (alreadyCleared) return false;

    final badge = CollectionBadge(
      badgeId: practiceLevelBadgeId(level),
      name: '$level 突破',
      description: '$level の問題で正答率${(LevelProgress.kPassThreshold * 100).round()}%以上を達成',
      rarity: BadgeRarity.uncommon,
      category: BadgeCategory.achievement,
      iconEmoji: '📜',
      requiredCount: LevelProgress.kTargetQuestions,
      conditionText:
          '$level の問題を${LevelProgress.kTargetQuestions}問以上解いて正答率${(LevelProgress.kPassThreshold * 100).round()}%以上',
      rewardCoins: 100,
      createdAt: DateTime.now(),
      level: level,
    );

    await firestoreService.addCollectionBadge(uid, badge);
    return true;
  } catch (e) {
    return false;
  }
}

/// ストリークに応じた実績バッジ（level は持たないので、コレクション画面の
/// 「実績バッジ」セクションに表示される）。
const Map<int, (String, String, String, String)> streakBadgeThresholds = {
  // streakDays: (badgeId, name, description, icon)
  7: ('streak_7', '継続は力なり', '7日連続で学習しました', '🔥'),
  30: ('streak_30', '継続マスター', '30日連続で学習しました', '🏆'),
};

/// ストリーク日数が閾値に達していれば実績バッジを付与する。
/// 新規に獲得したバッジがあれば、その badgeId のリストを返す。
Future<List<String>> checkAndAwardStreakBadges(dynamic ref, int streakCount) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null) return [];

  final newlyAwarded = <String>[];
  try {
    final firestoreService = ref.read(firestoreServiceProvider);
    final existingBadges = await firestoreService.getUserBadges(uid);
    final existingIds = existingBadges.map((b) => b.badgeId).toSet();

    for (final entry in streakBadgeThresholds.entries) {
      final threshold = entry.key;
      if (streakCount < threshold) continue;
      final (badgeId, name, description, icon) = entry.value;
      if (existingIds.contains(badgeId)) continue;

      final badge = CollectionBadge(
        badgeId: badgeId,
        name: name,
        description: description,
        rarity: threshold >= 30 ? BadgeRarity.rare : BadgeRarity.uncommon,
        category: BadgeCategory.streak,
        iconEmoji: icon,
        requiredCount: threshold,
        conditionText: '$threshold日連続で学習する',
        rewardCoins: threshold * 10,
        createdAt: DateTime.now(),
      );
      await firestoreService.addCollectionBadge(uid, badge);
      newlyAwarded.add(badgeId);
    }
  } catch (e) {
    // サイレント処理（他の達成チェックと同様）
  }
  return newlyAwarded;
}
