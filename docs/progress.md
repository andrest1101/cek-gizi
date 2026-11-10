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

## Batch 1 — Tema (2026-11-10)

### Perubahan
1. **Font ter-bundle (PRD §7.3):** Plus Jakarta Sans Regular/Medium/SemiBold/Bold (400/500/600/700) diunduh dari repo resmi Tokotype (`tokotype/PlusJakartaSans`) dan disertakan dengan lisensi OFL (`assets/fonts/OFL.txt`). Dideklarasikan di `pubspec.yaml` (family `PlusJakartaSans`).
2. **Token §7.2 — `AppColors` `ThemeExtension`** (`lib/core/theme/app_colors.dart`): light & dark sesuai PRD, termasuk pemisahan `statusWatch` (isi) vs `statusWatchText` (teks, light `#8A5A12`). `copyWith`/`lerp` lengkap.
3. **Token §7.3 — `AppTextStyles`** (`lib/core/theme/app_text_styles.dart`): heroNumber 28/34 w700, titleLarge 22/28 w700, titleMedium 17/24 w600, body/bodyTabular 16/24, bodySmall 14/20, label 13/16 w500. `FontFeature.tabularFigures()` untuk angka. Style tanpa warna (warna dari theme).
4. **Token §7.4 —** `AppSpacing` (skala 4pt: 4/8/12/16/20/24/32 + `screenPadding` 20 + `sectionGap` 28), `AppRadius` (control 12 / card 20 / pill 999), `AppMotion` (fast 200ms, normal 250ms, ring 400ms, `easeOutCubic`).
5. **`AppTheme.light()/dark()`** (`lib/core/theme/app_theme.dart`): `ColorScheme` M3 dari seed primer + override token PRD (`surfaceContainerHighest` = `surfaceVariant`, dsb.); `TextTheme` PlusJakartaSans dengan ukuran PRD; `CardThemeData` hairline border radius 20 tanpa elevation (PRD §7.4); `FilledButton`/`OutlinedButton` minimum 48dp radius 12; `InputDecorationTheme` hairline radius 12; `DividerTheme` hairline 1px. Helper `AppTheme.colorsOf(context)`.
6. **Komponen dasar** (`lib/shared/widgets/`): `TonalIconCircle`, `SectionHeader`, `EmptyState`, `ErrorCard` — semua tanpa literal warna, dengan `Semantics` dan copy dari `AppStrings` (§6.9: satu kalimat + satu tombol; tombol ≥48dp).
7. **Layar uji token** (`lib/shared/dev/token_gallery_screen.dart`): menampilkan SEMUA token warna (14), tipografi (7 style), spacing, radius, motion, tombol, dan komponen dasar di **kedua tema** (di-render dua preview side-by-side vertical via `Theme` override). Developer tool — akan diganti Beranda asli di Batch 4.
8. **AppStrings**: tambah `retry` dan `errorTitle`.
9. **Tidak ada dependency baru.**

### Verifikasi (2026-11-10)
- `flutter analyze` → **No issues found!**
- `flutter test` → **10/10 passed** (boot galeri, section token kedua tema, unit test `AppTheme`/`AppColors`/spacing/radius).
- DoD §10.1: `LinearGradient|RadialGradient|SweepGradient` di `lib/` → 0; `Colors.` di `lib/features` & `lib/shared` → 0 (galeri dev membaca token lewat `extension<AppColors>()` di dalam preview tema, bukan literal); `GEMINI_API_KEY=<literal>` → 0.

### Catatan teknis
- Grep DoD PRD `Colors\.` juga cocok pada substring `AppColors.` — dev galeri sengaja membaca token via `Theme` extension; sisa referensi `AppColors` hanya di `lib/core` dan `test/` (di luar scope grep PRD).
- Ikon memakai varian **Rounded bawaan Flutter** (`Icons.*_rounded`) — bundling font Material Symbols Rounded belum dilakukan (akan diputuskan bila diperlukan Batch 4+, dicatat di sini).
- `TokenGalleryScreen` masuk Batch 4: digantikan Beranda; galeri tetap sebagai dev tool.

### Status
Batch 1 SELESAI. Menunggu perintah lanjut ke Batch 2 (Supabase).

## Batch 2 — Supabase (2026-11-10)

### Konteks
- Project Supabase: `hvjqjjqgwpmpqnchnxts` (URL: `https://hvjqjjqgwpmpqnchnxts.supabase.co` — **tanpa** `/rest/v1/`, path itu ditambahkan SDK otomatis).
- Publishable key dipakai sebagai default di `AppConfig` (publik, dilindungi RLS; keputusan pemilik 2026-11-10). Kunci service_role/secret TIDAK PERNAH masuk repo/aplikasi.
- Anonymous Sign-Ins **sudah aktif** di dashboard (konfirmasi pemilik).
- CLI Supabase & Docker TIDAK tersedia di mesin dev → migrasi diterapkan manual oleh pemilik via **SQL Editor** (opsi B yang disetujui pemilik). Source of truth skema tetap file di `supabase/migrations/`.

### Perubahan (kode — sudah dikerjakan & terverifikasi)
1. Edge Function `health` ditulis (`supabase/functions/health/index.ts`; tanpa auth; roundtrip query ke tabel `ai_usage` sebagai "select 1"; 500/503 bila down) + `supabase/config.toml` (`project_id`, `verify_jwt = false` untuk health). **Deploy manual diperlukan** (lihat di bawah).
2. `supabase_flutter ^2.15.4` ditambahkan — alasan: backend client resmi PRD §4 (Supabase Auth + Postgrest + Edge Functions); dependency baru pertama untuk data layer.
3. Migrasi di `supabase/migrations/` (source of truth, dari PRD §5.2–5.4):
   - `20261111000001_schema.sql` — 6 tabel (`children`, `growth_measurements`, `food_logs`, `chat_messages`, `user_consents`, `ai_usage`) + CHECK constraints, FK `on delete cascade`/`set null`, `unique(child_id, measured_on)`, index.
   - `20261111000002_rls.sql` — RLS semua tabel; policy `own rows` (user = `authenticated` termasuk anonim); untuk tabel ber-`child_id`, WITH CHECK juga memverifikasi anak milik user; `chat_messages` mengizinkan `child_id NULL`; `ai_usage` read-only untuk user (tulis hanya `service_role`).
   - `20261111000003_quota.sql` — `public.consume_ai_quota(p_user, p_kind, p_limit)` SECURITY DEFINER, hari = `Asia/Jakarta`, atomic increment dengan limit; REVOKE dari public/anon/authenticated; GRANT hanya `service_role`.
   - `20261111000004_grants.sql` — GRANT tabel ke `authenticated` (CRUD, tapi `ai_usage` SELECT-only) & `service_role`; tanpa ini RLS tidak pernah dievaluasi (error 42501 saat uji pertama).
4. Script uji RLS dua pengguna: `supabase/tests/test_rls.sql` — transaksi + `rollback` di akhir; "dua pengguna" disimulasikan lewat `request.jwt.claims`; memverifikasi: A bisa CRUD sendiri; B tidak bisa select/update/delete/insert lintas anak (anak, growth, food_logs, chat, consents); chat `child_id NULL` diizinkan; kuota berhenti di limit (2) dan menolak kind tidak valid; dipanggil sebagai `service_role`.
5. Integrasi app: `Supabase.initialize()` di `main.dart` (URL + publishable key via `String.fromEnvironment`, default = nilai publik; override `--dart-define`); `AuthRepository` (abstrak, domain) + `AuthRepositoryImpl` (`supabase_flutter`) + use case `SignInAnonymously`; `auth_bootstrap.dart` — login anonim otomatis saat boot, kegagalan jaringan ditelan (offline tetap terbuka; retry di UI Batch 4+).

### Verifikasi (2026-11-10, mesin dev)
- `flutter analyze` → **No issues found!**
- `flutter test` → **12/12 passed** (termasuk unit test `AuthRepositoryImpl` tanpa jaringan).
- DoD §10.1: `Colors.` di `lib/features` & `lib/shared` → 0; gradien → 0; `GEMINI_API_KEY=<literal>` → 0.

### Perbaikan pasca-uji (2026-11-10, error 42501)
- Uji RLS pertama di SQL Editor gagal: `42501: permission denied for table children` — hak akses tabel untuk role `authenticated` tidak otomatis diberikan untuk tabel yang dibuat lewat SQL Editor. **Bukan bug RLS**: tanpa GRANT, RLS tidak pernah dievaluasi.
- Ditambahkan `20261111000004_grants.sql`: GRANT CRUD ke `authenticated` (CRUD data miliknya — RLS yang menyaring), `GRANT SELECT` saja di `ai_usage`, `GRANT ALL` ke `service_role`.
- **ATURAN BARU untuk semua migrasi berikutnya: setiap migrasi yang membuat tabel WAJIB menyertakan GRANT untuk `authenticated`/`service_role` di file yang sama.**
- Popup "Potential issue detected" di SQL Editor adalah peringatan standar untuk statement seperti DELETE/UPDATE/rollback — skrip uji aman (transaksi + `rollback` di akhir); klik "Run query" untuk melanjutkan.

### Verifikasi RLS oleh pemilik (progres)
- Anonymous Sign-In **terbukti aktif**: uid `f6c5d8e8-793f-4857-911d-b8276fb8488c` muncul di Authentication → Users setelah `flutter run` di Windows.
- Uji pertama gagal `42501 ... permission denied for table children` → diperbaiki dengan `20261111000004_grants.sql`.
- Uji kedua gagal `23503 ... Key is not present in table "users"` → UUID palsu tidak boleh; skrip diubah memakai UID asli pemilik (prefilled, bukan rahasia).
- Uji ketiga gagal `42501 ... permission denied for table rls_test` → temp table dibuat sebagai `authenticated` sehingga tidak bisa dibaca `service_role`; **skrip ditulis ulang tanpa temp table** (semua UUID literal; anak A pakai id eksplisit `cccccccc-...`). Section kuota (`service_role`) kini self-contained.
- Menunggu pemilik menjalankan ulang `supabase/tests/test_rls.sql` → semua notice PASS.

### Langkah tersisa untuk pemilik
1. Jalankan ulang `supabase/tests/test_rls.sql` di SQL Editor (klik **Run query** bila popup muncul) — semua notice PASS tanpa ERROR; jika lulus, Batch 2 resmi selesai.
2. **Deploy `health`** (bila diinginkan sekarang): dashboard Edge Functions (tempel `index.ts`, Verify JWT = OFF) atau CLI: `npx supabase login` → `npx supabase link --project-ref hvjqjjqgwpmpqnchnxts` → `npx supabase functions deploy health`. Tes: `curl.exe https://hvjqjjqgwpmpqnchnxts.supabase.co/functions/v1/health` → `{"status":"ok"}`.
3. Anonymous sign-in sudah terbukti (user anonim `f6c5d8e8-...` muncul di Authentication → Users).

### Catatan
- Keep-alive & backup terjadwal = Batch 9 (PRD §5.6), belum sekarang.
- `delete-account` & `ask-nutrition`/`analyze-meal` = Batch 9 / 5 & 7.
- Batas kuota default (`SCAN_DAILY_LIMIT=15`, `CHAT_DAILY_LIMIT=30`) = env di Edge Function saat Batch 5/7, bukan di klien.

### Status
Kode Batch 2 selesai & terverifikasi analyze/test. Menunggu langkah manual pemilik di atas; setelah RLS PASS + app masuk anonim → Batch 2 resmi selesai. Menunggu perintah lanjut ke Batch 3 (butuh file tabel Permenkes 2/2020 dari pemilik).
