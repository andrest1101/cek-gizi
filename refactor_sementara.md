# Refactor Sementara — UI/UX Hardening (sebelum Batch 5)

> Berkas kerja sementara. Jangan dihapus sampai refactor selesai.
> Sumber kebenaran tetap `PRD.md`; penyimpangan yang disetujui pemilik dicatat di sini.
> Verifikasi wajib tiap batch: `flutter analyze` bersih, `flutter test` hijau, DoD §10.1.

## Konteks & keputusan yang sudah disetujui (2026-11-12)

- Fokus: Beranda + Makan penuh; Tumbuh hanya konsistensi visual/empty state. Onboarding/Consent/Anak tidak dirombak.
- Ring hero tetap 8 busur + `accent` protein hewani (PRD §6.3) **plus label eksplisit**; ring mini jadi satu busur progres monokrom + angka.
- Celah busur dihitung dari stroke (`(stroke + 4dp) / radius`) agar jarak terlihat 4dp dan round cap tidak saling menimpa.
- Ring mengikuti semesta target usia: 8 kelompok (6–23 bln) / 7 kelompok tanpa ASI (24–59 bln) agar angka ring tidak kontradiktif dengan target.
- Tips: perbaiki string korup di `nutrition_rules.json`; tampilkan nama kelompok + aksi catat.
- "Hari ini" dan "Hari sebelumnya" dipisah; hari lama dilipat.
- Kelompok yang sudah tercatat tidak boleh menambah log duplikat; ketuk ulang menawarkan hapus.
- ASI 24–59 bulan tetap bisa dicatat, tapi jadi aksi sekunder berlabel "tidak dihitung pada target".
- Tanpa dependency baru, tanpa perubahan skema Supabase, tanpa menyentuh z-score/tabel SD.

## Status batch

| Batch | Fokus | Status |
|---|---|---|
| 6.1 | Koreksi P0 (data tips, geometri ring, duplikat, hari ini vs riwayat, ASI, hero) | Selesai (2026-11-12) |
| 6.2 | Hierarki Beranda & Makan (header bersama, hero, tips, grid, diary) | Selesai (2026-11-12) |
| 6.3 | Polish & konsistensi (Tumbuh empty state, copy, semantics, dokumen) | Selesai (2026-11-12) |
| 6.4 | Opsional: strip 7 hari, batas fetch riwayat | Belum (butuh keputusan retensi) |

---

## Batch 6.1 — Koreksi P0

### Checklist
- [x] Perbaiki string tips `grains_tubers` yang korup (sisipan lirik) di `assets/rules/nutrition_rules.json`.
- [x] Guard tips di `NutritionRulesLoader`: maksimum 140 karakter + tanpa baris baru, plus test penolakan.
- [x] Hitung celah busur dari stroke (`PiringRing.segmentGapDegrees`) + test matematika (jarak visual ±22dp pada hero).
- [x] `PiringProgressRing` baru (satu busur + angka) untuk ukuran 36–60dp.
- [x] Cegah quick-add duplikat; tile tercatat punya centang + label; ketuk ulang menawarkan hapus (`removeGroupToday`).
- [x] Pisahkan "Catatan hari ini" (selalu tampil, ada empty state) dan "Hari sebelumnya" (dilipat per hari).
- [x] Refresh saat app resume / lewat tengah malam (`TodayWatcher` di `AppShell`).
- [x] Hero: hapus badge "Tercapai" ganda; status protein hewani selalu tampil; legenda busur oranye.
- [x] ASI 24–59 bulan jadi aksi sekunder + copy "tidak dihitung pada target".
- [x] Test baru + baseline hijau.

### Catatan implementasi
- Guard tips menangkap string korup lama (>140 karakter) sebelum tampil ke pengguna.
- `segmentGapDegrees` memakai `(stroke + 4) / radius` radian, dibatasi 45% lebar busur agar ring kecil tidak kehilangan busur.
- `PiringRing` menerima `codes` (semesta 8/7); `PiringDay` menyediakan `targetCodes`/`countedGroups`.
- `meals_actions.dart` memusatkan quick-add + snackbar (undo / tawaran hapus) untuk grid Makan dan aksi tips Beranda.
- `TodayWatcher` menginvalidasi `foodLogsProvider` anak terpilih pada resume dan tengah malam.

## Batch 6.2 — Hierarki Beranda & Makan

### Checklist
- [x] `ScreenHeader` bersama (eyebrow tanggal + judul + subjudul + trailing) untuk Makan & Tumbuh.
- [x] `ChildSwitcherButton` (avatar 48dp) untuk header Makan/Tumbuh.
- [x] Beranda: nama anak tidak diulang (baris ganti anak hanya menampilkan usia + aksi).
- [x] Beranda: urutan header → identitas anak → hero → tips → status tumbuh; hanya satu `FilledButton` utama.
- [x] Makan: panel "hari ini" (ring berangka + target + protein) menggantikan header polos.
- [x] Grid: centang + label semantik "sudah tercatat"; hint tidak lagi mengandalkan warna saja.
- [x] Diary: baris lebih rapat; "Hari ini" terbuka, "Hari sebelumnya" dilipat.
- [x] Copy baru/berubah masuk `AppStrings`; string meal type tak terpakai dihapus.

## Batch 6.3 — Polish & konsistensi

### Checklist
- [x] Tumbuh: sembunyikan grafik/riwayat saat belum ada pengukuran (satu empty state).
- [x] Header Tumbuh konsisten + chip anak.
- [x] Semantics + target ketuk untuk chip/expand/aksi tips.
- [x] Update `docs/progress.md` (Batch 6.1).
- [ ] Opsional: strip 7 hari terakhir — belum.
- [ ] Opsional: batasi fetch riwayat (butuh keputusan retensi) — belum.
- [ ] Verifikasi visual di perangkat nyata oleh pemilik — menunggu.

### Verifikasi Batch 6.1–6.3 (2026-11-12)
- `flutter analyze` → **No issues found!**
- `flutter test` → **193/193 passed** (baseline 179; +14 test).
- DoD §10.1: gradien 0; `Colors.` di `lib/features`+`lib/shared` 0 (kecuali `Colors.transparent`); `GEMINI_API_KEY=<literal>` 0.
- Layout 360×640 @1,3 light/dark: hijau.

---

## Catatan risiko / hal yang belum bisa diverifikasi AI

- Estetika akhir (kontras hero di dark, kerapatan tipografi) harus dilihat pemilik di perangkat.
- Data `nutrition_rules.json` tetap `reviewed_by: null`; penanda "belum ditinjau ahli gizi" tetap tampil. Perbaikan string korup bukan perubahan aturan.
- `foods_id.json` belum tersedia → pencarian pangan tetap ditunda.
- Batch 5 tetap menunggu Cloud Billing + `GEMINI_API_KEY`.
- Batas fetch riwayat belum ada: `foodLogsProvider` masih mengambil seluruh riwayat anak (kandidat Batch 6.4).

## Langkah berikutnya
1. Pemilik memverifikasi tampilan & alur di perangkat: Beranda → Makan (quick-add, duplikat, ASI, lipat hari sebelumnya) → Beranda.
2. Siapkan `git add` per tema + pesan conventional commit (AI tidak commit/push).
3. Lanjut Batch 5 setelah Cloud Billing + `GEMINI_API_KEY` + `foods_id.json` tersedia.

---

## Siap commit (belum ada yang di-commit — commit manual oleh pemilik)

Perubahan dibagi per tema agar review mudah. AI tidak menjalankan commit.

**1. Fix data tips**
```powershell
git add assets/rules/nutrition_rules.json lib/domain_ref/nutrition_rules.dart test/domain_ref/nutrition_rules_test.dart
git commit -m "fix(rules): perbaiki tips grains_tubers yang tersisip teks asing" -m "Loader kini menolak tips >140 karakter / berisi baris baru; seed tips lolos guard. Verifikasi: flutter analyze bersih; flutter test 193/193."
```

**2. Feat meals: ring berangka, anti-duplikat, diary dipisah**
```powershell
git add lib/features/meals lib/core/constants/app_strings.dart lib/shared/widgets/screen_header.dart test/features/piring_ring_test.dart test/features/makan_flow_test.dart
git commit -m "feat(meals): ring progres berlabel & diary dipisah hari ini vs sebelumnya" -m "Celah busur dihitung dari stroke; ring mini jadi 1 busur monokrom; semesta target mengikuti usia (8/7); quick-add menolak duplikat & menawarkan hapus; hari sebelumnya dilipat; panel hari ini menggantikan header polos. Verifikasi: flutter analyze bersih; flutter test 193/193."
```

**3. Feat home/tumbuh: konsistensi header & empty state**
```powershell
git add lib/features/home lib/features/growth/presentation/screens/growth_screen.dart lib/shared/widgets/child_switcher.dart
git commit -m "feat(home): hierarki Beranda konsisten & Tumbuh satu empty state" -m "Header bersama ScreenHeader; nama anak tidak diulang; tips tampil sebelum kartu tumbuh; Tumbuh tanpa grafik/riwayat saat kosong; TodayWatcher memuat ulang catatan hari ini saat resume & tengah malam. Verifikasi: flutter analyze bersih; flutter test 193/193."
```

**4. Docs**
```powershell
git add docs/progress.md refactor_sementara.md
git commit -m "docs(progress): catat Batch 6.1 refactor UI/UX + pelacak refactor_sementara"
```

Catatan: `lib/shared/widgets/child_identity_row.dart` kini tidak dipakai di mana pun — dibiarkan ada, bisa dihapus di commit terpisah bila pemilik setuju.
