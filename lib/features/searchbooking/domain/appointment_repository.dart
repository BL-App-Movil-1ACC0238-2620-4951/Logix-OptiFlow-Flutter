import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> forPatient(String patientId);

  Future<Appointment> cancel(String appointmentId);

  Future<Appointment> book({
    required String patientId,
    required String opticalStoreId,
    required String timeSlotId,
  });

  Future<List<Appointment>> agenda(String opticalStoreId, DateTime date);
}
