import 'package:logix_optiflow/features/searchbooking/domain/staff_member.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_member_repository.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/search_booking_api.dart';

class StaffMemberRepositoryImpl implements StaffMemberRepository {
  const StaffMemberRepositoryImpl({required this.api});

  final SearchBookingApi api;

  @override
  Future<List<StaffMember>> list(String opticalStoreId) => api.staffMembers(opticalStoreId);

  @override
  Future<StaffMember> register({
    required String name,
    required String email,
    required String password,
    required String opticalStoreId,
    required String role,
  }) =>
      api.registerStaffMember(name: name, email: email, password: password, opticalStoreId: opticalStoreId, role: role);

  @override
  Future<StaffMember> assignRole(String id, String role) => api.assignStaffRole(id, role);

  @override
  Future<StaffMember> updateStatus(String id, bool active) => api.updateStaffMemberStatus(id, active);
}
