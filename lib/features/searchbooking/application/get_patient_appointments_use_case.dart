import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment_repository.dart';

class GetPatientAppointmentsUseCase {
  const GetPatientAppointmentsUseCase({required this.repository});

  final AppointmentRepository repository;

  Future<List<Appointment>> execute(String patientId) => repository.forPatient(patientId);
}
