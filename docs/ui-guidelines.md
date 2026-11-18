# CekGizi — Spesifikasi Visual (v2.1, Batch UX-0)

Dokumen ini adalah **kontrak visual** untuk seluruh layar. PRD v2.0 tetap
sumber kebenaran fitur; dokumen ini hanya mengatur bagaimana fitur tampil.
Semua angka di sini sudah berupa token di `lib/core/theme/` — jangan
menulis angka/warna baru di widget.

## 1. Prinsip

1. **Tenang, bukan ramai.** Satu layar = satu titik fokus. Permukaan datar
   dengan lapisan tone, bukan bayangan tebal.
2. **Jelas tanpa menebak.** Setiap ikon punya label atau `Semantics`.
   Status tidak pernah dikodekan warna saja.
3. **Hangat & tidak menghakimi.** Kalimat menyebut apa yang belum ada,
   bukan menilai anak. Contoh: "Belum ada protein hewani hari ini".
4. **Bisa dipakai dengan satu tangan.** Aksi utama di jangkauan ibu jari,
   target sentuh ≥ 48dp, aman di 360dp pada text scale 1,3.
5. **Jujur.** Tidak ada contoh data gizi/resep karangan. Fitur yang belum
   siap tampil sebagai empty state yang menjelaskan alasannya.

### Yang dilarang

- Gradien (`LinearGradient`, `RadialGradient`, `SweepGradient`) — 0 file.
- Literal `Colors.*` di `lib/features` & `lib/shared` (kecuali
  `Colors.transparent`) — pakai `AppColors`/`ColorScheme`.
- Bayangan tebal sebagai satu-satunya pembeda kedalaman.
- Glassmorphism, blob, ikon tanpa label, emoji sebagai ikon UI.
- Klaim klinis ("mencegah stunting", "mendiagnosis", "bebas stunting").

## 2. Warna

Sumber: `AppColors` (`ThemeExtension`) — light & dark, masing-masing 22
token. `AppColors.copyWith` dan `lerp` wajib diperbarui bila menambah field.

| Peran | Token | Light | Dark |
| --- | --- | --- | --- |
| Latar layar | `background` | `#FBF7F0` | `#101713` |
| Kartu/sheet/nav | `surface` | `#FFFFFF` | `#17211B` |
| Blok halus / track | `surfaceVariant` | `#F1EBDD` | `#1F2C25` |
| Hairline | `outline` | `#E6DDCB` | `#2C3B33` |
| Teks utama | `textPrimary` | `#1E2A25` | `#E9F0EB` |
| Teks sekunder | `textSecondary` | `#5F6B64` | `#A3B1A8` |
| Aksi utama | `primary` / `onPrimary` | `#1F6F54` / putih | `#7FD1A8` / `#06251A` |
| Tonal lembut | `primaryContainer` | `#D8EBDD` | `#1B4A38` |
| Sorotan hangat | `accent` | `#E9893B` | `#F2A55F` |
| Pita hangat | `accentContainer` / `onAccentContainer` | `#FBE8D6` / `#7A4318` | `#3E2A19` / `#F7C79B` |
| Status normal | `statusGood` | `#2E7D32` | `#7BD88F` |
| Perlu perhatian (isi/teks) | `statusWatch` / `statusWatchText` | `#F2B84B` / `#8A5A12` | `#F2C14E` |
| Perlu diperiksa | `statusAlert` | `#C0392B` | `#FF8E80` |
| Permukaan hero | `heroSurface` | `#1F6F54` | `#1E4A38` |
| Teks di hero | `onHeroSurface` | putih | `#EAF6EF` |
| Teks sekunder hero | `onHeroSurfaceMuted` | `#D8E9DF` | `#B9D6C6` |
| Sorotan di hero | `onHeroAccent` | `#FFE0C2` | `#F7B77C` |
| Track ring hero | `heroTrack` | `#3C8069` | `#2C6A50` |
| Garis tepi hero | `heroEdge` | transparan | `#2F6A52` |

Aturan:

- **Satu hero per layar.** Permukaan solid berwarna dominan; sisanya
  `surface`/`surfaceVariant`. Di light hero = `primary`; di dark hijau
  dinaikkan satu tone + hairline agar terbaca di atas `#101713`.
- Semua teks di atas hero wajib `onHeroSurface*` (kontras ≥ 4,5:1, diuji
  di `test/core/theme/app_theme_test.dart`).
- Status selalu **ikon + teks + warna**; warna tidak pernah sendirian.

## 3. Tipografi (Plus Jakarta Sans, bundled)

| Token | Ukuran/tinggi | Berat | Pemakaian |
| --- | --- | --- | --- |
| `displayMetric` | 40/44 | 700 | Angka dominan di ring hero |
| `heroNumber` | 28/34 | 700 | Angka besar lain |
| `metricNumber` | 26/32 | 700 | Angka metrik kartu (tabular) |
| `titleLarge` | 22/28 | 700 | Judul layar/sapaan |
| `titleMedium` | 16/22 | 700 | Judul kartu/section |
| `body` | 15/22 | 400 | Teks isi |
| `bodyTabular` | 15/22 | 400 | Teks isi berangka (tabular) |
| `bodySmall` | 13/18 | 400 | Penjelas, subtitle |
| `label` | 13/16 | 500 | Label tombol, eyebrow |
| `navLabel` | 11,5/14 | 500 | Label tab (5 tab di 360dp @1,3) |

Semua style **tanpa warna**; warna diambil di call site dari `AppColors`.

## 4. Ruang, radius, gerak

- Spasial 4pt: `AppSpacing.xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 20`,
  `xxl 24`, `xxxl 32`; `screenPadding 20`, `sectionGap 28`.
- Radius: `control 12` (tombol/input/chip), `card 20` (kartu/sheet/hero),
  `pill 999`.
- Gerak: `AppMotion.fast 200ms`, `normal 250ms`, `ring 400ms`,
  kurva `easeOutCubic`. Selalu lewat `AppMotion.of(context, durasi)` agar
  menghormati "kurangi animasi".

## 5. Lapisan permukaan (`AppSurfaces`)

| Lapisan | Light | Dark | Dipakai |
| --- | --- | --- | --- |
| `card` | `surface` + hairline `outline` | `surfaceVariant` tanpa garis | Kartu, panel, sheet |
| `sunken` | `surfaceVariant` | lebih gelap dari kartu | Blok di dalam kartu, empty state kecil |
| `hero` | `heroSurface` + teks `onHeroSurface*` | `heroSurface` + `heroEdge` | Satu blok dominan per layar |

Kedalaman berasal dari perbedaan tone 1 langkah + hairline, bukan shadow.

## 6. Navigasi (v2.1)

- 5 destinasi tetap: **Beranda · Makan · Resep · Tumbuh · Akun**
  (`AppDestination`, urutannya harus sama dengan `StatefulShellBranch`).
- `AppNavBar` kustom: permukaan `surface`, tanpa garis atas, pil tonal
  (`primaryContainer`) di destinasi aktif, ikon 19dp, label selalu tampil.
- Tanya Gizi **bukan tab**. Pintunya `TanyaBubble` — pil berlabel
  "Tanya gizi" di kanan bawah, mengambang di semua tab. Tanya adalah route
  penuh dengan tombol tutup eksplisit.
- Kamera **bukan FAB global**. Pintunya `CapturePanel` di tab Makan (usia
  ≥ 6 bulan), membuka `/scan`.

## 7. Komponen bersama (`lib/shared/widgets/`)

| Komponen | Catatan |
| --- | --- |
| `ScreenHeader` | eyebrow + judul + subtitle + trailing opsional |
| `SectionHeader` | judul bagian di dalam daftar |
| `EmptyState` | ikon/ilustrasi tonal + satu kalimat + satu aksi |
| `ErrorCard` | pesan ramah + "Coba lagi" |
| `Skeleton` | statis (tanpa animasi berulang), warna bisa di-override |
| `MetricTile` | angka metrik + label + status |
| `StatusPill` | pita status: ikon + teks + warna |
| `SegmentControl` | pemilih 2 bagian (Hari ini/Riwayat) |
| `TonalIconCircle` | ikon di lingkaran tonal, bukan emoji |
| `ChildAvatar` / `ChildSwitcher` | identitas anak, tanpa nama ganda |
| `ZScoreTable` | tabel z-score aksesibel |

| `SectionReveal` | masuk 250 ms (opacity + 8dp), ikut `AppMotion.of` |

Ilustrasi bergaya garis (`ChatIllustration`, `EmptyPlateIllustration`,
`SeedlingIllustration`, `PlateViewfinderIllustration`) memakai token warna,
bukan file gambar raster. `PlateViewfinderIllustration` punya dua mode:
`onHero` (panel Makan) dan `onCamera` (latar preview terbalik).

## 8. Pola per layar

- **Beranda** (v2.3): sapaan + `ChildSwitcherButton` di header, lalu **3 blok**:
  (1) `PiringHeroCard` — hero hijau, satu angka dominan 40dp + dua ubin metrik
  (protein hewani & tren berat) dipisah hairline; (2) `HomeWeekChips` — pil
  horizontal yang bisa digeser; (3) `GrowthStatusCard` dengan tips sebagai
  satu baris di dalamnya. Header tidak menyimpan aksi kelola/pengaturan.
- **Makan**: header (tanggal + judul + ganti anak + segmen Hari
  ini/Riwayat) **ikut menggulir** di dalam daftar — tidak disematkan di atas
  layar. Lalu `CapturePanel` (viewfinder + 3 langkah + privasi + CTA + pintu
  "Catat tanpa foto") → panel ringkasan → tur singkat → checklist kelompok →
  catatan hari ini. Pita protein hewani memakai `accentContainer` bila belum
  ada, `primaryContainer` bila sudah ada — selalu ikon + teks.
- **Resep**: empty state jujur sampai `recipes.json` tersedia.
- **Tumbuh** (v2.3): ringkasan `ZScoreSummaryStrip` (3 ubin, sekaligus
  pemilih indeks) → grafik pita SD **full-bleed** → riwayat berbentuk
  accordion (ringkasan selalu tampil, z-score & aksi dibuka saat diketuk).
- **Akun**: profil anak (kelola anak), pengingat lokal, catatan privasi.
- **Tanya**: banner disclaimer tetap, area pesan, input bar, chip cepat.
- **Splash / opening** (v2.3): **satu page** — native Android & frame
  pertama Flutter solid `#145C45` (`AppSurfaces.splashSurface`), lalu
  `OpeningScreen` memutar Lottie `assets/animations/cekgizi_opening.json`
  (1080×1080, 3 detik, latar konstan, **0,65× speed**, terpusat eksplisit)
  **+ suara khas `assets/audio/cek-gizi_audio.wav`** (volume 0,35, sekali,
  sinkron dengan `forward()`; reduce-motion = bisu). Lottie ∧
  `backendReadyProvider` bersamaan: bila animasi selesai lebih dulu, frame
  terakhir ditahan + progres halus. Reduce-motion dihormati; ada timeout
  pengaman 20 dtk; tidak ada logo ganda. Launcher icon Android = logo
  CekGizi (bukan bawaan Flutter).

## 9. Aksesibilitas (PRD §7.7)

- Tidak overflow di lebar 360dp pada text scale 1,3, light & dark
  (`test/features/layout_scale_test.dart`).
- Target sentuh ≥ 48dp; teks kontras ≥ 4,5:1.
- Setiap grafik/ikon punya `Semantics` (mis. ring: "3 dari 8 kelompok").
- Status tidak pernah hanya warna.
- Hormati `MediaQuery.disableAnimations`.

## 10. Copywriting

- Semua teks di `AppStrings`; suara "kamu", hangat, tanpa menghakimi.
- Angka & tanggal memakai format Indonesia (`IdDateFormat`, koma desimal).
- Nama aplikasi selalu dari `AppConfig.appName`.
