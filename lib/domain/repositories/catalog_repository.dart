import '../entities/frame.dart';

abstract class CatalogRepository {
  List<FrameItem> frames();

  FrameItem frame(String id);
}
