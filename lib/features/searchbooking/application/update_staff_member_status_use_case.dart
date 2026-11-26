import 'package:logix_optiflow/features/searchbooking/domain/staff_member.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_member_repository.dart';

/// Activa o desactiva el acceso (`PATCH staff-members/{id}/status`).
class UpdateStaffMemberStatusUseCase {
  const UpdateStaffMemberStatusUseCase({required this.repository});

  final StaffMemberRepository repository;

  Future<StaffMember> execute(String id, bool active) => repository.updateStatus(id, active);
}
