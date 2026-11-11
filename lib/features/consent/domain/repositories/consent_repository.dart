/// Kontrak consent (PRD §8.3, §5.2 `user_consents`).
abstract interface class ConsentRepository {
  Future<void> acceptConsent({required String version});
}
