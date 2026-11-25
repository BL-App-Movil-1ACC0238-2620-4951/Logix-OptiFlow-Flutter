import 'package:flutter/foundation.dart';

import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/features/auth/domain/user_role.dart';
import 'package:logix_optiflow/features/searchbooking/application/assign_staff_role_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/get_staff_members_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/register_staff_member_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/application/update_staff_member_status_use_case.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_member.dart';

/// Roles que el admin puede dar, en el orden de Kotlin.
const staffRoles = [UserRole.optometrist, UserRole.salesAdvisor, UserRole.technician, UserRole.admin];

String staffRoleLabel(String role) => switch (UserRole.fromApi(role)) {
      UserRole.optometrist => 'Optometrista',
      UserRole.salesAdvisor => 'Asesor de ventas',
      UserRole.technician => 'Técnico de laboratorio',
      UserRole.admin => 'Administrador',
      _ => role,
    };

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class StaffMembersUiState {
  const StaffMembersUiState({
    this.loading = true,
    this.members = const [],
    this.showForm = false,
    this.role = UserRole.optometrist,
    this.editingId,
    this.saving = false,
    this.message,
    this.error,
  });

  final bool loading;
  final List<StaffMember> members;
  final bool showForm;
  final UserRole role;
  /// Empleado cuyo rol se está cambiando.
  final String? editingId;
  final bool saving;
  final String? message;
  final String? error;

  StaffMembersUiState copyWith({
    bool? loading,
    List<StaffMember>? members,
    bool? showForm,
    UserRole? role,
    ValueGetter<String?>? editingId,
    bool? saving,
    ValueGetter<String?>? message,
    ValueGetter<String?>? error,
  }) {
    return StaffMembersUiState(
      loading: loading ?? this.loading,
      members: members ?? this.members,
      showForm: showForm ?? this.showForm,
      role: role ?? this.role,
      editingId: editingId != null ? editingId() : this.editingId,
      saving: saving ?? this.saving,
      message: message != null ? message() : this.message,
      error: error != null ? error() : this.error,
    );
  }
}

/// Personal de la óptica del admin: alta, cambio de rol y activación (`staff-members`).
class StaffMembersViewModel extends ChangeNotifier {
  StaffMembersViewModel({
    required this.getStaffMembersUseCase,
    required this.registerStaffMemberUseCase,
    required this.assignStaffRoleUseCase,
    required this.updateStaffMemberStatusUseCase,
  });

  final GetStaffMembersUseCase getStaffMembersUseCase;
  final RegisterStaffMemberUseCase registerStaffMemberUseCase;
  final AssignStaffRoleUseCase assignStaffRoleUseCase;
  final UpdateStaffMemberStatusUseCase updateStaffMemberStatusUseCase;

  StaffMembersUiState _state = const StaffMembersUiState();
  StaffMembersUiState get state => _state;
  String? _storeId;
  bool _disposed = false;

  void _emit(StaffMembersUiState value) {
    _state = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load(String? storeId) async {
    if (storeId == null || storeId.isEmpty) return;
    _storeId = storeId;
    try {
      final list = await getStaffMembersUseCase.execute(storeId);
      _emit(_state.copyWith(loading: false, members: list));
    } catch (e) {
      _emit(_state.copyWith(loading: false, error: () => _message(e, 'No se pudo cargar el personal.')));
    }
  }

  void showForm(bool show) =>
      _emit(_state.copyWith(showForm: show, role: UserRole.optometrist, error: () => null, message: () => null));

  void nextRole() => _emit(_state.copyWith(role: staffRoles[(staffRoles.indexOf(_state.role) + 1) % staffRoles.length]));

  void editRole(String? id) => _emit(_state.copyWith(editingId: () => id, error: () => null, message: () => null));

  Future<void> register({required String name, required String email, required String password}) async {
    final store = _storeId;
    if (store == null) return;
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final error = cleanName.isEmpty
        ? 'Escribe el nombre.'
        : !_email.hasMatch(cleanEmail)
            ? 'Escribe un correo válido.'
            : password.length < 8
                ? 'La contraseña temporal debe tener al menos 8 caracteres.'
                : null;
    if (error != null) {
      _emit(_state.copyWith(error: () => error));
      return;
    }
    final role = _state.role.apiValue;
    await _save(
      'Se registró a $cleanName como ${staffRoleLabel(role).toLowerCase()}.',
      () => registerStaffMemberUseCase.execute(name: cleanName, email: cleanEmail, password: password, opticalStoreId: store, role: role),
      closeForm: true,
    );
  }

  Future<void> changeRole(StaffMember member, UserRole role) => _save(
        '${member.name} ahora es ${staffRoleLabel(role.apiValue).toLowerCase()}; rige desde su siguiente inicio de sesión.',
        () => assignStaffRoleUseCase.execute(member.id, role.apiValue),
      );

  Future<void> toggleActive(StaffMember member) => _save(
        member.active ? '${member.name} ya no puede iniciar sesión.' : '${member.name} puede volver a iniciar sesión.',
        () => updateStaffMemberStatusUseCase.execute(member.id, !member.active),
      );

  Future<void> _save(String done, Future<StaffMember> Function() call, {bool closeForm = false}) async {
    if (_state.saving) return;
    _emit(_state.copyWith(saving: true, error: () => null, message: () => null));
    try {
      final updated = await call();
      final members = [..._state.members.where((m) => m.id != updated.id), updated]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _emit(_state.copyWith(
        saving: false,
        members: members,
        message: () => done,
        editingId: () => null,
        showForm: closeForm ? false : _state.showForm,
      ));
    } catch (e) {
      _emit(_state.copyWith(saving: false, error: () => _message(e, 'No se pudo guardar el cambio.')));
    }
  }

  String _message(Object error, String fallback) => error is ApiException ? error.message : fallback;
}
