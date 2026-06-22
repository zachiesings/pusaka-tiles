import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/constants.dart';

/// A self-contained banner ad bar. Loads a standard 320x50 banner (test unit
/// while K.useTestAds) and shows nothing until it's ready, so layout never jumps
/// awkwardly. Safe no-op when ads are disabled.
class BannerAdBar extends StatefulWidget {
  const BannerAdBar({super.key});

  @override
  State<BannerAdBar> createState() => _BannerAdBarState();
}

class _BannerAdBarState extends State<BannerAdBar> {
  BannerAd? _ad;
  bool _loaded = false;

  String get _unit {
    if (K.useTestAds) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    return K.bannerAdUnit;
  }

  @override
  void initState() {
    super.initState();
    if (K.adsEnabled) _load();
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: _unit,
      size: AdSize.banner,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox(height: 50);
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
