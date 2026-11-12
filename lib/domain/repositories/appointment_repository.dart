import '../entities/models.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> forPatient(String patientId);

  Future<Appointment> cancel(String appointmentId);

  Future<Appointment> book({
    required String patientId,
    required String opticalStoreId,
    required String timeSlotId,
  });

  Future<List<WorkOrder>> workOrders(String patientId);

  Future<List<ClinicalRecord>> clinicalRecords(String patientId);
}
