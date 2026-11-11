# Catatan Referensi — Permenkes No. 2 Tahun 2020

Sumber: **Peraturan Menteri Kesehatan Republik Indonesia Nomor 2 Tahun 2020 tentang Standar Antropometri Anak** (Lampiran, Tabel 1–12). Berkas PDF asli disimpan LOKAL di `.reference/permenkes_2_2020.pdf` (tidak di-commit). Tabel runtime ada di `assets/reference/permenkes_2_2020_sd.json`.

Ekstraksi dilakukan secara terprogram (`scripts/extract_permenkes.py`, pypdf) — **tidak ada angka yang diketik manual**. Tooling tambahan: Python 3.13 + pypdf. Verifikasi otomatis penuh: kontinuitas kunci, jumlah baris, monotonicity, dan **689 baris persis cocok verbatim dengan teks PDF**.

## Peta tabel yang diekstrak (halaman PDF, 1-based)

| Indeks | Tabel | Anak Laki-laki | Anak Perempuan |
|---|---|---|---|
| BB/U (WAZ) | Tabel 1 (lk) / Tabel 8 (pr) | hal. 16–17 (0–60 bln) | hal. 30–32 (0–60 bln) |
| PB/U (HAZ, 0–24) | Tabel 2 (lk) / Tabel 9 (pr) | hal. 18 (0–24 bln, 25 baris) | hal. 32–33 (0–24 bln, 25 baris) |
| TB/U (HAZ, 24–60) | Tabel 3 (lk) / Tabel 10 (pr) | hal. 19–20 (24–60 bln, 37 baris) | hal. 33–34 (24–60 bln, 37 baris) |
| BB/PB (WHZ, PB) | Tabel 4 (lk) / Tabel 11 (pr) | hal. 20–24 (45,0–110,0 cm step 0,5; 131 baris) | hal. 34–38 (45,0–110,0 cm step 0,5; 131 baris) |
| BB/TB (WHZ, TB) | Tabel 5 (lk) / Tabel 12 (pr) | hal. 24–27 (65,0–120,0 cm step 0,5; 111 baris) | hal. 38–42 (65,0–120,0 cm step 0,5; 111 baris) |

Tabel IMT/U (Tabel 6–8 lk, 13–16 pr) sengaja TIDAK diekstrak — di luar scope PRD v1.

## Struktur JSON (`assets/reference/permenkes_2_2020_sd.json`)

```json
{
  "version": "permenkes-2-2020",
  "extractedOn": "2026-11-11",
  "columnOrder": ["sdNeg3", "sdNeg2", "sdNeg1", "median", "sdPos1", "sdPos2", "sdPos3"],
  "tables": {
    "haz": { "male": {"pb_u": [[...], ...], "tb_u": [[...]]}, "female": {...} },
    "waz": { "male": [[...]], "female": [[...]] },
    "whz": { "male": {"pb": {"start": 45.0, "step": 0.5, "rows": [[...]]}, "tb": {"start": 65.0, "step": 0.5, "rows": [[...]]}}, "female": {...} }
  }
}
```

Konvensi akses (lihat `lib/domain_ref/permenkes_reference_tables.dart`):
- `haz`: umur < 24 bulan → `pb_u[umur]` (telentang); umur ≥ 24 bulan → `tb_u[umur − 24]` (berdiri). Usia 24 → TB/U (berdiri) per PRD §3.2.
- `waz`: index = umur (0–60), berlaku semua umur.
- `whz`: umur < 24 → tabel `pb`; umur ≥ 24 → `tb`; index = `round((cm − start) / 0.5)`; CM dibulatkan half-up oleh `LengthHeightStep` (nilai < 45 atau > 120 → di luar cakupan → ditolak).

## Aturan pembulatan & koreksi (dari PRD §3.2–3.3)

- Usia = **bulan penuh** pada tanggal ukur; 0–60; di luar itu input ditolak.
- Koreksi cara ukur (dihitung saat evaluasi, nilai mentah disimpan): usia < 24 bln diukur **berdiri** → +0,7 cm; usia ≥ 24 bln diukur **terlentang** → −0,7 cm.
- Rumus z (metode tabel SD Permenkes §3.3):
  `z = (X − median) / (median − SD(−1))` bila X < median; `z = (X − median) / (SD(+1) − median)` bila X ≥ median.
- Rentang masuk akal (PRD §3.5, WHO Anthro): HAZ ±6; WAZ −6 s.d. +5; WHZ −5 s.d. +5 — di luar itu **tidak diklasifikasikan**.
- Panjang/tinggi PB-U/TB-U: baris per bulan; WHZ: baris per 0,5 cm. **Step cm: half-up** (`floor(cm*2 + 0.5)/2`) — sesuai praktik lampiran; final menunggu verifikasi pemilik.
- Tabel Permenkes adalah **LMS (spacing tidak konstan antar kolom SD)** — jangan mengasumsikan linearity; gunakan selalu nilai per kolom sebagaimana tercetak.

## ⚠️ Cacat sumber — 1 sel

**`whz_tb_female`, panjang 69,5 cm, kolom −3 SD** tercetak `"6."` di PDF resmi (diverifikasi manual di streams konten PDF — BUKAN salah ekstrak). Sel ini disimpan sebagai `null`, kolom −3 boleh null secara desain, dan **tidak dipakai rumus z** (PRD §3.3 hanya memakai −1/median/+1). **Wajib ditinjau pemilik sebelum rilis** (PRD §13); jangan menebak angkanya.

## Verifikasi yang sudah dilakukan (2026-11-11)

1. Jumlah baris & kontinuitas: waz 61, haz pb 25 (0–24), haz tb 37 (24–60), whz pb 131 (45,0–110,0), whz tb 111 (65,0–120,0) — per jenis kelamin, tanpa duplikat.
2. Monotonicity kolom SD meningkat di semua baris (sel null dilewati): 0 pelanggaran.
3. **Verbatim**: seluruh 689 baris ditemukan persis di teks PDF.
4. Unit test Dart (`test/domain_ref/permenkes_reference_tables_test.dart`): anchor resmi dari PDF (waz lk umur 0 = [2.1, 2.5, 2.9, 3.3, 3.9, 4.4, 5.0]; haz pr umur 0 median 49.1; TB/U lk umur 24 median 87.1; sel cacat null), anchor matematis seluruh baris (z(−1)=−1, z(0)=0, z(+1)=+1), batas cakupan ditolak, pemilih PB/TB by usia.
5. Anchor yang DIPERIKSA langsung terhadap PDF — lihat test file (bukan dari ingatan).

## `nutrition_rules.json` (seed Lampiran A, 2026-11-11)

Berkas `assets/rules/nutrition_rules.json` adalah seed dari Lampiran A PRD dengan `reviewed_by: null` — **konten BELUM ditinjau ahli gizi/bidan**; UI wajib memberi penanda sampai ditinjau (PRD §9.1).

Loader `lib/domain_ref/nutrition_rules.dart` memvalidasi ketat saat parse (hal yang tidak boleh lolos):
- `groups` persis 8 kode tetap PRD §3.7 (duplikat/kode tak dikenal → gagal).
- `animal_source` persis `[dairy, flesh, eggs]`.
- `profiles`: `min_age_months` ≤ `max_age_months`, `count` ∈ {`all`, `without_breast_milk`}, `target_groups` 1..(8 atau 7), **tanpa tumpang tindih** (urutan diurutkan oleh usia).
- `tips`: kunci ⊆ kelompok yang dikenal, nilai tidak kosong.
- `reviewed_by`/`reviewed_on`: string atau null — `isReviewed` false berarti BELUM ditinjau.

Tips & target **tidak pernah di-hardcode di kode**; selalu dari berkas ini (PRD §3.7).

## Yang MASIH harus dilakukan pemilik (gate rilis, PRD §13)

- [ ] Mencocokkan tabel di `assets/reference/permenkes_2_2020_sd.json` dengan dokumen Permenkes asli (total 689 baris).
- [ ] Memutuskan nasib sel cacat `whz_tb_female[69.5].sdNeg3` (konfirmasi ke Permenkes cetak / sumber resmi lain, atau adendum).
- [ ] Menyediakan `nutrition_rules.json` (dari ahli gizi/bidan atau seed Lampiran A) & `foods_id.json`, `recipes.json`.
- [ ] 30 kasus uji manual vs tabel resmi (selisih ≤ 0,01) — bisa dikerjakan setelah gate di atas hijau (PRD §9.2/9.3).

## Sumber rujukan lainnya

- Permenkes No. 2 Tahun 2020 (kategori, ambang, koreksi cara ukur) — kategori status ada di PRD §3.4; implementasi di `growth_classification.dart`.
- WHO/UNICEF, indikator keragaman pangan minimum 6–23 bulan — dasar `nutrition_rules.json`.
- WHO Anthro — untuk verifikasi rentang z yang masuk akal.
