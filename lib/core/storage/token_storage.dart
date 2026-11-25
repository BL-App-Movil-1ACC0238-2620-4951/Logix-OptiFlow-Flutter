/// Guarda el token de la sesión fuera de las preferencias comunes.
abstract class TokenStorage {
  Future<String?> readToken();

  Future<void> saveToken(String token);

  Future<void> deleteToken();
}
