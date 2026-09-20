import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob広告まわりの初期化・広告ユニットID管理サービス
///
/// 児童向けアプリのため、常に子供向け設定（非パーソナライズ広告・
/// 年齢制限なしコンテンツ）を強制する。
class AdService {
  AdService._();

  /// アプリ起動時に一度だけ呼び出す
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();

    // 児童向けアプリとして常にタグ付けする（COPPA/ファミリーポリシー対応）。
    // これにより配信される広告は自動的に非パーソナライズ・全年齢向けに限定される。
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );
  }

  /// バナー広告ユニットID（本番用）
  static String get bannerAdUnitId => 'ca-app-pub-5058227312086483/5220932812';

  /// インタースティシャル（全画面）広告ユニットID
  ///
  /// 現在は未使用のためGoogle公式のテスト用IDのまま。
  /// 実際に使用する場合は、AdMob Consoleでインタースティシャル用の
  /// 広告ユニットを別途作成し、そのIDに差し替えること。
  static String get interstitialAdUnitId =>
      'ca-app-pub-3940256099942544/1033173712';

  /// 広告リクエストを生成（児童向け設定を反映）
  static AdRequest buildAdRequest() {
    return const AdRequest(
      nonPersonalizedAds: true,
    );
  }
}
