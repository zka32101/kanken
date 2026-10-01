import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat経由のサブスクリプション管理（広告非表示プラン）。
///
/// 参考実装: H:\マイドライブ\apps\card_rivals\lib\services\purchases_service.dart
///
/// 【要ユーザー対応】
/// RevenueCatダッシュボードで kanken 用の新規Appを作成し、
/// 以下を設定した上で `_apiKey` を実際のPublic SDK Keyに差し替えること:
///   - Google Play Console側でサブスクリプション商品を作成
///     (premium-monthly: 月額¥300 / premium-yearly: 年額¥2,400)
///   - RevenueCatのEntitlement「ad_free」に上記2商品を紐付け
///   - Offering「default」にpremium-monthly/premium-yearlyのPackageを追加
class PurchasesService {
  static const String _apiKey = 'goog_TFqirXGziXwifqVBVasvYInzHEp';

  static const String entitlementAdFree = 'ad_free';
  static const String premiumMonthly = 'premium-monthly';
  static const String premiumYearly = 'premium-yearly';

  static bool _initialized = false;

  /// RevenueCat 初期化（main.dartから起動時に一度だけ呼ぶ）
  static Future<void> initialize() async {
    if (_apiKey.startsWith('REPLACE_WITH_')) {
      // APIキー未設定の間はRevenueCatへ接続しない（クラッシュ防止）。
      // 広告非表示チェックは常にfalse（＝広告表示）として扱われる。
      return;
    }
    try {
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  static bool get isConfigured => _initialized;

  /// 利用可能な商品パッケージ（月額・年額）を取得
  static Future<List<Package>> getAvailablePackages() async {
    if (!_initialized) return [];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  /// 商品を購入
  static Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 購入の復元
  static Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(entitlementAdFree);
    } catch (_) {
      return false;
    }
  }

  /// 広告非表示エンタイトルメントを保持しているか
  static Future<bool> hasAdsRemoved() async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(entitlementAdFree);
    } catch (_) {
      return false;
    }
  }
}
