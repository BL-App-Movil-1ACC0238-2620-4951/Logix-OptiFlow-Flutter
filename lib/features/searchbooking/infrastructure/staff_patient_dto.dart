import 'package:logix_optiflow/core/time/store_time.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';

abstract final class StaffPatientDto {
  static StaffPatient fromJson(Map<String, dynamic> json, {DateTime? today}) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final birth = DateTime.tryParse(json['birthDate'] as String? ?? '');
    final date = today ?? StoreTime.today();
    final age = birth == null ? 0 : date.year - birth.year - (date.month < birth.month || (date.month == birth.month && date.day < birth.day) ? 1 : 0);
    final created = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final registered = created == null ? null : StoreTime.day(created);
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return StaffPatient(
      id: id, fullName: name, name: parts.take(2).join(' '),
      initials: parts.take(2).map((s) => s[0].toUpperCase()).join(),
      email: json['email'] as String? ?? '', phone: json['phone'] as String? ?? '',
      birthDate: birth, createdAt: created, age: age,
      rut: '-', note: registered == null ? 'Paciente registrado' : 'Registrado el ${registered.day} ${months[registered.month - 1]} ${registered.year}',
      lastVisit: '-', ficha: id.substring(0, id.length < 8 ? id.length : 8).toUpperCase(),
    );
  }
}
