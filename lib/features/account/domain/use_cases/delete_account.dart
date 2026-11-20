import '../repositories/account_repository.dart';

/// Use case menghapus akun (PRD §6.8, §9.4).
final class DeleteAccount {
  const DeleteAccount(this._repository);

  final AccountRepository _repository;

  Future<void> call() => _repository.deleteAccount();
}
