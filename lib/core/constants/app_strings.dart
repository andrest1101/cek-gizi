import 'package:cekgizi/core/config/app_config.dart';

/// Semua copy UI terpusat di sini (Bahasa Indonesia, nada hangat dan
/// tidak menghakimi — PRD §7.6). Widget tidak boleh menulis string bebas.
abstract final class AppStrings {
  const AppStrings._();

  /// Disclaimer tetap (PRD §8.5) — wajib tampil di Tentang & onboarding.
  static const String disclaimer =
      '${AppConfig.appName} adalah alat bantu edukasi dan pemantauan. '
      'Hasilnya bukan diagnosis dan tidak menggantikan pemeriksaan tenaga '
      'kesehatan. Jika anak sakit atau kamu khawatir, hubungi Posyandu, '
      'puskesmas, atau dokter.';

  /// Label tombol coba lagi (PRD §6.9).
  static const String retry = 'Coba lagi';

  /// Judul umum kartu galat (PRD §6.9).
  static const String errorTitle = 'Ups, terjadi kesalahan';

  // ── Onboarding ─────────────────────────────────────────────────
  static const onboardingSkip = 'Lewati';
  static const onboardingNext = 'Selanjutnya';
  static const onboardingStart = 'Mulai';
  static const onboardingTitle1 = 'Foto piring, lihat isinya';
  static const onboardingBody1 =
      'Ambil foto makanan anak, lalu lihat kelompok pangan mana yang sudah dan '
      'belum tercapai hari ini.';
  static const onboardingTitle2 = 'Tumbuh dalam konteks';
  static const onboardingBody2 =
      'Pantau tinggi, berat, dan status pertumbuhan menurut Permenkes 2/2020 — '
      'dengan bahasa yang tenang dan jelas.';
  static const onboardingTitle3 = 'Pendamping, bukan dokter';
  static const onboardingBody3 =
      '${AppConfig.appName} memberi edukasi, bukan diagnosis. Untuk kekhawatiran '
      'kesehatan, hubungi Posyandu, puskesmas, atau dokter.';

  // ── Consent (PRD §8.3) ─────────────────────────────────────────
  static const consentTitle = 'Sebelum mulai, baca ini dulu';
  static const consentIntro =
      '${AppConfig.appName} membantu memantau tumbuh kembang dan gizi balita '
      'kamu. Kami hanya menyimpan yang kamu izinkan — tidak lebih.';
  static const consentBullets = <String>[
    'Data yang tersimpan: nama panggilan, tanggal lahir, jenis kelamin, berat, tinggi, dan catatan perkembangannya.',
    'Foto makanan dikirim hanya untuk dikenali oleh AI dan dihapus setelah dianalisis — foto tidak disimpan.',
    'Data kamu sendiri yang bisa mengaksesnya (pengamanan tingkat baris di server).',
    'Kamu bisa mengekspor data, menghapus riwayat chat, atau menghapus akun beserta seluruh datanya kapan pun di Pengaturan.',
  ];
  static const consentAgreeLabel =
      'Saya setuju data anak saya disimpan untuk tujuan pemantauan dan edukasi.';
  static const consentSubmit = 'Setuju dan lanjutkan';
  static const consentDeclineHint =
      'Tanpa persetujuan, ${AppConfig.appName} tidak bisa dipakai.';

  // ── Anak (profil) ──────────────────────────────────────────────
  static const childAddTitle = 'Tambah anak';
  static const childEditTitle = 'Ubah data anak';
  static const childNicknameLabel = 'Nama panggilan';
  static const childNicknameHint = 'Mis. Siti, Arka, Bila';
  static const childBirthDateLabel = 'Tanggal lahir';
  static const childSexLabel = 'Jenis kelamin';
  static const childSexMale = 'Laki-laki';
  static const childSexFemale = 'Perempuan';
  static const childAvatarLabel = 'Avatar';
  static const childSave = 'Simpan';
  static const childDelete = 'Hapus';
  static const childDeleteTitle = 'Hapus data anak?';
  static const childDeleteBody =
      'Data anak beserta seluruh pengukurannya akan dihapus permanen. '
      'Tindakan ini tidak bisa dibatalkan.';
  static const childDeleteConfirm = 'Hapus';
  static const childDeleteCancel = 'Batal';
  static const childListTitle = 'Anak saya';
  static const childMaxReached = 'Maksimal 5 anak per akun.';
  static const childEmptyTitle = 'Belum ada anak terdaftar';
  static const childEmptyBody =
      'Tambahkan anak pertama — cukup nama panggilan, tgl lahir, dan jenis kelamin.';
  static const childEmptyCta = 'Tambah anak';
  static const childAgeYears = 'tahun';
  static const childAgeMonths = 'bulan';

  // ── Tumbuh ─────────────────────────────────────────────────────
  static const growthTitle = 'Tumbuh';
  static const growthAddMeasurement = 'Tambah ukuran';
  static const growthTabLengthHeight = 'Tinggi/Umur';
  static const growthTabWeight = 'Berat/Umur';
  static const growthTabWeightHeight = 'Berat/Tinggi';
  static const growthHistoryTitle = 'Riwayat pengukuran';
  static const growthMeasureWeight = 'Berat (kg)';
  static const growthMeasureHeightLength = 'Panjang/tinggi (cm)';
  static const growthMeasureDate = 'Tanggal ukur';
  static const growthMeasureMode = 'Cara ukur';
  static const growthMeasureModeLying = 'Terlentang (baring)';
  static const growthMeasureModeStanding = 'Berdiri';
  static const growthMeasureNote = 'Catatan (opsional)';
  static const growthMeasureSave = 'Simpan pengukuran';
  static const growthMeasureSaved = 'Pengukuran tersimpan';
  static const growthNoteMaxLength = 200;
  static const growthNoMeasurementsTitle = 'Belum ada pengukuran';
  static const growthNoMeasurementsBody =
      'Ukur berat dan panjang/tinggi anak untuk melihat grafik dan statusnya.';
  static const growthNoMeasurementsCta = 'Tambah ukuran pertama';

  // ── Validasi ukur (PRD §5.1 skema: 1–30 kg, 35–130 cm, 0–60 bln) ──
  static const validationWeightRange = 'Berat harus antara 1 dan 30 kg.';
  static const validationHeightRange = 'Panjang/tinggi harus antara 35 dan 130 cm.';
  static const validationDateFuture = 'Tanggal ukur tidak boleh di masa depan.';
  static const validationDateBeforeBirth =
      'Tanggal ukur tidak boleh sebelum anak lahir.';
  static const validationAgeRange =
      'Usia saat ukur di luar 0–60 bulan — remaja tidak bisa dipantau aplikasi ini.';
  static const validationDuplicateDate =
      'Sudah ada pengukuran pada tanggal ini. Ubah atau hapus dulu yang lama.';
  static const validationRequired = 'Wajib diisi.';

  // ── Status ramah (PRD §3.9 + §3.5) ──────────────────────────────
  static const statusNormalTitle = 'Sesuai umur';
  static const statusNormalBody =
      'Pertumbuhan anak sejalan dengan standar untuk umurnya.';
  static const statusNormalAction = 'Lanjut ukur bulan depan';
  static const statusBelowTitle = 'Di bawah rata-rata';
  static const statusBelowBody =
      'Angkanya di bawah rata-rata untuk umurnya. Ini bukan diagnosis.';
  static const statusBelowAction = 'Periksakan ke Posyandu atau puskesmas';
  static const statusAlertTitle = 'Perlu diperiksa segera';
  static const statusAlertBody =
      'Sebaiknya anak diperiksa tenaga kesehatan dalam waktu dekat.';
  static const statusAlertAction = 'Hubungi Posyandu/puskesmas';
  static const statusAboveTitle = 'Di atas rata-rata';
  static const statusAboveBody = 'Angkanya di atas rata-rata untuk umurnya.';
  static const statusAboveAction = 'Konsultasikan pola makan';
  static const statusOutOfRangeTitle = 'Periksa kembali';
  static const statusOutOfRangeBody =
      'Angka ini tampak tidak biasa. Periksa kembali berat dan panjang/tinggi '
      'yang kamu masukkan.';
  static const statusDetailTitle = 'Detail angka';
  static const statusDetailZScore = 'Skor z';
  static const statusDetailCategory = 'Kategori resmi';
  static const statusDetailDate = 'Tanggal ukur';
  static const statusViewDetail = 'Lihat detail';
  static const statusCardTitle = 'Status pertumbuhan';
  static const statusTrendNeedsAttention =
      'Berat turun dibanding pengukuran sebelumnya — sebaiknya periksakan.';
  static const statusTrendTracked = 'Tren sesuai. Lanjutkan pemantauan rutin.';
  static const statusAddFirst = 'Tambah ukuran';

  // ── Navigasi ───────────────────────────────────────────────────
  static const navHome = 'Beranda';
  static const navGrowth = 'Tumbuh';

  // ── Beranda ────────────────────────────────────────────────────
  static const homeGreeting = 'Ringkasan hari ini';

  // ── Kategori resmi (PRD §3.4) ───────────────────────────────────
  static const Map<String, String> officialCategoryHaz = {
    'very_short': 'Sangat pendek',
    'short': 'Pendek',
    'normal': 'Normal',
    'tall': 'Tinggi',
  };
  static const Map<String, String> officialCategoryWaz = {
    'very_low': 'Berat badan sangat kurang',
    'low': 'Berat badan kurang',
    'normal': 'Berat badan normal',
    'risk_overweight': 'Risiko berat badan lebih',
  };
  static const Map<String, String> officialCategoryWhz = {
    'severe_wasting': 'Gizi buruk',
    'wasting': 'Gizi kurang',
    'normal': 'Gizi baik',
    'risk_over': 'Berisiko gizi lebih',
    'overweight': 'Gizi lebih',
    'obese': 'Obesitas',
  };

  /// Indeks antropometri (tampilan detail).
  static const hazLabel = 'PB/U – TB/U';
  static const wazLabel = 'BB/U';
  static const whzLabel = 'BB/PB – BB/TB';
  static const statusOutOfRangeShort = 'Di luar rentang wajar';
}
