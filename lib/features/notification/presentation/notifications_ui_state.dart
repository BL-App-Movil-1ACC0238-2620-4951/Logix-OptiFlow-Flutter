import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/notification/domain/patient_notification.dart';

class NotificationSection {
  const NotificationSection(this.title, this.items);

  final String title;
  final List<PatientNotification> items;
}

class NotificationsUiState {
  const NotificationsUiState({this.items = const [], this.loading = true, this.error});

  final List<PatientNotification> items;
  final bool loading;
  final String? error;

  NotificationsUiState copyWith({List<PatientNotification>? items, bool? loading, ValueGetter<String?>? error}) {
    return NotificationsUiState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error != null ? error() : this.error,
    );
  }
}
