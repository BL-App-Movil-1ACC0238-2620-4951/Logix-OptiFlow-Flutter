import 'package:logix_optiflow/features/notification/domain/notification_repository.dart';
import 'package:logix_optiflow/features/notification/domain/patient_notification.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase({required this.repository});

  final NotificationRepository repository;

  Future<List<PatientNotification>> execute(String patientId) => repository.forPatient(patientId);
}
