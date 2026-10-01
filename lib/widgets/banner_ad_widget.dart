import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/purchases_provider.dart';
import '../services/ad_service.dart';

/// 再利用可能なバナー広告ウィジェット
///
/// 読み込みに失敗した場合や読み込み中は何も表示しない
/// （レイアウトが崩れないよう、読み込み完了後にのみ広告サイズ分の領域を確保する）。
/// サブスク加入中（広告非表示）のユーザーには表示しない。
class BannerAdWidget extends ConsumerWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAdsRemoved = ref.watch(hasAdsRemovedProvider).valueOrNull ?? false;
    if (hasAdsRemoved) return const SizedBox.shrink();
    return const _BannerAdWidgetInner();
  }
}

class _BannerAdWidgetInner extends StatefulWidget {
  const _BannerAdWidgetInner();

  @override
  State<_BannerAdWidgetInner> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidgetInner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: AdService.buildAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd = bannerAd;
    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;
    if (bannerAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }
}
