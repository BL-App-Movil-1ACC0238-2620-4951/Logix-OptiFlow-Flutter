import '../datasources/optiflow_api.dart';
import '../../domain/entities/models.dart';
import '../../domain/repositories/patient_repository.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._api);

  final OptiFlowApi _api;

  @override
  Future<PatientSession> login({required String email, required String password}) async {
    final dto = await _api.login(email: email, password: password);
    return dto.toEntity();
  }

  @override
  Future<PatientSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final dto = await _api.register(name: name, email: email, phone: phone, password: password);
    return dto.toEntity();
  }
}
