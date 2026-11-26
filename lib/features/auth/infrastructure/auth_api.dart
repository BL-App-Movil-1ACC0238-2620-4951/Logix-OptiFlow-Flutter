import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/auth/infrastructure/patient_dto.dart';

/// Login y registro de pacientes (`auth/tokens`, `patients`).
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<PatientDto> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final json = await _client.send('POST', 'patients', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return PatientDto.fromRegister(
      Map<String, dynamic>.from(json as Map),
      name: name,
      email: email,
      phone: phone,
    );
  }

  Future<PatientDto> login({required String email, required String password}) async {
    // Public requests must not carry a token from a previous account.
    _client.token = null;
    final json = await _client.send('POST', 'auth/tokens', {'email': email, 'password': password});
    try {
      final response = Map<String, dynamic>.from(json as Map);
      final account = PatientDto.fromLogin(response, email: email);
      if (!account.toEntity().isAuthenticated) {
        throw ApiException('La sesión recibida ya venció. Vuelve a iniciar sesión.');
      }
      _client.token = account.token;
      final path = account.toEntity().isPatient ? 'patients' : 'staff-members';
      final profile = await _client.get('$path/${account.id}');
      return PatientDto.fromLogin(response, email: email, profile: Map<String, dynamic>.from(profile as Map));
    } catch (error) {
      _client.token = null;
      if (error is ApiException) rethrow;
      throw ApiException('El servidor devolvió una respuesta de autenticación inválida.');
    }
  }
}
