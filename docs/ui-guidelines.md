# CekGizi — Spesifikasi Visual (v3.2, Batch Resep)

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
- Kontrol nonaktif: latar `surfaceVariant` + teks `textSecondary` (bukan
  hijau pudar), dan border checkbox memakai `textSecondary` agar tetap
  terlihat di dark mode.

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
  "Tanya gizi" **di kanan bawah tiap tab** (`floatingActionButton` di Scaffold
  tiap tab, bukan di shell) — sehingga semua modal bottom sheet otomatis
  menutupinya. Tanya adalah route
  penuh dengan tombol tutup eksplisit.
- Kamera **bukan FAB global**. Pintunya `CapturePanel` di tab Makan (usia
  ≥ 6 bulan), membuka `/scan`.

## 7. Komponen bersama (`lib/shared/widgets/`)

| Komponen | Catatan |
| --- | --- |
| ScreenHeader | eyebrow + judul + subtitle + trailing opsional |
| SectionHeading | judul seksi + aksi opsional (mis. Kelola anak) |
| SettingsTile | baris pengaturan berikon tonal 40dp + trailing switch/chevron |
| `SectionHeader` | judul bagian di dalam daftar |
| `EmptyState` | ikon/ilustrasi tonal + satu kalimat + satu aksi |
| `ErrorCard` | pesan ramah + "Coba lagi" |
| `Skeleton` | statis (tanpa animasi berulang), warna bisa di-override |
| `MetricTile` | angka metrik + label + status |
| `StatusPill` | pita status: ikon + teks + warna |
| `SegmentControl` | pemilih 2 bagian (Hari ini/Riwayat) |
| `TonalIconCircle` | ikon di lingkaran tonal, bukan emoji |
| `ChildAvatar` / `ChildSwitcher` | identitas anak; avatar default 2 bentuk (siluet laki/perempuan, otomatis ikut jenis kelamin) atau foto profil **lokal** (opsional, tidak pernah diunggah) |
| `ChildPhotoAvatar` (features) | avatar yang memuat foto lokal (`ChildPhotoStore`) dengan fallback ilustrasi |
| `ZScoreTable` | tabel z-score aksesibel |

| `SectionReveal` | masuk 250 ms (opacity + 8dp), ikut `AppMotion.of` |
| `AppLogoMark` | ikon merek 40dp (sudut `control`, hairline `outline`), dari `logo_cek-gizi_mark.png`; dekoratif (`ExcludeSemantics`) karena nama app selalu ada di sebelahnya |

Ilustrasi bergaya garis (`ChatIllustration`, `EmptyPlateIllustration`,
`SeedlingIllustration`, `PlateViewfinderIllustration`,
`OnboardingGrowthIllustration`, `OnboardingGuidanceIllustration`) memakai
token warna, bukan file gambar raster. `PlateViewfinderIllustration` punya dua
mode: `onHero` (panel Makan) dan `onCamera` (latar preview terbalik).
`OnboardingGrowthIllustration` **tanpa angka/label** — pita SD + garis tren
saja; `OnboardingGuidanceIllustration` = gelembung tanya + lencana perisai.

### Merek

- `assets/logo/logo_cek-gizi.png` (1024×1024) = **master** untuk ikon launcher
  Android (`flutter_launcher_icons`). Jangan diubah di widget.
- `assets/logo/logo_cek-gizi_mark.png` (256×256) = potongan rapat dari master
  (padding ±16% di sekitar huruf C–G) khusus untuk `AppLogoMark` di dalam app,
  agar terbaca pada 40dp dan tidak mendekode 1024px ke memori.
- Ikon launcher memakai **adaptive icon** (Android 8+): latar solid `#145C45`,
  foreground `logo_cek-gizi_foreground.png` (huruf C–G dengan alfa, inset 0
  karena sudah di dalam safe zone 72dp). API < 26 memakai `image_path` apa
  adanya. Hanya `logo_cek-gizi_mark.png` yang dibundel ke APK; master dan
  foreground hanya dipakai saat generate ikon.

## 8. Pola per layar

- **Beranda** (v2.3): sapaan + `ChildSwitcherButton` di header, lalu **3 blok**:
  (1) `PiringHeroCard` — hero hijau, satu angka dominan 40dp + dua ubin metrik
  (protein hewani & tren berat) dipisah hairline; di belakang hero digambar
  dekorasi **busur konsentris + 3 titik** (`HeroPatternPainter`, alpha ±0,09,
  `IgnorePointer` + `ExcludeSemantics`, di-clip radius kartu) → (2) `HomeWeekChips` — pil
  horizontal yang bisa digeser; (3) `GrowthStatusCard` dengan tips sebagai
  satu baris di dalamnya. Header tidak menyimpan aksi kelola/pengaturan.
- **Makan**: header (tanggal + judul + ganti anak + segmen Hari
  ini/Riwayat) **ikut menggulir** di dalam daftar — tidak disematkan di atas
  layar. Lalu `CapturePanel` (viewfinder + 3 langkah + privasi + CTA + pintu
  "Catat tanpa foto") → panel ringkasan → tur singkat → checklist kelompok →
  catatan hari ini. Pita protein hewani memakai `accentContainer` bila belum
  ada, `primaryContainer` bila sudah ada — selalu ikon + teks.
- **Sheet hasil scan** (v2.9): review editorial "Periksa isi piring" — item
  tanpa kotak bertumpuk (logo kelompok, nama inline, badge "Perlu dicek",
  pill kelompok, porsi), `showScanGroupPicker` grid 2 kolom maks. 3
  kelompok, tile "+ Tambah makanan", `SegmentControl` jenis makan, dan
  footer sticky dengan pratinjau Piring Hari Ini berbasis aturan (bukan AI).
  Porsi memakai `Wrap` selebar konten — dilarang `Wrap` di dalam `Row`
  (penyebab overflow 7,2 px).
- **Resep** (v3.2): katalog terkurasi dari `assets/recipes/recipes.json`
  (offline, tanpa jaringan). `ScreenHeader` + `ChildSwitcherButton` →
  penanda jujur **belum ditinjau ahli gizi/bidan** bila `reviewed_by` null
  (PRD §9.1, tidak bisa ditutup) → pencarian (judul/bahan) → chip usia
  horizontal (Semua · 6–8 · 9–11 · 12–23 · 24+ bln, target 48dp; default
  mengikuti usia anak) → saring **Protein hewani** + jumlah hasil.
  - Kartu resep: sampul **kolase logo kelompok pangan** (aset yang sudah ada,
    bukan foto karangan), judul 2 baris, meta jam + pil usia + pil protein
    hewani (ikon + teks), lalu chip kelompok. Seluruh kartu = satu tombol.
  - Detail (`/recipes/:id`, layar penuh tanpa nav bawah): blok hero tonal
    (sampul + judul + meta) → **Bahan** (kartu berhairline, takaran rata
    kanan) → **Langkah memasak** (lingkaran nomor tonal) → **Catatan keamanan**
    (tekstur + alergen, selalu ikon + teks) → status tinjauan → disclaimer.
    Footer sticky **Catat sebagai makan** → sheet pilih jenis makan →
    satu `food_logs` `source=recipe` (union kelompok masuk Piring Hari Ini)
    + snackbar Urungkan. Tanpa anak: CTA nonaktif + ajakan tambah profil.
  - Anak < 6 bulan: catatan ASI eksklusif; katalog tetap bisa dijelajahi.
    Empty state filter punya tombol "Atur ulang filter"; galat memuat punya
    kartu Coba lagi.
- **Tumbuh** (v2.3–v2.8): ringkasan `ZScoreSummaryStrip` (3 ubin, sekaligus
  pemilih indeks) → grafik pita SD **full-bleed** dengan judul sumbu + satuan
  (X: usia/panjang-tinggi, Y: tinggi/berat), **tap titik** → kartu detail
  (tanggal, usia, nilai, z-score, kategori + ikon, selisih ke median)
  muncul halus lewat `AnimatedSize` + fade/slide `AppMotion` (reduce-motion
  → durasi 0), hint ketuk → riwayat berbentuk
  accordion (ringkasan selalu tampil, z-score & aksi dibuka saat diketuk).
- **Akun** (v2.5): `ScreenHeader` → seksi **Profil anak** (`SectionHeading` +
  aksi "Kelola anak") → `AccountIdentityCard` (foto/avatar 68dp, nama 20 w700,
  pill usia & jenis kelamin, aksi ubah, divider hairline, baris **Pengukuran
  terakhir** — berat/tinggi + tanggal relatif, atau CTA "Belum ada
  pengukuran") → chip anak horizontal `AccountChildStrip` (hanya bila ≥ 2
  anak; state terpilih `primaryContainer` + border `primary`, plus chip
  "+ Tambah") → `ReminderSettingsSection` bergaya `SettingsTile` → seksi
  **Privasi & data** (`AccountPrivacyCard`: profil anak, foto profil, foto
  makanan, pengingat — jujur, tanpa klaim berlebihan, plus baris **Hapus akun**
  yang membuka dialog konfirmasi 48dp: server → foto lokal → prefs → logout →
  `/opening`) → seksi **Tentang
  aplikasi** (`AccountAboutSection`: sumber rujukan dalam sheet — Permenkes
  2/2020 & WHO — versi app, disclaimer).
- **Formatir anak** (v2.5–v2.8): preview besar 104dp + badge **pencil**;
  avatar/pencil → `ChildPhotoViewerSheet` full-screen (Atur · Hapus ·
  Selesai; tanpa Perbarui/Bingkai). Photo picker → `ChildPhotoCropScreen`
  (drag/pinch zoom, panduan lingkaran, tombol ≥48dp) sebelum disimpan;
  tombol Ambil foto/Galeri tetap di form. Avatar default memakai aset
  `assets/avatars` sesuai jenis kelamin; error izin/kompresi tampil inline.
- **Tanya / ruang konsultasi** (v3.1): bukan bubble-bubble setara. Susunan
  tetap: **header ringkas** (tutup · avatar · "Tanya Gizi" + "Asisten edukasi
  gizi" · menu ⋮ berisi *Hapus riwayat chat*) → **percakapan editorial** →
  **disclaimer tetap** → **kotak tulis**.
  - Jawaban asisten berupa **lembar `surface` ber-border hairline** (radius
    `card` 20, padding 16, tanpa shadow), **tanpa avatar dan tanpa nama**:
    identitas cukup di header, peran dibedakan lewat bentuk — lembar penuh di
    kiri vs pil `primary` di kanan. Jam `HH.mm` diletakkan **di luar** lembar.
    Pembaca layar tetap tahu perannya lewat `Semantics`
    (`tanyaAnswerSemantics` / `tanyaUserMessageSemantics`).
  - Pengelompokan: pesan berurutan dari peran sama dalam ≤ 5 menit berbagi
    jarak rapat dan satu label jam.
  - Pembatas hari (`Hari ini` / `Kemarin` / `16 Nov 2026`) memakai pil
    `surfaceVariant`; jam `HH.mm` di bawah pesan terakhir grup
    (`tanyaTimeSemantics`).
  - Indikator mengetik = lembar kecil berisi tiga titik (tanpa avatar, tanpa
    teks), tetap berlabel `tanyaAssistantTyping`.
  - Jawaban dirender `ChatMarkdown`: tebal, miring, bullet, daftar bernomor,
    heading. Tabel jadi baris `·`; tautan/gambar jadi teks; tidak ada HTML,
    gambar, atau tautan yang dieksekusi dari keluaran model.
  - Keadaan awal: ilustrasi + judul + body + **kartu saran vertikal**
    (ikon tonal 36dp, label, chevron) — bukan chip sempit; tetap memakai
    `Key('tanya-empty-list')` agar tes bisa menggulir.
  - Pertanyaan lanjutan (`ChatFollowups`) tampil sebagai kartu baris di bawah
    jawaban terakhir, bukan chip.
  - Disclaimer **selalu terlihat** tepat di atas kotak tulis, teks utuh tanpa
    ellipsis; tidak bisa ditutup. Galat kirim tampil ringkas di atas composer
    dengan tombol Coba lagi; peringatan sinkronisasi memakai baris `cloud_off`.
  - Kotak tulis: pil `surface` + border, `TextField` 1–5 baris, tombol kirim
    bulat 48dp. Baris konteks di atasnya: "Untuk {nama} · {usia}" dan sisa
    kuota (informasi tampilan; server tetap penentu, input tidak dikunci).
  - Safety card tetap kartu status (ikon + teks + warna). Setelah "Mengerti"
    kartu menyusut jadi baris "Panduan sudah dibaca", tidak hilang tanpa jejak.
  - Long-press pesan → sheet "Salin teks". Gulir otomatis hanya saat pengguna
    dekat dasar; tombol "Ke pesan terbaru" muncul saat membaca ke atas.
    Konten dibatasi 720dp pada tablet.
- **Onboarding** (v2.4): 3 halaman geser. Top bar merek (`AppLogoMark` 40dp
  + nama app + "Lewati" target 48dp) → **stage ilustrasi full-bleed**
  (tinggi 50% area, `surfaceVariant`, sudut bawah `card`, ring + titik
  `accent`) → eyebrow pill `primaryContainer` → judul 26/32 w700 rata kiri →
  body 15/23 `textSecondary` → footer tetap: progress 3 segmen + "01 / 03",
  CTA 52dp, disclaimer 11/16. Satu halaman = satu cerita; teks tidak
  di tengah agar hierarki terbaca. Reduce-motion = lompat halaman.
- **Consent / persetujuan** (v2.4–v2.5): tanpa AppBar/back. Top bar merek + pil
  "Langkah terakhir" → **hero hijau** (`AppSurfaces.hero`) berisi ikon perisai,
  eyebrow, judul 24/30, intro → kartu **5 baris data** berikon (profil anak,
  foto profil (opsional), foto makanan, akses terbatas, kendali penuh;
  divider hairline indent 68) → callout disclaimer `accentContainer` → **footer tetap** berisi
  checkbox (state terpilih `primaryContainer` + border `primary`), CTA 52dp
  (disabled sampai dicentang), dan hint penolakan. Checkbox + CTA tidak pernah
  butuh scroll. Error tampil di atas checkbox dengan `liveRegion`.
- **Splash / opening** (v3.0): **satu layar bermerek** — splash sistem Android
  solid `#145C45` dengan ikon transparan (`splash_icon_transparent.xml`),
  lalu `OpeningScreen` memutar Lottie `assets/animations/cekgizi_opening.json`
  (1080×1080, 3 detik, latar konstan, **1× speed**, terpusat eksplisit)
  **+ suara khas `assets/audio/cek-gizi_audio.wav`** (volume 0,35, sekali,
  laju 1,5× agar sinkron; reduce-motion = bisu). Animasi selesai → langsung
  lanjut; backend berjalan di latar dan tidak menghalangi navigasi. Reduce
  motion dihormati; timeout pengaman 6 dtk; tidak ada logo ganda. Launcher
  icon Android dibuat dari `logo_cek-gizi.png`; logo di dalam app memakai
  `AppLogoMark`.

## 9. Aksesibilitas (PRD §7.7)

- Tidak overflow di lebar 360dp pada text scale 1,3, light & dark
  (`test/features/layout_scale_test.dart`).
- Target sentuh ≥ 48dp; teks kontras ≥ 4,5:1. `WeekStrip` memakai sel 48dp
  dalam scroll horizontal (7 hari tidak muat di 360dp tanpa digeser).
- Setiap grafik/ikon punya `Semantics` (mis. ring: "3 dari 8 kelompok");
  `ZScoreTable` memberi label pembaca layar per baris (indeks + kategori +
  z-score).
- Status tidak pernah hanya warna.
- Hormati `MediaQuery.disableAnimations`.

## 10. Copywriting

- Semua teks di `AppStrings`; suara "kamu", hangat, tanpa menghakimi.
- Angka & tanggal memakai format Indonesia (`IdDateFormat`, koma desimal).
- Nama aplikasi selalu dari `AppConfig.appName`.
