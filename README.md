# CekGizi

> Alat bantu **edukasi dan pemantauan** gizi balita (6–59 bulan) untuk orang tua Indonesia.
> **Bukan alat diagnosis.** Hasilnya tidak menggantikan pemeriksaan tenaga kesehatan.

CekGizi membantu orang tua:

1. **Piring Hari Ini** — foto makanan, lihat kelompok pangan yang sudah/belum tercapai hari ini.
2. **Tumbuh dalam konteks** — grafik pertumbuhan berdasarkan standar antropometri **Permenkes 2/2020**, dengan bahasa yang tenang dan arahan yang jelas.
3. **Tanya Gizi** — jawaban edukatif singkat dengan batas aman yang tegas.

## Dokumen

| Dokumen | Isi |
|---|---|
| [`PRD.md`](PRD.md) | Product Requirements Document v2.0 — sumber kebenaran tunggal |
| [`AGENTS.md`](AGENTS.md) | Aturan kerja AI agent (Clean Architecture, workflow, git policy) |
| [`docs/progress.md`](docs/progress.md) | Catatan progres per batch + alasan dependency |
| [`docs/reference-notes.md`](docs/reference-notes.md) | Catatan tabel referensi Permenkes 2/2020 |

## Menjalankan

```bash
flutter pub get
flutter run
```

## Verifikasi

```bash
flutter analyze
flutter test
```

## Struktur singkat

```
lib/
├── core/        # config (AppConfig), constants (AppStrings), errors (Failure), theme (Batch 1)
├── domain_ref/  # loader tabel referensi gizi (diisi Batch 3, data dari pemilik)
├── features/    # <feature>/{data,domain,presentation} — auth, onboarding, consent, children,
│                #   growth, meals, chat, recipes, settings
└── shared/      # widget lintas fitur
supabase/
├── migrations/  # skema Postgres + RLS (Batch 2)
└── functions/   # Edge Functions: analyze-meal, ask-nutrition, delete-account, health (Batch 2+)
assets/          # fonts, rules, reference, data, images
docs/            # progress.md, reference-notes.md
```

## Aturan kontribusi

- Kerjakan **per batch** sesuai PRD §10, di branch `feature/app4-mvp`. Jangan merge ke `main`.
- Baca `PRD.md` sampai habis sebelum menyentuh kode.
- Data gizi hanya dari file yang disediakan pemilik proyek — jangan mengarang.
- Tidak ada kunci/rahasia di repo. `flutter analyze` dan `flutter test` wajib bersih.
