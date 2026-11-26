import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/production/domain/staff_order.dart';
import 'package:logix_optiflow/features/production/infrastructure/staff_order_dto.dart';
import 'package:logix_optiflow/features/production/infrastructure/work_order_dto.dart';

/// Órdenes de trabajo (contexto Production & Tracking).
class ProductionApi {
  const ProductionApi(this._client);

  final ApiClient _client;

  Future<List<WorkOrderDto>> workOrders(String patientId) async {
    final json = await _client.get('patients/$patientId/work-orders');
    final list = json is List ? json : const [];
    return list.whereType<Map>().map((e) => WorkOrderDto.fromJson(Map<String, dynamic>.from(e))).toList();
  }
  Future<List<StaffOrder>> staffOrders() async => _list(await _client.get('work-orders')).map(StaffOrderDto.fromJson).toList();

  List<Map<String, dynamic>> _list(Object? json) => _client.mapList(json, 'El servidor devolvió una lista del personal inválida.');
}
