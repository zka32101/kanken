import 'dart:async';

import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 学習コインを共通アカウント（Firestore）と同期する。
///
/// サインインした（匿名でも可）とき・アプリに戻ったときに、台帳を統合する。
/// 同期は [minInterval] 以内の再実行を自動でスキップし、失敗（オフライン等）でも例外は出さない。
/// 未ログイン・Firebase 未初期化のときは何もしない。コインの付与は端末内で完結するので、
/// 同期できなくても学習には影響しない。
class CoinSyncService with WidgetsBindingObserver {
  CoinSyncService({
    required this.container,
    required this.userChanges,
    CoinRemote Function(String uid)? remoteFor,
    this.minInterval = const Duration(minutes: 5),
  }) : _remoteFor = remoteFor ??
            ((uid) => FirebaseCoinRemote(uid: uid, examId: UkalabCert.kanjiKentei.id));

  final ProviderContainer container;
  /// ログイン中ユーザーの uid（未ログインは null）の流れ。
  final Stream<String?> userChanges;
  final Duration minInterval;
  final CoinRemote Function(String uid) _remoteFor;

  StreamSubscription<String?>? _sub;
  String? _uid;

  void start() {
    _sub ??= userChanges.listen((uid) {
      _uid = uid;
      unawaited(syncNow());
    }, onError: (_) {});
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(syncNow());
  }

  /// 今すぐ同期する（購入の直後などに呼べる）。間隔内・未ログイン・失敗のときは何もしない。
  Future<CoinSyncResult?> syncNow({bool force = false}) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      return await container.read(coinProvider.notifier).syncWith(
            _remoteFor(uid),
            minInterval: force ? Duration.zero : minInterval,
          );
    } catch (_) {
      return null;
    }
  }
}
