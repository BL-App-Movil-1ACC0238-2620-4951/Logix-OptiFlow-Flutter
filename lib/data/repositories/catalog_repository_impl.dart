import '../../domain/entities/frame.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_local_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  @override
  List<FrameItem> frames() => CatalogLocalDataSource.frames;

  @override
  FrameItem frame(String id) => CatalogLocalDataSource().frame(id);
}
