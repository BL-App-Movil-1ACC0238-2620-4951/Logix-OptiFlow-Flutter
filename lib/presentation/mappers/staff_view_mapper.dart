import 'package:intl/intl.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/store_time.dart';

abstract final class StaffViewMapper {
  static AgendaItem agenda(Appointment appointment, String name, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final waiting = !current.isBefore(appointment.start.subtract(const Duration(minutes: 15))) && current.isBefore(appointment.end);
    final status = switch (appointment.status) {
      'COMPLETED' => AgendaStatus.done, 'PENDING' => AgendaStatus.pending,
      _ => waiting ? AgendaStatus.waiting : AgendaStatus.confirmed,
    };
    return AgendaItem(
      appointmentId: appointment.id, patientId: appointment.patientId, name: name,
      time: DateFormat('HH:mm').format(StoreTime.clock(appointment.start)),
      duration: '${appointment.end.difference(appointment.start).inMinutes} min',
      service: 'Evaluación visual', status: status, startsAt: appointment.start, endsAt: appointment.end,
    );
  }
}
