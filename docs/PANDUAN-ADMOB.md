# Panduan AdMob — Pusaka Tiles

Sekarang game memakai **unit iklan TEST resmi Google** (aman disubmit). Iklan asli
aktif setelah langkah berikut.

## 1. Buat app di AdMob
1. https://admob.google.com → **Apps → Add app**, buat untuk **Android** & **iOS**.
2. Catat **App ID** tiap platform (`ca-app-pub-XXXX~YYYY`).

## 2. Buat unit iklan
Per platform, buat lalu catat id-nya (`ca-app-pub-XXXX/ZZZZ`):
- **Rewarded** (tombol "Lanjut — Tonton Iklan")
- **Interstitial**
- **Banner** (opsional)

## 3. Tempel ID ke kode
Edit `lib/core/constants.dart`:
```dart
static const bool useTestAds = false;     // ubah ke false
static const String rewardedAdUnit     = 'ca-app-pub-XXXX/REWARDED';
static const String interstitialAdUnit = 'ca-app-pub-XXXX/INTERSTITIAL';
static const String bannerAdUnit       = 'ca-app-pub-XXXX/BANNER';
```

## 4. Tempel App ID ke CI
- **Android** — `.github/workflows/build-apk.yml`: ganti nilai test
  `ca-app-pub-3940256099942544~3347511713` (cari `APPLICATION_ID`).
- **iOS** — `codemagic.yaml`: ganti `GADApplicationIdentifier` test
  `ca-app-pub-3940256099942544~1458002511`.

## 5. App Privacy / Data Safety
Iklan **non-personalized** → App Store boleh "Not used to track you"; Play Console
deklarasikan AdMob seperti biasa.
