import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/production_order.dart';
import '../../domain/entities/staff_alert.dart';
import '../../domain/entities/staff_patient.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_local_data_source.dart';

class StaffRepositoryImpl implements StaffRepository {
  StaffRepositoryImpl([StaffLocalDataSource? local]) : _local = local ?? StaffLocalDataSource();

  final StaffLocalDataSource _local;

  @override
  List<StaffPatient> patients() => StaffLocalDataSource.patients;

  @override
  List<AgendaItem> agenda() => StaffLocalDataSource.agenda;

  @override
  List<ProductItem> products() => StaffLocalDataSource.products;

  @override
  ProductItem product(String id) => _local.product(id);

  @override
  List<ProductionOrder> productionOrders() => StaffLocalDataSource.productionOrders;

  @override
  List<StaffAlert> alerts() => StaffLocalDataSource.alerts;

  @override
  List<double> reportBars() => StaffLocalDataSource.reportBars;
}
