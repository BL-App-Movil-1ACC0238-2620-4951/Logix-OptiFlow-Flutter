import '../entities/frame.dart';
import '../repositories/catalog_repository.dart';

class GetFrames {
  const GetFrames(this._catalog);

  final CatalogRepository _catalog;

  List<FrameItem> call() => _catalog.frames();
}

class GetFrame {
  const GetFrame(this._catalog);

  final CatalogRepository _catalog;

  FrameItem call(String id) => _catalog.frame(id);
}
