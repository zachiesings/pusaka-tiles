# Panduan Go-Live — Pusaka Tiles

Checklist final untuk mengubah build dari **mode tes** ke **rilis sungguhan** (AdMob real, App Store / Play Store). Semua kode sudah ada di GitHub & siap dibangun via **GitHub Actions** dan **Codemagic**.

---

## 1. AdMob (ganti dari iklan TES ke iklan SUNGGUHAN)

App pakai **ID iklan tes Google** selama development. Untuk menghasilkan uang, ganti ke ID akun AdMob bos:

1. https://admob.google.com → tambah app **Pusaka Tiles** (iOS & Android).
2. Buat 3 unit iklan: **Banner**, **Interstitial**, **Rewarded**.
3. Edit `lib/core/constants.dart`:
   ```dart
   static const bool useTestAds = false;          // ← dari true ke false
   static const String bannerAdUnit       = 'ca-app-pub-XXXX/BANNER';
   static const String interstitialAdUnit = 'ca-app-pub-XXXX/INTERSTITIAL';
   static const String rewardedAdUnit     = 'ca-app-pub-XXXX/REWARDED';
   ```
4. Ganti **AdMob App ID**:
   - iOS: `ios/Runner/Info.plist` → `GADApplicationIdentifier` (juga ada langkah di `codemagic.yaml`).
   - Android: `android/app/src/main/AndroidManifest.xml` → meta-data `APPLICATION_ID`.

> Penempatan iklan: **Banner** di beranda, **Interstitial** tiap ±2× game-over, **Rewarded** untuk revive (Lanjut) & "Koin Gratis" di Toko Tema.

---

## 2. Build & distribusi
- **GitHub Actions:** push `main` → `build-apk.yml` (APK/AAB) + `ios.yml` (IPA → TestFlight via App Store Connect API key).
- **Codemagic:** `codemagic.yaml` workflow iOS lengkap (signing + upload). Connect repo & jalankan.

---

## 3. App Store (iOS)
1. App **Pusaka Tiles** sudah ada (build masuk TestFlight).
2. Metadata: deskripsi, kata kunci, screenshot, kategori (Games > Music), rating umur.
3. **App Privacy**: deklarasikan data iklan AdMob (Identifiers, Usage Data) + link kebijakan privasi.
4. Submit for Review.

## 4. Play Store (Android)
1. Build AAB → upload ke Play Console.
2. Store listing + Data Safety (AdMob).
3. Submit.

---

✅ **Kode, CI (GitHub + Codemagic), dan AdMob semua sudah terpasang.** Tinggal swap 4 nilai di atas + isi metadata toko.

> Catatan: semua 15 lagu memakai **notasi angka** lagu daerah domain publik (tanpa lirik berhak cipta / audio asli) — semua nada disintesis sendiri. Aman untuk rilis.
