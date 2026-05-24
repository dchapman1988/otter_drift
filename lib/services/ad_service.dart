import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

/// Centralized service for managing Google AdMob advertisements.
///
/// This singleton service handles all ad types used in Otter Drift:
/// - **Banner ads**: Displayed at the bottom of menu screens (non-intrusive)
/// - **Interstitial ads**: Full-screen ads shown after game sessions (natural break points)
/// - **Rewarded video ads**: Optional ads that offer in-game rewards (extra lives, bonuses)
///
/// ## Best Practices
///
/// The service follows mobile game monetization best practices:
/// - Ads are placed at natural break points (menu screens, game over)
/// - Rewarded ads provide clear value exchange (extra life for watching ad)
/// - Ad frequency is controlled to maintain good user experience
/// - Test ads are used during development
///
/// ## Usage
///
/// ```dart
/// // Initialize the service (typically in main.dart)
/// await AdService().initialize();
///
/// // Load and show a banner ad
/// final bannerAd = await AdService().loadBannerAd();
///
/// // Load and show an interstitial ad
/// await AdService().loadInterstitialAd();
/// AdService().showInterstitialAd();
///
/// // Load and show a rewarded ad
/// await AdService().loadRewardedAd(
///   onRewarded: () => print('User earned reward!'),
///   onFailed: (error) => print('Ad failed: $error'),
/// );
/// AdService().showRewardedAd();
/// ```
///
/// ## Configuration
///
/// Ad unit IDs are configured in [AdConfig]. Before publishing to production,
/// replace the test ad unit IDs with your actual AdMob ad unit IDs.
///
/// See also:
/// - [AdConfig] for ad unit ID configuration
/// - [BannerAdWidget] for a ready-to-use banner ad widget
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Ad unit IDs - will be loaded from AdConfig
  String? _bannerAdUnitId;
  String? _interstitialAdUnitId;
  String? _rewardedAdUnitId;

  // Callbacks for rewarded ads
  Function()? _onRewardedAdEarnedReward;
  Function(String)? _onRewardedAdFailed;

  /// Initializes the Google Mobile Ads SDK.
  ///
  /// This method should be called once during app startup, typically in [main].
  /// It loads ad unit IDs from [AdConfig] and configures the AdMob SDK.
  ///
  /// In debug mode, test device IDs can be configured for testing purposes.
  ///
  /// Throws an exception if initialization fails. Errors are logged in debug mode.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await AdService().initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load ad unit IDs from config
      _bannerAdUnitId = AdConfig.bannerAdUnitId;
      _interstitialAdUnitId = AdConfig.interstitialAdUnitId;
      _rewardedAdUnitId = AdConfig.rewardedAdUnitId;

      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();

      // Request configuration for test devices (only in debug mode)
      if (kDebugMode) {
        final RequestConfiguration requestConfiguration =
            RequestConfiguration(
          testDeviceIds: [
            // Add your test device IDs here
            // You can get your test device ID from logcat when running the app
          ],
        );
        MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      }

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('AdService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdService: Initialization failed: $e');
      }
    }
  }

  /// Loads a banner advertisement.
  ///
  /// Banner ads are best displayed on menu screens where they don't interrupt
  /// gameplay. The ad is automatically sized and positioned by the widget.
  ///
  /// The loaded [BannerAd] can be displayed using [AdWidget] in a Flutter widget tree.
  ///
  /// Parameters:
  /// - [adSize]: The size of the banner ad (defaults to [AdSize.banner])
  /// - [adRequest]: Optional custom ad request configuration
  ///
  /// Returns the loaded [BannerAd] if successful, or `null` if loading fails
  /// or ad unit ID is not configured.
  ///
  /// Example:
  /// ```dart
  /// final bannerAd = await AdService().loadBannerAd();
  /// if (bannerAd != null) {
  ///   // Display in widget tree using AdWidget(ad: bannerAd)
  /// }
  /// ```
  Future<BannerAd?> loadBannerAd({
    AdSize adSize = AdSize.banner,
    AdRequest? adRequest,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_bannerAdUnitId == null || _bannerAdUnitId!.isEmpty) {
      if (kDebugMode) {
        debugPrint('AdService: Banner ad unit ID not configured');
      }
      return null;
    }

    // Dispose existing banner ad
    _bannerAd?.dispose();

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId!,
      size: adSize,
      request: adRequest ?? const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (kDebugMode) {
            debugPrint('AdService: Banner ad loaded');
          }
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('AdService: Banner ad failed to load: $error');
          }
          ad.dispose();
          _bannerAd = null;
        },
        onAdOpened: (_) {
          if (kDebugMode) {
            debugPrint('AdService: Banner ad opened');
          }
        },
        onAdClosed: (_) {
          if (kDebugMode) {
            debugPrint('AdService: Banner ad closed');
          }
        },
      ),
    );

    await _bannerAd!.load();
    return _bannerAd;
  }

  /// Loads an interstitial (full-screen) advertisement.
  ///
  /// Interstitial ads are best shown at natural break points, such as:
  /// - After a game session ends
  /// - When returning to the main menu
  /// - Between levels or game modes
  ///
  /// The ad is preloaded in the background. Use [showInterstitialAd] to display
  /// it when ready. After showing, a new ad is automatically preloaded.
  ///
  /// Parameters:
  /// - [adRequest]: Optional custom ad request configuration
  ///
  /// Example:
  /// ```dart
  /// // Preload the ad
  /// await AdService().loadInterstitialAd();
  ///
  /// // Later, when appropriate (e.g., after game over)
  /// AdService().showInterstitialAd();
  /// ```
  Future<void> loadInterstitialAd({AdRequest? adRequest}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_interstitialAdUnitId == null || _interstitialAdUnitId!.isEmpty) {
      if (kDebugMode) {
        debugPrint('AdService: Interstitial ad unit ID not configured');
      }
      return;
    }

    // Dispose existing interstitial ad
    _interstitialAd?.dispose();

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId!,
      request: adRequest ?? const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          if (kDebugMode) {
            debugPrint('AdService: Interstitial ad loaded');
          }

          // Set full screen content callback
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              // Preload next interstitial for better UX
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) {
                debugPrint('AdService: Interstitial ad failed to show: $error');
              }
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdShowedFullScreenContent: (ad) {
              if (kDebugMode) {
                debugPrint('AdService: Interstitial ad showed');
              }
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint('AdService: Interstitial ad failed to load: $error');
          }
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Displays a preloaded interstitial ad if available.
  ///
  /// Returns `true` if the ad was successfully shown, `false` if no ad is
  /// available. If no ad is available, a new ad is automatically preloaded
  /// for the next time.
  ///
  /// The ad is displayed as a full-screen overlay. After the user dismisses
  /// the ad, a new interstitial is automatically preloaded.
  ///
  /// Returns:
  /// - `true` if the ad was shown
  /// - `false` if no ad was available (new ad will be preloaded)
  ///
  /// Example:
  /// ```dart
  /// if (AdService().showInterstitialAd()) {
  ///   // Ad was shown
  /// } else {
  ///   // No ad available, continue normally
  /// }
  /// ```
  bool showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      return true;
    }
    if (kDebugMode) {
      debugPrint('AdService: No interstitial ad available to show');
    }
    // Preload for next time
    loadInterstitialAd();
    return false;
  }

  /// Loads a rewarded video advertisement.
  ///
  /// Rewarded ads offer value exchange - users watch an ad in exchange for
  /// in-game rewards such as:
  /// - Extra lives to continue playing
  /// - Bonus points or coins
  /// - Unlockable content
  ///
  /// The ad must be loaded before it can be shown. Use [showRewardedAd] to
  /// display it when ready.
  ///
  /// Parameters:
  /// - [adRequest]: Optional custom ad request configuration
  /// - [onRewarded]: Callback invoked when the user successfully watches the ad
  /// - [onFailed]: Callback invoked if the ad fails to load or show
  ///
  /// Example:
  /// ```dart
  /// await AdService().loadRewardedAd(
  ///   onRewarded: () {
  ///     // Give player an extra life
  ///     player.hearts = 1;
  ///   },
  ///   onFailed: (error) {
  ///     print('Rewarded ad failed: $error');
  ///   },
  /// );
  ///
  /// // Show the ad
  /// AdService().showRewardedAd();
  /// ```
  Future<void> loadRewardedAd({
    AdRequest? adRequest,
    Function()? onRewarded,
    Function(String)? onFailed,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_rewardedAdUnitId == null || _rewardedAdUnitId!.isEmpty) {
      if (kDebugMode) {
        debugPrint('AdService: Rewarded ad unit ID not configured');
      }
      onFailed?.call('Ad unit ID not configured');
      return;
    }

    // Store callbacks
    _onRewardedAdEarnedReward = onRewarded;
    _onRewardedAdFailed = onFailed;

    // Dispose existing rewarded ad
    _rewardedAd?.dispose();

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId!,
      request: adRequest ?? const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          if (kDebugMode) {
            debugPrint('AdService: Rewarded ad loaded');
          }

          // Set full screen content callback
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) {
                debugPrint('AdService: Rewarded ad failed to show: $error');
              }
              ad.dispose();
              _rewardedAd = null;
              _onRewardedAdFailed?.call(error.message);
            },
            onAdShowedFullScreenContent: (ad) {
              if (kDebugMode) {
                debugPrint('AdService: Rewarded ad showed');
              }
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint('AdService: Rewarded ad failed to load: $error');
          }
          _rewardedAd = null;
          _onRewardedAdFailed?.call(error.message);
        },
      ),
    );
  }

  /// Displays a preloaded rewarded ad if available.
  ///
  /// The user must watch the entire ad to earn the reward. The [onRewarded]
  /// callback passed to [loadRewardedAd] is invoked when the user completes
  /// watching the ad.
  ///
  /// Returns `true` if the ad was successfully shown, `false` if no ad is
  /// available. If no ad is available, the [onFailed] callback is invoked.
  ///
  /// Returns:
  /// - `true` if the ad was shown
  /// - `false` if no ad was available
  ///
  /// Example:
  /// ```dart
  /// if (AdService().showRewardedAd()) {
  ///   // Ad is showing, onRewarded will be called when user completes it
  /// } else {
  ///   // No ad available
  /// }
  /// ```
  bool showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          if (kDebugMode) {
            debugPrint(
                'AdService: User earned reward: ${reward.type} ${reward.amount}');
          }
          _onRewardedAdEarnedReward?.call();
        },
      );
      return true;
    }
    if (kDebugMode) {
      debugPrint('AdService: No rewarded ad available to show');
    }
    _onRewardedAdFailed?.call('Ad not loaded');
    return false;
  }

  /// Disposes all loaded advertisements and releases resources.
  ///
  /// This should be called when the app is shutting down or when ads are
  /// no longer needed. Typically, this is handled automatically by Flutter's
  /// widget lifecycle.
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
  }

  /// Whether a banner ad is currently loaded and ready to display.
  bool get isBannerAdLoaded => _bannerAd != null;

  /// Whether an interstitial ad is currently loaded and ready to display.
  bool get isInterstitialAdLoaded => _interstitialAd != null;

  /// Whether a rewarded ad is currently loaded and ready to display.
  bool get isRewardedAdLoaded => _rewardedAd != null;
}

