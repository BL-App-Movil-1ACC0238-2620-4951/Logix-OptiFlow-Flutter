import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/di/dependencies.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/entities/models.dart';
import '../../domain/entities/inventory.dart';
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
  List<FrameItem> _frames = [];
  final Map<String, FrameItem> _framesBySku = {};
  final Map<String, ProductItem> _productsBySku = {};
  List<ProductItem> products = [];
  bool catalogLoading = false;
  String? catalogError;
  bool inventoryLoading = false;
  String? inventoryError;
  final Set<String> frameLoading = {};
  final Map<String, String> frameErrors = {};
  final Map<String, int> _frameRequests = {};
  int _catalogRequest = 0;
  int _inventoryRequest = 0;
  List<Supplier> suppliers = [];
  bool suppliersLoading = false;
  String? suppliersError;
  int _supplierRequest = 0;
  List<StockMovement> stockMovements = [];
  bool movementsLoading = false;
  String? movementsError;
  int _movementsRequest = 0;
  bool inventoryMutationBusy = false;
  String? inventoryMutationError;
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
    final realAppts = upcoming.where((a) => a.fromApi);
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
    _catalogRequest++;
    _inventoryRequest++;
    _supplierRequest++;
    _movementsRequest++;
    for (final sku in _frameRequests.keys.toList()) { _frameRequests[sku] = _frameRequests[sku]! + 1; }
    _frames = [];
    _framesBySku.clear();
    _productsBySku.clear();
    products = [];
    frameLoading.clear();
    frameErrors.clear();
    catalogLoading = false;
    catalogError = null;
    inventoryLoading = false;
    inventoryError = null;
    suppliers = [];
    suppliersLoading = false;
    suppliersError = null;
    stockMovements = [];
    movementsLoading = false;
    movementsError = null;
    inventoryMutationBusy = false;
    inventoryMutationError = null;
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

  bool get canUseCatalog => session?.isAuthenticated == true && (session!.isPatient || session!.role.can(StaffFeature.catalog));

  String _inventoryMessage(Object error, String fallback) => error is ApiException ? error.message : fallback;

  void _cacheFrame(FrameItem frame) {
    _framesBySku[frame.id] = frame;
    _frames = [for (final item in _frames) item.id == frame.id ? frame : item];
  }

  ProductItem _product(FrameItem frame, {StockLevel? stock, bool storeStockLoaded = false}) => ProductItem(
    id: frame.id, sku: frame.sku, name: frame.name, code: frame.sku,
    detail: frame.description, price: frame.fromPrice, tag: frame.category,
    available: stock?.quantity ?? frame.stock, quantityKnown: storeStockLoaded || stock != null || frame.stockKnown,
    minimumStock: stock?.minimumStock ?? frame.minimumStock,
    image: frame.image, category: frame.category, size: '', location: '', supplier: '',
  );

  Future<void> refreshCatalog() async {
    if (!canUseCatalog) return;
    final current = session;
    final request = ++_catalogRequest;
    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    try {
      final loaded = await deps.getFrames();
      if (!identical(current, session) || request != _catalogRequest) return;
      _frames = loaded;
      for (final frame in loaded) { _framesBySku[frame.id] = frame; }
    } catch (e) {
      if (identical(current, session) && request == _catalogRequest) {
        catalogError = _inventoryMessage(e, 'No se pudo cargar el catálogo.');
      }
    } finally {
      if (identical(current, session) && request == _catalogRequest) {
        catalogLoading = false;
        notifyListeners();
      }
    }
  }

  Future<FrameItem?> loadFrame(String sku, {bool forInventory = false}) async {
    if (!canUseCatalog || frameLoading.contains(sku)) return frameById(sku);
    final current = session;
    final storeId = forInventory ? current?.opticalStoreId : null;
    if (forInventory && (storeId == null || storeId.isEmpty)) {
      frameErrors[sku] = 'Tu cuenta no tiene una óptica asignada.';
      notifyListeners();
      return null;
    }
    final request = (_frameRequests[sku] ?? 0) + 1;
    _frameRequests[sku] = request;
    frameLoading.add(sku);
    frameErrors.remove(sku);
    notifyListeners();
    try {
      final frame = await deps.getFrame(sku, opticalStoreId: storeId);
      if (!identical(current, session) || _frameRequests[sku] != request) return null;
      _cacheFrame(frame);
      if (forInventory) _productsBySku[sku] = _product(frame);
      return frame;
    } catch (e) {
      if (identical(current, session) && _frameRequests[sku] == request) {
        frameErrors[sku] = _inventoryMessage(e, 'No se encontró la montura o no se pudo cargar.');
      }
      return null;
    } finally {
      if (identical(current, session) && _frameRequests[sku] == request) {
        frameLoading.remove(sku);
        notifyListeners();
      }
    }
  }

  Future<void> refreshInventory() async {
    final current = session;
    if (!canOpen('/s/inventory')) return;
    final storeId = current?.opticalStoreId;
    if (storeId == null || storeId.isEmpty) {
      inventoryError = 'Tu cuenta no tiene una óptica asignada. Solicita la asignación al administrador.';
      notifyListeners();
      return;
    }
    final request = ++_inventoryRequest;
    inventoryLoading = true;
    inventoryError = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([deps.getFrames(), deps.getStoreStock(storeId)]);
      if (!identical(current, session) || request != _inventoryRequest) return;
      final catalog = results[0] as List<FrameItem>;
      final inventory = results[1] as StoreInventory;
      if (inventory.opticalStoreId != storeId) throw ApiException('El stock recibido pertenece a otra óptica.');
      final stocks = {for (final stock in inventory.stocks) stock.sku: stock};
      products = [for (final frame in catalog)
        _product(frame, stock: stocks[frame.sku], storeStockLoaded: true),
      ];
      _productsBySku.clear();
      for (final product in products) { _productsBySku[product.id] = product; }
      for (final frame in catalog) { _cacheFrame(frame); }
    } catch (e) {
      if (identical(current, session) && request == _inventoryRequest) {
        inventoryError = _inventoryMessage(e, 'No se pudo cargar el inventario de tu óptica.');
      }
    } finally {
      if (identical(current, session) && request == _inventoryRequest) {
        inventoryLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshSuppliers() async {
    if (!canOpen('/s/movement')) return;
    final current = session;
    final request = ++_supplierRequest;
    suppliersLoading = true;
    suppliersError = null;
    notifyListeners();
    try {
      final loaded = await deps.getSuppliers();
      if (identical(current, session) && request == _supplierRequest) suppliers = loaded;
    } catch (e) {
      if (identical(current, session) && request == _supplierRequest) suppliersError = _inventoryMessage(e, 'No se pudieron cargar los proveedores.');
    } finally {
      if (identical(current, session) && request == _supplierRequest) {
        suppliersLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshStockMovements({String? sku, DateTime? from, DateTime? to}) async {
    if (!canOpen('/s/movement')) return;
    final current = session;
    final storeId = current?.opticalStoreId;
    if (storeId == null || storeId.isEmpty) {
      movementsError = 'Tu cuenta no tiene una óptica asignada.';
      notifyListeners();
      return;
    }
    final request = ++_movementsRequest;
    movementsLoading = true;
    movementsError = null;
    stockMovements = [];
    notifyListeners();
    try {
      final end = to ?? DateTime.now();
      final loaded = await deps.getStockMovements(opticalStoreId: storeId, from: from ?? end.subtract(const Duration(days: 30)), to: end, sku: sku);
      if (identical(current, session) && request == _movementsRequest) stockMovements = loaded;
    } catch (e) {
      if (identical(current, session) && request == _movementsRequest) movementsError = _inventoryMessage(e, 'No se pudieron cargar los movimientos.');
    } finally {
      if (identical(current, session) && request == _movementsRequest) {
        movementsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> replenishStock({required String sku, required String supplierId, required int quantity, int? minimumStock}) async {
    if (inventoryMutationBusy) return false;
    inventoryMutationError = null;
    final current = session;
    final storeId = current?.opticalStoreId;
    if (!canOpen('/s/movement') || storeId == null || storeId.isEmpty) {
      inventoryMutationError = 'Solo el administrador con óptica asignada puede registrar ingresos.';
    } else if (sku.trim().isEmpty || supplierId.isEmpty || quantity < 1 || quantity > 1000 || (minimumStock != null && minimumStock < 0)) {
      inventoryMutationError = 'Elige montura y proveedor, cantidad de 1 a 1000 y mínimo mayor o igual a cero.';
    }
    if (inventoryMutationError != null) { notifyListeners(); return false; }
    inventoryMutationBusy = true;
    notifyListeners();
    try {
      await deps.replenishStock(opticalStoreId: storeId!, sku: sku.trim(), supplierId: supplierId, quantity: quantity, minimumStock: minimumStock);
      if (!identical(current, session)) return false;
      _inventoryRequest++;
      _frameRequests[sku] = (_frameRequests[sku] ?? 0) + 1;
      frameLoading.remove(sku);
      // The movement is already saved. A reload error must not invite a duplicate POST.
      await refreshInventory();
      await loadFrame(sku, forInventory: true);
      return identical(current, session);
    } catch (e) {
      if (identical(current, session)) inventoryMutationError = _inventoryMessage(e, 'No se pudo verificar el ingreso. Consulta los movimientos antes de reintentar.');
      return false;
    } finally {
      if (identical(current, session)) { inventoryMutationBusy = false; notifyListeners(); }
    }
  }

  Future<bool> updateFramePrice(String sku, num price) async {
    if (inventoryMutationBusy) return false;
    inventoryMutationError = null;
    if (!canUseCatalog || session!.isPatient || !session!.role.can(StaffFeature.catalog) || !price.isFinite || price <= 0 || price > 99999999.99 || (price * 100 - (price * 100).round()).abs() > 0.000001) {
      inventoryMutationError = 'Ingresa un precio válido, mayor a cero, con máximo dos decimales.';
      notifyListeners();
      return false;
    }
    final current = session;
    inventoryMutationBusy = true;
    notifyListeners();
    try {
      final updated = await deps.updateFramePrice(sku, price);
      if (!identical(current, session)) return false;
      _catalogRequest++;
      catalogLoading = false;
      _inventoryRequest++;
      inventoryLoading = false;
      _frameRequests[sku] = (_frameRequests[sku] ?? 0) + 1;
      frameLoading.remove(sku);
      _cacheFrame(updated);
      final old = _productsBySku[sku];
      final product = old?.withPrice(updated.fromPrice) ?? _product(updated);
      _productsBySku[sku] = product;
      products = [for (final item in products) item.id == sku ? product : item];
      return true;
    } catch (e) {
      if (identical(current, session)) inventoryMutationError = _inventoryMessage(e, 'No se pudo actualizar el precio.');
      return false;
    } finally {
      if (identical(current, session)) { inventoryMutationBusy = false; notifyListeners(); }
    }
  }
  List<FrameItem> get frames => _frames;
  FrameItem? frameById(String sku) => _framesBySku[sku];
  List<AgendaItem> get agenda => deps.getAgenda();
  ProductItem? productById(String sku) => _productsBySku[sku];
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

  int stockOf(ProductItem product) => product.available;

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
