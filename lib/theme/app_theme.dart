import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アプリ全体で使用する統一カラーパレット・スタイル定義
class AppColors {
  AppColors._();

  // ブランドカラー
  static const Color primary = Color(0xFFC2347A); // 共通テーマ「言語・教育」の分野色
  static const Color primaryDark = Color(0xFF90265A);

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
    final base = UkalabTheme.build(field: field, brightness: brightness);
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
