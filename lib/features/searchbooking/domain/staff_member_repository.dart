import 'package:logix_optiflow/features/searchbooking/domain/staff_member.dart';

abstract class StaffMemberRepository {
  Future<List<StaffMember>> list(String opticalStoreId);

  Future<StaffMember> register({
    required String name,
    required String email,
    required String password,
    required String opticalStoreId,
    required String role,
  });

  Future<StaffMember> assignRole(String id, String role);

  Future<StaffMember> updateStatus(String id, bool active);
}
