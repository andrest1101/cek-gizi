# Catatan Referensi — Permenkes No. 2 Tahun 2020

Dokumen kerja untuk tabel referensi antropometri. Isi tabel resmi **disediakan pemilik proyek** (lampiran Permenkes 2/2020) dan dimasukkan ke `assets/reference/` pada **Batch 3**. Jangan mengisi tabel dari ingatan atau sumber lain.

## Yang harus dicatat di sini saat Batch 3

- [ ] Versi/identitas berkas tabel SD resmi yang dipakai (nama file, tanggal rilis lampiran).
- [ ] Indikator yang dimasukkan:
  - PB/U atau TB/U (panjang/tinggi menurut umur) — 0–60 bulan
  - BB/U (berat menurut umur) — 0–60 bulan
  - BB/PB atau BB/TB (berat menurut panjang/tinggi) — langkah 0,5 cm; PB untuk 0–23 bulan, TB untuk 24–60 bulan
- [ ] Aturan pembulatan resmi dari lampiran Permenkes untuk:
  - Panjang/tinggi badan (cm) — bagaimana pecahan 0,5 cm diperlakukan saat mencocokkan ke kolom tabel
  - Berat badan (kg)
  - Umur (bulan penuh pada tanggal ukur)
- [ ] Aturan koreksi cara ukur: usia < 24 bulan diukur berdiri → +0,7 cm; usia ≥ 24 bulan diukur terlentang → −0,7 cm. Default cara ukur mengikuti usia. Nilai mentah & cara ukur selalu disimpan apa adanya; koreksi dihitung saat evaluasi.
- [ ] Rumus z-score (metode tabel SD, PRD §3.3):
  - `z = (X − median) / (median − SD(−1))` bila X < median
  - `z = (X − median) / (SD(+1) − median)` bila X ≥ median
- [ ] Rentang z yang masuk akal untuk menolak klasifikasi: PB/U ±6; BB/U −6 s.d. +5; BB/PB −5 s.d. +5 (diverifikasi terhadap WHO Anthro).
- [ ] Prosedur verifikasi: 30 kasus uji dibandingkan dengan perhitungan manual dari tabel resmi; selisih ≤ 0,01 (PRD §9.3). Nilai pada kolom −2 SD harus memberi z ≈ −2,00 ± 0,01; median memberi 0.
- [ ] Penandaan versi di database: kolom `ref_version` pada `growth_measurements` diisi dari `AppConfig.permenkesRefVersion`.

## Sumber rujukan lainnya

- Permenkes No. 2 Tahun 2020 — Standar Antropometri Anak (kategori, ambang z, koreksi cara ukur).
- WHO/UNICEF, indikator keragaman pangan minimum untuk anak 6–23 bulan (dasar `nutrition_rules.json`).
- WHO Anthro — untuk verifikasi rentang z yang masuk akal.

## Status

Menunggu file tabel resmi dari pemilik proyek. Batch 3 tidak dimulai sebelum file tersedia.
