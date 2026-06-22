# Pusaka Tiles

Game **piano-tiles** bertema Nusantara: ketuk ubin batik di lajur yang benar
mengikuti irama, dan tiap ketukan memainkan **nada melodi lagu daerah** (notasi
angka). Salah ketuk atau terlewat = selesai. Makin lama makin cepat. Monetisasi
lewat **AdMob** (rewarded ad untuk lanjut + interstitial).

Lagu (melodi rakyat/anak, public domain): Cicak-Cicak di Dinding, Burung Kakak
Tua, Ampar-Ampar Pisang, Cublak-Cublak Suweng. Semua **nada disintesis sendiri**
(lihat `tool/make_notes.py`) — tidak ada rekaman berhak cipta.

## Struktur repo
Repo hanya menyimpan `lib/` + `assets/` + konfigurasi CI. Folder native
(`android/`, `ios/`) digenerate CI via `flutter create` (lihat `.gitignore`).

```
lib/
  core/        konstanta, tema batik
  game/        model lagu + tabel nada + engine tiles (ada unit test)
  state/       AppState (best per lagu) + TilesGameController (loop game)
  services/    ads (AdMob) + audio (nada) + storage
  widgets/     pelukis papan tiles + latar batik
  features/    home (pilih lagu) / game / settings / about
```

## Build
- **Android:** GitHub Actions `.github/workflows/build-apk.yml` (APK + AAB).
- **iOS / TestFlight:** Codemagic `codemagic.yaml` (App Store Connect API key).

## AdMob
Pakai unit iklan **TEST** Google dulu (`K.useTestAds = true`). Lihat
[`docs/PANDUAN-ADMOB.md`](docs/PANDUAN-ADMOB.md) untuk pasang iklan asli.
