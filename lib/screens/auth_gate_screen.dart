import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/services_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../views/home_screen.dart';
import 'nickname_setup_screen.dart';

/// アプリ起動時の認証ゲート
///
/// 未ログインなら自動で匿名サインインし、初回はニックネーム設定画面を、
/// 設定済みならホーム画面を表示する。
class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  late final Future<void> _signInFuture;

  @override
  void initState() {
    super.initState();
    _signInFuture = ref.read(authServiceProvider).ensureSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _signInFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingScaffold();
        }
        if (snapshot.hasError) {
          return _ErrorScaffold(onRetry: () => setState(() {}));
        }

        final userAsync = ref.watch(currentUserProvider);
        return userAsync.when(
          data: (user) {
            if (user == null) {
              return NicknameSetupScreen(
                onComplete: () => setState(() {}),
              );
            }
            return const HomeScreen();
          },
          loading: () => const _LoadingScaffold(),
          error: (_, __) => _ErrorScaffold(onRetry: () => setState(() {})),
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorScaffold({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ログインに失敗しました'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('もう一度試す')),
          ],
        ),
      ),
    );
  }
}
