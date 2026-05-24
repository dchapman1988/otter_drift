import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// A reusable widget for displaying banner advertisements.
///
/// This widget automatically loads and displays a banner ad from AdMob.
/// It's designed to be placed at the bottom of menu screens where ads
/// don't interrupt gameplay.
///
/// ## Best Practices
///
/// - Place at the bottom of menu screens (main menu, profile, leaderboard, etc.)
/// - Do not display during active gameplay
/// - The widget automatically handles ad loading and error states
/// - Returns an empty widget if no ad is available (prevents layout shift)
///
/// ## Usage
///
/// ```dart
/// Scaffold(
///   body: Column(
///     children: [
///       // Your content here
///       Expanded(child: YourContent()),
///       // Banner ad at bottom
///       BannerAdWidget(),
///     ],
///   ),
/// )
/// ```
///
/// ## Customization
///
/// You can customize the ad size and background:
///
/// ```dart
/// BannerAdWidget(
///   adSize: AdSize.largeBanner,
///   showBackground: false,
/// )
/// ```
///
/// See also:
/// - [AdService] for ad management
/// - [AdConfig] for ad unit ID configuration
class BannerAdWidget extends StatefulWidget {
  /// The size of the banner ad.
  ///
  /// Defaults to [AdSize.banner]. Other common sizes include:
  /// - [AdSize.largeBanner] - Larger banner (320x100)
  /// - [AdSize.mediumRectangle] - Medium rectangle (300x250)
  final AdSize adSize;

  /// Whether to show a background container around the ad.
  ///
  /// When `true`, displays a subtle background with border to visually
  /// separate the ad from content. Defaults to `true`.
  final bool showBackground;

  /// Creates a banner ad widget.
  ///
  /// The ad will be automatically loaded when the widget is initialized.
  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.showBackground = true,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    final adService = AdService();
    final bannerAd = await adService.loadBannerAd(adSize: widget.adSize);

    if (bannerAd != null && mounted) {
      setState(() {
        _bannerAd = bannerAd;
        _isAdLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      // Return empty container if ad not loaded (prevents layout shift)
      return const SizedBox.shrink();
    }

    // Get the ad size dimensions
    final adHeight = _bannerAd!.size.height.toDouble();
    final adWidth = _bannerAd!.size.width.toDouble();
    
    // Use full width with proper constraints, centered content
    return Container(
      width: double.infinity,
      height: adHeight,
      alignment: Alignment.center,
      decoration: widget.showBackground
          ? BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            )
          : null,
      child: Center(
        child: SizedBox(
          width: adWidth,
          height: adHeight,
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}

