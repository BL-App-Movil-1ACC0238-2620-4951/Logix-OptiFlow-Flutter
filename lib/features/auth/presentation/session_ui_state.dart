import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/features/auth/domain/app_settings.dart';
import 'package:logix_optiflow/features/auth/domain/patient_session.dart';

class SessionUiState {
  const SessionUiState({
    this.session,
    this.bootstrapped = false,
    this.busy = false,
    this.error,
    this.settings = const AppSettings(),
  });

  final PatientSession? session;
  final bool bootstrapped;
  final bool busy;
  final String? error;
  final AppSettings settings;

  SessionUiState copyWith({
    ValueGetter<PatientSession?>? session,
    bool? bootstrapped,
    bool? busy,
    ValueGetter<String?>? error,
    AppSettings? settings,
  }) {
    return SessionUiState(
      session: session != null ? session() : this.session,
      bootstrapped: bootstrapped ?? this.bootstrapped,
      busy: busy ?? this.busy,
      error: error != null ? error() : this.error,
      settings: settings ?? this.settings,
    );
  }
}
