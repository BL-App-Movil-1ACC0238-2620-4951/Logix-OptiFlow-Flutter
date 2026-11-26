import 'package:logix_optiflow/features/notification/domain/patient_notification.dart';

abstract class NotificationRepository {
  Future<List<PatientNotification>> forPatient(String patientId);

  Future<void> markRead(String id);

  Future<int> loyaltyBalance(String patientId);

  Future<void> answerSurvey(String id, int rating, String? comment);

  Future<void> registerDevice(String patientId, String token);
}
