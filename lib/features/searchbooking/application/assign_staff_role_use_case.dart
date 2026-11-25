import 'package:logix_optiflow/features/searchbooking/domain/staff_member.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_member_repository.dart';

/// Cambia el rol (`PATCH staff-members/{id}/role`); rige desde el siguiente inicio de sesión.
class AssignStaffRoleUseCase {
  const AssignStaffRoleUseCase({required this.repository});

  final StaffMemberRepository repository;

  Future<StaffMember> execute(String id, String role) => repository.assignRole(id, role);
}
