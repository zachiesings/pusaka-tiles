import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants.dart';
import 'ads_service.dart';

/// Real AdMob implementation — REWARDED-ONLY (no interstitial, no banner).
///
/// Guideline 2.1(a) compliance: the watch-ad button is shown ONLY while
/// [rewardedReady] is true (an ad is actually loaded), and [showRewarded]
/// presents that real ad and grants the reward ONLY on the earned-reward
/// callback. If no ad is loaded the button is hidden and nothing is granted —
/// so a tap can never lead to "no ad shown". A background retry keeps trying to
/// load (no-fill is common for fresh units), and the button appears once a real
/// ad is available.
///
/// All requests are non-personalized → no cross-app tracking, no ATT prompt.
class GoogleMobileAdsService implements AdsService {
  bool _init = false;
  RewardedAd? _rewarded;
  bool _loading = false;
  Timer? _retry;
  final ValueNotifier<bool> _ready = ValueNotifier<bool>(false);

  @override
  bool get available => K.adsEnabled;

  @override
  ValueListenable<bool> get rewardedReady => _ready;

  Future<void> _ensureInit() async {
    if (_init) return;
    await MobileAds.instance.initialize();
    _init = true;
  }

  /// Google's official TEST rewarded unit in debug (so dev always fills); the
  /// real production unit in release. Release never uses a test id.
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
            _ready.value = true; // → button may now appear
          },
          onAdFailedToLoad: (_) {
            _rewarded = null;
            _loading = false;
            _ready.value = false; // no fill → keep the button hidden
            _scheduleRetry();
          },
        ),
      );
    }).catchError((_) {
      _loading = false;
      _ready.value = false;
      _scheduleRetry();
    });
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 30), () {
      if (_rewarded == null) preloadRewarded();
    });
  }

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    final ad = _rewarded;
    if (ad == null) {
      // Should be unreachable (button is hidden when not ready) — never fake it.
      preloadRewarded();
      return false;
    }
    _rewarded = null;
    _ready.value = false; // consumed; hide the button until the next ad loads
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
        if (!completer.isCompleted) completer.complete(false); // show failed → no reward
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }

  @override
  Future<void> maybeShowInterstitial() async {
    // Interstitial intentionally disabled (rewarded-only). Hard no-op.
    return;
  }

  @override
  void dispose() {
    _retry?.cancel();
    _rewarded?.dispose();
    _rewarded = null;
    _ready.dispose();
  }
}
