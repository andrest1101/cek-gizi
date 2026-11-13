/// Tipe galat tertutup (sealed) untuk seluruh lapisan data/domain.
///
/// Lapisan data melempar [Failure]; lapisan presentasi memetakannya ke copy
/// ramah + tombol coba lagi (AppStrings). Presentation TIDAK boleh berisi
/// logika bisnis - hanya memetakan Failure ke UI.
sealed class Failure {
  const Failure();
}

/// Tidak ada koneksi internet / timeout jaringan.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Server (Supabase/Edge Function) mengembalikan galat atau tidak merespons.
final class ServerFailure extends Failure {
  const ServerFailure();
}

/// Kuota harian AI habis (dihitung atomik di server, PRD §5.4).
final class QuotaExceededFailure extends Failure {
  const QuotaExceededFailure();
}

/// Sesi tidak valid / belum masuk.
final class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure();
}

/// Input ditolak (validasi server atau domain gagal).
final class InvalidInputFailure extends Failure {
  const InvalidInputFailure();
}

/// Data tidak ditemukan.
final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// Kesalahan tak terduga - log teknis di lapisan data, jangan data anak.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure();
}
