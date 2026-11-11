import '../../domain/entities/models.dart';

class PatientDto {
  const PatientDto({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.token,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String? token;

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

  factory PatientDto.fromLogin(Map<String, dynamic> json, {required String email}) {
    final patient = Map<String, dynamic>.from(json['patient'] as Map? ?? const {});
    final token = '${json['token'] ?? ''}';
    return PatientDto(
      id: '${patient['id']}',
      name: '${patient['name'] ?? ''}',
      email: '${patient['email'] ?? email}',
      phone: '${patient['phone'] ?? ''}',
      token: token,
    );
  }

  PatientSession toEntity() {
    return PatientSession(
      patientId: id,
      token: token,
      name: name,
      email: email,
      phone: phone,
    );
  }
}
