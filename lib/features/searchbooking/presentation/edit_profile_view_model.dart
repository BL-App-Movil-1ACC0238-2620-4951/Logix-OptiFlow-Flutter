import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/presentation/session_view_model.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_staff_patient_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/update_patient_profile_use_case.dart';

class EditProfileUiState {
  const EditProfileUiState({
    this.loading = true,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.birthDate = '',
    this.saving = false,
    this.error,
    this.saved = false,
  });

  final bool loading;
  final String name;
  final String email;
  final String phone;
  /// Fecha en formato dd/mm/aaaa; vacía si el paciente no la registró.
  final String birthDate;
  final bool saving;
  final String? error;
  final bool saved;

  EditProfileUiState copyWith({
    bool? loading,
    String? name,
    String? email,
    String? phone,
    String? birthDate,
    bool? saving,
    ValueGetter<String?>? error,
    bool? saved,
  }) {
    return EditProfileUiState(
      loading: loading ?? this.loading,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      saving: saving ?? this.saving,
      error: error != null ? error() : this.error,
      saved: saved ?? this.saved,
    );
  }
}

/// El paciente edita su nombre, teléfono y fecha de nacimiento con `PATCH patients/{id}`.
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel({required this.session, required this.getPatientUseCase, required this.updatePatientProfileUseCase});

  final SessionViewModel session;
  final GetStaffPatientUseCase getPatientUseCase;
  final UpdatePatientProfileUseCase updatePatientProfileUseCase;

  static final _display = DateFormat('dd/MM/yyyy');

  EditProfileUiState _state = const EditProfileUiState();
  EditProfileUiState get state => _state;

  void _emit(EditProfileUiState value) {
    _state = value;
    notifyListeners();
  }

  Future<void> load() async {
    final current = session.session;
    if (current == null || !current.isPatient) {
      _emit(_state.copyWith(loading: false, error: () => 'Inicia sesión para editar tu perfil.'));
      return;
    }
    try {
      final patient = await getPatientUseCase.execute(current.patientId);
      _emit(_state.copyWith(
        loading: false,
        name: patient.fullName,
        email: patient.email,
        phone: patient.phone,
        birthDate: patient.birthDate == null ? '' : _display.format(patient.birthDate!),
      ));
    } catch (e) {
      _emit(_state.copyWith(
        loading: false,
        name: current.name,
        email: current.email,
        phone: current.phone,
        error: () => e is ApiException ? e.message : 'No se pudieron cargar tus datos.',
      ));
    }
  }

  void onName(String value) => _emit(_state.copyWith(name: value, error: () => null));
  void onPhone(String value) => _emit(_state.copyWith(phone: value, error: () => null));
  void onBirthDate(String value) => _emit(_state.copyWith(birthDate: value, error: () => null));

  Future<void> save() async {
    final current = session.session;
    if (_state.saving || current == null) return;
    final name = _state.name.trim();
    final phone = _state.phone.trim();
    if (name.length < 2) return _emit(_state.copyWith(error: () => 'Escribe tu nombre completo.'));
    if (phone.isEmpty) return _emit(_state.copyWith(error: () => 'Escribe tu teléfono.'));
    DateTime? birthDate;
    if (_state.birthDate.trim().isNotEmpty) {
      birthDate = _parseBirthDate(_state.birthDate);
      if (birthDate == null) return _emit(_state.copyWith(error: () => 'Escribe la fecha como 24/05/1990.'));
    }
    _emit(_state.copyWith(saving: true, error: () => null));
    try {
      final patient = await updatePatientProfileUseCase.execute(current.patientId, name: name, phone: phone, birthDate: birthDate);
      // Inicio y Mi Perfil leen el nombre de la sesión.
      session.updateProfile(name: patient.fullName.isEmpty ? name : patient.fullName, phone: patient.phone.isEmpty ? phone : patient.phone);
      _emit(_state.copyWith(saving: false, saved: true));
    } catch (e) {
      _emit(_state.copyWith(saving: false, error: () => e is ApiException ? e.message : 'No se pudo guardar tu perfil.'));
    }
  }

  /// "24/05/1990" → fecha; null si no es una fecha pasada válida.
  static DateTime? _parseBirthDate(String text) {
    final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text.trim());
    if (match == null) return null;
    final day = int.parse(match[1]!), month = int.parse(match[2]!), year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) return null;
    return date.isBefore(DateTime.now()) ? date : null;
  }
}
