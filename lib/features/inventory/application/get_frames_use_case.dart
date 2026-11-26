import 'package:logix_optiflow/features/inventory/domain/catalog_repository.dart';
import 'package:logix_optiflow/features/inventory/domain/frame.dart';

class GetFramesUseCase {
  const GetFramesUseCase({required this.repository});

  final CatalogRepository repository;

  Future<List<FrameItem>> execute() => repository.frames();
}
