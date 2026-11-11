import '../repositories/consent_repository.dart';

/// Use case menerima consent berversi (PRD §8.3).
final class AcceptConsent {
  const AcceptConsent(this._repository);

  final ConsentRepository _repository;

  Future<void> call({required String version}) =>
      _repository.acceptConsent(version: version);
}
