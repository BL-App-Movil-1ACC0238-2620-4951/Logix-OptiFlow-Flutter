import '../entities/models.dart';

abstract class PatientRepository {
  Future<PatientSession> login({required String email, required String password});

  Future<PatientSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
}
