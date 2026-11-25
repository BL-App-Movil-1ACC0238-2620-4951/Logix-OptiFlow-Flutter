import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/searchbooking/domain/appointment.dart';
import 'package:logix_optiflow/presentation/models/ui_models.dart';

class BookingUiState {
  const BookingUiState({
    required this.weekStart,
    this.step = 1,
    this.stores = const [],
    this.selectedStoreIndex = 0,
    this.slots = const [],
    this.selectedDate,
    this.selectedSlot,
    this.loading = false,
    this.error,
    this.reschedulingId,
    this.appointment,
  });

  final int step;
  final List<StoreOption> stores;
  final int selectedStoreIndex;
  final List<SlotOption> slots;
  final DateTime weekStart;
  final DateTime? selectedDate;
  final SlotOption? selectedSlot;
  final bool loading;
  final String? error;
  final String? reschedulingId;

  /// Cita ya creada en el backend; evita reservar dos veces al reintentar una reprogramación.
  final Appointment? appointment;

  StoreOption? get selectedStore =>
      selectedStoreIndex >= 0 && selectedStoreIndex < stores.length ? stores[selectedStoreIndex] : null;

  BookingUiState copyWith({
    int? step,
    List<StoreOption>? stores,
    int? selectedStoreIndex,
    List<SlotOption>? slots,
    DateTime? weekStart,
    ValueGetter<DateTime?>? selectedDate,
    ValueGetter<SlotOption?>? selectedSlot,
    bool? loading,
    ValueGetter<String?>? error,
    ValueGetter<String?>? reschedulingId,
    ValueGetter<Appointment?>? appointment,
  }) {
    return BookingUiState(
      step: step ?? this.step,
      stores: stores ?? this.stores,
      selectedStoreIndex: selectedStoreIndex ?? this.selectedStoreIndex,
      slots: slots ?? this.slots,
      weekStart: weekStart ?? this.weekStart,
      selectedDate: selectedDate != null ? selectedDate() : this.selectedDate,
      selectedSlot: selectedSlot != null ? selectedSlot() : this.selectedSlot,
      loading: loading ?? this.loading,
      error: error != null ? error() : this.error,
      reschedulingId: reschedulingId != null ? reschedulingId() : this.reschedulingId,
      appointment: appointment != null ? appointment() : this.appointment,
    );
  }
}
