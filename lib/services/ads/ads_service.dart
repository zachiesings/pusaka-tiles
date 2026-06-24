import 'package:flutter/foundation.dart';
import '../../core/constants.dart';

/// What a rewarded ad grants. Labels only — the reward is applied by the caller
/// after [showRewarded] resolves true.
enum RewardKind { revive, doubleCoins, bonusCoins }

/// Abstraction so gameplay never imports an ad SDK directly. Swap [StubAdsService]
/// for [GoogleMobileAdsService] with zero changes to callers.
///
/// Monetisation is REWARDED-ONLY: there is no interstitial and no banner.
abstract class AdsService {
  bool get available;

  /// True when a rewarded ad is already loaded and can be shown instantly.
  /// The UI uses this to show a brief "memuat iklan…" state when false.
  bool get rewardedReady;

  /// Warm up a rewarded ad ahead of time (e.g. when the game screen opens) so
  /// the watch-ad button is instant. Safe to call repeatedly; a no-op if one is
  /// already loaded or loading.
  void preloadRewarded();

  /// Show a rewarded ad. Designed so the caller's button NEVER silently no-ops:
  ///  • a preloaded ad is shown → resolves true once the reward is earned;
  ///  • no ad is ready → it waits briefly for a fresh load;
  ///  • no-fill / timeout / SDK error → it GRANTS ANYWAY (resolves true).
  /// Resolves false only when the user dismissed a shown ad before earning.
  /// Must be user-initiated (a button), never auto.
  Future<bool> showRewarded(RewardKind kind);

  /// Interstitial is intentionally disabled (rewarded-only). Hard no-op; kept so
  /// existing callers compile. Never shows anything.
  Future<void> maybeShowInterstitial();

  void dispose() {}
}

/// Review-safe stub: simulates a short rewarded ad and always grants. No network,
/// no SDK, no tracking. Used only when [K.adsEnabled] is false.
class StubAdsService implements AdsService {
  @override
  bool get available => K.adsEnabled;

  @override
  bool get rewardedReady => true;

  @override
  void preloadRewarded() {}

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    debugPrint('[ads:stub] rewarded ad for $kind');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return true;
  }

  @override
  Future<void> maybeShowInterstitial() async {}

  @override
  void dispose() {}
}
