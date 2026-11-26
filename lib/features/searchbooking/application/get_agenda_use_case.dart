import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment_repository.dart';

class GetAgendaUseCase {
  const GetAgendaUseCase({required this.repository});

  final AppointmentRepository repository;

  Future<List<Appointment>> execute(String opticalStoreId, DateTime date) => repository.agenda(opticalStoreId, date);
}
