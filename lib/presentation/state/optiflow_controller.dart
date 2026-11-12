import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/di/dependencies.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/entities/models.dart';
import '../mappers/patient_view_mapper.dart';
import '../models/ui_models.dart';
import '../navigation/route_access.dart';

class OptiFlowController extends ChangeNotifier {
  OptiFlowController({AppDependencies? dependencies}) : deps = dependencies ?? AppDependencies() {
    deps.api.onUnauthorized = () { unawaited(logout()); };
  }

  final AppDependencies deps;
  static const minPassword = 8;

  bool bootstrapped = false;
  bool busy = false;
  String? error;

  PatientSession? session;
  Future<void>? _bootstrapFuture;
  String get homeRoute => homePath(session);
  bool canOpen(String path) => canAccessPath(session, path);
  List<AppointmentUi> appointments = [];
  bool appointmentsLoading = false;
  String? appointmentsError;
  bool appointmentActionLoading = false;
  String? appointmentActionError;
  int _appointmentsRequest = 0;
  List<OrderUi> orders = PatientDemo.orders();
  List<HistoryEntry> history = List.of(PatientDemo.history);
  PrescriptionUi prescription = PrescriptionUi.demo('Valentina Silva');
  List<OpticalStore> stores = const [];
  bool patientLoading = true;

  Set<String> readNotificationIds = {};
  AppSettings settings = const AppSettings();

  String searchQuery = '';
  String searchAddress = '';
  List<OpticalStore> searchResults = [];
  int _searchRequest = 0;
  double? minRating;
  bool searchLoading = false;
  String? searchMessage;
  String? searchError;

  int bookingStep = 1;
  List<StoreOption> bookingStores = [];
  int selectedStoreIndex = 0;
  List<SlotOption> slots = const [];
  DateTime weekStart = _monday(DateTime.now());
  DateTime? selectedDate;
  SlotOption? selectedSlot;
  bool bookingLoading = false;
  String? bookingError;
  String? reschedulingId;
  Appointment? bookingAppointment;
  int _bookingRequest = 0;
  StoreOption? get selectedBookingStore => selectedStoreIndex >= 0 && selectedStoreIndex < bookingStores.length ? bookingStores[selectedStoreIndex] : null;

  late List<StaffPatient> staffPatients = List.of(deps.getStaffPatients());
  final Map<String, int> stockDelta = {};
  int clinicalStage = 1;

  String get displayName => session?.name.trim().isNotEmpty == true ? session!.name.trim() : (session?.isPatient == false ? 'Personal' : 'Valentina Silva');
  String get firstName => displayName.split(' ').first;
  String get email => session?.email.trim().isNotEmpty == true ? session!.email.trim() : 'valentina.silva@email.com';
  String get initials {
    final parts = displayName.split(' ').where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  List<AppointmentUi> get upcoming =>
      appointments.where((a) => !a.isPast && a.status != AppointmentStatus.cancelled && a.status != AppointmentStatus.completed).toList();
  AppointmentUi? get nextAppointment => upcoming.isEmpty ? null : upcoming.first;

  List<NotificationItem> get notifications {
    final items = <NotificationItem>[];
    final now = DateTime.now();
    final realAppts = appointments.where((a) => a.fromApi && !a.isPast);
    {
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

  Future<void> bootstrap() => _bootstrapFuture ??= _bootstrap();

  Future<void> _bootstrap() async {
    session = await deps.loadSession();
    if (session != null && !session!.isAuthenticated) {
      session = null;
      await deps.clearSession();
    }
    deps.api.token = session?.token;
    readNotificationIds = await deps.loadReadNotifications();
    settings = await deps.loadSettings();
    bootstrapped = true;
    notifyListeners();
    if (session?.isPatient == true) {
      unawaited(refreshPatient());
    } else {
      patientLoading = false;
      notifyListeners();
    }
  }

  Future<void> setControlReminders(bool value) async {
    settings = settings.copyWith(controlReminders: value);
    await deps.saveSettings(settings);
    notifyListeners();
  }

  Future<void> _saveSession(PatientSession value) async {
    await deps.saveSession(value);
    deps.api.token = value.token;
    session = value;
    notifyListeners();
  }

  Future<void> logout() async {
    session = null;
    deps.api.token = null;
    _appointmentsRequest++;
    _searchRequest++;
    _bookingRequest++;
    readNotificationIds = {};
    selectedSlot = null;
    bookingStep = 1;
    stockDelta.clear();
    staffPatients = List.of(deps.getStaffPatients());
    appointments = [];
    appointmentsLoading = false;
    appointmentsError = null;
    appointmentActionLoading = false;
    appointmentActionError = null;
    bookingStores = [];
    slots = [];
    bookingAppointment = null;
    reschedulingId = null;
    bookingLoading = false;
    bookingError = null;
    searchResults = [];
    searchQuery = '';
    searchAddress = '';
    searchLoading = false;
    searchError = null;
    minRating = null;
    orders = PatientDemo.orders();
    history = List.of(PatientDemo.history);
    prescription = PrescriptionUi.demo('Valentina Silva');
    patientLoading = false;
    notifyListeners();
    await deps.clearSession();
    await deps.saveReadNotifications({});
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
    if (register && clinical) return 'Las cuentas del personal las crea el administrador de la óptica.';
    if (register && name.trim().isEmpty) return 'Ingresa tu nombre completo.';
    if (!email.contains('@')) return 'Ingresa un correo válido.';
    if (register && !clinical && phone.trim().isEmpty) return 'Ingresa tu teléfono.';
    if (password.length < minPassword) return 'La contraseña debe tener al menos $minPassword caracteres.';
    if (register && !terms) return 'Acepta los Términos de Servicio para continuar.';
    return null;
  }

  Future<void> login({required String email, required String password}) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _saveSession(await deps.loginPatient(email: email.trim(), password: password));
      if (session?.isPatient == true) unawaited(refreshPatient());
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
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await deps.registerPatient(name: name.trim(), email: email.trim(), phone: phone.trim(), password: password);
      await _saveSession(await deps.loginPatient(email: email.trim(), password: password));
      if (session?.isPatient == true) unawaited(refreshPatient());
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  AppointmentUi _appointmentView(Appointment appt) {
    final store = stores.where((s) => s.id == appt.opticalStoreId).firstOrNull;
    final status = AppointmentStatusLabel.fromApi(appt.status);
    return PatientViewMapper.appointment(
      id: appt.id, start: appt.start, end: appt.end,
      opticalStoreId: appt.opticalStoreId, timeSlotId: appt.timeSlotId,
      title: 'Evaluación visual', storeName: store?.name ?? 'Óptica',
      storeAddress: store?.address ?? '', status: status,
      isPast: appt.end.isBefore(DateTime.now()) || status == AppointmentStatus.completed,
      fromApi: true,
    );
  }

  void _putAppointment(Appointment appt) {
    appointments = [for (final item in appointments) if (item.id != appt.id) item, _appointmentView(appt)]
      ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
  }

  Future<void> refreshAppointments() async {
    final current = session;
    if (current?.isAuthenticated != true || !current!.isPatient) return;
    final request = ++_appointmentsRequest;
    appointmentsLoading = true;
    appointmentsError = null;
    notifyListeners();
    try {
      final storeRequest = deps.getStores().catchError((_) => stores);
      final results = await deps.getAppointments(current.patientId);
      final loadedStores = await storeRequest;
      if (!identical(current, session) || request != _appointmentsRequest) return;
      stores = loadedStores;
      appointments = results.map(_appointmentView).toList()
        ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
    } catch (e) {
      if (identical(current, session) && request == _appointmentsRequest) {
        appointmentsError = e is ApiException ? e.message : 'No se pudieron cargar tus citas. Intenta nuevamente.';
      }
    } finally {
      if (identical(current, session) && request == _appointmentsRequest) {
        appointmentsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshPatient() async {
    final current = session;
    if (current?.isAuthenticated != true || !current!.isPatient) return;
    patientLoading = true;
    notifyListeners();
    final appointmentsRequest = refreshAppointments();
    List<WorkOrder> apiOrders = const [];
    List<ClinicalRecord> records = const [];
    try { apiOrders = await deps.getWorkOrders(current.patientId); } catch (_) {}
    if (!identical(current, session)) return;
    try { records = await deps.getClinicalRecords(current.patientId); } catch (_) {}
    await appointmentsRequest;
    if (!identical(current, session)) return;
    final name = displayName;
    orders = apiOrders.map(PatientViewMapper.order).toList();
    if (orders.isEmpty) orders = PatientDemo.orders();
    history = records.map(PatientViewMapper.history).toList();
    if (history.isEmpty) history = List.of(PatientDemo.history);
    prescription = PatientViewMapper.prescription(records, name) ?? PrescriptionUi.demo(name);
    patientLoading = false;
    notifyListeners();
  }

  Future<bool> cancelAppointment(String id) async {
    if (appointmentActionLoading) return false;
    final current = session;
    final item = appointmentById(id);
    if (current?.isAuthenticated != true || current?.isPatient != true || item == null || !item.fromApi) return false;
    appointmentActionLoading = true;
    appointmentActionError = null;
    notifyListeners();
    try {
      final updated = await deps.cancelAppointment(id);
      if (!identical(current, session)) return false;
      _appointmentsRequest++; // Older list requests must not restore the old status.
      appointmentsLoading = false;
      _putAppointment(updated);
      return true;
    } catch (e) {
      if (identical(current, session)) appointmentActionError = e is ApiException ? e.message : 'No se pudo cancelar la cita.';
      return false;
    } finally {
      if (identical(current, session)) {
        appointmentActionLoading = false;
        notifyListeners();
      }
    }
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

  Future<void> markNotificationRead(String id) async {
    if (readNotificationIds.contains(id)) return;
    readNotificationIds = {...readNotificationIds, id};
    await deps.saveReadNotifications(readNotificationIds);
    notifyListeners();
  }

  Future<void> searchStores() async {
    final request = ++_searchRequest;
    searchLoading = true;
    searchError = null;
    searchMessage = null;
    notifyListeners();
    try {
      final result = await deps.searchStores(
        name: searchQuery.trim().isEmpty ? null : searchQuery.trim(),
        address: searchAddress.trim().isEmpty ? null : searchAddress.trim(),
        minRating: minRating,
      );
      if (request != _searchRequest) return;
      searchResults = result.stores;
      searchMessage = result.message;
    } catch (e) {
      if (request != _searchRequest) return;
      searchResults = [];
      searchError = e is ApiException ? e.message : 'No se pudieron buscar las ópticas.';
    } finally {
      if (request == _searchRequest) {
        searchLoading = false;
        notifyListeners();
      }
    }
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    _searchRequest++; // Invalidate earlier responses during the debounce interval.
  }

  void setSearchAddress(String value) {
    searchAddress = value;
    _searchRequest++;
  }

  void setMinRating(double? value) {
    minRating = value;
    unawaited(searchStores());
  }

  Future<void> prepareBooking(String? storeId, {String? rescheduleId}) async {
    if (bookingLoading && bookingStep == 3) return;
    final request = ++_bookingRequest;
    final current = session;
    bookingStep = 1;
    selectedSlot = null;
    slots = [];
    bookingStores = [];
    bookingAppointment = null;
    reschedulingId = rescheduleId;
    bookingError = null;
    bookingLoading = true;
    notifyListeners();
    try {
      if (rescheduleId != null) {
        await refreshAppointments();
        if (request != _bookingRequest || !identical(current, session)) return;
        final original = appointmentById(rescheduleId);
        if (original == null || original.isPast || original.status == AppointmentStatus.cancelled || original.status == AppointmentStatus.completed) {
          throw ApiException(appointmentsError ?? 'Esta cita no se puede reprogramar.');
        }
        storeId ??= original.opticalStoreId;
      }
      final loaded = await deps.getStores(); // Always load all stores, independent of search filters.
      if (request != _bookingRequest || !identical(current, session)) return;
      stores = loaded;
      bookingStores = [for (final store in loaded)
        if (const {'ACTIVE', 'OPEN', 'ABIERTO'}.contains(store.status.toUpperCase()))
          StoreOption(id: store.id, name: store.name, address: store.address,
            distance: '', availability: 'Consultar horarios', availableToday: false),
      ];
      selectedStoreIndex = bookingStores.indexWhere((s) => s.id == storeId);
      if (selectedStoreIndex < 0) selectedStoreIndex = 0;
      if (bookingStores.isEmpty) bookingError = 'No hay ópticas disponibles para reservar.';
    } catch (e) {
      if (request == _bookingRequest && identical(current, session)) {
        bookingError = e is ApiException ? e.message : 'No se pudieron cargar las ópticas.';
      }
    } finally {
      if (request == _bookingRequest && identical(current, session)) {
        bookingLoading = false;
        notifyListeners();
      }
    }
  }

  void selectStore(int index) {
    if (bookingLoading || bookingAppointment != null || index < 0 || index >= bookingStores.length) return;
    selectedStoreIndex = index;
    selectedSlot = null;
    slots = [];
    bookingError = null;
    notifyListeners();
  }

  Future<void> continueFromStore() async {
    if (bookingLoading || bookingAppointment != null) return;
    final store = selectedBookingStore;
    if (store?.id == null) return;
    final request = ++_bookingRequest;
    final current = session;
    bookingStep = 2;
    bookingLoading = true;
    slots = [];
    selectedSlot = null;
    selectedDate = null;
    bookingError = null;
    notifyListeners();
    try {
      final available = await deps.getAvailability(store!.id!);
      if (request != _bookingRequest || !identical(current, session)) return;
      final now = DateTime.now();
      slots = [for (final slot in available)
        if (slot.opticalStoreId == store.id && slot.start.isAfter(now) && slot.status.toUpperCase() == 'AVAILABLE')
          PatientViewMapper.slot(slot),
      ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      selectedDate = slots.firstOrNull?.date;
      weekStart = _monday(selectedDate ?? now);
    } catch (e) {
      if (request == _bookingRequest && identical(current, session)) {
        bookingError = e is ApiException ? e.message : 'No se pudieron cargar los horarios.';
      }
    } finally {
      if (request == _bookingRequest && identical(current, session)) {
        bookingLoading = false;
        notifyListeners();
      }
    }
  }

  void shiftWeek(int weeks) {
    if (bookingLoading || bookingAppointment != null) return;
    weekStart = weekStart.add(Duration(days: 7 * weeks));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    selectedDate = days.firstWhere(hasSlots, orElse: () => days.first);
    selectedSlot = null;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    if (bookingLoading || bookingAppointment != null) return;
    selectedDate = DateTime(date.year, date.month, date.day);
    selectedSlot = null;
    notifyListeners();
  }

  void selectSlot(SlotOption slot) {
    if (bookingLoading || bookingAppointment != null || !slots.contains(slot)) return;
    selectedSlot = slot;
    bookingError = null;
    notifyListeners();
  }

  bool continueFromDate() {
    if (bookingLoading) return false;
    if (selectedSlot?.id == null || !selectedSlot!.startsAt.isAfter(DateTime.now())) {
      bookingError = 'Selecciona un horario disponible para continuar.';
      notifyListeners();
      return false;
    }
    bookingStep = 3;
    bookingError = null;
    notifyListeners();
    return true;
  }

  void bookingBack() {
    if (bookingLoading || bookingAppointment != null) return;
    if (bookingStep > 1 && bookingStep < 4) {
      bookingStep--;
      bookingError = null;
      notifyListeners();
    }
  }

  Future<bool> confirmBooking() async {
    if (bookingLoading || bookingStep != 3) return false;
    final slot = selectedSlot;
    final store = selectedBookingStore;
    final current = session;
    if (slot?.id == null || store?.id == null || current?.isAuthenticated != true || current?.isPatient != true) {
      bookingError = 'Inicia sesión como paciente y selecciona un horario real.';
      notifyListeners();
      return false;
    }
    if (bookingAppointment == null && !slot!.startsAt.isAfter(DateTime.now())) {
      bookingError = 'Ese horario ya pasó. Elige otro.';
      notifyListeners();
      return false;
    }
    final request = ++_bookingRequest;
    bookingLoading = true;
    bookingError = null;
    notifyListeners();
    try {
      if (bookingAppointment == null) {
        final created = await deps.bookAppointment(patientId: current!.patientId, opticalStoreId: store!.id!, timeSlotId: slot!.id!);
        if (request != _bookingRequest || !identical(current, session)) return false;
        bookingAppointment = created;
        _appointmentsRequest++;
        appointmentsLoading = false;
        _putAppointment(created);
      }
      // The backend implements rescheduling as book-new, then cancel-old.
      // Keep the new id if cancellation fails, so retry never books it twice.
      if (reschedulingId != null) {
        final cancelled = await deps.cancelAppointment(reschedulingId!);
        if (request != _bookingRequest || !identical(current, session)) return false;
        _putAppointment(cancelled);
      }
      bookingStep = 4;
      return true;
    } catch (e) {
      if (request != _bookingRequest || !identical(current, session)) return false;
      if (bookingAppointment != null && reschedulingId != null) {
        bookingError = 'La nueva cita está reservada, pero no se pudo cancelar la anterior. Reintenta para completar la reprogramación; no se creará otra reserva.';
      } else if (e is ApiException && e.statusCode == 409) {
        bookingError = 'El horario ya no está disponible. Vuelve a elegir uno.';
        slots = slots.where((s) => s.id != slot!.id).toList();
        selectedSlot = null;
        bookingStep = 2;
      } else {
        bookingError = e is ApiException ? e.message : 'No se pudo confirmar la reserva. Revisa tus citas antes de intentar de nuevo.';
      }
      return false;
    } finally {
      if (request == _bookingRequest && identical(current, session)) {
        bookingLoading = false;
        notifyListeners();
      }
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

}
