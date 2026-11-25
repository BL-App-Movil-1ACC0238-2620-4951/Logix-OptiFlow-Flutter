import 'package:logix_optiflow/features/notification/domain/notification_repository.dart';
import 'package:logix_optiflow/features/notification/domain/patient_notification.dart';
import 'package:logix_optiflow/features/notification/infrastructure/notification_api.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({required this.api});

  final NotificationApi api;

  @override
  Future<List<PatientNotification>> forPatient(String patientId) => api.forPatient(patientId);

  @override
  Future<void> markRead(String id) => api.markRead(id);

  @override
  Future<void> answerSurvey(String id, int rating, String? comment) => api.answerSurvey(id, rating, comment);
}
