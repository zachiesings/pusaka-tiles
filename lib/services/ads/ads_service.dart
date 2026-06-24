import 'package:flutter/foundation.dart';
import '../../core/constants.dart';

/// What a rewarded ad grants. Labels only — the reward is applied by the caller
/// after [showRewarded] resolves true (i.e. the ad was actually shown + earned).
enum RewardKind { revive, doubleCoins, bonusCoins }

/// Abstraction so gameplay never imports an ad SDK directly.
///
/// Monetisation is REWARDED-ONLY (no interstitial, no banner). Guideline 2.1(a):
/// a watch-ad button must only ever lead to a REAL ad. So the UI shows the
/// button only while [rewardedReady] is true, and [showRewarded] NEVER grants a
/// reward unless an ad was actually presented and the reward was earned.
abstract class AdsService {
  bool get available;

  /// Reactive readiness — true ONLY when a rewarded ad is loaded and can be
  /// presented right now. The UI gates the watch-ad button on this, so tapping
  /// always shows an ad (no dead button, no "ad didn't show").
  ValueListenable<bool> get rewardedReady;

  /// Warm up a rewarded ad and keep retrying in the background until one loads.
  void preloadRewarded();

  /// Present the already-loaded rewarded ad. Resolves true ONLY if the user
  /// earned the reward (ad shown to completion). Resolves false if there is no
  /// ad, the show fails, or the user dismissed early — and grants NOTHING in
  /// those cases.
  Future<bool> showRewarded(RewardKind kind);

  /// Interstitial intentionally disabled (rewarded-only). Hard no-op.
  Future<void> maybeShowInterstitial();

  void dispose() {}
}

/// Review-safe stub: used only when [K.adsEnabled] is false. Pretends an ad is
/// always ready and "shown". Never used in production.
class StubAdsService implements AdsService {
  final ValueNotifier<bool> _ready = ValueNotifier<bool>(true);

  @override
  bool get available => K.adsEnabled;

  @override
  ValueListenable<bool> get rewardedReady => _ready;

  @override
  void preloadRewarded() => _ready.value = true;

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    debugPrint('[ads:stub] rewarded ad for $kind');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return true;
  }

  @override
  Future<void> maybeShowInterstitial() async {}

  @override
  void dispose() => _ready.dispose();
}
