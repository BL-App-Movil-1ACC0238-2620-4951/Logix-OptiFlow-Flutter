import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment_repository.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/search_booking_api.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  const AppointmentRepositoryImpl({required this.api});

  final SearchBookingApi api;

  @override
  Future<Appointment> cancel(String appointmentId) async {
    return (await api.cancelAppointment(appointmentId)).toEntity();
  }

  @override
  Future<List<Appointment>> forPatient(String patientId) async {
    final items = await api.appointments(patientId);
    return items.map((item) => item.toEntity()).toList();
  }

  @override
  Future<Appointment> book({
    required String patientId,
    required String opticalStoreId,
    required String timeSlotId,
  }) async {
    final created = await api.book(patientId: patientId, opticalStoreId: opticalStoreId, timeSlotId: timeSlotId);
    return created.toEntity();
  }

  @override
  Future<List<Appointment>> agenda(String opticalStoreId, DateTime date) async =>
      (await api.storeAgenda(opticalStoreId, date)).map((dto) => dto.toEntity()).toList();
}
