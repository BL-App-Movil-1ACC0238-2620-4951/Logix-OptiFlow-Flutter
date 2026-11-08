import '../../domain/entities/appointment.dart';

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
    String? date,
    String? issuedLabel,
  }) {
    return PrescriptionUi(
      patientName: patientName ?? this.patientName,
      date: date ?? this.date,
      issuedLabel: issuedLabel ?? this.issuedLabel,
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

class PatientDemo {
  static const stores = <StoreOption>[
    StoreOption(id: null, name: 'Providencia', address: 'Av. Providencia 1240', distance: '0,8 km', availability: 'Disponible hoy', availableToday: true),
    StoreOption(id: null, name: 'Las Condes', address: 'Av. Apoquindo 3472', distance: '3,2 km', availability: 'Disponible mañana', availableToday: false),
    StoreOption(id: null, name: 'Óptima Markitos', address: 'Av. San Marcos 1240', distance: '1,4 km', availability: 'Disponible hoy', availableToday: true),
    StoreOption(id: null, name: 'Dolores', address: 'Av. Hormigas 3472', distance: '3,6 km', availability: 'Disponible mañana', availableToday: false),
  ];

  static List<AppointmentUi> appointments() => const [
        AppointmentUi(id: 'demo-1', day: '24', month: 'JUN', monthName: 'Junio', weekday: 'Martes', time: '10:30', endTime: '11:15', title: 'Evaluación visual', storeName: 'Óptica Visión Norte', storeAddress: 'Av. Providencia 1240', professional: 'Dra. Fernanda Soto', status: AppointmentStatus.confirmed, isPast: false, fromApi: false),
        AppointmentUi(id: 'demo-2', day: '30', month: 'JUN', monthName: 'Junio', weekday: 'Lunes', time: '16:00', endTime: '16:45', title: 'Control de lentes', storeName: 'Óptica Visión Norte', storeAddress: 'Av. Providencia 1240', professional: 'Dr. Matías Araya', status: AppointmentStatus.pending, isPast: false, fromApi: false),
        AppointmentUi(id: 'demo-3', day: '12', month: 'MAR', monthName: 'Marzo', weekday: 'Miércoles', time: '09:30', endTime: '10:15', title: 'Evaluación visual', storeName: 'Óptica Visión Norte', storeAddress: 'Av. Providencia 1240', professional: 'Dra. Fernanda Soto', status: AppointmentStatus.confirmed, isPast: true, fromApi: false),
      ];

  static List<OrderUi> orders() => const [
        OrderUi(id: 'demo-order', code: 'OF-2481', title: 'Lentes ópticos + montura', dateLabel: '14 jun', step: 2, estimate: '26 y 28 de junio', product: 'Montura Nova N-24 · Azul', productDetail: 'Lentes monofocales con antirreflejo', pickup: 'Óptica Visión Norte · Providencia', history: ['14 jun · 12:24', '14 jun · 12:26'], fromApi: false),
        OrderUi(id: 'demo-order-2', code: 'OF-2210', title: 'Lentes de sol graduados', dateLabel: '02 mar', step: 4, estimate: '5 de marzo', product: 'Havana Sun · Dorado', productDetail: 'Lentes solares polarizados', pickup: 'Óptica Visión Norte · Providencia', history: ['2 mar · 10:02', '2 mar · 10:05'], fromApi: false),
      ];

  static const history = <HistoryEntry>[
    HistoryEntry(date: '12 MAR 2025', title: 'Evaluación visual', summary: 'Miopía leve estable', professional: 'Dra. Fernanda Soto'),
    HistoryEntry(date: '08 SEP 2024', title: 'Control de lentes', summary: 'Sin cambios relevantes', professional: 'Dr. Matías Araya'),
  ];
}
