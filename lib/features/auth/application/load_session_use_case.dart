import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/domain/session_repository.dart';

class LoadSessionUseCase {
  const LoadSessionUseCase({required this.repository});

  final SessionRepository repository;

  Future<PatientSession?> execute() => repository.read();
}
