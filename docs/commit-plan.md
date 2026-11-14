# Rencana Commit — Refactor UX (UX-1 .. UX-5)

> **AI tidak menjalankan commit.** Ini rencana staging + pesan commit yang
> siap kamu jalankan manual (AGENTS.md §7). Urutan sesuai dependensi batch.
> Setiap commit menyebut hasil verifikasi terkini.

## Status verifikasi saat rencana ini ditulis (2026-11-13)
- `flutter analyze` → **No issues found!**
- `flutter test` → **229/229 passed**.
- DoD §10.1: `LinearGradient|RadialGradient|SweepGradient` 0;
  `\bColors\.(?!transparent)` di `lib/features` + `lib/shared` → 0 (hanya
  `lib/core/theme` + `Colors.transparent`); `GEMINI_API_KEY=<literal>` 0;
  em dash (U+2014) di `.dart` → 0.
- Belum diverifikasi di perangkat (emulator offline / SM A155F tidak terhubung).

## Commit 1 — feat(meals): infrastruktur waktu & riwayat 30 hari (UX-1)

```bash
git add lib/core/time/ lib/core/utils/date_format.dart \
  lib/features/meals/domain/repositories/food_log_repository.dart \
  lib/features/meals/domain/services/history_summary.dart \
  lib/features/meals/data/repositories/food_log_repository_impl.dart \
  lib/features/meals/presentation/providers/meals_providers.dart \
  lib/features/home/presentation/app_shell.dart lib/main.dart \
  lib/core/router.dart lib/core/storage/local_prefs.dart \
  test/core/time/ test/features/history_summary_test.dart test/fakes.dart
git commit -m "feat(meals): infrastruktur hari ini & riwayat 30 hari (UX-1)" \
  -m "- clockProvider + aritmetika tanggal lokal murni (clock.dart, local_dates.dart)" \
  -m "- listLogs(childId, from, to): query dibatasi rentang (gte/lt, limit 1000)" \
  -m "- foodLogsProvider = hari ini saja; historyLogsProvider/historySummaryProvider baru" \
  -m "- TodayWatcher di AppShell meng-invalidate provider saat resume & tengah malam" \
  -m "- flutter analyze: bersih; flutter test: 229/229"
```
Catatan: `meals_providers.dart` juga berisi `addManualItemLog` (dipakai UX-4);
bila ingin pemisahan bersih, gunakan `git add -p` untuk hunk itu, atau biarkan
masuk di sini (bukan masalah).

## Commit 2 — feat(makan): arsitektur informasi Hari ini | Riwayat (UX-2)

```bash
git add lib/features/meals/presentation/screens/makan_screen.dart \
  lib/features/meals/presentation/widgets/makan_today_view.dart \
  lib/features/meals/presentation/widgets/makan_history_view.dart \
  lib/features/meals/presentation/widgets/food_group_checklist.dart \
  lib/features/meals/presentation/widgets/food_log_list.dart \
  lib/features/meals/presentation/widgets/catat_makan_sheet.dart \
  lib/features/meals/presentation/widgets/piring_info_sheet.dart \
  lib/features/meals/presentation/widgets/piring_tour_card.dart \
  lib/features/meals/presentation/widgets/week_strip.dart \
  lib/features/meals/presentation/widgets/month_calendar.dart \
  lib/features/meals/presentation/widgets/piring_tips_card.dart \
  lib/features/meals/presentation/widgets/photo_scan_fab.dart \
  lib/features/meals/presentation/meal_presentation.dart \
  lib/features/meals/presentation/meals_actions.dart \
  lib/features/meals/presentation/providers/makan_section.dart \
  lib/features/home/presentation/home_screen.dart \
  lib/shared/widgets/segment_control.dart \
  lib/core/constants/app_strings.dart \
  test/features/makan_flow_test.dart
git commit -m "feat(makan): arsitektur informasi Hari ini | Riwayat (UX-2)" \
  -m "- segment Hari ini | Riwayat di layar Makan; header pin (segment selalu terlihat)" \
  -m "- checklist kelompok berlabel (ASI baris pertama), aksi Catat/Hapus eksplisit," \
  -m "  anti-hapus untuk catatan gabungan, status tidak pernah hanya warna" \
  -m "- composer 'Catat satu kali makan' (satu log multi-kelompok; field skema lama)" \
  -m "- timeline catatan dipakai ulang; riwayat: ringkasan 30 hari, strip 7 hari," \
  -m "  kalender bulan (hanya jendela data), detail hari, error/offline, empty state" \
  -m "- Beranda: strip 7 hari + 'Lihat riwayat'; tur singkat sekali jalan (LocalPrefs)" \
  -m "- lembar 'Cara kerja Piring Hari Ini'; FAB heroTag null (duplikat hero tag fix)" \
  -m "- flutter analyze: bersih; flutter test: 229/229"
```
Catatan: `app_strings.dart` memuat copy untuk UX-3..UX-5 juga (tidak bisa
dipisah per batch tanpa `git add -p`); `makan_flow_test.dart` mencakup alur UX-2
dan dipakai kembali di UX-4.

## Commit 3 — feat(ui): design system v2 — motion & ilustrasi (UX-3)

```bash
git add lib/core/theme/app_motion.dart \
  lib/shared/illustrations/empty_plate_illustration.dart \
  lib/shared/illustrations/seedling_illustration.dart \
  lib/shared/widgets/empty_state.dart \
  lib/shared/widgets/segment_control.dart \
  lib/shared/widgets/child_avatar.dart \
  lib/features/meals/presentation/widgets/piring_ring.dart \
  lib/features/meals/presentation/widgets/food_group_checklist.dart \
  lib/features/meals/presentation/widgets/makan_today_view.dart \
  lib/features/meals/presentation/widgets/makan_history_view.dart \
  lib/features/growth/presentation/widgets/growth_status_card.dart \
  lib/features/home/presentation/home_screen.dart \
  lib/features/children/presentation/screens/children_screen.dart
git commit -m "feat(ui): design system v2 — motion, ilustrasi CustomPainter, avatar (UX-3)" \
  -m "- PiringProgressRing teranimasi (400ms easeOutCubic, hormati disableAnimations)" \
  -m "- transisi Hari ini/Riwayat (AnimatedSwitcher), transisi pilihan segment & checklist" \
  -m "- ilustrasi kosong dari CustomPainter (piring bersih / bibit), tanpa aset PNG" \
  -m "- EmptyState menerima parameter illustration; token motion AppMotion (fast/normal/ring)" \
  -m "- 5 opsi avatar baru (bunny, paw, music, cookie, sailboat)" \
  -m "- flutter analyze: bersih; flutter test: 229/229"
```
Catatan: `makan_screen.dart` memuat AnimatedSwitcher (UX-3) tetapi juga kode UX-2;
pilihan staging `git add -p` bila ingin benar-benar terpisah, atau biarkan menyatu.
`empty_state.dart`, `segment_control.dart`, `food_group_checklist.dart`,
`makan_today_view.dart`, `makan_history_view.dart`, `home_screen.dart` berisi
campuran UX-2/UX-3; mirip dengan di atas.

## Commit 4 — feat(scanner): catat manual tanpa foto (UX-4)

```bash
git add lib/features/meals/presentation/widgets/manual_food_sheet.dart \
  lib/features/meals/presentation/screens/scan_screen.dart \
  test/features/scan_flow_test.dart
git commit -m "feat(scanner): catat manual tanpa foto dari pemindai (UX-4)" \
  -m "- sheet 'Catat manual': ketik nama, pilih kelompok, waktu makan, simpan source=manual" \
  -m "- fallback kamera & panel error 'Catat manual' kini membuka sheet (bukan lompat tab)" \
  -m "- addManualItemLog pada notifier (satu item, groups canonical, source=manual)" \
  -m "- flutter analyze: bersih; flutter test: 229/229"
```

## Commit 5 — feat(growth): petunjuk tren saat pengukuran < 2 (UX-5)

```bash
git add lib/features/growth/presentation/screens/growth_screen.dart \
  lib/core/constants/app_strings.dart \
  test/features/layout_scale_test.dart
git commit -m "feat(growth): petunjuk tren saat pengukuran di bawah 2 (UX-5)" \
  -m "- catatan 'Belum cukup data untuk melihat tren' hanya tampil bila <2 pengukuran" \
  -m "- layout scale test: segment Riwayat (ringkasan + kalender) 360dp @1.3, light & dark" \
  -m "- flutter analyze: bersih; flutter test: 229/229"
```
Catatan: `app_strings.dart` staging di Commit 5 memindahkan seluruh copy batch
ini — gunakan `git add -p` bila ingin memisah `growthTrendHint` saja.

## Commit 6 — docs(progress): catatan UX-1..UX-5 & rencana commit

```bash
git add docs/progress.md docs/commit-plan.md
git commit -m "docs(progress): catatan UX-1..UX-5, verifikasi, dan rencana commit" \
  -m "- keputusan UX-1..UX-5 (segment Makan, checklist, composer, riwayat," \
  -m "  motion/ilustrasi, catat manual, Tumbuh), hasil verifikasi 229/229," \
  -m "  catatan bukti perangkat belum teruji, dan daftar item terbuka"
```

## Setelah commit — belum bisa dilakukan tanpa kamu
1. Jalankan `git push` manual bila perlu (branch `feature/app4-mvp`).
2. Verifikasi di perangkat (SM A155F / emulator hidup):
   - navigasi `Hari ini ↔ Riwayat`, kalender & pemilih hari, composer,
     sheet "Cara kerja", tur sekali jalan;
   - alur "Catat manual" dari pemindai;
   - transisi Hari ini/Riwayat tidak patah di 360×640 @1.3 light/dark.
3. Review ahli gizi `nutrition_rules.json` (`reviewed_by: null`) — masih terbuka.
4. Deploy `analyze-meal` Edge Function bila ingin uji scan end-to-end.
