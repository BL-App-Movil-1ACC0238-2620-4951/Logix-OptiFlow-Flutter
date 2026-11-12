import '../../domain/entities/models.dart';

class PatientDto {
  const PatientDto({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.token,
    this.role = UserRole.patient,
    this.expiresAt,
    this.opticalStoreId,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String? token;
  final UserRole role;
  final DateTime? expiresAt;
  final String? opticalStoreId;

  factory PatientDto.fromRegister(
    Map<String, dynamic> json, {
    required String name,
    required String email,
    required String phone,
  }) {
    return PatientDto(
      id: '${json['id']}',
      name: '${json['name'] ?? name}',
      email: '${json['email'] ?? email}',
      phone: '${json['phone'] ?? phone}',
    );
  }

  factory PatientDto.fromLogin(
    Map<String, dynamic> json, {
    required String email,
    Map<String, dynamic> profile = const {},
  }) {
    final id = json['userId'] as String?;
    final token = json['token'] as String?;
    final role = UserRole.fromApi(json['role'] as String?);
    if (id == null || id.trim().isEmpty || token == null || token.trim().isEmpty || role == null) {
      throw const FormatException('Respuesta de autenticación inválida.');
    }
    final expiresAt = json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt'] as String);
    return PatientDto(
      id: id,
      name: '${profile['name'] ?? ''}',
      email: '${profile['email'] ?? email}',
      phone: '${profile['phone'] ?? ''}',
      token: token,
      role: role,
      expiresAt: expiresAt,
      opticalStoreId: profile['opticalStoreId'] as String?,
    );
  }

  PatientSession toEntity() {
    return PatientSession(
      patientId: id,
      token: token,
      name: name,
      email: email,
      phone: phone,
      role: role,
      expiresAt: expiresAt,
      opticalStoreId: opticalStoreId,
    );
  }
}
