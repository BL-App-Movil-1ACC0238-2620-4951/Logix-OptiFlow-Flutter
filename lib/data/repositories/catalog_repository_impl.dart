import '../../domain/entities/frame.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/demo_data.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  @override
  List<FrameItem> frames() => DemoData.frames;

  @override
  FrameItem frame(String id) => DemoData.frame(id);
}
