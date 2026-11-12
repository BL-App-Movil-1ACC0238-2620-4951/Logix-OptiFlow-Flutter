import '../../domain/entities/staff_patient.dart';
import '../../domain/entities/staff_order.dart';
import '../../domain/entities/store_time.dart';

abstract final class StaffDto {
  static StaffPatient patient(Map<String, dynamic> json, {DateTime? today}) {
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

  static StaffOrder order(Map<String, dynamic> json) {
    final lenses = json['lenses'] as List? ?? [];
    return StaffOrder(
      id: json['id'] as String, patientId: json['patientId'] as String?, status: json['status'] as String,
      detail: lenses.isEmpty ? 'Sin lentes' : '${lenses.length} lentes · ${lenses.first['specifications'] ?? ''}',
      dueDate: json['estimatedDeliveryDate'] as String?, delayed: json['delayed'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
