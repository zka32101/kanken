import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
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

  /// バナー広告ユニットID（デバッグ時はGoogle公式テストID、リリースビルドは本番ID）
  static String get bannerAdUnitId => kReleaseMode
      ? 'ca-app-pub-5058227312086483/5220932812'
      : 'ca-app-pub-3940256099942544/6300978111';

  /// インタースティシャル（全画面）広告ユニットID
  ///
  /// 【要ユーザー対応】本番IDは未作成。AdMob Consoleでkankenアプリ
  /// (ca-app-pub-5058227312086483)配下にインタースティシャル広告ユニットを
  /// 新規作成し、下記のTODO部分を実際のユニットIDに差し替えること。
  /// 差し替えるまではリリースビルドでもテストIDのまま動作する（広告は表示されるが収益にはならない）。
  static String get interstitialAdUnitId => kReleaseMode
      ? 'ca-app-pub-3940256099942544/1033173712' // TODO: 本番インタースティシャルIDに差し替える
      : 'ca-app-pub-3940256099942544/1033173712';

  /// 広告リクエストを生成（児童向け設定を反映）
  static AdRequest buildAdRequest() {
    return const AdRequest(
      nonPersonalizedAds: true,
    );
  }
}

/// インタースティシャル広告の読み込み・表示・セッション数カウントを管理するクラス。
///
/// 演習・模擬試験の最中には広告を出さない方針(うかラボ共通方針)のため、
/// 出題のたびではなく「セッション(演習1回分、または模擬試験の結果画面)が
/// 終わるたびに呼ぶ」運用とする。表示頻度(sessionInterval相当)は
/// Remote Configの`interstitial_session_interval`キーで調整できる
/// (未設定時は[defaultSessionInterval]回に1回)。
///
/// 使い方:
///   final manager = InterstitialAdManager();
///   manager.preload(); // 画面表示時に先読み
///   ...
///   await manager.maybeShowAfterSession(); // 演習セッション・模擬試験結果表示後に呼ぶ
class InterstitialAdManager {
  InterstitialAdManager({this.remoteConfig});

  /// 未指定の場合はFirebaseRemoteConfig.instanceを使う(テスト時にモック差し替え可能にするため)
  final FirebaseRemoteConfig? remoteConfig;

  static const int defaultSessionInterval = 3;
  static const String remoteConfigKey = 'interstitial_session_interval';

  InterstitialAd? _ad;
  bool _isLoading = false;
  int _sessionCount = 0;

  int get _sessionInterval {
    try {
      final value = (remoteConfig ?? FirebaseRemoteConfig.instance).getInt(remoteConfigKey);
      return value > 0 ? value : defaultSessionInterval;
    } catch (_) {
      return defaultSessionInterval;
    }
  }

  /// 広告を先読みしておく（次に表示するタイミングで即座に出せるように）
  void preload() {
    if (_ad != null || _isLoading) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdService.interstitialAdUnitId,
      request: AdService.buildAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// 演習セッション・模擬試験結果表示など「ひと区切り」の終わりに呼ぶ。
  /// sessionInterval回に1回、広告を表示する。
  /// 広告が表示された場合はtrueを返す（呼び出し側で画面遷移等を一時止める場合の判定に使える）。
  Future<bool> maybeShowAfterSession() async {
    _sessionCount++;
    if (_sessionCount % _sessionInterval != 0) {
      return false;
    }
    return _show();
  }

  Future<bool> _show() async {
    final ad = _ad;
    if (ad == null) {
      preload();
      return false;
    }
    _ad = null;

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await ad.show();
    return completer.future;
  }

  /// カウンタをリセット（必要に応じて呼ぶ。通常は呼ばなくてよい）
  void reset() {
    _sessionCount = 0;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
