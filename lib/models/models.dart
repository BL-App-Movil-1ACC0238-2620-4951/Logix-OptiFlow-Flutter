class PatientSession {
  const PatientSession({
    required this.patientId,
    required this.name,
    required this.email,
    this.token,
    this.phone = '',
  });

  final String patientId;
  final String? token;
  final String name;
  final String email;
  final String phone;

  bool get hasToken => token != null && token!.isNotEmpty;

  PatientSession copyWith({String? name, String? email, String? phone, String? token}) {
    return PatientSession(
      patientId: patientId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      token: token ?? this.token,
    );
  }
}

class OpticalStore {
  const OpticalStore({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.rating,
    required this.status,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final double? rating;
  final String status;

  factory OpticalStore.fromJson(Map<String, dynamic> json) {
    return OpticalStore(
      id: '${json['id']}',
      name: '${json['name'] ?? 'Óptica'}',
      address: '${json['address'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      rating: (json['rating'] as num?)?.toDouble(),
      status: '${json['status'] ?? ''}',
    );
  }
}

class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.opticalStoreId,
    required this.start,
    required this.end,
    required this.status,
  });

  final String id;
  final String opticalStoreId;
  final DateTime start;
  final DateTime end;
  final String status;

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: '${json['id']}',
      opticalStoreId: '${json['opticalStoreId']}',
      start: DateTime.parse('${json['startDateTime']}').toLocal(),
      end: DateTime.parse('${json['endDateTime']}').toLocal(),
      status: '${json['status'] ?? ''}',
    );
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.opticalStoreId,
    required this.timeSlotId,
    required this.status,
    required this.start,
    required this.end,
  });

  final String id;
  final String patientId;
  final String opticalStoreId;
  final String timeSlotId;
  final String status;
  final DateTime start;
  final DateTime end;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: '${json['id']}',
      patientId: '${json['patientId']}',
      opticalStoreId: '${json['opticalStoreId']}',
      timeSlotId: '${json['timeSlotId']}',
      status: '${json['status'] ?? 'PENDING'}',
      start: DateTime.parse('${json['startDateTime']}').toLocal(),
      end: DateTime.parse('${json['endDateTime']}').toLocal(),
    );
  }
}

enum AppointmentStatus { confirmed, pending, cancelled }

extension AppointmentStatusLabel on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.confirmed => 'Confirmada',
        AppointmentStatus.pending => 'Pendiente',
        AppointmentStatus.cancelled => 'Cancelada',
      };

  static AppointmentStatus fromApi(String raw) {
    switch (raw.toUpperCase()) {
      case 'CONFIRMED':
      case 'CONFIRMADA':
      case 'BOOKED':
      case 'SCHEDULED':
        return AppointmentStatus.confirmed;
      case 'CANCELLED':
      case 'CANCELED':
      case 'CANCELADA':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.pending;
    }
  }
}

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

  AppointmentUi copyWith({AppointmentStatus? status}) => AppointmentUi(
        id: id,
        day: day,
        month: month,
        monthName: monthName,
        weekday: weekday,
        time: time,
        endTime: endTime,
        title: title,
        storeName: storeName,
        storeAddress: storeAddress,
        professional: professional,
        status: status ?? this.status,
        isPast: isPast,
        fromApi: fromApi,
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
    required this.pupillaryDistance,
    required this.diagnoses,
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
  final String pupillaryDistance;
  final List<String> diagnoses;
  final String observations;

  PrescriptionUi copyWith({
    String? sphereOd,
    String? cylinderOd,
    String? axisOd,
    String? additionOd,
    String? sphereOi,
    String? cylinderOi,
    String? axisOi,
    String? additionOi,
    String? pupillaryDistance,
    String? observations,
    String? patientName,
  }) {
    return PrescriptionUi(
      patientName: patientName ?? this.patientName,
      date: date,
      issuedLabel: issuedLabel,
      sphereOd: sphereOd ?? this.sphereOd,
      cylinderOd: cylinderOd ?? this.cylinderOd,
      axisOd: axisOd ?? this.axisOd,
      additionOd: additionOd ?? this.additionOd,
      sphereOi: sphereOi ?? this.sphereOi,
      cylinderOi: cylinderOi ?? this.cylinderOi,
      axisOi: axisOi ?? this.axisOi,
      additionOi: additionOi ?? this.additionOi,
      pupillaryDistance: pupillaryDistance ?? this.pupillaryDistance,
      diagnoses: diagnoses,
      observations: observations ?? this.observations,
    );
  }

  static PrescriptionUi demo(String name) => PrescriptionUi(
        patientName: name,
        date: '18/10/2026',
        issuedLabel: 'Emitida el 18 oct 2026',
        sphereOd: '−1.25',
        cylinderOd: '−0.50',
        axisOd: '175°',
        additionOd: '+0.75',
        sphereOi: '−1.00',
        cylinderOi: '−0.75',
        axisOi: '10°',
        additionOi: '+0.75',
        pupillaryDistance: '62',
        diagnoses: const ['Miopía', 'Astigmatismo'],
        observations: 'Uso permanente. Lentes monofocales con tratamiento antirreflejo y filtro UV.',
      );
}

enum NotificationType { appointment, order, health, promo }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.occurredAt,
    this.navigable = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime occurredAt;
  final bool navigable;
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
  const SlotOption({required this.id, required this.date, required this.time});

  final String? id;
  final DateTime date;
  final String time;

  String get label => time;
}
