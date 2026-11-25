import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment_repository.dart';

class CancelAppointmentUseCase {
  const CancelAppointmentUseCase({required this.repository});

  final AppointmentRepository repository;

  Future<Appointment> execute(String appointmentId) => repository.cancel(appointmentId);
}
