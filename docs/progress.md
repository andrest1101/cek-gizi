# Progress — CekGizi

Catatan kerja per batch (PRD §10). Setiap dependency baru WAJIB dicatat di sini dengan alasannya (PRD constraint #5). Jangan hapus entri lama.

## Info proyek

- **Nama aplikasi:** CekGizi (nama kerja lama "BebasStunting" diganti — keputusan pemilik, 2026-11-10)
- **Sumber kebenaran:** `PRD.md` v2.0
- **Branch kerja:** `feature/app4-mvp` (JANGAN merge ke `main`)
- **Platform:** Flutter — Android dulu, iOS menyusul (PRD §0)
- **Backend:** Supabase (Auth anonim + Postgres/RLS + Edge Functions). Gemini TIDAK dipanggil dari aplikasi.

## Batch 0 — Fondasi (2026-11-10)

### Baseline sebelum Batch 0
- Scaffold Flutter default (counter app di `lib/main.dart`), package `bebas_stunting`.
- Folder kosong `lib/features/feat/{data,domain,presentation}` (tidak sesuai clean architecture; dihapus).
- Tidak ada `core/`, `shared/`, `assets/`, `docs/`, `supabase/`, CI, atau dokumentasi progress.

### Perubahan
1. **Identitas → CekGizi**
   - `pubspec.yaml`: `name: cekgizi`, deskripsi produk sesuai PRD.
   - Android: `namespace`/`applicationId` = `com.example.cekgizi` (folder `MainActivity.kt` dipindah), `android:label` = `CekGizi`.
   - iOS: `CFBundleDisplayName`/`CFBundleName` = `CekGizi`, bundle id = `com.example.cekgizi` (termasuk RunnerTests).
   - Folder repo (`bebas_stunting/`) sengaja TIDAK di-rename otomatis.
   - Windows: `project()`/`BINARY_NAME` = `cekgizi`, `Runner.rc` (FileDescription/ProductName/dll) & judul window = `CekGizi`.
   - Linux: `BINARY_NAME` = `cekgizi`, `APPLICATION_ID` = `com.example.cekgizi`, judul window/header bar = `CekGizi`.
   - Web: `manifest.json` & `index.html` → `CekGizi` (+ warna tema sesuai design system: background `#FBF7F0`, theme `#1F6F54`).
   - macOS: TIDAK diubah — bukan target v1 (PRD §0) dan rename produk pbxproj berisiko tanpa verifikasi mesin macOS. Jika macOS di-ship, rename `PRODUCT_NAME`, bundle id, dan `*.app` di pbxproj/xcscheme sekaligus.
   - `ios/Flutter/*.sh` & `Generated.xcconfig` (berisi path lama) adalah file auto-generated — akan ditulis ulang otomatis oleh `flutter run`.
2. **Struktur (clean architecture, PRD §4)**
   - `lib/core/{config,constants,errors}` — `AppConfig` (nama app, `permenkesRefVersion`), `AppStrings` (copy terpusat), sealed `Failure`.
   - `lib/domain_ref/` — loader referensi gizi (diisi Batch 3).
   - `lib/features/<feature>/{data/{datasources,models,repositories}, domain/{entities,repositories,usecases}, presentation/{providers,screens,widgets}}` untuk: auth, onboarding, consent, children, growth, meals, chat, recipes, settings.
   - `lib/shared/widgets/`, `assets/{fonts,rules,reference,data,images}/`, `supabase/{migrations,functions/{_shared,analyze-meal,ask-nutrition,delete-account,health}}/`.
   - Folder kosong diisi `.gitkeep` agar struktur ter-track; logika nyata diisi per batch.
3. **App shell**: `lib/main.dart` (entry minimal) + `lib/app.dart` (`CekGiziApp`; layar penanda menampilkan `AppConfig.appName` + disclaimer PRD §8.5; tema desain masuk di Batch 1).
4. **AGENTS.md** ditulis ulang & disinkronkan ke PRD v2.0 (PRD sebagai sumber kebenaran; larangan mengarang data gizi; workflow per batch; PRD & branch discipline; kuota AI; RLS; DoD §10.1; klaim terlarang; a11y; commit manual tetap berlaku).
5. **Docs**: `docs/progress.md` (ini), `docs/reference-notes.md` (template catatan tabel Permenkes — menunggu file resmi dari pemilik), `README.md` (nama, cara run, struktur, aturan kontribusi).
6. **Keamanan repo**: `.gitignore` diperketat — `.env*`, `**/secrets/`, keystore/p12/pem, `google-services.json`, `GoogleService-Info.plist`, `supabase/.temp/`, `dump*.sql`, `*.apk/aab/ipa`.
7. **CI**: `.github/workflows/ci.yml` — `flutter pub get` → `flutter analyze` → `flutter test` pada push/PR ke `main` dan `feature/app4-mvp`.
8. **Test**: counter smoke test diganti `test/app_test.dart` (app boot + render `appName` + disclaimer).

### Dependency baru di Batch 0
**Tidak ada.** Fondasi sengaja tanpa dependency baru.
Rencana batch berikutnya (setiap penambahan akan dicatat di sini):
- Batch 1 (Tema): tidak perlu dependency baru (ThemeExtension murni).
- Batch 2 (Supabase): `supabase_flutter` — backend client resmi.
- Batch 3 (Domain): `flutter_test` sudah ada; tidak perlu package skor.
- Batch 4 (Layar & state): `flutter_riverpod`, `go_router` — sesuai PRD §4.
- Batch 5 dst: `camera`, `image_picker`, `flutter_image_compress`, `fl_chart`, `flutter_local_notifications` — sesuai kebutuhan batch masing-masing.

### Verifikasi (2026-11-10)
- `flutter analyze` → **No issues found!**
- `flutter test` → **All tests passed!** (1/1)
- DoD §10.1: `LinearGradient|RadialGradient|SweepGradient` di `lib/` → 0 temuan; `Colors.` di `lib/features` & `lib/shared` → 0 temuan; `GEMINI_API_KEY=<literal>` di repo → 0 temuan.

### Belum dikerjakan / menunggu pemilik
- File tabel SD Permenkes 2/2020 (→ Batch 3; dicatat di `docs/reference-notes.md`).
- `nutrition_rules.json`, `foods_id.json`, `recipes.json` (≥120 pangan, ≥24 resep, ditinjau ahli gizi/bidan) — Batch 6/8.
- Project Supabase (URL + anon key; service role hanya di secrets Edge Function) — Batch 2.
- Keputusan Cloud Billing Gemini — sebelum Batch 5 (PRD §13.3).

### Status
Batch 0 SELESAI. Menunggu perintah lanjut ke Batch 1 (Tema).
