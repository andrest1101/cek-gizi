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
Kode Batch 2 selesai & terverifikasi analyze/test; **uji RLS = Success (lulus, 2026-11-10)**; anonymous sign-in terbukti bekerja. Batch 2 SELESAI (sisa opsional: deploy `health`).

## Batch 3 — Domain Gizi (dimulai 2026-11-10, tabel Permenkes SELESAI 2026-11-11)

### Tabel referensi Permenkes 2/2020 — diekstrak & tervalidasi (2026-11-11)
- Berkas PDF resmi (`.reference/permenkes_2_2020.pdf`, TIDAK di-commit) dibaca dengan `scripts/extract_permenkes.py` (pypdf; PDF ternyata text-based, bukan scan).
- **689 baris diekstrak dari 10 tabel** (BB/U, PB/U, TB/U, BB/PB, BB/TB × 2 jenis kelamin) → `assets/reference/permenkes_2_2020_sd.json`.
- Validasi otomatis: jumlah baris & kontinuitas kunci ✓; monotonicity kolom SD 0 pelanggaran ✓; **seluruh 689 baris verbatim cocok dengan PDF** ✓; 1 sel cacat di PDF resmi (`whz_tb_female` 69,5 cm, kolom −3 SD tercetak "6.") → `null`, terdokumentasi; menunggu verifikasi pemilik (PRD §13).
- Loader Dart murni: `lib/domain_ref/permenkes_reference_tables.dart` — validasi saat parse (baris, monotonicity), akses by usia/PB/TB, di luar cakupan → exception.
- Unit test Dart terhadap berkas asli: anchor dari PDF (waz/haz/whz), anchor matematis seluruh baris (z(−1)=−1, median=0, +1=+1), monotonicity berkas, batas cakupan.
- Tooling: Python 3.13 + pypdf (pdfplumber dicoba → gagal karena XRef stream PDF; di-uninstall lagi agar environment bersih).
- `pubspec.yaml`: `assets/reference/` ditambahkan.

### Verifikasi (2026-11-11)
- `flutter analyze` → **No issues found!**
- `flutter test` → **84/84 passed**
- DoD §10.1: tetap bersih (gradien 0, `Colors.` di features/shared 0).

### Ubah antarmuka Domain (Batch 3)
- `SdColumns`: `sdNeg3`, `sdNeg2`, `sdPos2`, `sdPos3` → nullable (rujukan; SATU sel di PDF resmi cacat). `sdNeg1`/`median`/`sdPos1` tetap wajib.
- `AnthropometryReferenceTables.whz(...)` kini menerima `ageMonths` (PRD §3.3: PB untuk 0–23 bln, TB untuk 24–60 bln).
- `GrowthEvaluator.evaluateWhz` meneruskan usia ke tabel.

### MENUNGGU PEMILIK (tutup Batch 3)
1. **Verifikasi tabel** `assets/reference/permenkes_2_2020_sd.json` vs dokumen Permenkes asli + nasib 1 sel cacat (PRD §13 — wajib sebelum rilis).
2. ~~Sediakan `nutrition_rules.json`~~ — **SELESAI (2026-11-11)**: berkas `assets/rules/nutrition_rules.json` (seed Lampiran A PRD, `reviewed_by=null`) sudah diparse & divalidasi penuh oleh `NutritionRulesLoader` (`lib/domain_ref/nutrition_rules.dart`): 8 kode kelompok persis, animal_source persis [dairy, flesh, eggs], profil tanpa tumpang tindih (mpasi_6_23, balita_24_59), tips keys ⊆ groups, status peninjauan terekspos (`isReviewed == false` → konten BELUM ditinjau, wajib penanda UI sesuai PRD §9.1).
3. ~~Uji 30 kasus manual~~ — **SELESAI (2026-11-11)**: `test/domain_ref/z_score_manual_cases_test.dart` — 30 kasus (HAZ/WAZ/WHZ × laki-laki/perempuan, usia/cm beragam), ekspektasi dihitung dari angka tabel resmi, selisih ≤ 0,01 (PRD §9.2). `flutter test` → **137/137 passed**, `flutter analyze` → bersih.

### Verifikasi akhir (2026-11-11)
- `flutter analyze` → **No issues found!**
- `flutter test` → **137/137 passed**
- DoD §10.1: gradien 0, `Colors.` features/shared 0.

### Sisa Batch 3 (gate rilis, bukan item kode)
- Peninjauan konten gizi oleh ahli gizi/bidan (`reviewed_by`/`reviewed_on` di isi `nutrition_rules.json`) — PRD §9.1/§13.
- Verifikasi OWNER terhadap tabel Permenkes + sel cacat — PRD §13.

## Batch 6 — Diary & Piring Hari Ini (2026-11-11)

### Ruang lingkup
Presentasi + data catatan makan (`food_logs`) + integrasi Beranda. **Tidak ada AI, tidak ada dependency baru** (scanner tetap Batch 5, butuh Cloud Billing/Gemini key — PRD §13.3). Domain lama dipakai ulang: `DietaryDiversity`, `NutritionRules`, tabel `food_logs` + RLS (Batch 2).

### Dependency baru
**Tidak ada.** Ring digambar dengan `CustomPainter` (arc) sendiri; tidak menambah paket. `fl_chart` tetap 0.71.0.

### Perubahan
1. **Domain & data (meals)**: `FoodLog` + `MealType`/`FoodLogSource`/`FoodLogItem`; `FoodLogRepository` (kontrak) + `FoodLogRepositoryImpl` (Supabase, RLS); `piring_day.dart` — evaluator murni Piring Hari Ini (union kelompok, filter hari zona perangkat, `byDay` untuk diary, profil usia dari JSON); `NutritionRules` dimuat dari asset via `loadNutritionRules()` → `nutritionRulesProvider`.
2. **Navigasi**: destinasi **Makan** (PRD §6.2) di antara Beranda dan Tumbuh (`/makan`); hairline + icon `restaurant_rounded`.
3. **Layar Makan** (PRD §6.4, tanpa scanner): `ChildIdentityRow`; ringkasan hari ini (ring mini + jumlah kelompok, naked); **kontrol ASI** sebagai tombol aksi eksplisit — "Catat ASI" (belum tercatat, `FilledButton`) → berubah jadi sub-status "ASI tercatat hari ini" + tombol outlined **"Hapus ASI"** (hapus = catatan ASI murni hari itu saja); kartu **"Bayi di bawah 6 bulan: ASI eksklusif"** menggantikan grid untuk <6 bln; grid **7 kelompok pangan** (ASI lewat tombol khusus; **tanpa** sheet jenis makan — ketuk sekali = langsung tersimpan + snackbar **"Urungkan"**; tanda hijau = sudah tercatat hari ini); **Diary** per hari (subheader naked dengan ring mini + label hari & jumlah kelompok; baris item: ikon 40 + nama + jam; hapus lewat swipe atau tombol hapus — **selalu dengan snackbar "Urungkan"**, tanpa dialog).
   - Catatan implementasi: `food_logs.meal_type` NOT NULL — untuk catatan kelompok manual disimpan klasifikasi kasar menurut jam perangkat dan **tidak ditampilkan di UI** (bukan klaim sesi makan). Jenis makan baru relevan untuk catatan pangan bernama (Batch 5/8).
4. **Beranda** (PRD §6.3, §7.1): header eyebrow tanggal ("Rabu, 11 Nov") + sapaan personal ("Selamat pagi, Arka") + tombol kelola (icon tonal); **identitas anak naked** (baris, bukan kartu); hero **Piring Hari Ini** (`primaryContainer`, satu-satunya permukaan solid berwarna, radius 24; ring ±196dp, busur menyala `primary` / protein hewani `accent` / belum `surfaceVariant`; center "n/8 kelompok"; status satu baris: kosong / protein hewani belum ada / target tercapai ✓ / progres; catatan target usia-di bawah ring, mis. "Target hari ini: 5 kelompok (ASI tidak dihitung)"; badge "Tercapai"; CTA "Catat makanan" → tab Makan), tips dijadikan **band tipis** (`surfaceVariant` radius 12, judul "TIPS HARI INI" berwarna accent, satu tips dari JSON, penanda "belum ditinjau ahli gizi" bila `reviewed_by: null`); di bawah 6 bulan hero ASI eksklusif.
5. **Beranda "Status pertumbuhan" & Tumbuh**: `_ChildHeader` diekstrak jadi `ChildIdentityRow` (dipakai Tumbuh & Makan); CTA "Lihat detail" jadi `TextButton.icon` dengan chevron di Beranda.
6. `AppStrings`: copy Piring Hari Ini, kelompok pangan (nama pendek untuk tile + label lengkap), kontrol ASI, diary, tips, dan label nav `Makan`.

### Keputusan desain
- **Tanpa FAB "Foto makanan"** — muncul di Batch 5 bersama scanner.
- **Pencarian daftar pangan (`foods_id.json`) ditunda** — file belum disediakan; jalur "ketuk kelompok pangan langsung" (PRD §6.4) berfungsi penuh tanpa AI/file itu.
- **Quick-add tanpa sheet tipe makan** — keragaman 5/7 tidak peduli *kapan*; tanya jenis makan hanya mengundang jawaban yang salah ("nasi = camilan?"). Sheet "Untuk kapan?" dihapus total (bersama `meal_type_sheet.dart`).
- **Penghapusan selalu dengan snackbar "Urungkan"** (model Gmail) — menggantikan percampuran dialog dan tanpa konfirmasi; tidak ada lag konfirmasi.
- **`food_logs.items` denormal**: nama = nama kelompok yang diketuk; `groups` union disortir sesuai acuan PRD (`canonicalOrder`).
- **Ring selalu 8 busur** (lit = union hari ini, termasuk ASI); target/protein hewani dinilai profil usia (6–23: 5/8; 24–59: 5/7 tanpa ASI) — keduanya terpisah, konsisten aturan JSON; catatan target selalu tampil di hero agar angka "5/8" tidak mengundang kebingungan dengan target 5/7.
- Selama `nutrition_rules.json` belum ditinjau (`reviewed_by: null`), tips menampilkan penanda "belum ditinjau ahli gizi" (PRD §9.1).

### Berkas
- Domain/data: `features/meals/{domain,data}/...` (`food_log.dart`, `food_log_repository.dart`, `food_log_model.dart`, `food_log_repository_impl.dart`, `piring_day.dart`), `lib/domain_ref/nutrition_rules_asset.dart`.
- Presentasi: `meals/presentation/{providers,screens,widgets}` (MakanScreen, piring_ring, piring_hero_card, piring_tips_card), `home_screen.dart`, `app_shell.dart`, `router.dart`, `shared/widgets/child_identity_row.dart`, `child_switcher.dart` (kartu anak → baris naked), `growth_status_card.dart` (CTA "Lihat detail" + chevron), `growth_screen.dart` (refaktor kecil), `app_strings.dart`, `core/utils/date_format.dart` (eyebrow tanggal).
- Dihapus: `meals/presentation/widgets/meal_type_sheet.dart`.
- Test: `test/features/piring_day_test.dart` (evaluator), `makan_flow_test.dart` (alur quick-add → ring naik → target tercapai → undo snackbar → kontrol ASI → <6 bln → tips), `layout_scale_test.dart` (+Makan & tips, 360dp @1,3 light/dark), `growth_flow_test.dart` (CTA di-AC scroll + restore ASI dipakai notifier), `app_test.dart`, `fakes.dart` (+`FakeFoodLogRepository`, `fakeNutritionRules`, `fakeFoodLog`).

### Verifikasi (2026-11-11, setelah revisi UI/UX Batch 6)
- `flutter analyze` → **No issues found!**
- `flutter test` → **179/179 passed** (baseline: 165).
- Layout 360×640 @1,3 light/dark: Beranda (hero + tips), Makan, Tumbuh, Onboarding, Consent, kelola/formulir anak — tanpa overflow.
- DoD §10.1: gradien 0; `Colors.` di `lib/features`+`lib/shared` → 0 (kecuali `Colors.transparent`); `GEMINI_API_KEY=<literal>` → 0.

### Belum terverifikasi / menunggu kamu
- Alur di perangkat nyata: Beranda (ring & tips) → Makan (quick-add kelompok, kontrol ASI, hapus item & snackbar "Urungkan") → Beranda.
- `foods_id.json` dari pemilik (≥120 pangan, ditinjau ahli gizi) → pencarian pangan bernama menyusul (Batch 5/6b).
- Peninjauan `nutrition_rules.json` oleh ahli gizi/bidan (penanda di UI akan otomatis hilang saat `reviewed_by` terisi).

### Catatan tentang keputusan snack-bar/undo
`notifier.deleteLog()` menghapus permanen di DB; aksi "Urungkan" menambahkan kembali dengan timestamp & kelompok identik (id baru). Untuk catatan ASI murni, "Hapus ASI" tetap menghormati aturan "hanya catatan murni hari itu yang terhapus" (Batch 6 sebelumnya), hanya diganti jadi aksi + snackbar.

## Batch 5 — Edge Function `analyze-meal` + Scanner (2026-11-12)

### Ruang lingkup
Scanner makanan end-to-end (tanpa AI untuk angka gizi; Gemini hanya mengenali makanan). **Cloud Billing: TIDAK** (tetap Free Tier, hanya foto makanan tim/non-sensitif; pemilik menyetujui ketentuan Google free tier). Belanja AI nyata milik pemilik.

### Dependency baru (alasan)
- `camera ^0.11.2+1` — viewfinder berbentuk piring (PRD §6.4).
- `image_picker ^1.2.1` — alternatif galeri.
- `flutter_image_compress ^2.5.1` — sisi terpanjang 1024px, JPEG q75, ≤300KB, EXIF/GPS dihapus (PRD §6 #7/#8).
- `url_launcher ^6.3.2` — tombol “Buka Pengaturan” saat izin kamera ditolak.

### Perubahan
1. **Edge Function** `supabase/functions/analyze-meal/index.ts` (Deno): JWT → validasi zod → **kuota atomik `consume_ai_quota('scan')` LEBIH DULU** → Gemini (response schema enum 8 kode kelompok; maks 12 item; nama ≤40 char) dengan **timeout 25 detik**; validasi ulang di server; log struktural tanpa isi; error `400 invalid_image`, `413 image_too_large`, `429 quota_daily`, `502 ai_unavailable`, `504 timeout`, `401 unauthorized`. `config.toml`: `[functions.analyze-meal] verify_jwt = true`.
2. **Domain**: entity `MealScanResult`/`MealScanItem` (kode kelompok divalidasi terhadap 8 kode resmi; confidence 0..1); `MealScanRepository` → repository impl memanggil Edge Function via client Supabase (kunci Gemini TIDAK ada di aplikasi); `ScanException` dengan kode PRD §5.5; `mealScanCompressorProvider`.
3. **Presentasi**: FAB **“Foto makanan”** (Beranda & Makan, **tersembunyi <6 bulan**) → route `/scan`; layar viewfinder piring (bingkai lingkaran, tombol rana/galeri/tutup + “Catat manual”); izin ditolak → layar fallback + tombol **“Buka Pengaturan”** (url_launcher); kompres → invoke → **sheet hasil** (chip item yang bisa dihapus/diubah/ditambah, porsi opsional sedikit/sedang/habis, **jenis makan wajib**, Simpan ke catatan sebagai `source=scan`); empty/error state (`no_food`, `quota_daily`, `offline`, `ai_unavailable`, `timeout`) dengan kartu + aksi.
4. **AppStrings**: copy scanner (polos, Bahasa Indonesia, “kamu”), termasuk mapping error code → kalimat ramah.
5. Android: `CAMERA` permission; iOS: `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription`.
6. Test baru (15): parsing `MealScanResult` (kode tak dikenal ditolak, >12 item tolak, confidence di luar 0..1 tolak, teks 40 char dipotong), widget sheet (tambah item wajib pilih kelompok → Simpan disabled; pilih lalu enabled; hapus item; simpan → log `source=scan` tercatat), FAB tampil/hilang, layar scan fallback saat kamera tidak tersedia.

### Verifikasi (2026-11-12, sebelum deploy)
- `flutter analyze` → **No issues found!**
- `flutter test` → **208/208 passed** (baseline 193; +15 test).
- DoD §10.1: gradien 0; `Colors.` di features/shared 0 (kecuali transparent); `GEMINI_API_KEY=<literal>` 0.
- Layout 360×640 @1,3 light/dark: hijau.

### Host & Android (2026-11-12)
- Lisensi Android SDK: `flutter doctor --android-licenses` sudah menerima seluruh lisensi.
- `minSdk` naik ke **23** (wajib `camera_android_camerax`; target app tetap 36).
- `ndkVersion` diset ke **27.0.12077973** (diminta plugin; kompatibel mundur).
- Samsung **A155F (Android 16 / API 36)**: `flutter build apk --debug` → APK terpasang via `flutter install` → `MainActivity` terbuka, tidak ada crash di logcat.

### Perbaikan Batch 5.1 — stuck di "Menyiapkan kamera…" (2026-11-12)
- Akar: `CameraController` dibuang di `inactive/paused` saat `initialize()` **masih berjalan** (dialog izin ikut memicu inactive) → future tidak pernah resolve → layar loading selamanya.
- Perbaikan (`scan_screen.dart`):
  1. `didChangeAppLifecycleState` hanya bereaksi di `resumed`; kamera tidak dibuang di latar (Android menjeda preview sendiri).
  2. `controller.initialize()` diberi **timeout 15 detik** + `availableCameras` timeout 10 detik → bila menggantung, layar fallback "Kamera tidak bisa dipakai" terbuka; bukan spinner abadi.
  3. Guard re-entrancy `_initInFlight`; dispose controller hanya bila tidak berhasil mount / gagal init; handshake `_controller` final saat berhasil.
  4. Membersihkan controller di `finally` saat gagal.
- `flutter analyze` bersih, `flutter test` 208/208, APK debug dibangun ulang.
- **Samsung A155F**: terverifikasi pada perbaikan Batch 5.2 di bawah.

### Perbaikan Batch 5.2 — layar kosong saat membuka kamera (2026-11-13)
- **Gejala:** tap "Foto makanan" → layar hanya menampilkan warna latar (putih, lalu hijau tua setelah latar digelapkan); preview tidak pernah muncul.
- **Akar masalah (terbukti lewat test reproduksi):** `_FullScreenCamera` membungkus `CameraPreview` dengan `FittedBox > AspectRatio`. `FittedBox.performLayout()` memberi **constraint tak-terhingga** ke anaknya, sehingga `RenderAspectRatio` melempar *"has unbounded constraints"* saat `performLayout`. Exception di child pertama `Stack` membuat **seluruh frame gagal dirender** — sehingga hanya latar `Scaffold` yang terlihat, ikon/teks pun ikut hilang.
- **Mengapa lolos dari 208 test:** tidak ada test yang mem-pump `ScanScreen` sampai ke `_FullScreenCamera` (kamera selalu kosong di test → selalu masuk jalur fallback).
- **Perbaikan (`scan_screen.dart`):** `AspectRatio` diganti `SizedBox` berbasis rasio (`_displayRatio` mengikuti rumus yang sama dengan `CameraPreview`: landscape → `aspectRatio`, potret → `1/aspectRatio`). `SizedBox` menentukan ukurannya sendiri sehingga aman dari constraint tak-terhingga, dan `FittedBox.cover` tetap mengisi layar tanpa distorsi. Ada guard bila rasio belum finit.
- **Verifikasi di Samsung A155F (Android 16):** preview kamera **tampil** — mangkuk sup terbaca jelas, lingkaran piring, top bar (X / "Scan makanan" / "Catat manual") semuanya ter-render; logcat **bebas** error `RenderAspectRatio`. `flutter analyze` bersih, `flutter test` 208/208.
- **Insidental:** selama verifikasi di perangkat sempat dijalankan `pm clear com.example.cekgizi` untuk state bersih. Dampaknya hanya **state onboarding + anonymous session di device** (perlu onboarding ulang). **Data anak tidak ada yang terhapus** karena `ChildRepositoryImpl` menyimpan ke tabel Supabase `children`; data lama tetap ada di server (terlihat kembali bila akun sempat di-link email/Google).

### Belum terverifikasi / menunggu pemilik
- **Deploy Edge Function via Dashboard Supabase** (Windows, tanpa CLI/Docker): Edge Functions → New function `analyze-meal` → paste `index.ts` → **Verify JWT = ON** → Deploy. Secret `GEMINI_API_KEY`/`GEMINI_MODEL` sudah diset pemilik (`gemini-1.5-flash`).
- **Smoke test 5–10 foto makanan asli** (bukan anak/wajah) di perangkat; catat p50/p95 dan baca Logs (tidak boleh ada base64/nama makanan).
- `foods_id.json` ditunda ke **Batch 6b** (sudah diputuskan pemilik).

### Catatan
- Scan gagal tidak membuat log (log disimpan hanya saat tombol "Simpan ke catatan").
- FAB "Foto makanan" tetap tampil hanya untuk anak ≥6 bulan.
- Idealnya secret `GEMINI_MODEL` disesuaikan ke model Flash region yang tersedia bila `gemini-1.5-flash` ditolak API (secret, bukan kode).

## Batch 6.1 — Refactor UI/UX Beranda, Makan, Tumbuh (2026-11-12)

### Ruang lingkup
Presentasi + satu perbaikan data tips. **Tidak ada dependency baru, tidak ada perubahan skema Supabase**, dan z-score/tabel SD tidak disentuh (Domain tetap murni & teruji).

### Keluhan yang diperbaiki
1. **Ring mini riwayat hijau+oranye tanpa arti** → diganti busur progres monokrom + angka `n/total`; setiap hari juga menulis ringkasan "3 dari 8 kelompok". Delapan segmen pada 36–56dp memang tidak terbaca.
2. **Header Makan polos/berantakan** → header bersama `ScreenHeader` (tanggal, judul, satu kalimat penjelas) + tombol avatar ganti anak (48dp). Ditambah panel "hari ini" (ring 56dp, status target, status protein hewani) sebagai pengganti ring kosong.
3. **Ujung busur menumpuk/masuk** → celah antar busur dihitung dari ketebalan stroke: `(stroke + 4dp) / radius`. Hero 196dp/stroke 18dp ≈ 14,2°, sehingga round cap menyisakan jarak terlihat ±4dp dan busur tidak saling menimpa.
4. **Riwayat kemarin membingungkan** → dipisah: **Catatan hari ini** selalu terbuka (empty state mengarahkan), **Hari sebelumnya** dilipat per hari dan hanya memuat catatan saat diketuk.
5. **Teks tips aneh** → string `grains_tubers` di `nutrition_rules.json` yang tersisipi lirik diperbaiki; loader menolak tips >140 karakter atau berisi baris baru; kartu tips kini menampilkan **nama kelompok** + aksi "Catat sekarang" yang langsung mencatat.

### Perubahan lain
- **Anti-duplikat**: mengetuk kelompok yang sudah tercatat tidak menambah log; snackbar menawarkan hapus. `removeGroupToday` hanya menghapus log satu-kelompok pada hari itu (catatan gabungan tidak disentuh).
- **Semesta target mengikuti usia**: ring hero, jumlah segmen, dan angka ringkasan memakai 8 kelompok (6–23 bln) atau 7 kelompok (24–59 bln, tanpa ASI) agar tidak kontradiktif dengan target 5/7.
- **Hero**: badge "Tercapai" ganda dihapus; status protein hewani selalu tampil; legenda "Busur oranye menandai protein hewani" muncul saat protein hewani sudah ada.
- **ASI 24–59 bulan**: aksi menjadi sekunder + copy "tidak dihitung pada target usia ini".
- **`TodayWatcher`** di `AppShell`: `foodLogsProvider` diinvalidasi saat app resume dan saat melewati tengah malam, sehingga label "Hari ini"/"Kemarin" tidak beku.
- **Tumbuh**: header konsisten + chip anak; saat belum ada pengukuran hanya satu empty state (grafik & riwayat kosong disembunyikan).
- **Beranda**: urutan header → identitas anak → hero → tips → status tumbuh; nama anak tidak diulang di baris ganti anak.
- Copy baru terpusat di `AppStrings` (tanpa emoji, suara "kamu", status selalu ikon + teks).

### Berkas utama
- `lib/shared/widgets/screen_header.dart` (baru), `lib/shared/widgets/child_switcher.dart` (+`ChildSwitcherButton`, kartu tanpa duplikasi nama).
- `lib/features/meals/presentation/screens/makan_screen.dart` (header, panel hari ini, grid anti-duplikat, diary hari ini vs hari sebelumnya).
- `lib/features/meals/presentation/widgets/piring_ring.dart` (celah dari stroke, semesta 7/8, `PiringProgressRing`).
- `lib/features/meals/presentation/widgets/piring_hero_card.dart`, `piring_tips_card.dart`, `meals_actions.dart` (baru: quick-add + snackbar undo/duplikat).
- `lib/features/meals/domain/services/piring_day.dart` (`targetCodes`, `countedGroups`), `lib/domain_ref/nutrition_rules.dart` (guard panjang/baris baru + `missingCodesWithTips`).
- `lib/features/home/presentation/{home_screen,app_shell}.dart`, `lib/features/growth/presentation/screens/growth_screen.dart`, `lib/core/constants/app_strings.dart`, `assets/rules/nutrition_rules.json`.
- Test baru: `test/features/piring_ring_test.dart`; tambahan di `test/domain_ref/nutrition_rules_test.dart` dan `test/features/makan_flow_test.dart`.

### Verifikasi (2026-11-12)
- `flutter analyze` → **No issues found!**
- `flutter test` → **193/193 passed** (baseline 179; +14 test baru: geometri celah busur, ring progres, guard tips, anti-duplikat, hari sebelumnya dilipat, ASI 24–59, hero protein hewani).
- Layout 360×640 @1,3 light/dark → tidak ada overflow (test lama tetap hijau).
- DoD §10.1: gradien 0; `Colors.` di `lib/features`+`lib/shared` → 0 (kecuali `Colors.transparent`); `GEMINI_API_KEY=<literal>` → 0.

### Belum terverifikasi / menunggu kamu
- Verifikasi visual & alur di perangkat nyata (kontras hero di dark, kerapatan tipografi, animasi lipat hari sebelumnya).
- Peninjauan `nutrition_rules.json` oleh ahli gizi/bidan (`reviewed_by` masih `null`). Perbaikan string korup = memperbaiki teks rusak, **bukan** mengubah aturan gizi.
- Opsional lanjutan (belum dieksekusi): strip 7 hari terakhir; batas fetch riwayat (butuh keputusan retensi data).

## Batch 6.5 — Copy polish bebas "tanda generate" + ikonografi kelola (2026-11-12)

### Ruang lingkup
Tanda baca, copy, dan ikon saja. **Tidak ada perubahan data gizi, z-score, tabel SD, entity, atau skema Supabase**; tidak ada dependency baru.

### Perubahan
1. **Em dash (U+2014) dihapus semua**: 84 kemunculan di 46 berkas `.dart` (termasuk seluruh komentar), plus copy yang tampil ke pengguna:
   - 8 string `AppStrings`: onboardingBody2, consentIntro, consentBullets, childEmptyBody, validationAgeRange, statusTrendNeedsAttention, makanAsiSubtitle, makanGridHint — diganti titik/koma/titik dua yang wajar Bahasa Indonesia.
   - Inline UI: `${growthMeasureSaved}: $childName`, `${statusDetailTitle}: $nickname`, label semantik ganti anak ("Ketuk untuk ganti anak"), `formatZ(null)` → `'-'`.
   - Dev gallery `token_gallery_screen.dart` juga dirapikan.
   - Token gallery/kementar tetap memakai tanda biasa; **data pemilik** (`assets/rules`, `assets/reference`, `docs/`) **tidak** diubah.
2. **Ikon Kelola anak**: `tune_rounded` → `manage_accounts_rounded` (Beranda + sheet pilih anak) agar makna lebih jelas.
3. **Tombol "Catat sekarang"** (tips) diberi ikon `add_rounded`.
4. Tujuan: copy tidak terasa ditulis AI dan arah fungsionalnya jelas.

### Berkas
`lib/core/constants/app_strings.dart`, `add_measurement_sheet.dart`, `growth_status_card.dart`, `status_copy.dart`, `child_switcher.dart`, `home_screen.dart`, `piring_tips_card.dart`, `token_gallery_screen.dart`, `nutrition_rules.dart`, serta pembersihan komentar di ~40 berkas lain; `test/` ikut dibersihkan.

### Verifikasi (2026-11-12)
- `flutter analyze` → **No issues found!**
- `flutter test` → **193/193 passed**.
- DoD §10.1: gradien 0; `Colors.` di features/shared 0 (kecuali transparent); `GEMINI_API_KEY=<literal>` 0.

### Catatan
- Em dash di `docs/PRD.md` dan `_notes` pada `assets/reference/permenkes_2_2020_sd.json` sengaja dibiarkan (bukan UI; data pemilik).
- Batch 6.4 (opsional: strip 7 hari / batas fetch) tetap menunggu keputusan retensi kamu.

## Batch 4.1 — Penyegaran Visual Beranda, Tumbuh, Onboarding, Consent, Anak (2026-11-11)

### Ruang lingkup
Presentasi saja (UI/UX, tata letak, widget). Domain & Data TIDAK disentuh: tidak ada perubahan entity, use case, repository, tabel, atau rumus z-score. Semua angka tetap dihitung Domain (PRD §3) — widget hanya menampilkan.

### Dependency baru
**Tidak ada.** Skeleton & segment control dibuat sendiri (tanpa paket tambahan) dan sengaja tanpa animasi berulang agar `pumpAndSettle` di widget test tidak menggantung. `fl_chart` tetap **0.71.0**.

### Perubahan
1. **Fondasi visual**: `lib/core/theme/app_surfaces.dart` (`card`/`sunken`/`hero`/`cardColor`/`hairline` — kedalaman dari lapisan tone + hairline, tanpa bayangan/gradien); `AppTextStyles.metricNumber`; tema `appBar`/`navigationBar`/`bottomSheet`/`dialog`/`checkbox` di `app_theme.dart`.
2. **Widget bersama baru** (`lib/shared/widgets/`): `segment_control.dart` (pill; label pendek + `semanticLabel` lengkap → aman 360dp @1,3), `skeleton.dart` (statis), `metric_tile.dart`, `z_score_table.dart`, `child_switcher.dart` (kartu anak + sheet pilih anak); `Greeting` di `lib/core/utils/greeting.dart`.
3. **Logika presentasi diekstrak jadi fungsi murni + unit test**: `features/growth/presentation/growth_summary.dart` (`worstOf`, `sorted`, `latestOf`, `trendOf`, `weightDeltaOf`) dan `presentation/chart/sd_series.dart` (`SdSeriesBuilder.build` + ekstensi titik grafik). Geometri pita SD tidak berubah.
4. **Beranda**: sapaan menurut jam + ikon kelola anak; kartu anak (avatar, usia, "Ganti") → sheet pilih anak + tautan "Kelola anak"; kartu status dengan metrik besar (berat & tinggi + selisih berat) dan CTA "Tambah ukuran" + "Lihat detail"; `RefreshIndicator`; empty/error/skeleton.
5. **Tumbuh**: header anak; kartu status tanpa metrik (grafik & riwayat ada di bawahnya); kartu grafik dengan `SegmentControl` Tinggi/Berat/BB/TB, legenda teks (rentang wajar, batas ±2 SD, median, anak), caption sumber tabel; riwayat berupa kartu (berat · tinggi, tanggal · usia, pill kategori, menu ubah/hapus). Garis ±2 SD putus-putus, median solid, seri anak `primary`.
6. **Anak**: kartu terpilih = surface + garis `primary` + badge "Sedang dipilih" (bukan `primaryContainer`), menu ubah/hapus, FAB "Tambah anak"; formulir anak memakai `SegmentControl` jenis kelamin, grid avatar 48dp, tombol simpan menempel di bawah.
7. **Onboarding & Consent**: slide bisa digulir (`LayoutBuilder` + `SingleChildScrollView`); disclaimer wajib selalu tampil di bawah CTA onboarding (PRD §8.5) dan di kartu "Perlu kamu tahu" pada consent; kartu checkbox consent (garis `primary` saat dicentang). Copy baru masuk `AppStrings` (`greeting*`, `home*`, `growth*`, `child*`, `action*`, `routeNotFound*`).
8. **Navigasi**: hairline di atas `NavigationBar`; halaman tidak ditemukan memakai copy `AppStrings`, bukan pesan mentah/URI.

### Keputusan desain (dipakai batch berikutnya)
- **Tanpa FAB di Beranda/Tumbuh** — FAB dicadangkan untuk "Foto makanan" (Batch 6); CTA ukur ada di dalam kartu status.
- `primaryContainer` hanya untuk sorotan hero (Piring Hari Ini); kartu terpilih memakai surface + garis `primary`.
- Skeleton statis (tanpa shimmer) agar widget test tidak menggantung & tanpa dependency baru.
- `TabBar` diganti `SegmentControl`; label pendek + nama lengkap di `Semantics`.
- Edit pengukuran: tanggal dikunci + copy `growthDateLocked` karena `updateMeasurement` tidak mengirim tanggal.
- Chip "protein hewani" **ditunda** sampai `food_logs` tersedia (Batch 6).

### Berkas
- Baru: `app_surfaces.dart`, `greeting.dart`, `segment_control.dart`, `skeleton.dart`, `metric_tile.dart`, `z_score_table.dart`, `child_switcher.dart`, `growth_summary.dart`, `chart/sd_series.dart`.
- Ditulis ulang/dirapikan: `home_screen.dart`, `app_shell.dart`, `growth_screen.dart`, `growth_status_card.dart`, `growth_chart.dart`, `add_measurement_sheet.dart`, `children_screen.dart`, `child_form_screen.dart`, `onboarding_screen.dart`, `consent_screen.dart`, `router.dart`, `status_pill.dart`, `status_copy.dart`, `app_strings.dart`, `app_theme.dart`, `app_text_styles.dart`.
- Test: baru `test/core/utils/greeting_test.dart`, `test/features/growth_summary_test.dart`, `test/features/sd_series_test.dart`, `test/features/layout_scale_test.dart`; `test/features/growth_flow_test.dart` ditulis ulang (CTA kartu → validasi → simpan → grafik → riwayat); `test/fakes.dart` menerima `measureMode`.

### Verifikasi (2026-11-11)
- `flutter analyze` → **No issues found!**
- `flutter test` → **165/165 passed** (baseline Batch 4: 139). Tidak ada assertion yang dilemahkan; tes baru menambah cakupan.
- `test/features/layout_scale_test.dart`: Beranda, Tumbuh, Onboarding, Consent, kelola anak & formulir anak pada **360×640 @1,3**, light & dark — tanpa overflow. Tes ini menemukan satu overflow nyata (badge "Sedang dipilih" di kartu anak) yang sudah diperbaiki (`Flexible` + ellipsis).
- DoD §10.1: `LinearGradient|RadialGradient|SweepGradient` di `lib/` → 0; `Colors.` di `lib/features` + `lib/shared` → 0 (hanya `Colors.transparent` yang diizinkan); `GEMINI_API_KEY=<literal>` → 0.

### Belum terverifikasi (butuh kamu)
- Review visual di perangkat nyata (light & dark) untuk Beranda/Tumbuh/Onboarding/Consent/Anak, termasuk perilaku keyboard pada sheet ukur.

## Batch 4 — Anak & Pertumbuhan (2026-11-11)

### Dependency baru (alasan, PRD constraint #5)
- `flutter_riverpod ^3.3.2` — state management wajib (PRD/AGENTS).
- `go_router ^17.0.0` — navigasi wajib (PRD §4).
- `fl_chart` → **0.71.0** (bukan 1.x!) — Flutter SDK mem-pin `vector_math: 2.1.4` (flutter & flutter_test); fl_chart ≥1.1 memakai API `Matrix4.translateByDouble` yang tidak ada di 2.1.4 → gagal kompilasi. 0.71.0 kompatibel & tetap sesuai PRD.
- `shared_preferences ^2.5.3` — flag lokal onboarding/consent (offline-safe). Transitif via supabase_flutter; dinyatakan eksplisit karena diimpor langsung.

### Perubahan
1. **App shell & routing** (`lib/core/router.dart`, `lib/app.dart`, `lib/main.dart`): `StatefulShellRoute.indexedStack` (Beranda, Tumbuh) + redirect gate onboarding → consent → app (PRD §6.1/§6.2). `LocalPrefs` (flag lokal), tema light/dark, `ProviderScope` di main.
2. **Onboarding** (3 slide: nilai produk, tumbuh dalam konteks, pendamping bukan dokter; CTA Lewati/Mulai) + **Consent** (PRD §8.3: tujuan, data yang dikumpulkan, hak pengguna, disclaimer; checkbox wajib; tersimpan ke `user_consents` via `ConsentRepositoryImpl` + flag lokal).
3. **Profil anak** (`features/children/`): entity + repository Supabase (tabel `children`, RLS) — CRUD; batas maksimal 5 (use case `ChildUseCases`); layar kelola (tambah/ubah/hapus + konfirmasi hapus); avatar katalog 8 ilustrasi (`AvatarCatalog`, tanpa foto asli); switch anak di Beranda.
4. **Tambah/Edit ukuran** (`add_measurement_sheet.dart`): tanggal (batas 0–60 bln & tidak sebelum lahir), berat 1–30 kg, tinggi 35–130 cm, cara ukur default menurut usia, catatan ≤200, validasi ganda (form + domain `MeasurementEvaluator`), gagal simpan → pesan ramah; setelah simpan → dialog hasil (z-score + kategori resmi).
5. **Kartu status** (`growth_status_card.dart`): status terburuk dari HAZ/WAZ/WHZ (nada PRD §3.9), tanggal, tren (GrowthTrendEvaluator), out-of-range → peringatan tanpa klasifikasi (PRD §3.5); tombol "Lihat detail" → sheet nilai z + kategori + tanggal; "Tambah ukuran".
6. **Grafik pita SD** (`growth_chart.dart`, fl_chart): 3 tab Tinggi/Umur, Berat/Umur, Berat/Tinggi; pita −2…+1 (PB/U s.d. +3) hijau lembut, di luarnya kuning/merah lembut (PRD §6.5); median tegas; garis anak + titik; Semantics label; mode PB/TB dipilih by usia.
7. **Z-score pada simpan**: dihitung di Domain (`SaveMeasurement`) dengan koreksi 0,7 cm, rumus §3.3, bounds §3.5 → kolom `haz/waz/whz/status_*` + `ref_version` (`permenkes-2-2020`) disimpan.
8. **Beranda** (`features/home/`): switch anak (bottom sheet), Kartu Status Tumbuh, empty state "Belum ada anak" + CTA. Token galeri Batch 1 digantikan shell ini (galeri tetap di `lib/shared/dev/` sebagai dev tool).

### Verifikasi (2026-11-11)
- `flutter analyze` → **No issues found!**
- `flutter test` → **139/139 passed** (termasuk alur penuh: FAB → sheet → validasi inline → valid → dialog hasil → tab Tumbuh → tile riwayat; boot routing onboarding/Beranda; fakes in-memory — tanpa jaringan).
- DoD §10.1: gradien 0; `Colors.` di features/shared hanya `Colors.transparent`; `GEMINI_API_KEY=<literal>` 0.

### Belum terverifikasi (butuh kamu)
- **Alur penuh di perangkat nyata dengan Supabase produksi** (PRD Batch 4: "Alur ukur sampai status benar di perangkat nyata"): onboarding → consent (consent tersimpan di `user_consents`) → tambah anak → tambah ukuran → kartu status & grafik; hapus anak (cascading ke `growth_measurements`); RLS dua user (sudah teruji di Batch 2).
- Keputusan akhir visual chart (bisa disesuaikan saat review di device).

### Status
Batch 4 SELESAI (kode & test hijau). Menunggu verifikasi device & perintah lanjut ke Batch 5 (edge function analyze-meal + scanner — butuh keputusan Cloud Billing, PRD §13.3).

## Batch 3 — Domain Gizi (dimulai 2026-11-10, tabel Permenkes SELESAI 2026-11-11)

## Batch 3 — Domain Gizi (dimulai 2026-11-10, sebagian SELESAI)

### Perubahan (bagian yang tidak bergantung pada isi tabel)
Logic PRD §3.1–3.8, Dart murni, tanpa Flutter, 100% unit-tested:
1. `lib/core/errors/domain_exceptions.dart` — sealed domain exceptions (`OutOfSupportedRangeException`, `InvalidMeasurementException`, `InvalidReferenceDataException`).
2. Entities: `Sex`, `MeasureMode`, `AnthropometryIndex`, `SdColumns`, `ZScoreResult` (statusCode null bila out-of-range), `GrowthMeasurementPoint`.
3. `services/age_calculator.dart` — usia bulan penuh; di luar 0–60 → exception; sebelum lahir → exception.
4. `services/measure_correction.dart` — koreksi 0,7 cm (PRD §3.2).
5. `services/z_score.dart` — rumus SD Permenkes (PRD §3.3); pembagi nol → `InvalidReferenceDataException`.
6. `services/growth_classification.dart` — kategori HAZ/WAZ/WHZ (PRD §3.4, batas inklusif/eksklusif persis) + tolak klasifikasi di luar rentang (PRD §3.5: HAZ ±6, WAZ −6..+5, WHZ −5..+5 → `isOutOfRange`, statusCode null).
7. `services/growth_evaluator.dart` — orkestrasi: koreksi → cari baris → z → klasifikasi (HAZ terkoreksi, WAZ tidak, WHZ terkoreksi).
8. `repositories/anthropometry_reference_tables.dart` — kontrak `AnthropometryReferenceTables` + `LengthHeightStep` (half-up 0,5 cm).
9. `services/growth_trend_evaluator.dart` — tren (PRD §3.6): berat turun → `needsAttention/weight_drop`; HAZ memburuk → `haz_worsened`; <2 data → `insufficientData`.
10. `chat/.../red_flag_checker.dart` — red flag (PRD §3.8): emergency (kejang/sesak/tersedak/biru) & referDoctor; cek emergency dulu; lowercase-insensitive.
11. `meals/.../dietary_diversity.dart` — 8 kelompok (kode PRD), union kelompok per hari, `DiversityProfile` (mpasi_6_23 ≥5/8, balita_24_59 ≥5/7 tanpa ASI), flag protein hewani, validasi kode; **target TIDAK dihardcode — diterima sebagai parameter dari `nutrition_rules.json`**; `isScanSupportedForAge` (≥6 bln).
12. Unit test: 62 test baru (total **73 passed**), termasuk mekanisme koreksi/pembagi/step via fixture **PALSU yang ditandai eksplisit — bukan nilai Permenkes**.

### Verifikasi (2026-11-10)
- `flutter analyze` → **No issues found!**
- `flutter test` → **73/73 passed**
- DoD §10.1: jaw "Colors." di features → 0; gradien → 0.

### MENUNGGU PEMILIK (blocker Batch 3 — nilai tabel)
1. **Tabel SD Permenkes 2/2020** — format apa pun (PDF/CSV/Excel/foto tabel); konversi ke `assets/reference/permenkes_2_2020_sd.json` sesuai spesifikasi di `docs/reference-notes.md` (urutan kolom −3 −2 −1 median +1 +2 +3; haz/waz per bulan; whz step 0,5 half-up). **Aku DILARANG mengetik ulang nilai dari ingatan.**
2. **`nutrition_rules.json`** — (a) file ditinjau ahli gizi/bidan, atau (b) seed Lampiran A PRD bertanda `reviewed_by=null`. Loader JSON belum ditulis (menunggu file).
3. Setelah tabel ada: verifikasi z-score 30 kasus (selisih ≤ 0,01; kolom −2 SD ≈ −2,00; median = 0) + rekonsiliasi terhadap WHO Anthro (PRD §9.2/9.3).

### Catatan
- `DietaryDiversity` tidak menyimpan target di kode; angka 5/8, 5/7, dan tips hanya boleh dari `nutrition_rules.json`.
- Scanner <6 bulan dinonaktifkan (`isScanSupportedForAge`); kartu "ASI eksklusif" menyusul di UI (Batch 5/6).

### MENUNGGU PEMILIK (blocker Batch 3)
1. **Tabel SD Permenkes 2/2020** — format apa pun (PDF/CSV/Excel/foto); aku konversi ke `assets/reference/` sesuai spec di `docs/reference-notes.md`. Aku DILARANG mengetik ulang nilai tabel dari ingatan.
2. **`nutrition_rules.json`** — boleh (a) file yang sudah ditinjau ahli gizi/bidan, atau (b) contoh Lampiran A PRD sebagai seed bertanda `reviewed_by=null` sampai ditinjau.

### Status
Domain inti terbangun + unit test hijau; nilai tabel & loader `nutrition_rules.json` menunggu file dari pemilik.

## Batch 5.3 — Perbaikan model Gemini & timeout (2026-11-16)

### Temuan
- Semua panggilan scan ditolak dengan `outcome=gemini_http_error, status=404` untuk model `gemini-2.5-flash`, `gemini-1.5-flash(-latest)`, dan `gemini-2.0-flash`.
- Listing `v1beta/models` menunjukkan key project ini tidak lagi bisa memakai `gemini-2.5-flash`:
  "This model models/gemini-2.5-flash is no longer available to new users. Please update your code to use models/gemini-3.8-flash".
- API key berfungsi; `health` = 200; `listModels` menampilkan `models/gemini-3.8-flash`, `models/gemini-2.5-flash-lite`, dst.
- Dengan `gemini-3.8-flash` fungsi berjalan tetapi >25 detik (timeout di 25 000 ms); log `timeout` terbaca.

### Perbaikan
- `GEMINI_TIMEOUT_MS`: 25 000 → **45 000** (aman di bawah limit eksekusi Edge Function; model 3.x butuh waktu lebih untuk satu foto).
- Default `GEMINI_MODEL`: `gemini-1.5-flash` (usang) → **`gemini-3.8-flash`**; override tetap lewat `SUPABASE_SECRET/GEMINI_MODEL`.
- Setiap `safeLog` outcome sekarang menyertakan `model: GEMINI_MODEL` — sehingga "tuduhan model salah vs key salah vs kuota habis" bisa dibaca langsung dari log.

### Verifikasi
- `flutter analyze` → No issues found (kode app tidak berubah).
- `flutter test` → 232/232 passed.
- Fungsi tetap perlu di-redeploy manual oleh pemilik setelah merge (secret `GEMINI_MODEL=gemini-3.8-flash` sudah diatur di Dashboard).

## UX Refactor (UX-1 & UX-2) — Informasi & Riwayat (2026-11-13)

### Dependency baru
**Tidak ada.** Semua elemen (segment control, strip 7 hari, kalender, ring) dibuat sendiri dari komponen yang sudah ada; tidak ada paket tambahan.

### UX-1 — Infrastruktur "Hari ini" & riwayat
1. `lib/core/time/clock.dart` (`clockProvider`) dan `lib/core/time/local_dates.dart` (rentang hari/bulan, `localRecentDaysRange`, `localDayRange`, `localMonthRange`, `localDayDifference`, `addLocalMonths`) — aritmetika tanggal lokal murni dan teruji.
2. `FoodLogRepository.listLogs(childId, {from, to})`; query Supabase dibatasi rentang (`gte`/`lt`, limit 1000, urut naik) sehingga catatan hari ini tidak lagi menarik seluruh riwayat dan batas baris server tidak bisa memotong data terbaru.
3. `foodLogsProvider` kini hanya hari ini; `historyLogsProvider` (30 hari, `FutureProvider.family`) dan `historySummaryProvider` (evaluasi per hari dengan usia SAAT ITU) baru; `piringTodayProvider` memakai `clockProvider`.
4. Domain baru `meals/domain/services/history_summary.dart` (`HistoryDay`, `HistorySummary`, `HistoryEvaluator`, jendela 30 hari termasuk hari ini, target mengikuti `nutrition_rules.json` per usia saat itu).
5. `AppShell` (TodayWatcher) meng-invalidate provider hari ini dan riwayat saat resume serta melewati tengah malam; `localPrefsProvider` dipindah ke `core/storage/local_prefs.dart` (router tidak lagi mendefinisikannya).
6. Unit test: `test/features/history_summary_test.dart` (7 test) dan `test/core/time/local_dates_test.dart` (7 test); `makan_flow_test` diberi assert reset target saat ganti hari.

### UX-2 — Arsitektur informasi & copy (layar Makan → `Hari ini | Riwayat`)
1. **Navigasi Makan kini dua bagian (segmented)**: "Hari ini" (target harian + checklist + catatan hari ini) dan "Riwayat" (30 hari terakhir: ringkasan, strip 7 hari, kalender bulan, detail hari). Destinasi tetap 3; riwayat tidak memperbanyak tab.
2. **Checklist kelompok pangan berlabel**: ASI baris pertama; tiap baris ikon + nama + contoh; status selalu berpasangan (ikon + teks "Tercatat"/"Belum tercatat", tidak pernah warna saja); aksi eksplisit "Catat" / "Hapus" (atau "Catat ASI" untuk ASI); baris juga bisa diketuk; tombol "Hapus" hanya tampil bila SEMUA catatan yang memuat kelompok itu adalah catatan satu-kelompok (tidak menghapus kelompok yang ikut tercatat di catatan gabungan); baris ASI diberi catatan sekunder di usia 24–59 bulan.
3. **Composer "Catat satu kali makan"**: sheet (waktu makan, centang beberapa kelompok, porsi opsional — porsi tidak dinilai); menghasilkan SATU `FoodLog` multi-kelompok memakai field yang sudah ada (`meal_type`, `items[].portion`, `groups`); tombol Simpan nonaktif sampai minimal satu kelompok dipilih; snackbar dengan "Urungkan".
4. **Timeline "Catatan hari ini"** dipakai ulang untuk hari ini dan riwayat (`FoodLogList`/`FoodLogRow`): hapus lewat geser atau tombol + "Urungkan".
5. **Riwayat**: kartu ringkasan 30 hari (hari ada catatan / mencapai target / ada protein hewani); strip 7 hari ketuk untuk memilih hari; kalender bulan (hanya tanggal yang masuk jendela 30 hari dan bukan masa depan yang bisa dipilih); detail hari (progress ring + protein hewani + daftar catatan yang bisa dihapus); error/offline dengan tombol "Coba lagi"; empty state "Belum ada catatan" + CTA kembali ke catatan hari ini.
6. **Beranda**: strip 7 hari di bawah hero (`HomeWeekStrip`) + tombol "Lihat riwayat" yang membuka tab Makan bagian Riwayat; ketuk satu hari langsung membuka hari itu.
7. **Copy dan onboarding ringan**: tur singkat sekali jalan (`PiringTourCard`, flag `piring_tour_seen` di `LocalPrefs`, bisa ditutup); sheet penjelasan "Cara kerja Piring Hari Ini" (aturan target, reset harian, ASI sekali per hari, protein hewani dicek terpisah, porsi tidak dinilai, penanda aturan belum ditinjau ahli gizi).
8. **Header layar di-pin** (ScreenHeader + segment tetap terlihat saat menggulir); FAB "Foto makanan" diberi `heroTag: null` (menghindari duplicate Hero tag antara Beranda/Makan yang sebelumnya memicu assertion runtime di widget test).
9. **`SegmentControl` minimum height 44 → 48dp** (target sentuh); `makanSectionProvider`/`historySelectedDayProvider` (`NotifierProvider`) membuat Beranda dapat mem-pre-select hari riwayat sebelum pindah tab.
10. **Catatan arsitektur (penting)**: nested autoDispose family providers (`foodLogsProvider` + `piringTodayProvider` + `historySummaryProvider`) memicu assertion `UncontrolledProviderScope` saat `TickerMode` pindah tab dengan invalidation tertunda. Keempat provider itu dijadikan non-autoDispose (murah; di-invalidate eksplisit saat mutasi; invalidation didefer dengan `addPostFrameCallback`).
11. **Test**: `makan_flow_test` diperluas (riwayat menggantikan "hari sebelumnya dilipat", composer, lembar Cara kerja, tur sekali jalan, strip 7 hari Beranda → Riwayat, aksi ASI via key); `layout_scale_test` tetap hijau (360dp @1.3, light/dark); Semantics label untuk strip hari dan sel kalender.

### Verifikasi (2026-11-13)
- `flutter analyze` → **No issues found!**
- `flutter test` → **226/226 passed**.
- DoD §10.1: `LinearGradient|RadialGradient|SweepGradient` → 0; `\bColors\.(?!transparent)` di `lib/features` + `lib/shared` → 0; `GEMINI_API_KEY=<literal>` → 0; em dash (U+2014) di `.dart` → 0 (8 sisa komentar dari Batch 5 dirapikan).
- Layout: `test/features/layout_scale_test.dart` — Beranda/Tumbuh/Onboarding/Consent/Makan muat di 360×640 @1.3, light + dark, tanpa overflow.

### Belum terverifikasi (butuh kamu)
- Emulator/perangkat tidak tersedia saat pengerjaan (`adb` hanya menampilkan `emulator-5562` dalam status `offline`; SM A155F tidak terhubung). Verifikasi visual di perangkat (light/dark, navigasi Hari ini ↔ Riwayat, composer, kalender) belum dilakukan.
- Review ahli gizi `nutrition_rules.json` (`reviewed_by: null`) masih terbuka (PRD §9.1); tips dan target tetap dari berkas itu, tidak dikarang.
- Scanner end-to-end menunggu deploy Edge Function `analyze-meal` (kuota server 15/hari, Asia/Jakarta).

### Next (UX-3 .. UX-5)
- UX-3: design system v2 — motion (press states, transisi), ilustrasi `CustomPainter`, opsi avatar.
- UX-4: scanner manual (nama item tanpa foto), kamera fallback, alur "foto gagal → catat manual".
- UX-5: Tumbuh (empty state/informasi lebih ramah), onboarding/consent audit, audit a11y menyeluruh (360dp @1.3, target 48dp, Semantics), dokumen akhir + rencana commit per kategori (AI tidak commit).


## UX Refactor — UX-3, UX-4, UX-5 (2026-11-13)

### Dependency baru
**Tidak ada.** Ilustrasi dari `CustomPainter` (bukan PNG/aset), animasi memakai `TweenAnimationBuilder`/`AnimatedSwitcher` bawaan Flutter, motion token dari `AppMotion` yang sudah ada.

### UX-3 — Design system v2: motion, ilustrasi, avatar
1. `lib/core/theme/app_motion.dart` — token motion dipertahankan (`fast` 200, `normal` 250, `ring` 400, `easeOutCubic`) + tambahan helper `AppMotion.of(context, d)` yang mengembalikan `Duration.zero` bila pengguna meminta "kurangi animasi". (Pertama kali ditimpa lalu dipulihkan; token asli dipertahankan.)
2. **Ilustrasi kosong (CustomPainter, token-only, light/dark)**: `lib/shared/illustrations/empty_plate_illustration.dart` (piring bersih + sendok/garpu/uap) dan `seedling_illustration.dart` (bibit di pot). `EmptyState` kini menerima parameter `illustration` opsional. Dipakai di empty state Tumbuh (kartu status), Beranda/Anak (belum ada anak), Riwayat "Belum ada catatan" (piring), dan "Catatan hari ini" kosong.
3. **Motion**: `PiringProgressRing` teranimasi (`TweenAnimationBuilder`, 400ms); `AnimatedSwitcher` (250ms fade) saat pindah Hari ini/Riwayat; `AnimatedContainer` pada pilihan segment (200ms) dan baris checklist saat diketuk.
4. **Avatar baru**: `bunny`, `paw`, `music`, `cookie`, `sailboat` ditambahkan ke `AvatarCatalog` (total 13 opsi); form avatar otomatis memakai `Wrap` sehingga tidak overflow.
5. **Test**: test piring_ring & makan_flow tetap hijau (nilai progres hanya saat cincin digambar ulang).

### UX-4 — Catat manual tanpa foto dari pemindai
1. Sheet "**Catat manual**" (`manual_food_sheet.dart`): ketik nama makanan (60 char), pilih kelompok (chip, minimal satu), pilih waktu makan (segment), simpan satu `FoodLog` `source = manual` via `addManualItemLog` pada notifier (item bernama; `groups` union canonical; porsi tidak dinilai dan tidak ditanyakan).
2. Tombol "Catat manual" di pemindai (fallback kamera, top bar, panel error) kini membuka sheet itu (dulu lompat ke tab Makan). Berhasil disimpan → kembali ke layar sebelumnya + snackbar dengan "Urungkan".
3. Tombol Simpan dinonaktifkan sampai nama dan minimal satu kelompok terisi; error ramah bila gagal.
4. **Test**: `scan_flow_test` — alur fallback tanpa kamera: buka pemindai → sheet terbuka → validasi simpan nonaktif → isi nama + dua kelompok → tersimpan, `log.source == manual`, `groups == ['grains_tubers','flesh']`, kembali ke Beranda.

### UX-5 — Tumbuh & audit a11y; dokumen akhir
1. **Tumbuh**: kartu grafik menampilkan catatan "Belum cukup data untuk melihat tren. Tambah satu ukuran lagi." hanya saat pengukuran `< 2` (copy `growthTrendHint`, terpusat di `AppStrings`).
2. **Audit a11y (360×640 @1.3, light/dark)**: semua `IconButton` punya `tooltip`; segment ketuk ≥48dp (`SegmentControl` minHeight 48); status tidak pernah hanya warna (ikon + teks); Semantics untuk strip 7 hari/sel kalender/segment grup; `layout_scale_test` diperluas dengan segment Riwayat (ringkasan + kalender) di 360dp @1.3, light & dark — **tanpa overflow**.
   - Catatan trade-off: sel kalender & strip 7 hari ≈45-46dp lebar di 360dp (320dp konten / 7 kolom); tinggi 48dp; jadi tidak bisa 100% ≥48dp lebar tanpa mengurangi padding layar. Dicatat sebagai trade-off sadar.
3. **Copy & klaim**: tidak ada klaim diagnosis/pencegahan di seluruh `lib/` (hanya kalimat negasi/edukasi); nama aplikasi selalu dari `AppConfig.appName`.
4. **Dokumen**: `docs/commit-plan.md` baru (rencana staging `git add` + pesan konvensional per commit, dengan hasil verifikasi); catatan UX-1..UX-5 terpusat di sini; seluruh em dash di `.dart` dibersihkan (8 sisa komentar Batch 5).

### Verifikasi (2026-11-13, UX-1..UX-5)
- `flutter analyze` → **No issues found!**
- `flutter test` → **229/229 passed**.
- DoD §10.1: gradien 0; `\bColors\.(?!transparent)` di `lib/features` + `lib/shared` → 0; `GEMINI_API_KEY=<literal>` 0; em dash di `.dart` → 0.
- Layout: `test/features/layout_scale_test.dart` mencakup Beranda, Tumbuh, Onboarding, Consent, Makan hari ini, **Riwayat Makan (ringkasan + kalender)**, Kelola anak & formulir anak — semuanya 360dp @1.3 light/dark tanpa overflow.

### Belum terverifikasi (butuh kamu)
- Emulator/perangkat tidak tersedia saat pengerjaan; verifikasi visual di perangkat (transisi, ilustrasi, kalender, sheet catat manual) belum dilakukan.
- Review ahli gizi `nutrition_rules.json` masih terbuka; scanner end-to-end menunggu deploy `analyze-meal`.
- Commit BELUM dijalankan (manual oleh pemilik); lihat `docs/commit-plan.md`.


## UX-6 — Logo kelompok pangan (UX-2 selesai, sesuai request pemilik, 2026-11-15)

### Dependency baru
**Tidak ada** di `pubspec.yaml` (hanya menambahkan `assets/logo_kelompok_norm/` ke `assets:`). Normalisasi aset dilakukan satu kali memakai Pillow (offline, bukan bagian aplikasi).

### Aset: normalisasi satu kali (`assets/logo_kelompok/` → `assets/logo_kelompok_norm/`)
- Semua PNG sumber 512x512, transparan, tetapi bidang kontennya TIDAK seragam (susu 53%x97%, daging 100%x68%, nasi hampir penuh, dst). BoxFit.contain tanpa normalisasi membuat logo terlihat beda ukuran.
- Normalisasi: crop tiap PNG ke opaque bbox -> skala agar SISI TERPANJANG konten = 392px (76.5% kanvas) -> tempel di tengah kanvas transparan 512x512. Hasil: semua logo punya diameter visual identik; tidak ada yang terpotong/meluber.
- Originals `assets/logo_kelompok/` TIDAK diubah dan TIDAK dibundel; `assets/logo_kelompok_norm/` (nama = kode resmi PRD 3.7: breast_milk, grains_tubers, legumes_nuts, dairy, flesh, eggs, vit_a_fruit_veg, other_fruit_veg) yang didaftarkan di pubspec.

### UI: widget FoodGroupLogo (satu sumber)
- `lib/features/meals/presentation/widgets/food_group_logo.dart`: map kode kelompok → asset; `fit: BoxFit.contain`, `filterQuality: high`; ukuran gambar dikontrol parameter `size` (default 34; konten terlihat ±76% = ±26dp); kode tak dikenal -> ikon netral (tanpa crash).
- Lingkaran semua konsisten `primaryContainer` (mis. checklist 40dp + timeline catatan 40dp + sheet "Catat manual" 26dp + hero ASI eksklusif); status "sudah tercatat" tetap lewat badge centang, tidak pernah hanya warna (PRD 7.2).
- Ikon kelompok (`foodGroupIcon` di meal_presentation.dart) DIHAPUS: tidak ada lagi ikon generik di samping/gantinya logo di semua titik (log timeline, checklist, composer, sheet ASI/hero, sheet info ASI, kartu eksklusif <6 bulan).

### Verifikasi (2026-11-15)
- `flutter analyze` → No issues found!
- `flutter test` → 232/232 passed (3 test baru: semua 8 asset termuat light, dark, dan fallback kode tak dikenal).
- Layout 360dp @1.3: `layout_scale_test` tetap hijau, Makan hari ini & Riwayat muat.
- Catatan visual: pemilik belum verifikasi di perangkat (emulator/device belum terhubung); cek visual di lapangan masih diperlukan.


## Batch 7 - Edge Function `ask-nutrition` + Tanya Gizi (2026-11-17)

### Ruang lingkup
PRD Batch 7: Edge Function `ask-nutrition` (red flag, kuota, Gemini) + layar **Tanya Gizi** (UI chat modern, kartu aman, kuota terlihat, riwayat terhapus) + polish UI/UX mengikuti design system yang ada. **Tanpa dependency baru** (`url_launcher` sudah ada; ilustrasi & animasi buatan sendiri; `CustomPainter`). Tidak ada perubahan skema Supabase (tabel `chat_messages` & `ai_usage` dari Batch 2 dipakai apa adanya, RLS teruji).

### Batch 7.1 - Edge Function `supabase/functions/ask-nutrition/index.ts`
1. Verifikasi JWT -> 401. Validasi zod: `{ messages (1-10, role user|assistant, content <=4000), context { age_months 0-60, sex male|female } }`, pesan terakhir wajib dari user.
2. **Red flag TANPA LLM lebih dulu** (PRD section 3.8): kejang/sesak/tersedak/biru -> `safety_flag="emergency"` + jawaban tetap IGD/112; lemas/tidak mau minum/muntah terus/diare/berdarah/bengkak setelah makan/alergi/demam -> `"refer_doctor"`. Red flag tidak memanggil Gemini dan **tidak menghanguskan kuota**.
3. Kuota atomik `consume_ai_quota('chat', CHAT_DAILY_LIMIT default 30)` SEBELUM Gemini -> 429 quota_daily.
4. Gemini `GEMINI_MODEL` env (default `gemini-3.8-flash`, INVARIAN deploy sama dgn analyze-meal) dengan response_schema JSON terstruktur; timeout **45 dtk** (deviasi sadar dari PRD 25 dtk, sejalan Batch 5.3). Konteks ke Gemini HANYA `age_months` + `sex` (disisipkan ke system instruction); tidak pernah nama/tanggal lahir.
5. Validasi ulang respons di server (answer 1-1500 char, safety_flag enum, followups maks 2 x 140 char) -> 502 gemini_schema_reject bila melenceng. Log metadata saja (request_id, outcome, duration_ms, model). `config.toml`: `[functions.ask-nutrition] verify_jwt = true`. `deno check` lulus.
6. Deviasi sadar dari urutan PRD: red flag tidak memakai kuota (short-circuit sebelum `consume_ai_quota`).

### Batch 7.2 - Domain & Data (`features/chat/`)
Domain murni: entity `ChatMessage` (+ enum `ChatRole`, `ChatSafetyFlag` dgn mapping db), `AskNutritionResult` (fromJson defensif), `ChatException` (kode PRD), kontrak `ChatRepository`, `ChatUseCases.askQuestion` (validasi usia/jenis kelamin/pesan, jendela 10 pesan kronologis). Data: `ChatMessageModel`, `ChatRepositoryImpl` (list/add/clear via `chat_messages` RLS; invoke Edge Function; `ai_usage` SELECT-sendiri untuk badge kuota - Asia/Jakarta, `null` bila gagal -> badge disembunyikan).

### Batch 7.3 - UI/UX Tanya Gizi (sesuai design system)
Navigasi ke-4 **Tanya** (`chat_bubble_outline_rounded`/`chat_bubble_rounded`, `/tanya`, IndexStack cabang baru; Resep tetap menyusul Batch 8). Layar: `ScreenHeader` (eyebrow `EDUKASI GIZI UMUM`, judul, tombol hapus riwayat dgn dialog konfirmasi); **banner tetap** "Informasi umum, bukan pengganti tenaga kesehatan" (satu baris, ellipsis); badge kuota `Sisa n/30 hari ini` (tabular figures, disembunyikan bila tidak terbaca); area pesan `ListView(reverse)`: bubble user (`primary`, kanan) / asisten (avatar tonal `spa_rounded`, `surface` + hairline, kiri); **kartu safety** bukan bubble: `refer_doctor` (tonal kuning, ikon+teks, tombol Mengerti) dan `emergency` (tonal merah, ikon+teks, tombol **Hubungi 112** -> `tel:112`, + catatan IGD); indikator "sedang menjawab" 3 titik (hormati disableAnimations); input bar menempel di atas keyboard (disabled saat mengirim, anti double-send); follow-ups dari jawaban terbaru sebagai chip yang langsung bertanya; empty state (`ChatIllustration` CustomPainter token-only + 4 chip pertanyaan cepat yang bisa digulir); kartu error ramah per kode (`quota_daily`, `timeout`, `offline`, `unauthorized`, `ai_unavailable`) dgn **Coba lagi**; banner gagal-sinkronisasi riwayat + **Simpan lagi** (retry persist TANPA memanggil AI ulang, kuota aman). `AppConfig.chatDailyLimit = 30` (hanya tampilan; penegak = server). Copy terpusat di `AppStrings` (suara "kamu", tanpa klaim klinis). Semua status selalu ikon + teks; tap targets >= 48dp; `Semantics` lengkap.

**Perbaikan tata letak penting (a11y 360dp @1.3):** versi awal meninggalkan hanya ~52dp untuk area pesan di 360x640 @1.3 (header rendahan membengkak + banner 2 baris + input 5 baris). Diperbaiki: subtitle dihapus (redundan dgn banner), banner satu baris, input bar dipadatkan, `maxLines` 4. Area pesan kini ~140dp+ dan bisa digulir; semua teks utuh, tidak ada overflow.

### Batch 7.4 - Verifikasi (2026-11-17)
- `flutter analyze` bersih. `flutter test` **258/258** (baseline 232; +26: `chat_domain_test.dart` 16, `tanya_flow_test.dart` 8, `layout_scale_test.dart` +2).
- Layout 360dp @1.3 light/dark: Tanya muat, tidak ada overflow.
- DoD 10.1: gradien 0; `\bColors\.(?!transparent)` di features/shared 0; `GEMINI_API_KEY=<literal>` 0 (hanya `Deno.env.get`); em dash di `.dart` 0 (2 file batch lain yang ikut tersapu dikembalikan).
- `deno check supabase/functions/ask-nutrition/index.ts` -> exit 0.

### Belum terverifikasi (menunggu pemilik)
1. **Deploy `ask-nutrition`** via Dashboard (Edge Functions -> New function -> tempel `index.ts` -> Verify JWT = ON -> Deploy). Secret `GEMINI_API_KEY`/`GEMINI_MODEL` sudah ada (gemini-3.8-flash); `CHAT_DAILY_LIMIT` opsional (default 30 di kode).
2. **Smoke test end-to-end** di perangkat: tanya biasa, kuota, offline, red flag (kejang/demam/diare), emergency kartu 112, hapus riwayat.
3. **Evaluasi keamanan PRD 9.3(4)**: 30 prompt red flag + 20 prompt di luar topik/diagnosis/dosis; target >= 95% red flag dieskalasi benar; 100% permintaan diagnosis/dosis ditolak. Aku siapkan daftar promptnya (lihat dokumen commit-plan) bila dibutuhkan.
4. Verifikasi visual 1.3 text scale + light/dark di perangkat (ilustrasi chat, kartu safety, chip pertanyaan).

### Catatan
- Riwayat chat satu thread global; konteks usia/jenis kelamin diambil dari anak terpilih **saat kirim** (bukan per-thread anak). `child_id` disimpan di baris pesan (boleh null).
- Fix CI (2026-11-18): `flutter-version` di `.github/workflows/ci.yml` di-pin ke `3.32.8` karena `channel: stable` mengambang ke Flutter terbaru (≈3.47) dan `flutter analyze` di CI gagal dengan 69 `deprecated_member_use` (`package:flutter/material.dart` ditandai deprecated setelah v3.47.0-0.pre). Lokal memakai 3.32.8 dan bersih. Migrasi ke SDK terbaru adalah pekerjaan terpisah, bukan fitur.
- Follow-up chips tidak disimpan di DB (sesi aktif saja); `safety_flag` dari server disimpan apa adanya di `chat_messages`.
- `RedFlagChecker` (Dart, Batch 3) dan daftar kata kunci di Edge Function harus tetap selaras; tidak ada kode bersama antar runtime (disengaja).
- Ilustrasi `ChatIllustration` token-only CustomPainter (`shared/illustrations/`).
- Commit belum dijalankan (manual oleh pemilik) - lihat `docs/commit-plan.md`.

## Batch 8 Blok A — Pengingat lokal + Pengaturan minimal (2026-11-18)

### Ruang lingkup
PRD Batch 8 hanya bagian **pengingat lokal** (PRD §6.8, §12) + layar Pengaturan minimal (bagian Pengingat saja). **Blok B (Resep) TIDAK dikerjakan** — `recipes.json` belum disediakan pemilik; implementasi fitur Resep menunggu file tersebut (skema PRD §9.1, ≥24 resep, ditinjau ahli gizi/bidan).

### Dependency baru (disetujui pemilik 2026-11-18)
- `flutter_local_notifications` (^20.1.0) — notifikasi lokal terjadwal (ukur anak bulanan & catat makan harian), tanpa server/push; stack PRD §4. Alasan tertulis sesuai aturan dependency baru.
- `timezone` (^0.10.1) — dependensi transitif resmi untuk `zonedSchedule`; zona waktu lokal dipilih dari offset perangkat (Indonesia tidak mengenal DST), fallback UTC.

### Perubahan
1. `lib/core/notifications/reminder_schedule.dart` — `ReminderSettings` (default MATI) + next-occurrence murni (harian & bulanan, tanggal 1–28).
2. `lib/core/notifications/notification_service.dart` — abstraksi `ReminderScheduler` (fake di tes) + `LocalNotificationScheduler`: init tz, izin Android 13+/iOS (opsional, default ditolak), channel lokal `cek_gizi_reminders`, `zonedSchedule` mode inexact (tanpa izin exact alarm), id 7101 (bulanan) & 7102 (harian); jadwal dibatalkan dan ditulis ulang penuh pada setiap perubahan.
3. `lib/core/notifications/reminder_providers.dart` — `reminderSettingsProvider` (Notifier; mundur atomik + snackbar bila penerapan gagal) dan `reminderSchedulerProvider` (diooverride di tes).
4. `LocalPrefs` — 5 kunci pengingat (bulanan: enabled + hari 1–28; harian: enabled + jam/menit, default 19.00).
5. Layar **Pengaturan minimal** `/settings` (`lib/features/settings/presentation/screens/settings_screen.dart`): bagian **Pengingat** saja; switch untuk dua pengingat, pemilih tanggal 1–28 & pemilih jam; default MATI; catatan kaki jujur. Profil/akun/privasi tetap Batch 9.
6. Avatar di header Beranda (`account_circle_rounded`, tooltip "Pengaturan") membuka `/settings`; tombol "Kelola anak" tetap ada.
7. Router: rute `/settings` di luar shell (layar push, bukan tab).
8. AndroidManifest: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, receiver `ScheduledNotificationReceiver` & `ScheduledNotificationBootReceiver` (reschedule setelah reboot/ganti paket). iOS tidak diubah. Semua copy di `AppStrings`; tidak ada push server; tidak ada data anak di isi notifikasi.

### Verifikasi (2026-11-18)
- `flutter analyze` — **No issues found!**
- `flutter test` — **281/281 passed** (baseline 267; +12 `reminder_schedule_test`, +2 layout test Pengaturan light/dark).
- Layout 360dp @1.3 light + dark: layar Pengaturan (pengingat) muat; Kelola anak tetap hijau.
- DoD §10.1: gradien 0; `Colors.xxx` di features/shared tetap 0.

### Belum terverifikasi (butuh kamu)
- Perangkat nyata: tampilan notifikasi Android 13+ (izin `POST_NOTIFICATIONS` pertama kali), penjadwalan setelah reboot, dan pemilih waktu bawaan sistem.
- Blok B (Resep) menunggu `recipes.json` dari pemilik.
- Commit belum dijalankan (manual oleh pemilik).

## UX-0 & UX-1 — Spesifikasi visual v2.1 + navigasi 5 tab (2026-11-18)

### Ruang lingkup
Batch UX-0 (kontrak visual) + UX-1 (arsitektur navigasi baru). **Tidak ada fitur gizi baru dan tidak ada data karangan.** Semua perhitungan, aturan, dan copy fitur tetap seperti batch sebelumnya.

### Dependency baru
**Tidak ada.** Navbar, bubble, panel kamera, dan token baru dibuat dari widget/token yang sudah ada.

### UX-0 — Kontrak visual (`docs/ui-guidelines.md`)
1. Dokumen baru `docs/ui-guidelines.md`: prinsip, larangan (gradien/`Colors.*`/ikon tanpa label), tabel token warna light+dark, skala tipografi, spacing/radius/motion, tiga lapisan permukaan (`card`/`sunken`/`hero`), aturan navigasi, inventaris komponen `lib/shared/widgets/`, pola per layar, a11y, dan copywriting.
2. Token baru: `displayMetric` (40/44, w700) dan `navLabel` (11,5/14, w500) di `AppTextStyles`.
3. Enam token hero di `AppColors` (light + dark, ikut `copyWith`/`lerp`): `heroSurface`, `onHeroSurface`, `onHeroSurfaceMuted`, `onHeroAccent`, `heroTrack`, `heroEdge`.
4. `AppSurfaces.hero` berubah dari tonal `primaryContainer` menjadi **permukaan solid dominan** (light `#1F6F54`; dark `#1E4A38` + hairline `heroEdge`), dengan kontras teks ≥ 4,5:1 yang diuji di `test/core/theme/app_theme_test.dart`.

### UX-1 — Navigasi 5 tab
1. `AppDestination` + `AppNavBar` kustom (`lib/features/home/presentation/widgets/app_nav_bar.dart`): **Beranda · Makan · Resep · Tumbuh · Akun**, pil tonal di destinasi aktif, label selalu tampil, tanpa garis atas, target sentuh ≥ 48dp. Urutan enum = urutan `StatefulShellBranch`.
2. Router: 5 cabang (`/`, `/makan`, `/recipes`, `/growth`, `/account`). `/tanya` menjadi route penuh di luar shell; `/settings` dihapus.
3. `TanyaBubble` (`features/chat/presentation/widgets/tanya_bubble.dart`) — pil berlabel "Tanya gizi" di kanan bawah, tampil di semua tab; Tanya tetap layar penuh dan kini punya tombol tutup eksplisit (dulu tab, tidak butuh tombol kembali).
4. `CapturePanel` (`features/meals/presentation/widgets/capture_panel.dart`) — pintu kamera satu-satunya, di tab Makan, disembunyikan untuk anak < 6 bulan. `PhotoScanFab` dihapus dari Beranda.
5. `AccountScreen` (`features/account/`) — profil anak + `ReminderSettingsSection` (logika pengingat dipindah dari `SettingsScreen`) + catatan privasi/disclaimer. `SettingsScreen` (`/settings`) dihapus; kebutuhan Batch 8 kini tinggal di tab Akun.
6. `RecipesScreen` (`features/recipes/`) — empty state jujur "Katalog resep sedang disiapkan" sampai `recipes.json` tersedia; tidak ada resep contoh.
7. `PiringHeroCard`/`PiringRing(hero: true)` memakai token hero; `Skeleton` menerima warna agar terbaca di atas hero.
8. Header Beranda dibersihkan (dua `IconButton` dipindah ke tab Akun/panel Makan) supaya satu layar punya satu aksi utama.

### Verifikasi (2026-11-18)
- `flutter analyze` → **No issues found!**
- `flutter test` → **287/287 passed** (baseline 281; +4 `test/features/navigation_test.dart`, +2 tes kontras token hero di `app_theme_test`; 2 tes FAB diganti 2 tes panel kamera, netral).
- Layout 360dp @1.3 light + dark: Beranda, Makan, Resep, Tumbuh, Akun, Tanya, dan Kelola anak tanpa overflow (`layout_scale_test` diperbarui ke tab Akun/Resep).
- DoD §10.1: gradien 0; `Colors.xxx` di `lib/features` + `lib/shared` hanya `Colors.transparent`; `GEMINI_API_KEY=<literal>` 0.

### Deviasi sadar (keputusan pemilik)
- PRD v2.0 §6.2 masih menyebut 3–4 tab dengan Tanya sebagai tab. Implementasi kini 5 tab dengan Tanya sebagai bubble + route penuh. **PRD perlu diselaraskan ke v2.1** (menunggu izin pemilik untuk mengedit `PRD.md`); fitur & isi tidak berubah.
- Batch 8 memakai rute `/settings`; pada UX-1 isinya dipindahkan ke tab Akun. Tidak ada fungsi yang hilang.

### Belum terverifikasi (butuh kamu)
- Verifikasi visual di perangkat (light & dark, 360dp @1.3): hero hijau, pil navbar, bubble Tanya, panel kamera.
- Review apakah tab "Resep" sebaiknya disembunyikan sampai `recipes.json` ada (kini tampil dengan empty state jujur).
- Commit belum dijalankan (manual oleh pemilik).

## Batch 8 — Perbaikan build Android (core library desugaring) (2026-11-18)

### Temuan
`flutter run` (APK debug) gagal di task `:app:checkDebugAarMetadata`:
`flutter_local_notifications` membutuhkan **core library desugaring** untuk `:app` (memakai API `java.time` di perangkat lama).

### Perubahan (`android/app/build.gradle.kts`)
1. `compileOptions`: tambah `isCoreLibraryDesugaringEnabled = true`.
2. Dependency Gradle baru (bukan pub): `com.android.tools:desugar_jdk_libs:2.1.4` — versi yang dipatok oleh README `flutter_local_notifications` 20.1.0; dicantumkan resmi sesuai aturan dependency baru.
3. Java/Kotlin tetap 11 (desugaring kompatibel; tidak ada alasan menaikkan menjadi 17).

### Verifikasi
- `flutter build apk --debug` → **✓ Built** `build/app/outputs/flutter-apk/app-debug.apk` (Gradle `assembleDebug` 105 dtk). `Exit code 1` pada pemanggilan sebelumnya hanya karena stderr PowerShell (peringatan x86), bukan kegagalan build.
- `flutter analyze` / `flutter test` tidak berubah (tidak ada kode Dart yang disentuh).

## Fix splash + UX-2 + UX-3 — startup tanpa "macet di logo", Makan & motion v2.2 (2026-11-18)

### Fix "stuck di logo CekGizi" (prioritas)
**Temuan:** `main()` menunggu `Supabase.initialize` + `signInAnonymously` tanpa batas waktu. Saat jaringan lambat/putus, eksekusi berhenti sebelum `runApp`, sehingga pengguna melihat splash native (ikon CekGizi) tanpa henti. Splash native bawaan juga berwarna putih generik.

**Perubahan:**
1. `lib/core/bootstrap/startup_guard.dart` (baru): `runStartupTask<T>()` — timeout + tangkap galat, hanya mencatat tipe galat (tanpa data sensitif), tidak pernah melempar.
2. `auth_bootstrap.dart`: inisialisasi SDK (batas 8s) dan sesi anonim (batas 5s) lewat guard. Kegagalan sesi tidak menghentikan aplikasi; layar terkait tetap punya tombol "Coba lagi".
3. `main.dart`: bootstrap tidak lagi di-`await` sebelum `runApp`; semua langkah I/O tetap dibatasi sehingga frame pertama selalu tergambar. `CekGiziApp(backendReady: …)` menampilkan `_StartupScreen` bermerek + indikator memuat sampai bootstrap selesai (tanpa `MaterialApp.router`, memakai `Theme` + `Directionality` sendiri).
4. `OpeningScreen`: mulai setelah frame pertama, `TickerFuture` dibungkus (ticker bisa dibatalkan sistem), **timer pengaman 1900 ms** memaksa lanjut bila animasi tidak pernah selesai, `cacheWidth: 352` agar PNG 1,2 MB tidak di-decode penuh.
5. Android: `values/colors.xml` + `values-night/colors.xml` (krem `#FBF7F0` / gelap `#101713`), `drawable(-v21)/launch_background.xml` memakai warna tersebut, serta `values(-night)-v31/styles.xml` untuk splash sistem Android 12+ (latar + ikon merek). Tidak ada gambar baru; ikon memakai `ic_launcher` yang sudah ada.
6. Tes regresi: `test/core/bootstrap/startup_guard_test.dart` (3 tes: sukses, future menggantung, galat), `test/features/splash/opening_screen_test.dart` (napas animasi + jalan saat "kurangi animasi" aktif), dan `test/app_test.dart` (layar bermerek tampil selagi backend disiapkan, lalu hilang setelah selesai).

### UX-2 — Makan & kamera
1. `CapturePanel` disusun ulang: eyebrow "FOTO PIRING", judul, ilustrasi viewfinder, tiga langkah (Foto piring → Dikenali AI → Kamu periksa), catatan privasi, CTA utama, serta pintu offline **"Catat tanpa foto"** (membuka sheet catat manual). Seluruhnya di atas permukaan hero dengan token `onHeroSurface*`.
2. `PlateViewfinderIllustration` (baru, `shared/illustrations/`): CustomPainter token-only — sudut bingkai, lingkaran putus-putus, piring, tiga benda makanan abstrak. Dipakai di panel Makan (onHero) dan di layar kamera saat memuat (onCamera, kontras mengikuti tema terbalik).
3. `ScanScreen`: loading memakai ilustrasi + `AppStrings.scanPreparing`; viewfinder responsif menggantikan lingkaran statis; header & kontrol bawah memakai scrim solid (bukan bayangan/gradien).
4. `MakanTodayView`: panel ringkasan kini punya hairline + pita status protein hewani (ikon + teks + warna); tur "Mulai dari sini" dipindah ke dekat checklist.

### UX-3 — warna, gerak, ilustrasi
1. Dua token baru di `AppColors` (`accentContainer` / `onAccentContainer`, ikut `copyWith` + `lerp`) untuk pita hangat "belum ada protein hewani"; kontras ≥ 4,5:1 diuji di `app_theme_test.dart`.
2. `SectionReveal` (baru, `shared/widgets/`): masuk 250 ms (opacity + 8 dp), lewat `AppMotion.of` sehingga "kurangi animasi" menonaktifkannya. Dipakai pada panel kamera & ringkasan Makan.
3. `PiringRing` besar kini menyala bertahap 400 ms (track digambar untuk semua busur, busur terisi mengisi dari kiri ke kanan); `PiringProgressRing` sudah lebih dulu animatif.
4. `AppTheme`: tema terpadu untuk `TextButton`, `IconButton`, FAB (pill, elevasi rendah), `Chip`, `ProgressIndicator`, dan `SnackBar` (floating, hairline, tanpa elevasi) — menghilangkan tampilan "polos" default Material.

### Dependency baru
**Tidak ada.** Semua komponen memakai Flutter SDK + token yang sudah ada.

### Verifikasi (2026-11-18)
- `flutter analyze` → **No issues found!**
- `flutter test` → **293/293 passed** (baseline 287; +3 startup guard, +1 opening reduce-mode, +1 kontras token hangat, +1 layar startup bermerek).
- DoD §10.1: `LinearGradient|RadialGradient|SweepGradient` = 0; `Colors.*` (kecuali `transparent`) di `lib/features` + `lib/shared` = 0.
- Layout 360dp @1.3 light + dark: Makan tanpa overflow (pita status dibungkus `Expanded` agar teks panjang tidak melebar).

### Catatan tes
- Dua tes `scan_flow_test` dan satu tes tur `makan_flow_test` diperbarui untuk menggulir ke CTA/tur yang sekarang berada di bawah lipatan akibat panel kamera yang lebih tinggi. Alur & asersi fitur tidak berubah.

### Belum terverifikasi (butuh kamu)
- Perangkat nyata: apakah splash benar-benar hilang saat jaringan mati (coba mode pesawat saat membuka aplikasi), serta tampilan splash Android 12+ light/dark.
- Review visual akhir light/dark @1.3 untuk panel kamera & ring animasi di perangkat.
- Commit belum dijalankan (manual oleh pemilik).

## UX-2b — Header Makan ikut menggulir (2026-11-18)

### Temuan
Kepala Makan (tanggal, judul, ganti anak, segmen Hari ini/Riwayat) disematkan di luar daftar sehingga selalu menutupi konten saat pengguna menggulir — tidak seperti Beranda.

### Perubahan
1. `makan_header.dart` (baru): `MakanHeader` — kepala Makan (eyebrow tanggal + ScreenHeader + SegmentControl) sebagai satu komponen.
2. `MakanTodayView` & `MakanHistoryView`: `MakanHeader` menjadi anak pertama daftar, sehingga seluruh kepala ikut menggulir.
3. `MakanScreen`: header/segmen dihapus dari posisi statis; body hanya berisi `AnimatedSwitcher` berisi salah satu bagian.
4. `makan_flow_test` ("riwayat"): gulir kembali ke segmen sebelum mengetuknya; alur tetap sama.

### Verifikasi
- `flutter analyze` → **No issues found!**
- `flutter test` → **293/293 passed**.
- Perilaku: kepala hilang dari layar saat menggulir (identik dengan Beranda).
- Commit belum dijalankan (manual oleh pemilik).

## UX-4 — Beranda & Tumbuh: 3 blok berhierarki (2026-11-18)

### Ruang lingkup
Perbaikan struktur & presentasi sesuai pemetaan UX-4. **Tidak ada aturan gizi, angka, atau resep baru** — semua nilai tetap berasal dari domain (`PiringDay`, `GrowthSummary`, `GrowthStatusCopy`).

### Beranda
1. `PiringHeroCard`: hero tetap satu per layar (ring + angka dominan), kini ditambah **2 ubin metrik berdampingan** di dalam permukaan yang sama, dipisah hairline: protein hewani (ikon+teks, pindah dari status line) dan tren berat (`GrowthSummary.weightDeltaOf`; "Belum ada ukuran" bila kosong).
2. Identitas anak pindah ke header sebagai `ChildSwitcherButton` — `ChildSwitcherCard` tidak dipakai lagi di Beranda.
3. `HomeWeekChips` (baru): strip 7 hari jadi **pil horizontal** yang bisa digeser; `WeekStrip` grid tetap dipakai di Riwayat Makan. `openWeekHistory()` diekstrak agar kedua pintu memakai satu logika.
4. `PiringTipsCard`: bukan kartu/sunken lagi — jadi satu baris ringkas (maks 2 baris + aksi inline) yang ditempatkan sebagai `footer` di dalam `GrowthStatusCard`. Hasilnya 3 blok: **Fokus hari ini → Minggu ini → Tumbuh ringkas**.

### Tumbuh
1. `ZScoreSummaryStrip` (baru): tiga ubin (Tinggi, Berat, BB/TB) memuat z-score + status ikon/teks/warna, **sekaligus pemilih indeks grafik** — menggantikan `SegmentControl` terpisah.
2. `GrowthChartCard` jadi **full-bleed** (menyentuh tepi layar; hairline atas/bawah, tanpa kartu melayang). Blok lain dibungkus padding 20dp.
3. Riwayat pengukuran jadi **accordion kustom** (`Semantics(expanded:)`, `AnimatedSize`, hormati `AppMotion.of`): ringkasan + status selalu terlihat, z-score & aksi edit/hapus dibuka saat diketuk. `ExpansionTile` tidak dipakai karena memicu assert semantics pada Flutter 3.32.8.

### Perubahan tes
- `makan_flow_test`: `_berandaScrollable` mengambil `Scrollable` pertama karena Beranda kini punya daftar vertikal + strip horizontal; tes riwayat menggulir ke segmen sebelum mengetuk.
- `growth_flow_test`: gulir ke grafik/ubin/riwayat sebelum berinteraksi karena konten lebih tinggi.
- `layout_scale_test`: tinggi chip minggu dinaikkan (88dp) agar aman 360dp @1,3.
- `test/features/ux4_layout_test.dart` (baru, 2 tes): struktur 3 blok Beranda & perilaku accordion Tumbuh.

### Dependency baru
**Tidak ada.**

### Verifikasi (2026-11-18)
- `flutter analyze` → **No issues found!**
- `flutter test` → **295/295 passed** (baseline 293; +2 tes UX-4).
- `flutter build apk --debug` → **✓ Built**.
- DoD §10.1: gradien 0; `Colors.*` (selain `transparent`) di `lib/features` + `lib/shared` = 0.
- Layout 360dp @1.3 light + dark: Beranda & Tumbuh tanpa overflow.
- Commit belum dijalankan (manual oleh pemilik).

## UX-7 — Splash & Opening Lottie (2026-11-18)

### Ruang lingkup
Layar pembuka & splash diganti dari animasi logo Flutter statis menjadi **Lottie bermerek** yang disediakan pemilik. Tidak ada perubahan alur onboarding/consent.

### Dependency baru (disetujui 2026-11-18)
- **`lottie` (^3.3.1)** — renderer vektor untuk `cekgizi_opening.json` (1080×1080, 60fps, 3 dtk, 9 layer, tanpa aset gambar eksternal) sebagai pengganti animasi logo. Alasan: satu-satunya cara menampilkan Lottie secara aman di Flutter; tanpa plugin native, tanpa jaringan; tetap bisa diuji widget.

### Perubahan
1. `OpeningScreen` ditulis ulang: `Lottie.asset('assets/animations/cekgizi_opening.json', controller, repeat: false)`, `onLoaded` dipakai untuk mengatur durasi lalu `forward()`. Saat selesai → `context.go(nextLocation)` seperti sebelumnya. Reduce-motion dihormati (langsung lanjut). **Timeout pengaman 4,5 dtk** dan `errorBuilder` (fallback `_Wordmark`) menjamin tidak pernah macet seperti kasus splash lama.
2. `_StartupScreen` (yang tampil selagi backend disiapkan) disederhanakan: **solid `#145C45` + `CircularProgressIndicator`** — tidak ada logo ganda sebelum Lottie.
3. `AppSurfaces.splashSurface` / `onSplashSurface` / `onSplashSurfaceMuted` (baru): token konstan `#145C45`, sama dengan `Background_Surface` di dalam Lottie sehingga **tidak ada letterbox/warna berbeda** di light maupun dark.
4. Android: `values(-night)/colors.xml` → `splash_background = #145C45`; `launch_background.xml` / `drawable-v21` memakai warna tersebut; `values(-night)-v31` (Android 12+) memakai warna yang sama.
5. Tes `opening_screen_test.dart` diperbarui: mencari widget `Lottie` (bukan `Image`) dan memverifikasi pindah layar saat animasi selesai serta saat reduce-motion.

### Catatan penting — "logo Flutter"
Tidak ditemukan class splash/logo Flutter di engine yang dipakai (Flutter 3.32.8). Logo Flutter yang tampak sebelumnya kemungkinan besar berasal dari artefak **debug** (`flutter run`), bukan dari kode aplikasi. Setelah perubahan ini splash native sudah solid `#145C45`; jika logo masih muncul, **uninstall aplikasi lama / cek build release** (`flutter run --release`) — di release Flutter tidak menyuntik logo.

### Verifikasi
- `flutter analyze` → **No issues found!**
- `flutter test` → **295/295 passed**.
- `flutter build apk --debug` → **✓ Built**.
- DoD §10.1: gradien 0; `Colors.*` (selain `transparent`) di `lib/features` + `lib/shared` = 0.
- Perlu tinjauan di perangkat: light/dark, apakah video/Lottie terpotong atau pas, dan apakah logo Flutter benar-benar hilang saat debug/uninstall ulang.
- Commit belum dijalankan (manual oleh pemilik).

## UX-8 — Splash Satu Page, Logo Pusat, Ikon CekGizi (2026-11-18)

### Ruang lingkup
Lanjutan UX-7: perbaikan posisi Lottie, satu page splash, ganti launcher/splash icon bawaan Flutter, dan speed Lottie 0,65×.

### Dependency baru (disetujui 2026-11-18)
- **`flutter_launcher_icons` (devDependency, ^0.14.4)** — generate launcher icon Android (`ic_launcher`) dari `assets/logo/logo_splash_screen.png` sekali jalan; tidak di-ship di runtime. Alasan: sumber ikon default Flutter (`mipmap-*/ic_launcher.png`) harus diganti ke logo CekGizi tanpa manipulasi manual 5 density.
- `lottie` (^3.3.1) sudah tercantum di UX-7.

### Perubahan
1. **Ikon aplikasi**: sebelumnya `mipmap-*/ic_launcher.png` adalah **logo Flutter bawaan** — itulah yang tampak saat aplikasi dibuka. Kini digenerate dari logo CekGizi (`flutter_launcher_icons`; config di `pubspec.yaml`).
2. **Splash Android 12+** (`values-v31` & `values-night-v31`): `windowSplashScreenAnimatedIcon` dihapus → splash sistem **solid `#145C45` tanpa ikon**. Logo pertama kali muncul di dalam Lottie.
3. **Satu page**: `_StartupScreen` dihapus. `CekGiziApp` langsung `MaterialApp.router`; `backendReadyProvider` (baru, default = future selesai untuk tes) di-override di `main()` dengan `bootstrapBackend()`. `OpeningScreen` menunggu animasi **∧** backend bersamaan: bila Lottie selesai lebih dulu, frame terakhir ditahan dengan progres halus; bila backend selesai lebih dulu, aplikasi langsung masuk setelah animasi. Reduce-motion: langsung lanjut. Fallback keras 20 dtk.
4. **Posisi Lottie**: ukuran kotak eksplisit (`shortSide × 0.66`, dibatasi 208–300dp) + `Center` + `Column(mainAxisSize: min)` — terpusat di kedua sumbu.
5. **Speed Lottie 0,65×**: durasi controller dilebarkan jadi `composition.duration / 0.65` (~4,6 dtk). `_fallbackDelay` disesuaikan ke 20 dtk.
6. Tes `opening_screen_test.dart` dibungkus `ProviderScope` (OpeningScreen kini `ConsumerStatefulWidget`); `app_test.dart` dibersihkan.

### Verifikasi
- `flutter analyze` → **No issues found!**
- `flutter test` → **294/294 passed** (baseline 295; satu tes percobaan reduce-motion-lambat-backend dihapus karena lingkungan tes tidak bisa memaksa `disableAnimations` lewat root wrapper — cakupan reduce-motion tetap ada di `opening_screen_test.dart`).
- `flutter build apk --debug` → **✓ Built**.
- DoD: gradien 0; `Colors.*` (selain `transparent`) di `lib/features` + `lib/shared` = 0.
- Wajib di perangkat: uninstall aplikasi lama dulu (Android meng-cache ikon/splash), lalu install ulang; pastikan urutannya native hijau → Lottie (satu page, center, 0,65×) → aplikasi, dan tidak ada logo Flutter.
- Commit belum dijalankan (manual oleh pemilik).

## UX-8b — Ukuran Lottie diperbesar (2026-11-18)

Font & logo Lottie terlalu kecil: ukuran diubah dari `shortSide × 0.66` (±238dp di 360dp) menjadi **`shortSide × 0.80`** (±288dp; dibatasi 220–330dp). Satu page splash, posisi center, ∧ backend, x0.65 — tidak berubah.

### Verifikasi
- `flutter analyze` → **No issues found!**
- `flutter test` → **294/294 passed**
- `flutter build apk --debug` → **✓ Built**
- Commit belum dijalankan (manual oleh pemilik).

## UX-9 — Efek suara khas logo saat splash (2026-11-18)

### Ruang lingkup
Memutar audio khusus logo bersamaan dengan Lottie di `OpeningScreen`. Tidak ada perubahan alur/onboarding.

### Dependency baru (disetujui 2026-11-18)
- **`audioplayers` (^6.6.0)** — satu-satunya audio player yang dipakai (tanpa konfigurasi native tambahan; mendukung WAV). Alasan: memainkan `assets/audio/cek-gizi_audio.wav` bersama animasi; tanpa jaringan; cukup satu instance; tidak ada playback background.

### Perubahan
1. `assets/audio/cek-gizi_audio.wav` (814 KB, dibuat pemilik/AI — durasi sudah diselaraskan dengan Lottie 0,65×).
2. `pubspec.yaml`: `assets/audio/` didaftarkan; `audioplayers` ditambahkan.
3. `OpeningScreen`: saat `onLoaded` (normal path), audio diputar **sekali** pada volume **0,35**, bersamaan dengan `forward()`.
   - Reduce-motion → **tanpa suara**.
   - Gagal audio → diabaikan (bisu), splash tetap jalan.
   - `ReleaseMode.stop`; player dilepas di `dispose()`.
   - Tidak ada toggle Akun dulu; default **nyala** (sesuai permintaan), bisa ditambahkan nanti bila perlu.

### Catatan ukuran file
WAV 814 KB menambah ukuran APK (~0,8 MB). Bila ukuran jadi prioritas, sebaiknya dikonversi ke MP3/AAC (~100–150 KB) dengan tool eksternal; kode tidak berubah (cukup ganti aset/`AssetSource`).

### Verifikasi
- `flutter analyze` → **No issues found!**
- `flutter test` → **294/294 passed** (audio dipanggil dalam try/catch, tidak menyentuh tes).
- `flutter build apk --debug` → **✓ Built**.
- Perlu tinjauan di perangkat: apakah suara terdengar di cold start, apakah tidak mengejutkan (volume 0,35), dan apakah reduce-motion benar-benar membisukan.
- Commit belum dijalankan (manual oleh pemilik).
