import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/purchases_service.dart';

/// 広告非表示（サブスク加入中）かどうか。
/// RevenueCat未設定（APIキー未差し替え）の間は常にfalse＝広告表示。
final hasAdsRemovedProvider = FutureProvider<bool>((ref) async {
  return PurchasesService.hasAdsRemoved();
});

/// 購入可能なパッケージ一覧（月額・年額プラン）
final availablePackagesProvider = FutureProvider<List<Package>>((ref) async {
  return PurchasesService.getAvailablePackages();
});

/// 購入処理の状態管理
final purchaseProvider =
    StateNotifierProvider<PurchaseNotifier, AsyncValue<bool>>(
  (ref) => PurchaseNotifier(ref),
);

class PurchaseNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;
  PurchaseNotifier(this._ref) : super(const AsyncValue.data(false));

  Future<void> purchasePackage(Package package) async {
    state = const AsyncValue.loading();
    try {
      final success = await PurchasesService.purchasePackage(package);
      state = AsyncValue.data(success);
      if (success) {
        _ref.invalidate(hasAdsRemovedProvider);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> restore() async {
    state = const AsyncValue.loading();
    try {
      final success = await PurchasesService.restorePurchases();
      state = AsyncValue.data(success);
      if (success) {
        _ref.invalidate(hasAdsRemovedProvider);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(false);
  }
}
