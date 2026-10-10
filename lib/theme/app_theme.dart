import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アプリ全体で使用する統一カラーパレット・スタイル定義
class AppColors {
  AppColors._();

  // ブランドカラー
  // 漢字検定は別ブランド（子ども向け）。小学コレ！国語と同系のオレンジで統一する。
  // 設計書: ukalab_分野別・資格別カラー割当_v0_1（漢字検定）。
  // light = #B45F06（白文字 4.58:1）／ dark = #F5B461（文字 #10151C 10.11:1）。
  static const Color primary = Color(0xFFB45F06);
  static const Color primaryDark = Color(0xFF8A4905);
  static const Color primaryOnDark = Color(0xFFF5B461);
  // 淡い塗り（背景・選択行）。primaryDark の文字が 6.05:1。
  static const Color primarySoft = Color(0xFFFBEEDC);

  // 機能カテゴリカラー（意味のグルーピングに基づく統一配色）
  static const Color study = Color(0xFF2FA86A);      // 学習・演習系（緑）
  static const Color analysis = Color(0xFFEA8C2E);   // 分析・計画系（オレンジ）
  static const Color social = Color(0xFF8B5CF6);     // ソーシャル系（紫）
  static const Color reward = Color(0xFFE0A62E);     // コレクション・報酬系（琥珀）
  static const Color info = Color(0xFF2F8FE0);       // 情報・管理系（青）

  // セマンティックカラー
  static const Color success = Color(0xFF2FA86A);
  static const Color warning = Color(0xFFE0A62E);
  static const Color error = Color(0xFFE0453C);

  // 中立色
  static const Color surfaceMuted = Color(0xFFF5F6FA);
  static const Color textMuted = Color(0xFF6B7280);
}

/// アプリ全体のテーマ定義。
///
/// 基本の色・文字サイズ・角丸・タップ領域は、うかラボ共通テーマ（app_common_kit v0.2、
/// 「言語・教育」の分野色）に従う。書体は従来どおり Noto Sans JP。
/// [AppColors] は機能カテゴリ（学習・分析・ソーシャルなど）の色として残す。
class AppTheme {
  AppTheme._();

  static const UkalabField field = UkalabField.lang;

  /// [googleFont] が false なら端末の標準書体（テスト用。通信でフォントを取らない）。
  static ThemeData light({bool googleFont = true}) => _base(Brightness.light, googleFont);
  static ThemeData dark({bool googleFont = true}) => _base(Brightness.dark, googleFont);

  static ThemeData _base(Brightness brightness, bool googleFont) {
    final built = UkalabTheme.build(field: field, brightness: brightness);
    final isDark = brightness == Brightness.dark;
    final fill = isDark ? AppColors.primaryOnDark : AppColors.primary;
    final onFill = isDark ? const Color(0xFF10151C) : Colors.white;
    // 共通テーマ（言語・教育のピンク）を、漢検のオレンジに差し替える。
    // コンテナ色は面と文字をセットで決める（沈んで読めなくなるのを防ぐ）。
    final scheme = built.colorScheme.copyWith(
      primary: fill,
      onPrimary: onFill,
      primaryContainer: isDark ? const Color(0xFF4A2D08) : const Color(0xFFFBE5CC),
      onPrimaryContainer: isDark ? const Color(0xFFFBE0B8) : const Color(0xFF5A2F00),
      secondary: fill,
      onSecondary: onFill,
      secondaryContainer: isDark ? const Color(0xFF4A2D08) : const Color(0xFFFBE5CC),
      onSecondaryContainer: isDark ? const Color(0xFFFBE0B8) : const Color(0xFF5A2F00),
    );
    final base = built.copyWith(
      colorScheme: scheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(UkalabTheme.minTapTarget, UkalabTheme.minTapTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UkalabTheme.buttonRadius)),
          backgroundColor: fill,
          foregroundColor: onFill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(UkalabTheme.minTapTarget, UkalabTheme.minTapTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UkalabTheme.buttonRadius)),
          foregroundColor: fill,
        ),
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(UkalabTheme.buttonRadius),
    );
    return base.copyWith(
      textTheme: googleFont ? GoogleFonts.notoSansJpTextTheme(base.textTheme) : base.textTheme,
      appBarTheme: base.appBarTheme.copyWith(centerTitle: true),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(UkalabTheme.minTapTarget, UkalabTheme.minTapTarget),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: shape,
          backgroundColor: base.colorScheme.primary,
          foregroundColor: base.colorScheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(UkalabTheme.minTapTarget, UkalabTheme.minTapTarget),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: shape,
          foregroundColor: base.colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UkalabTheme.buttonRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
