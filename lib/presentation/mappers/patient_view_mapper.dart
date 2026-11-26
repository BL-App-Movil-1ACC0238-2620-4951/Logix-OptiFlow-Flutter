import 'package:intl/intl.dart';

import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/features/clinical/domain/clinical_record.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/features/searchbooking/domain/time_slot.dart';
import 'package:logix_optiflow/features/production/domain/work_order.dart';
import 'package:logix_optiflow/presentation/models/ui_models.dart';

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
    final at = StoreTime.clock(start);
    return AppointmentUi(
      id: id,
      day: DateFormat('d', 'es').format(at),
      month: DateFormat('MMM', 'es').format(at).replaceAll('.', '').toUpperCase(),
      monthName: _cap(DateFormat('MMMM', 'es').format(at)),
      weekday: _cap(DateFormat('EEEE', 'es').format(at)),
      time: DateFormat('HH:mm').format(at),
      endTime: DateFormat('HH:mm').format(StoreTime.clock(end)),
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
    final at = StoreTime.clock(slot.start);
    return SlotOption(
      id: slot.id,
      date: DateTime(at.year, at.month, at.day),
      time: DateFormat('HH:mm').format(at),
      startsAt: slot.start,
      endsAt: slot.end,
    );
  }

  static OrderUi order(WorkOrder order, {List<QuotationItem> items = const [], String? storeName}) {
    final step = switch (order.status.toUpperCase()) {
      'PENDING' => 1,
      'IN_WORKSHOP' || 'QUALITY_CONTROL' => 2,
      'READY_FOR_DELIVERY' => 3,
      'DELIVERED' => 4,
      _ => 0,
    };
    final id = order.id;
    final created = order.createdAt ?? DateTime.now();
    final delivery = DateTime.tryParse(order.estimatedDelivery ?? '');
    final frame = items.where((i) => i.type == 'FRAME').firstOrNull?.description;
    final lenses = items.where((i) => i.type != 'FRAME').map((i) => i.description).join(' · ');
    String shortDateTime(DateTime at) => DateFormat("d MMM · HH:mm", 'es').format(StoreTime.clock(at));
    final history = [for (final change in order.statusHistory) shortDateTime(change.changedAt)];
    return OrderUi(
      id: id,
      code: 'OF-${id.substring(0, id.length < 4 ? id.length : 4).toUpperCase()}',
      title: frame != null ? 'Lentes ópticos + montura' : 'Lentes ópticos',
      dateLabel: DateFormat('d MMM', 'es').format(StoreTime.clock(created)),
      step: step,
      estimate: delivery == null ? 'por confirmar' : DateFormat("d 'de' MMMM", 'es').format(delivery),
      product: frame ?? 'Lentes',
      productDetail: lenses.isNotEmpty ? lenses : (order.lensSpecification ?? 'Lentes'),
      pickup: storeName ?? 'Óptica OptiFlow',
      history: history.isEmpty ? [shortDateTime(created)] : history,
      fromApi: true,
      statusDates: {for (final change in order.statusHistory) change.status: shortDateTime(change.changedAt)},
      delayReason: order.delayReason,
    );
  }

  static PurchaseUi purchase(Sale sale, num? pendingTotal) {
    final date = sale.paidAt ?? sale.closedAt ?? sale.issuedAt;
    final amount = sale.amount ?? pendingTotal;
    final method = sale.paymentMethod?.toUpperCase();
    final pending = sale.status == SaleStatus.pendingPayment;
    return PurchaseUi(
      id: sale.id,
      date: date == null ? 'Sin fecha' : DateFormat('d MMM yyyy', 'es').format(StoreTime.clock(date)),
      amount: amount == null ? '—' : soles(amount),
      paymentMethod: switch (method) {
        null => 'Pago pendiente',
        'CASH' => 'Efectivo',
        'CARD' => 'Tarjeta',
        'YAPE' => 'Yape',
        _ => _cap(method.toLowerCase()),
      },
      status: switch (sale.status) {
        SaleStatus.paid => 'Pagada',
        SaleStatus.pendingPayment => 'Pendiente de pago',
        SaleStatus.closed => 'Completada',
      },
      receiptNumber: sale.receiptNumber,
      payable: pending,
      paymentRejected: pending && sale.paymentStatus == 'REJECTED',
    );
  }

  static HistoryEntry history(ClinicalRecord record) {
    final when = record.examinationDate == null ? null : StoreTime.clock(record.examinationDate!);
    return HistoryEntry(
      date: when == null ? '—' : DateFormat('dd MMM yyyy', 'es').format(when).toUpperCase().replaceAll('.', ''),
      title: 'Evaluación visual',
      summary: record.observations ?? 'Sin observaciones',
      professional: 'Optometrista de la óptica',
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
    return prescriptionUi(values, chosen?.examinationDate, chosen?.observations, name);
  }

  /// Recetas de "Mis recetas", de la más reciente a la más antigua.
  static List<PrescriptionItemUi> prescriptionItems(List<ClinicalRecord> records) {
    final withRx = records.where((r) => r.prescription != null && r.id != null).toList()
      ..sort((a, b) => (b.examinationDate ?? DateTime(0)).compareTo(a.examinationDate ?? DateTime(0)));
    return [
      for (final record in withRx)
        PrescriptionItemUi(
          recordId: record.id!,
          date: record.examinationDate == null ? 'Sin fecha' : DateFormat('d MMM yyyy', 'es').format(StoreTime.clock(record.examinationDate!)),
          summary: 'OD ${_rx(record.prescription!.sphereOd)} · OI ${_rx(record.prescription!.sphereOs)}',
        ),
    ];
  }

  static PrescriptionUi prescriptionUi(PrescriptionValues values, DateTime? examinationDate, String? observations, String name) {
    final date = StoreTime.clock(examinationDate ?? DateTime.now());
    final treatment = values.treatment?.trim() ?? '';
    final notes = observations?.trim() ?? '';
    return PrescriptionUi(
      patientName: name,
      date: DateFormat('dd/MM/yyyy').format(date),
      issuedLabel: 'Emitida el ${DateFormat('d MMM yyyy', 'es').format(date)}',
      sphereOd: _rx(values.sphereOd),
      cylinderOd: _rx(values.cylinderOd),
      axisOd: values.axisOd == null ? '—' : '${values.axisOd}°',
      additionOd: _rx(values.addition, plus: true),
      sphereOi: _rx(values.sphereOs),
      cylinderOi: _rx(values.cylinderOs),
      axisOi: values.axisOs == null ? '—' : '${values.axisOs}°',
      additionOi: _rx(values.addition, plus: true),
      observations: [if (treatment.isNotEmpty) treatment, if (notes.isNotEmpty) notes].join(' · '),
    );
  }

  static String _rx(num? value, {bool plus = false}) {
    if (value == null) return '—';
    final text = value.toStringAsFixed(2);
    if (plus && value > 0) return '+$text';
    return text.replaceAll('-', '−');
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
