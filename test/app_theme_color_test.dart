import 'dart:math' show pow;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final l1 = lum(a), l2 = lum(b);
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('漢検のテーマ色は国語オレンジ系（設計書どおり）', () {
    final light = AppTheme.light(googleFont: false).colorScheme;
    final dark = AppTheme.dark(googleFont: false).colorScheme;
    expect(light.primary, const Color(0xFFB45F06));
    expect(dark.primary, const Color(0xFFF5B461));
  });

  test('塗り色と文字色のコントラストは AA（4.5:1）以上', () {
    final light = AppTheme.light(googleFont: false).colorScheme;
    final dark = AppTheme.dark(googleFont: false).colorScheme;
    expect(_contrast(light.primary, light.onPrimary), greaterThanOrEqualTo(4.5));
    expect(_contrast(dark.primary, dark.onPrimary), greaterThanOrEqualTo(4.5));
    expect(_contrast(light.primaryContainer, light.onPrimaryContainer), greaterThanOrEqualTo(4.5));
    expect(_contrast(dark.primaryContainer, dark.onPrimaryContainer), greaterThanOrEqualTo(4.5));
  });
}
