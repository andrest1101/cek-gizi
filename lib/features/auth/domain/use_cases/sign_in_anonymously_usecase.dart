import '../repositories/auth_repository.dart';

/// Use case masuk anonim otomatis saat pertama dibuka (PRD §6.1).
class SignInAnonymously {
  const SignInAnonymously(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signInAnonymously();
}
