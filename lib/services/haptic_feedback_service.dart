import 'package:flutter/services.dart';

/// ハプティクスフィードバック管理サービス
class HapticFeedbackService {
  static bool _isEnabled = true;

  /// 軽いタップ（正解フィードバック）
  static Future<void> lightTap() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // デバイスが対応していない場合はスキップ
    }
  }

  /// 中程度のタップ（コンボ達成）
  static Future<void> mediumTap() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // スキップ
    }
  }

  /// 強いタップ（バッジ獲得・合格）
  static Future<void> heavyTap() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // スキップ
    }
  }

  /// シェイク（不正解フィードバック）
  static Future<void> shake() async {
    if (!_isEnabled) return;
    try {
      // 3回のタップでシェイク表現
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      // スキップ
    }
  }

  /// セレクション変更（UI操作）
  static Future<void> selectionTap() async {
    if (!_isEnabled) return;
    try {
      // selectionTap not available in all Flutter versions, use lightImpact instead
      await HapticFeedback.lightImpact();
    } catch (e) {
      // スキップ
    }
  }

  /// ハプティクス有効・無効を設定
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// ハプティクス有効状態を取得
  static bool isEnabled() => _isEnabled;
}
