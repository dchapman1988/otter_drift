import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode;

/// AdMob ad unit IDs.
///
/// In release builds, real ad unit IDs MUST be supplied via `--dart-define`:
///   --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXX/YYYY
///   --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXXX/YYYY
///   --dart-define=ADMOB_REWARDED_ID=ca-app-pub-XXXX/YYYY
///
/// Without these, debug builds fall back to Google's test unit IDs.
class AdConfig {
  static const String _envBannerId =
      String.fromEnvironment('ADMOB_BANNER_ID');
  static const String _envInterstitialId =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
  static const String _envRewardedId =
      String.fromEnvironment('ADMOB_REWARDED_ID');

  // Google's official test ad unit IDs (safe to ship, only serve test ads).
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testBannerIos =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  static String get bannerAdUnitId =>
      _envBannerId.isNotEmpty ? _envBannerId : _testBanner;
  static String get interstitialAdUnitId =>
      _envInterstitialId.isNotEmpty ? _envInterstitialId : _testInterstitial;
  static String get rewardedAdUnitId =>
      _envRewardedId.isNotEmpty ? _envRewardedId : _testRewarded;

  static String get _testBanner =>
      Platform.isIOS ? _testBannerIos : _testBannerAndroid;
  static String get _testInterstitial =>
      Platform.isIOS ? _testInterstitialIos : _testInterstitialAndroid;
  static String get _testRewarded =>
      Platform.isIOS ? _testRewardedIos : _testRewardedAndroid;

  /// True when shipping a release build without real ad IDs configured.
  /// Used to surface misconfiguration during release QA.
  static bool get isMisconfiguredForRelease =>
      kReleaseMode &&
      (_envBannerId.isEmpty ||
          _envInterstitialId.isEmpty ||
          _envRewardedId.isEmpty);
}
