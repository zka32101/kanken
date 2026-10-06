import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 手書き判定の厳しさ（合格点の段階）。点数そのものは変えず、合格ラインだけ変える。
enum HandwritingStrictness {
  easy('やさしい', 60, 'ざっくり合っていれば合格'),
  normal('ふつう', 70, 'ふつうの厳しさ'),
  strict('きびしい', 80, '形をていねいに');

  const HandwritingStrictness(this.label, this.passingScore, this.description);
  final String label;
  final int passingScore;
  final String description;

  static const HandwritingStrictness defaultLevel = HandwritingStrictness.normal;
}

/// 端末内(SharedPreferences)への保存。
class HandwritingStrictnessStore {
  static const String prefsKey = 'handwriting_strictness';

  static Future<HandwritingStrictness> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(prefsKey);
      return HandwritingStrictness.values.firstWhere(
        (e) => e.name == name,
        orElse: () => HandwritingStrictness.defaultLevel,
      );
    } catch (_) {
      return HandwritingStrictness.defaultLevel;
    }
  }

  static Future<void> save(HandwritingStrictness level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, level.name);
  }
}

class HandwritingStrictnessNotifier extends StateNotifier<HandwritingStrictness> {
  HandwritingStrictnessNotifier() : super(HandwritingStrictness.defaultLevel) {
    _loaded = HandwritingStrictnessStore.load().then((v) {
      if (mounted && !_changed) state = v;
    });
  }

  late final Future<void> _loaded;
  bool _changed = false;

  /// 保存値の読み込み完了を待つ（判定の直前に使う）。
  Future<void> ensureLoaded() => _loaded;

  Future<void> set(HandwritingStrictness level) async {
    _changed = true;
    state = level;
    await HandwritingStrictnessStore.save(level);
  }
}

final handwritingStrictnessProvider =
    StateNotifierProvider<HandwritingStrictnessNotifier, HandwritingStrictness>(
        (ref) => HandwritingStrictnessNotifier());
