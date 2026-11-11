import '../entities/models.dart';
import '../repositories/patient_repository.dart';

class LoginPatient {
  const LoginPatient(this._patients);

  final PatientRepository _patients;

  Future<PatientSession> call({required String email, required String password}) {
    return _patients.login(email: email, password: password);
  }
}

class RegisterPatient {
  const RegisterPatient(this._patients);

  final PatientRepository _patients;

  Future<PatientSession> call({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return _patients.register(name: name, email: email, phone: phone, password: password);
  }
}
