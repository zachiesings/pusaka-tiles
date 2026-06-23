import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants.dart';
import 'ads_service.dart';

/// Real AdMob implementation. The SDK is initialized lazily (first ad request)
/// so app launch never depends on it. All requests are non-personalized → no
/// cross-app tracking → "Not used to track you" in App Privacy, no ATT prompt.
class GoogleMobileAdsService implements AdsService {
  bool _init = false;
  InterstitialAd? _interstitial;

  @override
  bool get available => K.adsEnabled;

  Future<void> _ensureInit() async {
    if (_init) return;
    await MobileAds.instance.initialize();
    _init = true;
  }

  // Google's official TEST units while K.useTestAds is true.
  String get _rewardedUnit {
    if (K.useTestAds) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    return K.rewardedAdUnit;
  }

  String get _interstitialUnit {
    if (K.useTestAds) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-3940256099942544/1033173712';
    }
    return K.interstitialAdUnit;
  }

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    if (!available) return false;
    try {
      await _ensureInit();
    } catch (_) {
      return false; // SDK not ready (e.g. missing app-id) → fail gracefully
    }
    final completer = Completer<bool>();
    await RewardedAd.load(
      adUnitId: _rewardedUnit,
      request: const AdRequest(nonPersonalizedAds: true),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var rewarded = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(rewarded);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (_, __) => rewarded = true);
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  @override
  Future<void> maybeShowInterstitial() async {
    if (!available || !K.interstitialEnabled) return; // Rewarded-only
    if (K.interstitialAdUnit.isEmpty) return;
    try {
      await _ensureInit();
    } catch (_) {
      return;
    }
    final completer = Completer<void>();
    await InterstitialAd.load(
      adUnitId: _interstitialUnit,
      request: const AdRequest(nonPersonalizedAds: true),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    return completer.future;
  }

  @override
  void dispose() {
    _interstitial?.dispose();
  }
}
