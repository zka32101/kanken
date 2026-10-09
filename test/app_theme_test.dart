import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/theme/app_theme.dart';

void main() {
  test('共通テーマ（言語・教育）を使う', () {
    final l = AppTheme.light(googleFont: false);
    final d = AppTheme.dark(googleFont: false);
    expect(l.colorScheme.primary, const Color(0xFFB45F06));
    expect(d.colorScheme.primary, const Color(0xFFF5B461));
    expect(d.colorScheme.onPrimary, UkalabPalette.onFillDark);
    expect(AppColors.primary, l.colorScheme.primary, reason: '機能色の primary もテーマと同じ');
  });

  test('ボタンのタップ領域は 44pt 以上', () {
    final s = AppTheme.light(googleFont: false).elevatedButtonTheme.style!;
    expect(s.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(44));
  });
}
