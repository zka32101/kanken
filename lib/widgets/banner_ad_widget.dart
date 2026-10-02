import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchases_provider.dart';
import '../services/ad_service.dart';

/// ホーム画面下部のバナー広告（AdGate経由）。
/// 広告非表示プラン加入中・読み込み前・初期化失敗時は何も表示しない。
class BannerAdWidget extends ConsumerWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAdsRemoved = ref.watch(hasAdsRemovedProvider).valueOrNull ?? false;
    if (hasAdsRemoved) return const SizedBox.shrink();
    return AdService.gate?.banner(BannerPlacement.home) ?? const SizedBox.shrink();
  }
}
