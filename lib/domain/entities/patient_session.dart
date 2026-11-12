import 'user_role.dart';

class PatientSession {
  const PatientSession({
    required this.patientId,
    required this.name,
    required this.email,
    this.token,
    this.phone = '',
    this.role = UserRole.patient,
    this.expiresAt,
    this.opticalStoreId,
  });

  final String patientId;
  final String? token;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final DateTime? expiresAt;
  final String? opticalStoreId;

  bool get hasToken => token != null && token!.trim().isNotEmpty;
  bool get isPatient => role == UserRole.patient;
  bool get isExpired => expiresAt != null && !expiresAt!.isAfter(DateTime.now());
  bool get isAuthenticated => hasToken && patientId.trim().isNotEmpty && !isExpired;

  PatientSession copyWith({String? name, String? email, String? phone, String? token}) {
    return PatientSession(
      patientId: patientId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      role: role,
      expiresAt: expiresAt,
      opticalStoreId: opticalStoreId,
    );
  }
}
