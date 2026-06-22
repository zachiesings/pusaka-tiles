# Panduan TestFlight — Pusaka Tiles

Bundle ID `id.pusakatiles.pusakatiles` **sudah didaftarkan** (via ASC API), jadi
langsung muncul di dropdown saat membuat app. Tinggal 2 langkah:

## Langkah A — Buat record app di App Store Connect (±2 menit)
1. Buka https://appstoreconnect.apple.com → **Apps** → tombol **“+” → New App**.
2. **Platform:** iOS
3. **Name:** Pusaka Tiles
4. **Primary Language:** Indonesian (Bahasa Indonesia)
5. **Bundle ID:** pilih `id.pusakatiles.pusakatiles` (sudah ada di daftar)
6. **SKU:** bebas, mis. `pusakatiles001`
7. **User Access:** Full Access → **Create**

## Langkah B — Hubungkan ke Codemagic & build
1. Buka https://codemagic.io → login (akun yang sama dgn Beat Nusantara).
2. **Add application → GitHub →** pilih repo `zachiesings/pusaka-tiles`.
   Codemagic otomatis membaca `codemagic.yaml`.
3. Pastikan **environment variables** ini ada (boleh pakai group yang sama
   seperti Beat Nusantara — nilainya identik):
   - `APP_STORE_CONNECT_PRIVATE_KEY` = isi file `AuthKey_DK5TAZT3F9.p8`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER` = `DK5TAZT3F9`
   - `APP_STORE_CONNECT_ISSUER_ID` = `cdaa6ed4-07f4-4151-ac76-eb1e66b6effb`
   - `CERTIFICATE_PRIVATE_KEY` = (sama seperti Beat Nusantara)
4. **Start new build** → pilih workflow **`ios-appstore`**.
5. Build menandatangani + meng-upload ke TestFlight otomatis
   (`submit_to_testflight: true`). Notifikasi email ke `asd95179517@gmail.com`.

## Langkah C — biar aku yang handle (via ASC API)
Begitu build muncul di App Store Connect, kabari aku — aku akan:
- daftarkan emailmu sebagai **TestFlight tester** (internal) → kamu dapat undangan,
- cek status pemrosesan build,
- (nanti) tambahkan Sean `kai.s.m@icloud.com` saat kamu kasih aba-aba.
