import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants.dart';
import 'ads_service.dart';

/// Real AdMob implementation — REWARDED-ONLY (no interstitial, no banner).
///
/// The SDK is initialized lazily (first request) so app launch never depends on
/// it. All requests are non-personalized → no cross-app tracking → "Not used to
/// track you" in App Privacy, and no ATT prompt is needed.
///
/// Critically, [showRewarded] always resolves to a usable result: if a brand-new
/// ad unit returns no-fill (common for hours/days after creation), or the SDK
/// errors, or loading times out, it GRANTS THE REWARD ANYWAY so the watch-ad
/// button can never silently do nothing (the cause of the 2.1(a) rejection).
class GoogleMobileAdsService implements AdsService {
  bool _init = false;
  RewardedAd? _rewarded;
  bool _loading = false;

  static const Duration _loadTimeout = Duration(seconds: 7);

  @override
  bool get available => K.adsEnabled;

  @override
  bool get rewardedReady => _rewarded != null;

  Future<void> _ensureInit() async {
    if (_init) return;
    await MobileAds.instance.initialize();
    _init = true;
  }

  /// Google's official TEST rewarded unit in debug builds (so dev always fills),
  /// the real production unit in release. Release never uses a test id.
  String get _rewardedUnit {
    if (kDebugMode || K.useTestAds) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    return K.rewardedAdUnit;
  }

  @override
  void preloadRewarded() {
    if (!available || _rewarded != null || _loading) return;
    _loading = true;
    _ensureInit().then((_) {
      RewardedAd.load(
        adUnitId: _rewardedUnit,
        request: const AdRequest(nonPersonalizedAds: true),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewarded = ad;
            _loading = false;
          },
          onAdFailedToLoad: (_) {
            _rewarded = null;
            _loading = false; // leave the button to fall back to a grant
          },
        ),
      );
    }).catchError((_) {
      _loading = false;
    });
  }

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    if (!available) return true; // ads off → never block the user's action
    try {
      await _ensureInit();
    } catch (_) {
      return true; // SDK unavailable → grant so the button still works
    }

    // Make sure we have (or briefly wait for) an ad.
    if (_rewarded == null) {
      preloadRewarded();
      await _waitForLoad(_loadTimeout);
    }
    if (_rewarded == null) {
      return true; // no-fill / timeout → grant anyway (never a dead button)
    }

    final ad = _rewarded!;
    _rewarded = null; // consume
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewarded(); // warm up the next one
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        preloadRewarded();
        if (!completer.isCompleted) completer.complete(true); // show failed → grant
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }

  /// Poll until a rewarded ad finishes loading or [timeout] elapses.
  Future<void> _waitForLoad(Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (_rewarded == null && _loading && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  @override
  Future<void> maybeShowInterstitial() async {
    // Interstitial intentionally disabled (rewarded-only). Hard no-op.
    return;
  }

  @override
  void dispose() {
    _rewarded?.dispose();
    _rewarded = null;
  }
}
