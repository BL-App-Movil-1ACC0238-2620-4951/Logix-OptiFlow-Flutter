import 'package:intl/intl.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/entities/clinical_record.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/entities/work_order.dart';
import '../models/ui_models.dart';

abstract final class PatientViewMapper {
  static AppointmentUi appointment({
    required String id,
    required DateTime start,
    required DateTime end,
    required String title,
    required String storeName,
    required String storeAddress,
    required AppointmentStatus status,
    required bool isPast,
    required bool fromApi,
    String? opticalStoreId,
    String? timeSlotId,
  }) {
    return AppointmentUi(
      id: id,
      day: DateFormat('d', 'es').format(start),
      month: DateFormat('MMM', 'es').format(start).replaceAll('.', '').toUpperCase(),
      monthName: _cap(DateFormat('MMMM', 'es').format(start)),
      weekday: _cap(DateFormat('EEEE', 'es').format(start)),
      time: DateFormat('HH:mm').format(start),
      endTime: DateFormat('HH:mm').format(end),
      title: title,
      storeName: storeName,
      storeAddress: storeAddress,
      professional: 'Por asignar en la óptica',
      status: status,
      isPast: isPast,
      fromApi: fromApi,
      opticalStoreId: opticalStoreId,
      timeSlotId: timeSlotId,
      startsAt: start,
    );
  }

  static AppointmentUi reschedule(
    AppointmentUi item, {
    required String title,
    required String storeName,
    required String storeAddress,
    required DateTime date,
    required String time,
  }) {
    return item.copyWith(
      title: title,
      storeName: storeName,
      storeAddress: storeAddress,
      day: DateFormat('d', 'es').format(date),
      month: DateFormat('MMM', 'es').format(date).replaceAll('.', '').toUpperCase(),
      monthName: _cap(DateFormat('MMMM', 'es').format(date)),
      weekday: _cap(DateFormat('EEEE', 'es').format(date)),
      time: time,
      endTime: _plusMinutes(time, 45),
      status: AppointmentStatus.pending,
      isPast: date.isBefore(DateTime.now()),
    );
  }

  static SlotOption slot(TimeSlot slot) {
    return SlotOption(
      id: slot.id,
      date: DateTime(slot.start.year, slot.start.month, slot.start.day),
      time: DateFormat('HH:mm').format(slot.start),
      endsAt: slot.end,
    );
  }

  static OrderUi order(WorkOrder order) {
    final status = order.status.toUpperCase();
    final step = switch (status) {
      'PENDING' => 1,
      'IN_WORKSHOP' || 'QUALITY_CONTROL' || 'IN_PRODUCTION' || 'PRODUCTION' => 2,
      'READY_FOR_DELIVERY' || 'READY' => 3,
      'DELIVERED' => 4,
      _ => 0,
    };
    final id = order.id;
    return OrderUi(
      id: id,
      code: 'OF-${id.substring(0, id.length < 4 ? id.length : 4).toUpperCase()}',
      title: 'Lentes ópticos + montura',
      dateLabel: DateFormat('d MMM', 'es').format(order.createdAt ?? DateTime.now()),
      step: step,
      estimate: order.estimatedDelivery ?? 'por confirmar',
      product: 'Montura Nova N-24 · Azul',
      productDetail: order.lensSpecification ?? 'Lentes monofocales con antirreflejo',
      pickup: 'Óptica Visión Norte · Providencia',
      history: const [],
      fromApi: true,
    );
  }

  static HistoryEntry history(ClinicalRecord record) {
    final when = record.examinationDate?.toLocal();
    return HistoryEntry(
      date: when == null ? '—' : DateFormat('dd MMM yyyy', 'es').format(when).toUpperCase().replaceAll('.', ''),
      title: 'Evaluación visual',
      summary: record.observations ?? 'Sin observaciones',
      professional: 'Dra. Fernanda Soto',
    );
  }

  static PrescriptionUi? prescription(List<ClinicalRecord> records, String name) {
    ClinicalRecord? chosen;
    for (final record in records) {
      if (record.prescription == null) continue;
      final date = record.examinationDate;
      if (chosen == null || (date != null && (chosen.examinationDate == null || date.isAfter(chosen.examinationDate!)))) {
        chosen = record;
      }
    }
    final values = chosen?.prescription;
    if (values == null) return null;
    String fmt(num? value, {bool plus = false}) {
      if (value == null) return '—';
      final text = value.toStringAsFixed(2);
      if (plus && value > 0) return '+$text';
      return text.replaceAll('-', '−');
    }

    final date = chosen?.examinationDate?.toLocal() ?? DateTime.now();
    final treatment = values.treatment?.trim() ?? '';
    return PrescriptionUi.demo(name).copyWith(
      patientName: name,
      date: DateFormat('dd/MM/yyyy').format(date),
      issuedLabel: 'Emitida el ${DateFormat('d MMM yyyy', 'es').format(date)}',
      sphereOd: fmt(values.sphereOd),
      cylinderOd: fmt(values.cylinderOd),
      axisOd: values.axisOd == null ? '—' : '${values.axisOd}°',
      additionOd: fmt(values.addition, plus: true),
      sphereOi: fmt(values.sphereOs),
      cylinderOi: fmt(values.cylinderOs),
      axisOi: values.axisOs == null ? '—' : '${values.axisOs}°',
      additionOi: fmt(values.addition, plus: true),
      observations: treatment.isEmpty ? null : values.treatment,
    );
  }

  static String _cap(String value) => value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  static String _plusMinutes(String hhmm, int minutes) {
    final parts = hhmm.split(':');
    final total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
    final hour = (total ~/ 60).toString().padLeft(2, '0');
    final minute = (total % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
