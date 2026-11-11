class PatientSession {
  const PatientSession({
    required this.patientId,
    required this.name,
    required this.email,
    this.token,
    this.phone = '',
  });

  final String patientId;
  final String? token;
  final String name;
  final String email;
  final String phone;

  bool get hasToken => token != null && token!.isNotEmpty;

  PatientSession copyWith({String? name, String? email, String? phone, String? token}) {
    return PatientSession(
      patientId: patientId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      token: token ?? this.token,
    );
  }
}
