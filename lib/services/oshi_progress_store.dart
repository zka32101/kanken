import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ukalab_paths.dart';

/// 推しの成長（網羅率）に使う、端末内の学習記録。
///
/// - 解いた問題のID：回答のたびに端末内へ記録する（これから先の分が対象）。
///   Firestore の回答ログは直近200件までしか取れないため、別に持つ。
/// - 級ごとの総問題数：Firestore の件数集計で取得し、端末内に保持する。
///   取得できないとき（オフラインなど）は前回の値を使う。
class OshiProgressStore {
  OshiProgressStore._();

  static String _answeredKey(String profileId, String level) =>
      'oshi_answered_${profileId}_$level';

  static String _totalKey(String level) => 'oshi_total_$level';

  /// 解いた問題IDを記録する。同じIDは一度だけ。
  static Future<void> markAnswered({
    required String profileId,
    required String level,
    required String questionId,
  }) async {
    if (questionId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _answeredKey(profileId, level);
    final ids = List<String>.of(prefs.getStringList(key) ?? const <String>[]);
    if (ids.contains(questionId)) return;
    ids.add(questionId);
    await prefs.setStringList(key, ids);
  }

  /// 解いた問題の種類数。
  static Future<int> answeredCount({
    required String profileId,
    required String level,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_answeredKey(profileId, level)) ?? const <String>[])
        .length;
  }

  /// その級の総問題数。取得できなければ前回の値、それも無ければ 0。
  static Future<int> totalQuestions(
    String level, {
    FirebaseFirestore? firestore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final snapshot = await (firestore ?? FirebaseFirestore.instance)
          .kanjiCollection('questions')
          .where('level', isEqualTo: level)
          .count()
          .get();
      // cloud_firestore のバージョンにより count は int／int? のどちらか。
      final dynamic raw = snapshot.count;
      final total = raw is int ? raw : 0;
      if (total > 0) {
        await prefs.setInt(_totalKey(level), total);
        return total;
      }
    } catch (_) {
      // オフラインなど。前回の値にフォールバックする。
    }
    return prefs.getInt(_totalKey(level)) ?? 0;
  }
}
