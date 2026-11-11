/// Batas jumlah anak per akun (PRD §2: profil anak maks 5).
final class ChildLimitException implements Exception {
  const ChildLimitException();

  @override
  String toString() => 'Maksimal 5 anak per akun.';
}
