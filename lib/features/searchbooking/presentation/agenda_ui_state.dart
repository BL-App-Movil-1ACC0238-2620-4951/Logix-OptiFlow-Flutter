import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/searchbooking/domain/agenda_item.dart';
import 'package:logix_optiflow/features/searchbooking/domain/time_slot.dart';

class AgendaUiState {
  const AgendaUiState({
    required this.date,
    this.agenda = const [],
    this.loading = false,
    this.error,
    this.bookingSlots = const [],
    this.bookingPatientId,
    this.bookingSlotId,
    this.bookingDay,
    this.bookingLoading = false,
    this.bookingSaving = false,
    this.bookingError,
  });

  final List<AgendaItem> agenda;
  final DateTime date;
  final bool loading;
  final String? error;

  /// Nueva cita agendada por el personal.
  final List<TimeSlot> bookingSlots;
  final String? bookingPatientId;
  final String? bookingSlotId;
  final DateTime? bookingDay;
  final bool bookingLoading;
  final bool bookingSaving;
  final String? bookingError;

  AgendaUiState copyWith({
    List<AgendaItem>? agenda,
    DateTime? date,
    bool? loading,
    ValueGetter<String?>? error,
    List<TimeSlot>? bookingSlots,
    ValueGetter<String?>? bookingPatientId,
    ValueGetter<String?>? bookingSlotId,
    ValueGetter<DateTime?>? bookingDay,
    bool? bookingLoading,
    bool? bookingSaving,
    ValueGetter<String?>? bookingError,
  }) {
    return AgendaUiState(
      agenda: agenda ?? this.agenda,
      date: date ?? this.date,
      loading: loading ?? this.loading,
      error: error != null ? error() : this.error,
      bookingSlots: bookingSlots ?? this.bookingSlots,
      bookingPatientId: bookingPatientId != null ? bookingPatientId() : this.bookingPatientId,
      bookingSlotId: bookingSlotId != null ? bookingSlotId() : this.bookingSlotId,
      bookingDay: bookingDay != null ? bookingDay() : this.bookingDay,
      bookingLoading: bookingLoading ?? this.bookingLoading,
      bookingSaving: bookingSaving ?? this.bookingSaving,
      bookingError: bookingError != null ? bookingError() : this.bookingError,
    );
  }
}
