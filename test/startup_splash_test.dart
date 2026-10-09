import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/widgets/startup_splash.dart';

void main() {
  testWidgets('起動画面は、アプリのアイコンと組織ロゴを一枚の画面に出す', (tester) async {
    await tester.pumpWidget(MaterialApp(home: kankenStartupSplash()));

    final paths = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => (i.image as AssetImage).assetName)
        .toList();
    expect(paths, contains('assets/branding/app_icon.png'));
    expect(paths, contains('assets/branding/yourwish_logo.png'));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      kankenSplashBackground,
    );
  });
}
