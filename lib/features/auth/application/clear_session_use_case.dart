import 'package:logix_optiflow/features/auth/domain/session_repository.dart';

class ClearSessionUseCase {
  const ClearSessionUseCase({required this.repository});

  final SessionRepository repository;

  Future<void> execute() => repository.clear();
}
