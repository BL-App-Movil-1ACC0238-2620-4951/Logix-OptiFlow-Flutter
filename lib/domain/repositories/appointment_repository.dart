import '../entities/models.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> forPatient(String patientId);

  Future<Appointment> book({
    required String patientId,
    required String opticalStoreId,
    required String timeSlotId,
  });

  Future<List<Map<String, dynamic>>> workOrders(String patientId);

  Future<List<Map<String, dynamic>>> clinicalRecords(String patientId);
}
