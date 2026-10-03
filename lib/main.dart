import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_common_kit/app_common_kit.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/ad_service.dart';
import 'services/purchases_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化
  // google-services.jsonが存在する場合、ネイティブ側(FirebaseInitProvider)が
  // アプリ起動時に自動でデフォルトアプリを初期化する。この時点ではDart側の
  // Firebase.appsキャッシュがネイティブ状態と同期していないため isEmpty
  // チェックだけでは防げず、initializeApp呼び出し自体が
  // 「A Firebase App named "[DEFAULT]" already exists」で失敗する
  // (未捕捉例外のため、リリースビルドではスプラッシュ画面のままフリーズして見える)。
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // サブスクリプション（広告非表示プラン）初期化
  await PurchasesService.initialize();

  // 広告初期化（児童向け設定を含む。権利状態に依存するため購入初期化の後）
  await AdService.initialize();

  // 学習コイン（app_common_kit）。財布はアプリごと。端末内に保存する。
  // コインは学習の成長でのみ獲得する（課金・広告視聴での付与はしない）。
  final coinService = CoinService(
    store: SharedPreferencesCoinStore('kanken'),
    shop: OutfitCatalog.shopItems([UkalabCert.kanjiKentei]),
  );
  await coinService.load();
  // 衣装（着替え・ショップ。合格記念・準備完了の解放もここに保存する）
  final outfitService =
      OutfitService(store: SharedPreferencesOutfitStore('kanken'));
  await outfitService.load();

  // 全アプリ共通フィードバック機能(app_common_kit)の送信処理を注入
  final container = ProviderContainer(
    overrides: [
      coinServiceProvider.overrideWithValue(coinService),
      outfitServiceProvider.overrideWithValue(outfitService),
    ],
  );
  container.read(feedbackProvider.notifier).setSubmitHandler((report) async {
    await FirebaseFirestore.instance
        .collection('feedback')
        .doc(report.id)
        .set(report.toJson());
  });
  // 未送信分の再送信を試みる(オフライン等で失敗した報告のリトライ)
  unawaited(container.read(feedbackProvider.notifier).retryPendingReports());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'うかラボ漢字検定',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
