import 'package:cekgizi/core/config/app_config.dart';

/// Semua copy UI terpusat di sini (Bahasa Indonesia, nada hangat dan
/// tidak menghakimi - PRD §7.6). Widget tidak boleh menulis string bebas.
abstract final class AppStrings {
  const AppStrings._();

  /// Disclaimer tetap (PRD §8.5) - wajib tampil di Tentang & onboarding.
  static const String disclaimer =
      '${AppConfig.appName} adalah alat bantu edukasi dan pemantauan. '
      'Hasilnya bukan diagnosis dan tidak menggantikan pemeriksaan tenaga '
      'kesehatan. Jika anak sakit atau kamu khawatir, hubungi Posyandu, '
      'puskesmas, atau dokter.';

  /// Label tombol coba lagi (PRD §6.9).
  static const String retry = 'Coba lagi';

  /// Judul umum kartu galat (PRD §6.9).
  static const String errorTitle = 'Ups, terjadi kesalahan';

  // ── Umum ───────────────────────────────────────────────────────
  static const String actionEdit = 'Ubah';
  static const String actionDelete = 'Hapus';
  static const String actionCancel = 'Batal';
  static const String actionClose = 'Tutup';
  static const String skeletonLoading = 'Sedang memuat';

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
      'Pantau tinggi, berat, dan status pertumbuhan menurut Permenkes 2/2020, '
      'dengan bahasa yang tenang dan jelas.';
  static const onboardingTitle3 = 'Pendamping, bukan dokter';
  static const onboardingBody3 =
      '${AppConfig.appName} memberi edukasi, bukan diagnosis. Untuk kekhawatiran '
      'kesehatan, hubungi Posyandu, puskesmas, atau dokter.';
  static String onboardingPageSemantics(int page, int total) =>
      'Halaman $page dari $total';

  // ── Consent (PRD §8.3) ─────────────────────────────────────────
  static const consentTitle = 'Sebelum mulai, baca ini dulu';
  static const consentIntro =
      '${AppConfig.appName} membantu memantau tumbuh kembang dan gizi balita '
      'kamu. Kami hanya menyimpan yang kamu izinkan, tidak lebih.';
  static const consentBullets = <String>[
    'Data yang tersimpan: nama panggilan, tanggal lahir, jenis kelamin, berat, tinggi, dan catatan perkembangannya.',
    'Foto makanan dikirim hanya untuk dikenali oleh AI dan dihapus setelah dianalisis. Foto tidak disimpan.',
    'Data kamu sendiri yang bisa mengaksesnya (pengamanan tingkat baris di server).',
    'Kamu bisa mengekspor data, menghapus riwayat chat, atau menghapus akun beserta seluruh datanya kapan pun di Pengaturan.',
  ];
  static const consentAgreeLabel =
      'Saya setuju data anak saya disimpan untuk tujuan pemantauan dan edukasi.';
  static const consentSubmit = 'Setuju dan lanjutkan';
  static const consentDeclineHint =
      'Tanpa persetujuan, ${AppConfig.appName} tidak bisa dipakai.';
  static const consentPrivacySemantics = 'Privasi data anak';
  static const consentDataTitle = 'Yang kami simpan dan jaga';
  static const consentDisclaimerTitle = 'Perlu kamu tahu';
  static const consentError =
      'Persetujuan belum tersimpan. Periksa koneksi internet kamu, lalu coba lagi.';

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
      'Tambahkan anak pertama. Cukup nama panggilan, tanggal lahir, dan jenis kelamin.';
  static const childEmptyCta = 'Tambah anak';
  static const childAgeYears = 'tahun';
  static const childAgeMonths = 'bulan';
  static const childSelectedBadge = 'Sedang dipilih';
  static const childOptionsTooltip = 'Opsi anak';
  static const childManageHint =
      'Ketuk kartu untuk memilih anak yang tampil di Beranda.';
  static const childListLoadError =
      'Gagal memuat data anak. Periksa koneksi internet kamu, lalu coba lagi.';
  static const childBirthDateHint = 'Usia 0–60 bulan.';
  static const childNicknameMaxLength = 'Maksimal 30 karakter.';
  static const childSaveError =
      'Gagal menyimpan. Periksa koneksi internet kamu, lalu coba lagi.';
  static const childNotFound = 'Anak tidak ditemukan.';
  static String childAvatarSemantics(String key) => 'Avatar $key';

  // ── Tumbuh ─────────────────────────────────────────────────────
  static const growthTitle = 'Tumbuh';
  static const growthSubtitle =
      'Pantau berat, tinggi, dan status gizi anak menurut Permenkes 2/2020.';
  static const growthAddMeasurement = 'Tambah ukuran';
  static const growthTabLengthHeight = 'Tinggi/Umur';
  static const growthTabWeight = 'Berat/Umur';
  static const growthTabWeightHeight = 'Berat/Tinggi';
  static const growthTabLengthHeightShort = 'Tinggi';
  static const growthTabWeightShort = 'Berat';
  static const growthTabWeightHeightShort = 'BB/TB';
  static const growthTabLengthHeightSemantics =
      'Grafik tinggi badan menurut umur';
  static const growthTabWeightSemantics = 'Grafik berat badan menurut umur';
  static const growthTabWeightHeightSemantics =
      'Grafik berat badan menurut panjang atau tinggi badan';
  static const growthHistoryTitle = 'Riwayat pengukuran';
  static const growthChartTitle = 'Grafik pertumbuhan';
  static const growthChartCaption = 'Tabel rujukan: Permenkes 2/2020';
  static const growthTrendHint =
      'Belum cukup data untuk melihat tren. Tambah satu ukuran lagi.';
  static const growthLegendBand = 'Rentang wajar';
  static const growthLegendLimit = 'Batas ±2 SD';
  static const growthLegendMedian = 'Median';
  static const growthLegendChild = 'Anak';
  static const growthLatestWeight = 'Berat terakhir';
  static const growthLatestHeight = 'Tinggi terakhir';
  static const growthDeltaSame = 'Sama dengan ukur lalu';
  static const growthDeltaSince = 'sejak ukur terakhir';
  static const growthHistoryEmpty = 'Belum ada riwayat pengukuran.';
  static const growthLoadError =
      'Gagal memuat pengukuran. Periksa koneksi internet kamu, lalu coba lagi.';
  static const growthReferenceError =
      'Tabel rujukan belum bisa dimuat. Periksa koneksi, lalu coba lagi.';
  static const growthNoChildTitle = 'Belum ada anak';
  static const growthNoChildBody =
      'Tambahkan profil anak dulu untuk mulai memantau pertumbuhan.';
  static const growthNoChildCta = 'Tambah anak';
  static const growthEditTitle = 'Ubah pengukuran';
  static const growthSheetHint =
      'Catat hasil ukur di Posyandu atau timbangan rumah.';
  static const growthDateLocked = 'Tanggal ukur tidak bisa diubah.';
  static const growthOptionsTooltip = 'Opsi pengukuran';
  static const growthDeleteTitle = 'Hapus pengukuran?';
  static const growthDeleteBody = 'Pengukuran ini akan dihapus permanen.';
  static const growthViewChart = 'Lihat di grafik';
  static const growthMeasureWeight = 'Berat (kg)';
  static const growthMeasureHeightLength = 'Panjang/tinggi (cm)';
  static const growthMeasureDate = 'Tanggal ukur';
  static const growthMeasureMode = 'Cara ukur';
  static const growthMeasureModeLying = 'Terlentang';
  static const growthMeasureModeStanding = 'Berdiri';
  static const growthMeasureModeLyingSemantics =
      'Diukur terlentang (baring)';
  static const growthMeasureModeStandingSemantics = 'Diukur berdiri';
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
      'Usia saat ukur di luar 0–60 bulan. Remaja tidak bisa dipantau aplikasi ini.';
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
  static const statusDetailFootnote =
      'Skor z dihitung dari tabel Permenkes 2/2020.';
  static const statusViewDetail = 'Lihat detail';
  static const statusCardTitle = 'Status pertumbuhan';
  static const statusTrendNeedsAttention =
      'Berat turun dibanding pengukuran sebelumnya. Sebaiknya periksakan.';
  static const statusTrendTracked = 'Tren sesuai. Lanjutkan pemantauan rutin.';
  static const statusAddFirst = 'Tambah ukuran';

  // ── Piring Hari Ini (PRD §3.7, §6.3) ─────────────────────────────
  static const piringTitle = 'Piring Hari Ini';
  static const piringEmpty = 'Belum ada catatan makan hari ini.';
  static const piringAnimalProteinMissing = 'Belum ada protein hewani hari ini.';
  static const piringAnimalProteinPresent = 'Protein hewani sudah ada hari ini.';
  static const piringLegendAnimal = 'Busur oranye menandai protein hewani.';
  static const piringTargetReached = 'Keragaman pangan hari ini tercapai';
  static const piringGroupsLabel = 'kelompok';
  static const piringCta = 'Catat makanan';
  static const piringUnreviewedCaption =
      'Aturan keragaman pangan belum ditinjau ahli gizi.';
  static const piringNoProfile =
      'Target keragaman belum tersedia untuk usia ini. Tetap catat kelompok yang dimakan.';
  static const tipTitle = 'Tips hari ini';
  static const tipsAction = 'Catat sekarang';
  static const asiExclusiveTitle = 'Bayi di bawah 6 bulan';
  static const asiExclusiveBody =
      'ASI eksklusif adalah yang terbaik untuk usia ini. Setelah usia 6 bulan, '
      'diversifikasi pangan bisa dimulai dengan pendampingan bidan atau ahli gizi.';
  static String piringGroupsMetSemantics(int met, int total) =>
      'Keragaman pangan hari ini: $met dari $total kelompok terisi.';
  static String piringTargetNote(int target, {required bool breastMilkNotCounted}) =>
      breastMilkNotCounted
          ? 'Target hari ini: $target kelompok (ASI tidak dihitung).'
          : 'Target hari ini: $target kelompok.';
  static const heroAsiCta = 'Catat ASI';

  // ── Kelompok pangan (PRD §3.7) ─────────────────────────────────
  static const groupGrainsTubersShort = 'Makanan pokok';
  static const groupLegumesNutsShort = 'Tempe & kacang';
  static const groupDairyShort = 'Susu & olahan';
  static const groupFleshShort = 'Lauk hewani';
  static const groupEggsShort = 'Telur';
  static const groupVitAFruitVegShort = 'Buah/sayur A';
  static const groupOtherFruitVegShort = 'Buah/sayur lain';
  static const groupGrainsTubers = 'Makanan pokok';
  static const groupGrainsTubersExamples = 'Nasi, bubur, kentang, ubi';
  static const groupLegumesNuts = 'Kacang dan biji-bijian';
  static const groupLegumesNutsExamples = 'Tahu, tempe, kacang hijau';
  static const groupDairy = 'Susu dan olahannya';
  static const groupDairyExamples = 'Susu, yogurt, keju';
  static const groupFlesh = 'Daging, ikan, unggas, hati';
  static const groupFleshExamples = 'Ikan kembung, hati ayam, daging';
  static const groupEggs = 'Telur';
  static const groupEggsExamples = 'Telur rebus, orak-arik';
  static const groupVitAFruitVeg = 'Buah & sayur vitamin A';
  static const groupVitAFruitVegExamples = 'Wortel, labu, bayam, pepaya, mangga';
  static const groupOtherFruitVeg = 'Buah & sayur lainnya';
  static const groupOtherFruitVegExamples = 'Pisang, apel, kol, buncis';

  /// Label kelompok menurut kode resmi PRD §3.7 (dipakai tips & aksi).
  static String groupLabel(String code) => switch (code) {
        'breast_milk' => 'ASI',
        'grains_tubers' => groupGrainsTubers,
        'legumes_nuts' => groupLegumesNuts,
        'dairy' => groupDairy,
        'flesh' => groupFlesh,
        'eggs' => groupEggs,
        'vit_a_fruit_veg' => groupVitAFruitVeg,
        'other_fruit_veg' => groupOtherFruitVeg,
        _ => code,
      };

  /// Label pendek untuk tombol aksi (muat di 360dp).
  static String groupShortLabel(String code) => switch (code) {
        'breast_milk' => 'ASI',
        'grains_tubers' => groupGrainsTubersShort,
        'legumes_nuts' => groupLegumesNutsShort,
        'dairy' => groupDairyShort,
        'flesh' => groupFleshShort,
        'eggs' => groupEggsShort,
        'vit_a_fruit_veg' => groupVitAFruitVegShort,
        'other_fruit_veg' => groupOtherFruitVegShort,
        _ => code,
      };

  /// Contoh makanan untuk satu kelompok (baris bantuan di checklist).
  static String groupExamples(String code) => switch (code) {
        'breast_milk' => 'Cukup satu tanda untuk hari ini',
        'grains_tubers' => groupGrainsTubersExamples,
        'legumes_nuts' => groupLegumesNutsExamples,
        'dairy' => groupDairyExamples,
        'flesh' => groupFleshExamples,
        'eggs' => groupEggsExamples,
        'vit_a_fruit_veg' => groupVitAFruitVegExamples,
        'other_fruit_veg' => groupOtherFruitVegExamples,
        _ => '',
      };

  // ── Makan (PRD §6.4) ───────────────────────────────────────────
  static const makanTitle = 'Makan';
  static const makanSubtitle =
      'Catat apa yang anak makan hari ini. Porsi tidak dinilai.';

  // Segment Hari ini / Riwayat.
  static const makanSectionToday = 'Hari ini';
  static const makanSectionHistory = 'Riwayat';
  static const makanSectionTodaySemantics = 'Catatan makan hari ini';
  static const makanSectionHistorySemantics =
      'Riwayat catatan makan 30 hari terakhir';

  // ASI.
  static const makanAsiToday = 'ASI hari ini';
  static const makanAsiSubtitle =
      'Cukup satu tanda untuk hari ini. Tidak perlu menghitung berapa disusukan.';
  static const makanAsiSecondaryNote =
      'ASI tetap boleh dicatat, tetapi tidak dihitung pada target usia ini.';
  static const makanAsiActionLog = 'Catat ASI';
  static const makanAsiActionRemove = 'Hapus catatan ASI';
  static const makanAsiLogged = 'ASI tercatat hari ini';
  static const makanAsiLoggedFeedback = 'ASI hari ini tercatat.';
  static const makanAsiRemovedFeedback = 'Catatan ASI hari ini dihapus.';

  // Checklist kelompok pangan.
  static const makanGridTitle = 'Catat yang sudah dimakan';
  static const makanGridHint =
      'Ketuk satu kelompok, catatan langsung tersimpan. Ketuk lagi untuk '
      'menghapus.';
  static const makanChecklistActionLog = 'Catat';
  static const makanChecklistActionRemove = 'Hapus';
  static const makanChecklistCounted = 'Tercatat';
  static const makanChecklistUncounted = 'Belum tercatat';
  static const makanChecklistOptional = 'Tidak dihitung di usia ini';
  static String makanChecklistSemantics(
    String label,
    String examples,
    bool logged,
  ) =>
      logged
          ? '$label, sudah tercatat. $examples'
          : '$label, belum tercatat. $examples';
  static String makanChecklistActionSemantics(String label, bool logged) =>
      logged ? 'Hapus catatan $label' : 'Catat $label';
  static String makanChecklistCountSemantics(int met, int total) =>
      '$met dari $total kelompok tercatat hari ini.';

  // Composer "Catat satu kali makan".
  static const makanComposerCta = 'Catat makan';
  static const makanComposerHint =
      'Untuk satu piring yang berisi beberapa kelompok sekaligus.';
  static const catatMakanTitle = 'Catat satu kali makan';
  static const catatMakanSubtitle =
      'Pilih waktu makan dan kelompok yang ada di piring.';
  static const catatMakanMealTypeLabel = 'Waktu makan';
  static const catatMakanGroupsLabel = 'Kelompok yang dimakan';
  static const catatMakanGroupsHint = 'Pilih minimal satu. Boleh lebih dari satu.';
  static const catatMakanPortionLabel = 'Porsi (opsional)';
  static const catatMakanPortionHint =
      'Porsi hanya catatan kamu, bukan penilaian.';
  static const catatMakanSave = 'Simpan catatan';
  static const catatMakanSaved = 'Catatan makan tersimpan.';
  static const catatMakanEmptyGroups = 'Pilih minimal satu kelompok dulu.';
  static const catatMakanError =
      'Gagal menyimpan catatan. Periksa koneksi internet kamu, lalu coba lagi.';
  static String catatMakanSelectedCount(int count) => '$count kelompok dipilih';

  // Diary hari ini.
  static const makanDiaryTodayTitle = 'Catatan hari ini';
  static const makanDiaryEmpty =
      'Belum ada catatan hari ini. Ketuk kelompok di atas untuk mulai.';
  static const makanTimelineHint =
      'Geser catatan ke kiri atau ketuk ikon hapus untuk membuangnya.';
  static const makanDeleteLog = 'Hapus catatan';
  static const makanLogDeleted = 'Catatan dihapus.';
  static const makanUndoAction = 'Urungkan';
  static String makanLogAdded(String label) => '$label ditambahkan ke catatan.';
  static String makanGroupAlreadyLogged(String label) =>
      '$label sudah tercatat hari ini.';
  static const makanGroupInCombinedLog =
      'Kelompok ini tercatat dalam catatan gabungan. Hapus lewat daftar '
      'catatan hari ini.';
  static String makanGroupLogSemantics(String label) => 'Catat $label';
  static String makanGroupLoggedSemantics(String label) =>
      '$label, sudah tercatat hari ini';
  static String makanDayToggleSemantics(String day, int met, int total) =>
      '$day, $met dari $total kelompok. Ketuk untuk membuka catatan.';
  static String makanTodayProgress(int met, int total) =>
      '$met dari $total kelompok';
  static const makanTodayEmpty = 'Belum ada kelompok tercatat';
  static const makanToday = 'Hari ini';
  static const mealBreakfast = 'Sarapan';
  static const mealLunch = 'Siang';
  static const mealDinner = 'Malam';
  static const mealSnack = 'Camilan';
  static const makanYesterday = 'Kemarin';
  static const makanLoadError =
      'Gagal memuat catatan makan. Periksa koneksi internet kamu, lalu coba lagi.';
  static const makanSaveError =
      'Gagal menyimpan catatan. Periksa koneksi internet kamu, lalu coba lagi.';

  // Riwayat makan.
  static const makanHistoryTitle = 'Riwayat makan';
  static const makanHistorySubtitle =
      'Lihat catatan 30 hari terakhir anak kamu.';
  static const makanHistoryLoadError =
      'Gagal memuat riwayat makan. Periksa koneksi internet kamu, lalu coba lagi.';
  static const makanHistoryEmptyTitle = 'Belum ada catatan';
  static const makanHistoryEmptyBody =
      'Mulai catat makan hari ini. Riwayat akan muncul di sini.';
  static const makanHistoryEmptyCta = 'Catat makan hari ini';
  static const makanHistoryDayEmpty = 'Tidak ada catatan pada hari ini.';
  static const makanHistoryWindowNote =
      'Riwayat yang tersedia: 30 hari terakhir.';
  static const makanHistorySummaryTitle = '30 hari terakhir';
  static const makanHistoryCalendarTitle = 'Pilih tanggal';
  static const makanHistoryCalendarHint =
      'Ketuk tanggal untuk melihat catatannya.';
  static const makanHistoryPrevMonth = 'Bulan sebelumnya';
  static const makanHistoryNextMonth = 'Bulan berikutnya';
  static String makanHistoryDaysWithLogs(int logged, int total) =>
      '$logged dari $total hari ada catatan';
  static String makanHistoryTargetDays(int days) =>
      '$days hari mencapai target';
  static String makanHistoryAnimalDays(int days) =>
      '$days hari ada protein hewani';
  static String makanHistoryDaySemantics(
    String day,
    int met,
    int total,
    bool hasLogs,
  ) =>
      hasLogs
          ? '$day, $met dari $total kelompok. Ketuk untuk melihat catatan.'
          : '$day, belum ada catatan.';
  static String makanHistoryDayProgress(int met, int total) =>
      '$met dari $total kelompok';
  static const makanHistoryLegendLogged = 'Ada catatan';
  static const makanHistoryLegendReached = 'Target tercapai';

  // Info "Cara kerja Piring Hari Ini".
  static const piringInfoOpen = 'Cara kerja';
  static const piringInfoOpenSemantics = 'Cara kerja Piring Hari Ini';
  static const piringInfoTitle = 'Cara kerja Piring Hari Ini';
  static const piringInfoIntro =
      'Piring Hari Ini adalah catatan keragaman pangan, bukan penilaian gizi.';
  static const piringInfoResetTitle = 'Mulai dari nol setiap hari';
  static const piringInfoResetBody =
      'Semua catatan pada hari ini dihitung menurut waktu perangkat. Saat '
      'tengah malam, hitungan mulai lagi dari nol.';
  static const piringInfoTargetTitle = 'Target kelompok';
  static String piringInfoTargetBody(
    int target, {
    required bool breastMilkNotCounted,
  }) =>
      breastMilkNotCounted
          ? 'Target usia ini: minimal $target dari 7 kelompok. ASI tidak dihitung.'
          : 'Target usia ini: minimal $target dari 8 kelompok.';
  static const piringInfoAsiTitle = 'ASI dicatat sekali';
  static const piringInfoAsiBody =
      'Cukup satu tanda untuk hari ini. Kamu tidak perlu menghitung berapa '
      'kali menyusui.';
  static const piringInfoAnimalTitle = 'Protein hewani dicek terpisah';
  static const piringInfoAnimalBody =
      'Susu, lauk hewani, dan telur tetap masuk hitungan kelompok, lalu dicek '
      'lagi sebagai protein hewani.';
  static const piringInfoNotJudgingTitle = 'Catatan, bukan penilaian';
  static const piringInfoNotJudgingBody =
      'Porsi dan jumlah tidak dinilai. Yang dilihat hanya variasi kelompok '
      'pangan.';
  static const piringInfoClose = 'Tutup';

  // Tur singkat sekali jalan.
  static const piringTourTitle = 'Mulai dari sini';
  static const piringTourBody =
      'Ketuk kelompok yang sudah dimakan hari ini. Kalau satu piring berisi '
      'beberapa kelompok, pakai "Catat satu kali makan" agar cukup sekali '
      'simpan.';
  static const piringTourDismiss = 'Mengerti';
  static const piringTourSemantics = 'Panduan singkat Piring Hari Ini';

  // Strip 7 hari di Beranda & Riwayat.
  static const homeWeekTitle = '7 hari terakhir';
  static const homeWeekHistoryCta = 'Lihat riwayat';
  static const homeWeekEmpty = 'Belum ada catatan minggu ini.';
  static const homeWeekHint = 'Ketuk satu hari untuk melihat catatannya.';
  static const homeWeekToday = 'Hari ini';
  static const homeWeekLoadError = 'Riwayat belum bisa dimuat.';
  static String homeWeekDaySemantics(
    String day,
    int met,
    int total, {
    required bool hasLogs,
    required bool reached,
  }) {
    if (!hasLogs) return '$day, belum ada catatan.';
    final suffix = reached ? ' Target tercapai.' : '';
    return '$day, $met dari $total kelompok.$suffix';
  }

  // ── Catat manual (di dalam pemindai) ─────────────────────────────
  static const manualFoodTitle = 'Catat manual';
  static const manualFoodSubtitle =
      'Tulis nama makanannya, lalu pilih kelompoknya.';
  static const manualFoodNameLabel = 'Nama makanan';
  static const manualFoodNameHint = 'Mis. bubur ayam, telur rebus, tahu';
  static const manualFoodGroupsLabel = 'Kelompok yang dimakan';
  static const manualFoodSave = 'Simpan catatan';
  static const manualFoodSaved = 'Catatan makan tersimpan.';
  static const manualFoodError =
      'Gagal menyimpan catatan. Periksa koneksi internet kamu, lalu coba lagi.';
  static const manualFoodEmptyName = 'Tulis nama makanannya dulu.';
  static const manualFoodEmptyGroups = 'Pilih minimal satu kelompok.';

  // ── Scan makanan (PRD §6.4) ───────────────────────────────────────
  static const photoScanFab = 'Foto makanan';
  static const photoScanFabSemantics =
      'Foto makanan. Foto dikenali lalu dihapus; tidak disimpan.';
  static const scanTitle = 'Scan makanan';
  static const scanHint = 'Posisikan piring di dalam lingkaran';
  static const scanShutter = 'Ambil foto';
  static const scanShutterSemantics = 'Ambil foto makanan';
  static const scanGallery = 'Galeri';
  static const scanClose = 'Tutup';
  static const scanAnalyzing = 'Mengenali isi piring.';
  static const scanCameraPermissionTitle = 'Izin kamera dibutuhkan';
  static const scanCameraPermissionBody =
      'Izinkan akses kamera untuk memindai makanan kamu.';
  static const scanCameraUnavailableTitle = 'Kamera tidak bisa dipakai';
  static const scanCameraUnavailableBody =
      'Kamera tidak bisa dipakai di perangkat ini. Kamu tetap bisa mencatat manual.';
  static const scanOpenSettings = 'Buka Pengaturan';
  static const scanNoFoodTitle = 'Makanan tidak terdeteksi';
  static const scanNoFoodBody =
      'Makanan tidak terdeteksi. Coba foto ulang dengan cahaya cukup.';
  static const scanSheetTitle = 'Hasil pemindaian';
  static const scanSheetSubtitle = 'Periksa lalu simpan ke catatan.';
  static const scanConfidenceLow = 'kurang yakin';
  static const scanAddSectionTitle = 'Tambah item';
  static const scanAddItemHint = 'Nama makanan';
  static const scanAddItemButton = 'Tambah';
  static const scanItemEmptyGroups =
      'Pilih minimal satu kelompok untuk item ini.';
  static const scanSave = 'Simpan ke catatan';
  static const scanSaved = 'Catatan tersimpan.';
  static const scanSaveError =
      'Gagal menyimpan catatan. Periksa koneksi internet kamu, lalu coba lagi.';
  static const scanQuotaTitle = 'Kuota analisis habis';
  static const scanBusyTitle = 'Layanan sedang sibuk';
  static const scanOfflineTitle = 'Tidak ada koneksi internet';
  static const scanManualButton = 'Catat manual';
  static const scanRetry = 'Coba lagi';
  static const scanPhotoAgain = 'Foto lagi';
  static const scanGroupLabel = 'Kelompok';
  static const scanMealTypeLabel = 'Jenis makan';
  static const portionLabel = 'Porsi';
  static const portionLittle = 'Sedikit';
  static const portionMedium = 'Sedang';
  static const portionFinished = 'Habis';
  static String scanSheetError(String code) => switch (code) {
        'quota_daily' =>
          'Kuota analisis hari ini habis. Kamu masih bisa mencatat manual.',
        'image_too_large' =>
          'Foto terlalu besar. Coba lagi dengan cahaya terang di dekat jendela.',
        'invalid_image' =>
          'Foto tidak bisa dipakai. Coba foto ulang dengan cahaya cukup.',
        'timeout' =>
          'Prosesnya terlalu lama. Periksa koneksi internet kamu, lalu coba lagi.',
        'ai_unavailable' => 'Layanan sedang sibuk, coba lagi sebentar.',
        'offline' =>
          'Tidak ada koneksi internet. Scan membutuhkan internet; kamu tetap bisa mencatat manual.',
        'unauthorized' =>
          'Sesi berakhir. Tutup lalu buka aplikasi lagi.',
        _ => 'Layanan sedang sibuk, coba lagi sebentar.',
      };

  // ── Navigasi ───────────────────────────────────────────────────
  static const navHome = 'Beranda';
  static const navMakan = 'Makan';
  static const navGrowth = 'Tumbuh';

  // ── Beranda ────────────────────────────────────────────────────
  static const greetingMorning = 'Selamat pagi';
  static const greetingNoon = 'Selamat siang';
  static const greetingEvening = 'Selamat sore';
  static const greetingNight = 'Selamat malam';
  static const homeManageChild = 'Kelola anak';
  static const homeSwitchChildHint =
      'Pilih anak untuk melihat ringkasannya di Beranda.';
  static const childSwitcherTooltip = 'Ganti anak';
  static String homeGreeting(String greeting, String nickname) =>
      '$greeting, $nickname';
  static const homeLoadError =
      'Tidak bisa memuat data. Periksa koneksi internet kamu, lalu coba lagi.';

  // ── Navigasi lain ──────────────────────────────────────────────
  static const routeNotFoundTitle = 'Halaman tidak ditemukan';
  static const routeNotFoundBody =
      'Alamat ini tidak ada. Kembali ke Beranda, ya.';

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
