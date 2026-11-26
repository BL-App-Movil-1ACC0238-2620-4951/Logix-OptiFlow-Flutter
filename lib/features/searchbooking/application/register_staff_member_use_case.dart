import 'package:logix_optiflow/features/searchbooking/domain/staff_member.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_member_repository.dart';

/// Alta de un miembro del personal con una contraseña temporal (`POST staff-members`).
class RegisterStaffMemberUseCase {
  const RegisterStaffMemberUseCase({required this.repository});

  final StaffMemberRepository repository;

  Future<StaffMember> execute({required String name, required String email, required String password, required String opticalStoreId, required String role}) => repository.register(name: name, email: email, password: password, opticalStoreId: opticalStoreId, role: role);
}
