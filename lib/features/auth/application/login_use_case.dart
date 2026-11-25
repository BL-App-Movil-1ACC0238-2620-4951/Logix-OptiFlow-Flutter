import 'package:logix_optiflow/features/auth/domain/auth_repository.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';

class LoginUseCase {
  const LoginUseCase({required this.repository});

  final AuthRepository repository;

  Future<PatientSession> execute({required String email, required String password}) => repository.login(email: email, password: password);
}
