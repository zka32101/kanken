import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/foundation.dart';

import 'purchases_service.dart';

/// 広告まわりの初期化とAdGate(app_common_kit)の保持。
///
/// 児童向けアプリのため、常に子供向けタグ・最大レーティングG・非パーソナライズ広告を指定する。
/// 表示ルール(うかラボ共通方針): インタースティシャルは演習セッション終了時のみ
/// (最短3分間隔・1日5回)、バナーはホームのみ。出題中は出さない。
/// 広告非表示プラン加入中は広告SDKを初期化せず何も出さない。
class AdService {
  AdService._();

  static AdGate? _gate;

  /// 初期化に失敗した場合はnull（広告なしで動作を続ける）。
  static AdGate? get gate => _gate;

  /// 広告ユニットID（デバッグ時はGoogle公式テストID、リリースビルドは本番ID）
  static AdUnitIds get unitIds => kReleaseMode
      ? const AdUnitIds(
          banner: 'ca-app-pub-5058227312086483/5220932812',
          // 2026-10-01 AdMob Consoleで作成(広告ユニット名 interstitial_practice_session)。
          // 新規作成した広告ユニットは配信開始まで最大1時間程度かかる場合がある。
          interstitial: 'ca-app-pub-5058227312086483/4433430916',
          // リワード広告は未使用。テストIDを避けるためダミーの本番形式IDを置く。
          rewarded: 'ca-app-pub-5058227312086483/0000000000',
        )
      : const AdUnitIds(
          banner: 'ca-app-pub-3940256099942544/6300978111',
          interstitial: 'ca-app-pub-3940256099942544/1033173712',
          rewarded: 'ca-app-pub-3940256099942544/5224354917',
        );

  /// アプリ起動時に一度だけ呼ぶ。[PurchasesService.initialize] の後に呼ぶこと。
  static Future<void> initialize() async {
    try {
      _gate = await AdGate.init(
        config: AdConfig(
          unitIds: unitIds,
          childDirected: true,
          maxAdContentRating: AdContentRating.g,
          nonPersonalizedAds: true,
        ),
        adsHidden: () => PurchasesService.entitlement?.state.adsHidden ?? false,
      );
    } catch (e) {
      debugPrint('AdService.initialize failed: $e');
    }
  }
}
