import 'package:logix_optiflow/features/auth/domain/auth_repository.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/infrastructure/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.api});

  final AuthApi api;

  @override
  Future<PatientSession> login({required String email, required String password}) async {
    final dto = await api.login(email: email, password: password);
    return dto.toEntity();
  }

  @override
  Future<PatientSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final dto = await api.register(name: name, email: email, phone: phone, password: password);
    return dto.toEntity();
  }
}
