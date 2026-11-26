import 'package:logix_optiflow/features/notification/domain/patient_notification.dart';

abstract class NotificationRepository {
  Future<List<PatientNotification>> forPatient(String patientId);

  Future<void> markRead(String id);

  Future<void> answerSurvey(String id, int rating, String? comment);
}
