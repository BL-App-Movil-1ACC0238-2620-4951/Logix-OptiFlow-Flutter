import 'package:logix_optiflow/features/searchbooking/domain/staff_member.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_member_repository.dart';

/// El personal de una óptica (`GET staff-members?opticalStoreId=`).
class GetStaffMembersUseCase {
  const GetStaffMembersUseCase({required this.repository});

  final StaffMemberRepository repository;

  Future<List<StaffMember>> execute(String opticalStoreId) => repository.list(opticalStoreId);
}
