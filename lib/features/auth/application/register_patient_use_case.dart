import 'package:logix_optiflow/features/auth/domain/auth_repository.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';

class RegisterPatientUseCase {
  const RegisterPatientUseCase({required this.repository});

  final AuthRepository repository;

  Future<PatientSession> execute({required String name, required String email, required String phone, required String password}) => repository.register(name: name, email: email, phone: phone, password: password);
}
