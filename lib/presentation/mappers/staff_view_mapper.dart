import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';
import 'package:logix_optiflow/features/production/domain/production_order.dart';
import 'package:logix_optiflow/features/production/domain/staff_order.dart';
import 'package:logix_optiflow/features/searchbooking/domain/agenda_item.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/core/time/store_time.dart';

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

  /// Orden de trabajo del backend como tarjeta del tablero de producción.
  static ProductionOrder productionOrder(StaffOrder order, String patientName, {DateTime? today}) {
    final stage = switch (order.status) {
      'IN_WORKSHOP' => ProductionStage.inWorkshop, 'QUALITY_CONTROL' => ProductionStage.qualityControl,
      'READY_FOR_DELIVERY' => ProductionStage.ready, 'DELIVERED' => ProductionStage.delivered,
      _ => ProductionStage.pending,
    };
    final date = DateTime.tryParse(order.dueDate ?? '');
    final day = today ?? StoreTime.today();
    final due = date == null
        ? 'Sin fecha'
        : order.delayed
            ? 'Atrasada'
            : DateUtils.isSameDay(date, day)
                ? 'Entrega hoy'
                : 'Entrega ${DateFormat('d MMM', 'es').format(date).replaceAll('.', '')}';
    return ProductionOrder(
      id: order.id,
      code: 'OT-${order.id.substring(0, order.id.length < 4 ? order.id.length : 4).toUpperCase()}',
      patient: patientName,
      detail: order.detail,
      stage: stage,
      due: due,
      needsAttention: order.delayed,
    );
  }
}
