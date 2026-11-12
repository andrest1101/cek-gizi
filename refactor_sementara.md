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
- Copy bersih dari tanda "hasil generate AI" (em dash U+2014), termasuk semua komentar kode.
- Tanpa dependency baru, tanpa perubahan skema Supabase, tanpa menyentuh z-score/tabel SD.

## Status batch

| Batch | Fokus | Status |
|---|---|---|
| 6.1 | Koreksi P0 (data tips, geometri ring, duplikat, hari ini vs riwayat, ASI, hero) | Selesai (2026-11-12) |
| 6.2 | Hierarki Beranda & Makan (header bersama, hero, tips, grid, diary) | Selesai (2026-11-12) |
| 6.3 | Polish & konsistensi (Tumbuh empty state, copy, semantics, dokumen) | Selesai (2026-11-12) |
| 6.4 | Opsional: strip 7 hari, batas fetch riwayat | Belum (butuh keputusan retensi) |
| 6.5 | Copy polish: hapus em dash, ikon kelola anak, ikon tombol tips | Selesai (2026-11-12) |

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

## Batch 6.5 — Copy polish bebas "tanda generate" + ikonografi kelola

### Checklist
- [x] Em dash (U+2014) dihapus semua: 84 kemunculan di 46 berkas `.dart` (termasuk semua komentar), disesuaikan ke titik/koma/titik dua.
- [x] Copy yang tampil di app diperbaiki (8 string `AppStrings`): onboarding, consent, anak kosong, validasi, tren berat, ASI, hint grid.
- [x] Inline UI: judul dialog simpan jadi `"...: $childName"`, detail angka pakai titik dua, label semantik "Ketuk untuk ganti anak", `formatZ(null)` → `'-'`.
- [x] Ikon Kelola anak: `tune_rounded` → `manage_accounts_rounded` (Beranda + sheet anak).
- [x] Tombol "Catat sekarang" pada tips diberi ikon tambah.
- [x] `flutter analyze` bersih; `flutter test` **193/193 passed**.
- [x] Update `docs/progress.md` (Batch 6.5).

### Catatan
- Data pemilik TIDAK diubah: `assets/rules/nutrition_rules.json` (kecuali perbaikan string korup), `assets/reference/*`, `PRD.md`.
- `0–60`, `6–23`, `24–59` (en dash U+2013 pada rentang angka) sengaja dibiarkan karena wajar.
- Em dash di komentar/dokumen ikut dibersihkan; ini tidak mengubah perilaku aplikasi.

---

## Catatan risiko / hal yang belum bisa diverifikasi AI

- Estetika akhir (kontras hero di dark, kerapatan tipografi) harus dilihat pemilik di perangkat.
- Data `nutrition_rules.json` tetap `reviewed_by: null`; penanda "belum ditinjau ahli gizi" tetap tampil. Perbaikan string korup bukan perubahan aturan.
- `foods_id.json` belum tersedia → pencarian pangan tetap ditunda.
- Batch 5 tetap menunggu Cloud Billing + `GEMINI_API_KEY`.
- Batas fetch riwayat belum ada: `foodLogsProvider` masih mengambil seluruh riwayat anak (kandidat Batch 6.4).

## Langkah berikutnya
1. Pemilik memverifikasi tampilan & alur di perangkat: Beranda → Makan (quick-add, duplikat, ASI, lipat hari sebelumnya) → Beranda → Tumbuh.
2. Commit manual sesuai kelompok di bawah (AI tidak commit/push).
3. Lanjut Batch 5 setelah Cloud Billing + `GEMINI_API_KEY` + `foods_id.json` tersedia.

---

## Siap commit (commit manual oleh pemilik)

Pembersihan em dash menyentuh hampir semua berkas, jadi pemisahan per tema **tidak lagi bersih secara path**.
Rekomendasi: satu commit refactor UI/UX penuh, atau commit granular dengan `git add -p`.

**Opsi A (direkomendasikan) — satu commit refactor UI/UX**
```powershell
git add -A
git commit -m "refactor(ui): poles total Beranda, Makan, Tumbuh bebas copy AI" -m "Ring progres untuk ukuran kecil & celah busur dari stroke; semesta target mengikuti usia (8/7); quick-add menolak duplikat & menawarkan hapus; diary dipisah hari ini vs hari sebelumnya; header bersama ScreenHeader + panel hari ini; tumbuh satu empty state; ikon Kelola anak & tombol tips; copy bebas em dash; tips grains_tubers korup diperbaiki + guard loader. Verifikasi: flutter analyze bersih; flutter test 193/193."
```

**Opsi B — tetap per tema (granular, pakai git add -p)**
1. `fix(rules): perbaiki tips grains_tubers tersisip teks asing` — `assets/rules/nutrition_rules.json`, `lib/domain_ref/nutrition_rules.dart`, `test/domain_ref/nutrition_rules_test.dart`.
2. `feat(meals): ring progres berlabel & diary dipisah` — seluruh `lib/features/meals`, `lib/core/constants/app_strings.dart`, `lib/shared/widgets/screen_header.dart`, `test/features/piring_ring_test.dart`, `test/features/makan_flow_test.dart`.
3. `feat(home): hierarki Beranda konsisten & Tumbuh satu empty state` — `lib/features/home`, `growth_screen.dart`, `child_switcher.dart`.
4. `style(copy): hapus semua em dash + rapikan copy UI` — sisa berkas (komentar & tanda baca).
5. `docs(progress): catat Batch 6.1 & 6.5 + pelacak refactor_sementara`.

Catatan: `lib/shared/widgets/child_identity_row.dart` kini tidak dipakai di mana pun — dibiarkan ada, bisa dihapus di commit terpisah bila pemilik setuju.
