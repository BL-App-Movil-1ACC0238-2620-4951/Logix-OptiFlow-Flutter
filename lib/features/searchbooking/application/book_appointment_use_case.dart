import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment_repository.dart';

class BookAppointmentUseCase {
  const BookAppointmentUseCase({required this.repository});

  final AppointmentRepository repository;

  Future<Appointment> execute({required String patientId, required String opticalStoreId, required String timeSlotId}) => repository.book(patientId: patientId, opticalStoreId: opticalStoreId, timeSlotId: timeSlotId);
}
