import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/di/dependencies.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/entities/models.dart';
import '../models/ui_models.dart';

class OptiFlowController extends ChangeNotifier {
  OptiFlowController({AppDependencies? dependencies}) : deps = dependencies ?? AppDependencies();

  final AppDependencies deps;
  static const minPassword = 8;

  bool bootstrapped = false;
  bool busy = false;
  String? error;

  PatientSession? session;
  List<AppointmentUi> appointments = PatientDemo.appointments();
  List<OrderUi> orders = PatientDemo.orders();
  List<HistoryEntry> history = List.of(PatientDemo.history);
  PrescriptionUi prescription = PrescriptionUi.demo('Valentina Silva');
  List<OpticalStore> stores = const [];
  bool patientLoading = true;

  final Set<String> _cancelled = {};
  Set<String> readNotificationIds = {};

  String searchQuery = '';
  double? minRating;
  bool searchLoading = false;
  String? searchMessage;
  String? searchError;

  int bookingStep = 1;
  List<StoreOption> bookingStores = PatientDemo.stores;
  int selectedStoreIndex = 0;
  List<SlotOption> slots = const [];
  DateTime weekStart = _monday(DateTime.now());
  DateTime? selectedDate;
  SlotOption? selectedSlot;
  String bookingReason = '';
  bool bookingLoading = false;
  String? bookingError;
  bool bookingDemo = true;

  late List<StaffPatient> staffPatients = List.of(deps.getStaffPatients());
  final Map<String, int> stockDelta = {};
  int clinicalStage = 1;

  String get displayName => session?.name.trim().isNotEmpty == true ? session!.name.trim() : 'Valentina Silva';
  String get firstName => displayName.split(' ').first;
  String get email => session?.email.trim().isNotEmpty == true ? session!.email.trim() : 'valentina.silva@email.com';
  String get initials {
    final parts = displayName.split(' ').where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  List<AppointmentUi> get upcoming =>
      appointments.where((a) => !a.isPast && a.status != AppointmentStatus.cancelled).toList();
  AppointmentUi? get nextAppointment => upcoming.isEmpty ? null : upcoming.first;

  List<NotificationItem> get notifications {
    final items = <NotificationItem>[];
    final now = DateTime.now();
    final realAppts = appointments.where((a) => a.fromApi && !a.isPast);
    if (realAppts.isEmpty) {
      items.add(NotificationItem(
        id: 'demo-appt-reminder',
        type: NotificationType.appointment,
        title: 'Recordatorio de cita',
        message: 'Tu evaluación visual es el martes a las 10:30.',
        occurredAt: now.subtract(const Duration(hours: 2)),
      ));
    } else {
      for (final appt in realAppts) {
        items.add(NotificationItem(
          id: 'appt-${appt.id}',
          type: NotificationType.appointment,
          title: 'Recordatorio de cita',
          message: 'Tu evaluación visual es el ${appt.weekday.toLowerCase()} a las ${appt.time}.',
          occurredAt: now.subtract(const Duration(hours: 2)),
        ));
      }
    }
    final realOrders = orders.where((o) => o.fromApi);
    if (realOrders.isEmpty) {
      items.add(NotificationItem(
        id: 'demo-order-progress',
        type: NotificationType.order,
        title: 'Tu pedido avanzó',
        message: 'Tus lentes ya están en producción.',
        occurredAt: now.subtract(const Duration(hours: 5)),
      ));
    } else {
      for (final order in realOrders) {
        items.add(NotificationItem(
          id: 'order-${order.id}',
          type: NotificationType.order,
          title: 'Tu pedido avanzó',
          message: order.statusLabel == 'En producción' ? 'Tus lentes ya están en producción.' : 'Estado del pedido: ${order.statusLabel}.',
          occurredAt: now.subtract(const Duration(hours: 5)),
        ));
      }
    }
    items.add(NotificationItem(
      id: 'health-last-check',
      type: NotificationType.health,
      title: 'Cuida tu salud visual',
      message: 'Han pasado 9 meses desde tu último control.',
      occurredAt: now.subtract(const Duration(days: 1)),
    ));
    items.add(NotificationItem(
      id: 'promo-season',
      type: NotificationType.promo,
      title: 'Descuento de Temporada',
      message: 'Compra un armazón oftálmico y llévate el segundo al 50% de descuento.',
      occurredAt: now.subtract(const Duration(hours: 25)),
      navigable: true,
    ));
    items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return items;
  }

  int get unreadCount => notifications.where((n) => !readNotificationIds.contains(n.id)).length;

  Future<void> bootstrap() async {
    session = await deps.loadSession();
    readNotificationIds = await deps.loadReadNotifications();
    bootstrapped = true;
    notifyListeners();
    if (session?.hasToken == true) {
      await refreshPatient();
    } else {
      patientLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession(PatientSession value) async {
    session = value;
    await deps.saveSession(value);
    notifyListeners();
  }

  Future<void> logout() async {
    session = null;
    await deps.clearSession();
    appointments = PatientDemo.appointments();
    orders = PatientDemo.orders();
    history = List.of(PatientDemo.history);
    prescription = PrescriptionUi.demo('Valentina Silva');
    notifyListeners();
  }

  String? validateAuth({
    required bool register,
    required bool clinical,
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool terms,
  }) {
    if (register && name.trim().isEmpty) return 'Ingresa tu nombre completo.';
    if (!email.contains('@')) return 'Ingresa un correo válido.';
    if (register && !clinical && phone.trim().isEmpty) return 'Ingresa tu teléfono.';
    if (password.length < minPassword) return 'La contraseña debe tener al menos $minPassword caracteres.';
    if (register && !terms) return 'Acepta los Términos de Servicio para continuar.';
    return null;
  }

  Future<void> login({required String email, required String password}) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _saveSession(await deps.loginPatient(email: email.trim(), password: password));
      await refreshPatient();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await deps.registerPatient(name: name.trim(), email: email.trim(), phone: phone.trim(), password: password);
      await _saveSession(await deps.loginPatient(email: email.trim(), password: password));
      await refreshPatient();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshPatient() async {
    patientLoading = true;
    notifyListeners();
    final current = session;
    List<OpticalStore> loadedStores = const [];
    List<Appointment> apiAppointments = const [];
    List<WorkOrder> apiOrders = const [];
    List<ClinicalRecord> records = const [];
    try {
      loadedStores = await deps.getStores();
    } catch (_) {}
    if (current != null) {
      try {
        apiAppointments = await deps.getAppointments(current.patientId);
      } catch (_) {}
      try {
        apiOrders = await deps.getWorkOrders(current.patientId);
      } catch (_) {}
      try {
        records = await deps.getClinicalRecords(current.patientId);
      } catch (_) {}
    }
    stores = loadedStores;
    final byId = {for (final store in loadedStores) store.id: store};
    final now = DateTime.now();
    final mapped = apiAppointments.map((appt) {
      final store = byId[appt.opticalStoreId];
      return _appointmentUi(
        id: appt.id,
        start: appt.start,
        end: appt.end,
        title: 'Evaluación visual',
        storeName: store?.name ?? 'Óptica OptiFlow',
        storeAddress: store?.address ?? '',
        status: AppointmentStatusLabel.fromApi(appt.status),
        isPast: appt.end.isBefore(now),
        fromApi: true,
      );
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    appointments = (mapped.isEmpty ? PatientDemo.appointments() : mapped)
        .map((a) => _cancelled.contains(a.id) ? a.copyWith(status: AppointmentStatus.cancelled) : a)
        .toList();
    final name = displayName;
    orders = apiOrders.map(_orderUi).toList();
    if (orders.isEmpty) orders = PatientDemo.orders();
    history = records.map(_history).toList();
    if (history.isEmpty) history = List.of(PatientDemo.history);
    prescription = _prescription(records, name) ?? PrescriptionUi.demo(name);
    patientLoading = false;
    notifyListeners();
  }

  void rescheduleAppointment({
    required String id,
    required String title,
    required String storeName,
    required String storeAddress,
    required DateTime date,
    required String time,
  }) {
    final end = _plusMinutes(time, 45);
    String cap(String value) => value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
    appointments = [
      for (final item in appointments)
        if (item.id == id)
          item.copyWith(
            title: title,
            storeName: storeName,
            storeAddress: storeAddress,
            day: DateFormat('d', 'es').format(date),
            month: DateFormat('MMM', 'es').format(date).replaceAll('.', '').toUpperCase(),
            monthName: cap(DateFormat('MMMM', 'es').format(date)),
            weekday: cap(DateFormat('EEEE', 'es').format(date)),
            time: time,
            endTime: end,
            status: AppointmentStatus.pending,
            isPast: date.isBefore(DateTime.now()),
          )
        else
          item,
    ];
    notifyListeners();
  }

  static String _plusMinutes(String hhmm, int minutes) {
    final parts = hhmm.split(':');
    final total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
    final h = (total ~/ 60).toString().padLeft(2, '0');
    final m = (total % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  void cancelAppointment(String id) {
    _cancelled.add(id);
    appointments = [for (final a in appointments) if (a.id == id) a.copyWith(status: AppointmentStatus.cancelled) else a];
    notifyListeners();
  }

  void savePrescription(PrescriptionUi value) {
    prescription = value;
    notifyListeners();
  }

  void updateProfile({required String name, required String phone}) {
    final current = session;
    if (current == null) return;
    session = current.copyWith(name: name.trim(), phone: phone.trim());
    _saveSession(session!);
  }

  Future<void> markNotificationsRead() async {
    readNotificationIds = notifications.map((n) => n.id).toSet();
    await deps.saveReadNotifications(readNotificationIds);
    notifyListeners();
  }

  Future<void> searchStores() async {
    searchLoading = true;
    searchError = null;
    searchMessage = null;
    notifyListeners();
    try {
      final name = searchQuery.trim().isEmpty ? null : searchQuery.trim();
      if (minRating != null) {
        final result = await deps.searchStores(name: name, minRating: minRating);
        stores = result.stores;
        searchMessage = result.stores.isEmpty ? result.message : null;
      } else {
        stores = await deps.getStores(name: name);
      }
    } on ApiException catch (e) {
      searchError = e.message;
    } catch (e) {
      searchError = '$e';
    } finally {
      searchLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setMinRating(double? value) {
    minRating = value;
    notifyListeners();
    searchStores();
  }

  Future<void> prepareBooking(String? storeId) async {
    bookingStep = 1;
    selectedSlot = null;
    bookingError = null;
    bookingReason = '';
    bookingLoading = true;
    notifyListeners();
    List<OpticalStore> loaded = stores;
    if (loaded.isEmpty) {
      try {
        loaded = await deps.getStores();
        stores = loaded;
      } catch (_) {}
    }
    const distances = ['0,8 km', '3,2 km', '1,4 km', '3,6 km'];
    if (loaded.isNotEmpty) {
      bookingStores = [
        for (var i = 0; i < loaded.length; i++)
          StoreOption(
            id: loaded[i].id,
            name: loaded[i].name,
            address: loaded[i].address,
            distance: distances[i % distances.length],
            availability: i.isEven ? 'Disponible hoy' : 'Disponible mañana',
            availableToday: i.isEven,
          ),
      ];
      bookingDemo = false;
    } else {
      bookingStores = PatientDemo.stores;
      bookingDemo = true;
    }
    final index = bookingStores.indexWhere((s) => s.id != null && s.id == storeId);
    selectedStoreIndex = index < 0 ? 0 : index;
    bookingLoading = false;
    notifyListeners();
  }

  void selectStore(int index) {
    selectedStoreIndex = index;
    bookingError = null;
    notifyListeners();
  }

  Future<void> continueFromStore() async {
    final store = bookingStores[selectedStoreIndex];
    bookingStep = 2;
    bookingLoading = true;
    selectedSlot = null;
    bookingError = null;
    notifyListeners();
    List<TimeSlot> apiSlots = const [];
    if (store.id != null) {
      try {
        apiSlots = await deps.getAvailability(store.id!);
      } catch (_) {}
    }
    if (apiSlots.isEmpty) {
      slots = _demoSlots();
      bookingDemo = true;
    } else {
      slots = [
        for (final slot in apiSlots)
          SlotOption(
            id: slot.id,
            date: DateTime(slot.start.year, slot.start.month, slot.start.day),
            time: DateFormat('HH:mm').format(slot.start),
          ),
      ];
    }
    selectedDate = slots.isEmpty ? null : slots.map((s) => s.date).reduce((a, b) => a.isBefore(b) ? a : b);
    weekStart = _monday(selectedDate ?? DateTime.now());
    bookingLoading = false;
    notifyListeners();
  }

  void shiftWeek(int weeks) {
    weekStart = weekStart.add(Duration(days: 7 * weeks));
    final days = List.generate(5, (i) => weekStart.add(Duration(days: i)));
    selectedDate = days.firstWhere(hasSlots, orElse: () => days.first);
    selectedSlot = null;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    selectedDate = DateTime(date.year, date.month, date.day);
    selectedSlot = null;
    notifyListeners();
  }

  void selectSlot(SlotOption slot) {
    selectedSlot = slot;
    bookingError = null;
    notifyListeners();
  }

  void setReason(String value) {
    bookingReason = value;
    notifyListeners();
  }

  bool continueFromDate() {
    if (selectedSlot == null) {
      bookingError = 'Selecciona un horario para continuar.';
      notifyListeners();
      return false;
    }
    bookingStep = 3;
    bookingError = null;
    notifyListeners();
    return true;
  }

  void bookingBack() {
    if (bookingStep > 1 && bookingStep < 4) {
      bookingStep -= 1;
      bookingError = null;
      notifyListeners();
    }
  }

  Future<bool> confirmBooking() async {
    final slot = selectedSlot;
    final store = bookingStores.isEmpty ? null : bookingStores[selectedStoreIndex];
    if (slot == null || store == null) return false;
    if (slot.id == null || store.id == null) {
      bookingStep = 4;
      notifyListeners();
      return true;
    }
    if (session == null) {
      bookingError = 'Inicia sesión como paciente para reservar.';
      notifyListeners();
      return false;
    }
    bookingLoading = true;
    bookingError = null;
    notifyListeners();
    try {
      await deps.bookAppointment(patientId: session!.patientId, opticalStoreId: store.id!, timeSlotId: slot.id!);
      bookingStep = 4;
      await refreshPatient();
      return true;
    } on ApiException catch (e) {
      bookingError = e.message;
      return false;
    } finally {
      bookingLoading = false;
      notifyListeners();
    }
  }

  List<SlotOption> slotsFor(DateTime? date) {
    if (date == null) return const [];
    return slots.where((s) => _sameDay(s.date, date)).toList();
  }

  bool hasSlots(DateTime date) => slots.any((s) => _sameDay(s.date, date));

  List<FrameItem> get frames => deps.getFrames();
  FrameItem frameById(String id) => deps.getFrame(id);
  List<AgendaItem> get agenda => deps.getAgenda();
  List<ProductItem> get products => deps.getProducts();
  ProductItem productById(String id) => deps.getProduct(id);
  List<ProductionOrder> get productionOrders => deps.getProductionOrders();
  List<StaffAlert> get alerts => deps.getStaffAlerts();
  List<double> get reportBars => deps.getReportBars();

  void addStaffPatient({required String name, required String phone, required String rut, required String reason}) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    staffPatients = [
      StaffPatient(
        id: 'local-${staffPatients.length + 1}',
        initials: initials.isEmpty ? 'NP' : initials,
        name: parts.take(2).join(' '),
        fullName: name.trim(),
        rut: rut.trim().isEmpty ? '—' : rut.trim(),
        note: reason,
        phone: phone.trim(),
        lastVisit: '—',
        ficha: 'OPT-LOCAL-${staffPatients.length + 1}',
        age: 0,
      ),
      ...staffPatients,
    ];
    notifyListeners();
  }

  int stockOf(ProductItem product) => product.available + (stockDelta[product.id] ?? 0);

  void adjustStock(String productId, int delta) {
    stockDelta[productId] = (stockDelta[productId] ?? 0) + delta;
    notifyListeners();
  }

  void setClinicalStage(int index) {
    clinicalStage = index;
    notifyListeners();
  }

  AppointmentUi? appointmentById(String id) {
    for (final item in appointments) {
      if (item.id == id) return item;
    }
    return null;
  }

  OrderUi? orderById(String id) {
    for (final item in orders) {
      if (item.id == id) return item;
    }
    return null;
  }

  StaffPatient staffPatient(String id) {
    return staffPatients.firstWhere((p) => p.id == id, orElse: () => staffPatients.first);
  }

  static DateTime _monday(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static List<SlotOption> _demoSlots() {
    final monday = _monday(DateTime.now().add(const Duration(days: 7)));
    const times = ['09:00', '09:30', '10:30', '11:00', '15:00', '15:30', '16:00', '17:30'];
    return [
      for (var offset = 0; offset < 5; offset++)
        for (final time in times) SlotOption(id: null, date: monday.add(Duration(days: offset)), time: time),
    ];
  }

  AppointmentUi _appointmentUi({
    required String id,
    required DateTime start,
    required DateTime end,
    required String title,
    required String storeName,
    required String storeAddress,
    required AppointmentStatus status,
    required bool isPast,
    required bool fromApi,
  }) {
    String cap(String value) => value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
    return AppointmentUi(
      id: id,
      day: DateFormat('d', 'es').format(start),
      month: DateFormat('MMM', 'es').format(start).replaceAll('.', '').toUpperCase(),
      monthName: cap(DateFormat('MMMM', 'es').format(start)),
      weekday: cap(DateFormat('EEEE', 'es').format(start)),
      time: DateFormat('HH:mm').format(start),
      endTime: DateFormat('HH:mm').format(end),
      title: title,
      storeName: storeName,
      storeAddress: storeAddress,
      professional: 'Dra. Fernanda Soto',
      status: status,
      isPast: isPast,
      fromApi: fromApi,
    );
  }

  OrderUi _orderUi(WorkOrder order) {
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

  HistoryEntry _history(ClinicalRecord record) {
    final when = record.examinationDate?.toLocal();
    return HistoryEntry(
      date: when == null ? '—' : DateFormat('dd MMM yyyy', 'es').format(when).toUpperCase().replaceAll('.', ''),
      title: 'Evaluación visual',
      summary: record.observations ?? 'Sin observaciones',
      professional: 'Dra. Fernanda Soto',
    );
  }

  PrescriptionUi? _prescription(List<ClinicalRecord> records, String name) {
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
}
