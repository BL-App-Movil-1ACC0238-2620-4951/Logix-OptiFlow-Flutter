import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:logix_optiflow/core/storage/token_storage.dart';

/// Token cifrado con el almacenamiento seguro del sistema (Keystore en Android).
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage({required this.storage});

  final FlutterSecureStorage storage;

  static const _key = 'token';

  @override
  Future<String?> readToken() => storage.read(key: _key);

  @override
  Future<void> saveToken(String token) => storage.write(key: _key, value: token);

  @override
  Future<void> deleteToken() => storage.delete(key: _key);
}
