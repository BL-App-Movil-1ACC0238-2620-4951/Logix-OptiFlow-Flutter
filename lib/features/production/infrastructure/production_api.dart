import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/production/domain/staff_order.dart';
import 'package:logix_optiflow/features/production/domain/work_order_detail.dart';
import 'package:logix_optiflow/features/production/infrastructure/staff_order_dto.dart';
import 'package:logix_optiflow/features/production/infrastructure/work_order_detail_dto.dart';
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

  Future<WorkOrderDetail> workOrder(String id) async => _detail(await _client.get('work-orders/$id'));
  Future<WorkOrderDetail> assignTechnician(String id, String technicianId) async =>
      _detail(await _client.send('PATCH', 'work-orders/$id/technician', {'technicianId': technicianId}));
  Future<WorkOrderDetail> sendToLaboratory(String id, String laboratoryId) async =>
      _detail(await _client.send('PATCH', 'work-orders/$id/laboratory', {'laboratoryId': laboratoryId}));
  /// La respuesta solo trae el estado nuevo.
  Future<void> updateStatus(String id, String status) => _client.send('PATCH', 'work-orders/$id/status', {'status': status});
  /// Sin `lensIds` se marcan todos los lentes.
  Future<WorkOrderDetail> completeLenses(String id, List<String>? lensIds) async =>
      _detail(await _client.send('PATCH', 'work-orders/$id/lenses', {if (lensIds != null) 'lensIds': lensIds}));
  Future<WorkOrderDetail> notifyDelay(String id, String reason, String newEstimatedDeliveryDate) async => _detail(
      await _client.send('POST', 'work-orders/$id/delays', {'reason': reason, 'newEstimatedDeliveryDate': newEstimatedDeliveryDate}));
  Future<List<NamedRef>> technicians() async => _refs(await _client.get('technicians'));
  Future<List<NamedRef>> laboratories() async => _refs(await _client.get('laboratories'));

  WorkOrderDetail _detail(Object? json) {
    if (json is! Map) throw ApiException('El servidor devolvió una orden de trabajo inválida.');
    return WorkOrderDetailDto.fromJson(Map<String, dynamic>.from(json));
  }

  List<NamedRef> _refs(Object? json) => _list(json).map(WorkOrderDetailDto.namedRef).whereType<NamedRef>().toList();

  List<Map<String, dynamic>> _list(Object? json) => _client.mapList(json, 'El servidor devolvió una lista del personal inválida.');
}
