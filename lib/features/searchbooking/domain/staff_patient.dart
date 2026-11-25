class StaffPatient {
  const StaffPatient({
    required this.id,
    required this.initials,
    required this.name,
    required this.fullName,
    required this.rut,
    required this.note,
    required this.phone,
    required this.lastVisit,
    required this.ficha,
    required this.age,
    this.email = '',
    this.birthDate,
    this.createdAt,
  });

  final String id;
  final String initials;
  final String name;
  final String fullName;
  final String rut;
  final String note;
  final String phone;
  final String lastVisit;
  final String ficha;
  final int age;
  final String email;
  final DateTime? birthDate;
  final DateTime? createdAt;
}
