import 'package:flutter/foundation.dart';
import '../../core/constants.dart';

/// What a rewarded ad grants. Labels only — the reward is applied by the caller
/// after [showRewarded] returns true.
enum RewardKind { revive, doubleCoins, bonusCoins }

/// Abstraction so gameplay never imports an ad SDK directly. Swap [StubAdsService]
/// for [GoogleMobileAdsService] with zero changes to callers.
abstract class AdsService {
  bool get available;

  /// Show a rewarded ad. Returns true ONLY if the user finished it and the
  /// reward should be granted. Must be user-initiated (a button), never auto.
  Future<bool> showRewarded(RewardKind kind);

  /// Optional interstitial between runs. Returns when dismissed (or immediately
  /// if unavailable). Never blocks gameplay.
  Future<void> maybeShowInterstitial();

  void dispose() {}
}

/// Review-safe stub: simulates a short rewarded ad, always grants. No network,
/// no SDK, no tracking — guarantees a green build and lets the full UX be demoed.
class StubAdsService implements AdsService {
  @override
  bool get available => K.adsEnabled;

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    if (!K.adsEnabled) return false;
    debugPrint('[ads:stub] rewarded ad for $kind');
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    return true;
  }

  @override
  Future<void> maybeShowInterstitial() async {
    debugPrint('[ads:stub] interstitial');
  }

  @override
  void dispose() {}
}
