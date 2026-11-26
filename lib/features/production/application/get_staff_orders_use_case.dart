import 'package:logix_optiflow/features/production/domain/production_repository.dart';
import 'package:logix_optiflow/features/production/domain/staff_order.dart';

class GetStaffOrdersUseCase {
  const GetStaffOrdersUseCase({required this.repository});

  final ProductionRepository repository;

  Future<List<StaffOrder>> execute() => repository.orders();
}
