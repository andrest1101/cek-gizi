/// Galat logis dari `AccountRepository.deleteAccount()`.
///
/// [code] berisi kode konvensional ('delete_account_error'), sehingga UI
/// bisa memetakan ke copy ramah tanpa leak detail teknis.
final class AccountException implements Exception {
  const AccountException(this.code);

  final String code;

  @override
  String toString() => 'AccountException($code)';
}
