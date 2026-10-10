import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_common_kit/app_common_kit.dart';
import '../providers/purchases_provider.dart';
import '../services/purchases_service.dart';
import '../theme/app_theme.dart';
import '../widgets/parental_gate_dialog.dart';

/// サブスクリプション（広告非表示プラン）の購入画面。
/// 月額¥300 / 年額¥2,400。
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAdsRemovedAsync = ref.watch(hasAdsRemovedProvider);
    final packagesAsync = ref.watch(availableOffersProvider);
    final purchaseState = ref.watch(purchaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プレミアムプラン'),
        centerTitle: true,
      ),
      body: hasAdsRemovedAsync.when(
        data: (hasAdsRemoved) {
          if (hasAdsRemoved) {
            return _buildAlreadySubscribed(context);
          }
          return _buildPaywallContent(context, ref, packagesAsync, purchaseState);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
      ),
    );
  }

  Widget _buildAlreadySubscribed(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'ご加入ありがとうございます！',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'プレミアムプランが有効です。広告なしで学習でき、準1級・1級も利用できます。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<EntitlementOffer>> packagesAsync,
    AsyncValue<bool> purchaseState,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.block, size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          '広告を非表示にする',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '演習中のバナー広告・インタースティシャル広告が表示されなくなります。\n集中して学習したい方におすすめです。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 28),
        packagesAsync.when(
          data: (packages) {
            if (packages.isEmpty) {
              return _buildUnavailableNotice();
            }
            return Column(
              children: packages.map((p) => _buildPlanCard(context, ref, p)).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => _buildUnavailableNotice(),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: purchaseState.isLoading
                ? null
                : () async {
                    await ref.read(purchaseProvider.notifier).restore();
                    if (context.mounted) {
                      final restored = ref.read(purchaseProvider).valueOrNull ?? false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(restored ? '購入を復元しました' : '復元できる購入が見つかりませんでした'),
                        ),
                      );
                    }
                  },
            child: const Text('購入を復元する'),
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '現在プランを取得できません。しばらくしてから再度お試しください。',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54, fontSize: 13),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, WidgetRef ref, EntitlementOffer offer) {
    final isYearly = offer.productId.contains(PurchasesService.premiumYearly);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isYearly ? const BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isYearly ? '年額プラン' : '月額プラン',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'おすすめ',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.priceString,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: ref.watch(purchaseProvider).isLoading
                  ? null
                  : () async {
                      final passedGate = await requireParentalGate(context);
                      if (!passedGate || !context.mounted) return;
                      await ref.read(purchaseProvider.notifier).purchaseOffer(offer.id);
                      final success = ref.read(purchaseProvider).valueOrNull ?? false;
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ご購入ありがとうございます！')),
                        );
                      }
                    },
              child: const Text('選択'),
            ),
          ],
        ),
      ),
    );
  }
}
