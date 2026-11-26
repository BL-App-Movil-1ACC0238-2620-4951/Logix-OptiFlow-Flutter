import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';

class AppointmentUi {
  const AppointmentUi({
    required this.id,
    required this.day,
    required this.month,
    required this.monthName,
    required this.weekday,
    required this.time,
    required this.endTime,
    required this.title,
    required this.storeName,
    required this.storeAddress,
    required this.professional,
    required this.status,
    required this.isPast,
    required this.fromApi,
    this.opticalStoreId,
    this.timeSlotId,
    this.startsAt,
  });

  final String id;
  final String day;
  final String month;
  final String monthName;
  final String weekday;
  final String time;
  final String endTime;
  final String title;
  final String storeName;
  final String storeAddress;
  final String professional;
  final AppointmentStatus status;
  final bool isPast;
  final bool fromApi;
  final String? opticalStoreId;
  final String? timeSlotId;
  final DateTime? startsAt;

  AppointmentUi copyWith({
    AppointmentStatus? status,
    String? day,
    String? month,
    String? monthName,
    String? weekday,
    String? time,
    String? endTime,
    String? title,
    String? storeName,
    String? storeAddress,
    bool? isPast,
  }) =>
      AppointmentUi(
        id: id,
        day: day ?? this.day,
        month: month ?? this.month,
        monthName: monthName ?? this.monthName,
        weekday: weekday ?? this.weekday,
        time: time ?? this.time,
        endTime: endTime ?? this.endTime,
        title: title ?? this.title,
        storeName: storeName ?? this.storeName,
        storeAddress: storeAddress ?? this.storeAddress,
        professional: professional,
        status: status ?? this.status,
        isPast: isPast ?? this.isPast,
        fromApi: fromApi,
        opticalStoreId: opticalStoreId,
        timeSlotId: timeSlotId,
        startsAt: startsAt,
      );
}

class OrderUi {
  const OrderUi({
    required this.id,
    required this.code,
    required this.title,
    required this.dateLabel,
    required this.step,
    required this.estimate,
    required this.product,
    required this.productDetail,
    required this.pickup,
    required this.history,
    required this.fromApi,
    this.statusDates = const {},
    this.delayReason,
  });

  final String id;
  final String code;
  final String title;
  final String dateLabel;
  /// 0 recibido · 1 pago · 2 producción · 3 listo · 4 entregado
  final int step;
  final String estimate;
  final String product;
  final String productDetail;
  final String pickup;
  final List<String> history;
  final bool fromApi;
  /// Fecha y hora en que la orden llegó a cada estado del backend (PENDING, IN_WORKSHOP, …).
  final Map<String, String> statusDates;
  /// Motivo del retraso informado por el taller.
  final String? delayReason;

  bool get delivered => step >= 4;

  String get statusLabel => switch (step) {
        0 => 'Pedido recibido',
        1 => 'Pago confirmado',
        2 => 'En producción',
        3 => 'Listo para retirar',
        _ => 'Entregado',
      };
}

class HistoryEntry {
  const HistoryEntry({
    required this.date,
    required this.title,
    required this.summary,
    required this.professional,
  });

  final String date;
  final String title;
  final String summary;
  final String professional;
}

class PrescriptionUi {
  const PrescriptionUi({
    required this.patientName,
    required this.date,
    required this.issuedLabel,
    required this.sphereOd,
    required this.cylinderOd,
    required this.axisOd,
    required this.additionOd,
    required this.sphereOi,
    required this.cylinderOi,
    required this.axisOi,
    required this.additionOi,
    required this.observations,
  });

  final String patientName;
  final String date;
  final String issuedLabel;
  final String sphereOd;
  final String cylinderOd;
  final String axisOd;
  final String additionOd;
  final String sphereOi;
  final String cylinderOi;
  final String axisOi;
  final String additionOi;
  final String observations;
}

/// Una receta de "Mis recetas"; [recordId] es la ficha clínica que la contiene.
class PrescriptionItemUi {
  const PrescriptionItemUi({required this.recordId, required this.date, required this.summary});

  final String recordId;
  final String date;
  final String summary;
}

/// Una venta del paciente en "Mis compras".
class PurchaseUi {
  const PurchaseUi({
    required this.id,
    required this.date,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.receiptNumber,
    this.payable = false,
    this.paymentRejected = false,
  });

  final String id;
  final String date;
  final String amount;
  final String paymentMethod;
  final String status;
  final String? receiptNumber;
  /// Pendiente de pago: el paciente puede pagarla con tarjeta o Yape.
  final bool payable;
  /// El último intento con Mercado Pago fue rechazado.
  final bool paymentRejected;
}

class StoreOption {
  const StoreOption({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.availability,
    required this.availableToday,
  });

  final String? id;
  final String name;
  final String address;
  final String distance;
  final String availability;
  final bool availableToday;
}

class SlotOption {
  const SlotOption({required this.id, required this.date, required this.time, required this.startsAt, this.endsAt});

  final String? id;
  /// Día y hora en Lima, como se muestran.
  final DateTime date;
  final String time;
  final DateTime startsAt;
  final DateTime? endsAt;

  int? get durationMinutes => endsAt?.difference(startsAt).inMinutes;

  String get label => time;
}

