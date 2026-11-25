import 'package:logix_optiflow/features/auth/domain/patient_session.dart';
import 'package:logix_optiflow/features/auth/domain/session_repository.dart';

class SaveSessionUseCase {
  const SaveSessionUseCase({required this.repository});

  final SessionRepository repository;

  Future<void> execute(PatientSession session) => repository.save(session);
}
