import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/ad_service.dart';

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

  // 広告初期化（児童向け設定を含む）
  await AdService.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '漢検チャレンジ',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
