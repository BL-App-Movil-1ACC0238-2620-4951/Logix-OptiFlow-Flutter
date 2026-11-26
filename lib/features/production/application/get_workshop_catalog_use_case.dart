import 'package:logix_optiflow/features/production/domain/production_repository.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';

class GetWorkshopCatalogUseCase {
  const GetWorkshopCatalogUseCase({required this.repository});

  final ProductionRepository repository;

  Future<WorkshopCatalog> execute() => repository.workshopCatalog();
}
