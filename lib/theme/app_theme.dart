import 'package:flutter/material.dart';

/// アプリ全体で使用する統一カラーパレット・スタイル定義
class AppColors {
  AppColors._();

  // ブランドカラー
  static const Color primary = Color(0xFF3B6CF2);
  static const Color primaryDark = Color(0xFF2749B0);

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

/// アプリ全体のテーマ定義
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'NotoSansJP',
      scaffoldBackgroundColor: AppColors.surfaceMuted,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'NotoSansJP',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
