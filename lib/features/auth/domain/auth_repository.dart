import 'package:logix_optiflow/features/auth/domain/patient_session.dart';

abstract class AuthRepository {
  Future<PatientSession> login({required String email, required String password});

  Future<PatientSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
}
