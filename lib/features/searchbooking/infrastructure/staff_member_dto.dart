import 'package:logix_optiflow/features/searchbooking/domain/staff_member.dart';

abstract final class StaffMemberDto {
  static StaffMember fromJson(Map<String, dynamic> json) => StaffMember(
        id: '${json['id']}',
        opticalStoreId: '${json['opticalStoreId'] ?? ''}',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
        active: json['active'] as bool? ?? true,
      );
}
