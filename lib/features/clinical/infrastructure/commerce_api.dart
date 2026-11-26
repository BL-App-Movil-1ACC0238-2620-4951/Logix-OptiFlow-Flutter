import 'package:logix_optiflow/core/errors/api_exception.dart';
import 'package:logix_optiflow/core/network/api_client.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/commerce_dto.dart';

/// Cotizaciones y ventas (contexto Clinical & Commercial).
class CommerceApi {
  const CommerceApi(this._client);

  final ApiClient _client;

  Future<List<Quotation>> recordQuotations(String recordId) async => _list(await _client.get('clinical-records/${Uri.encodeComponent(recordId)}/quotations')).map(CommerceDto.quotation).toList();
  Future<Quotation> quotation(String id) async => CommerceDto.quotation(Map<String, dynamic>.from(await _client.get('quotations/${Uri.encodeComponent(id)}') as Map));
  Future<Quotation> generateQuotation(String recordId, List<QuotationItem> items) async => CommerceDto.quotation(Map<String, dynamic>.from(await _client.send('POST', 'quotations', {'clinicalRecordId': recordId, 'items': items.map(CommerceDto.item).toList()}) as Map));
  Future<Quotation> discountQuotation(String id, String type, num value, String? reason) async => CommerceDto.quotation(Map<String, dynamic>.from(await _client.send('PATCH', 'quotations/${Uri.encodeComponent(id)}/discount', {'type': type, 'value': value, 'reason': reason}) as Map));
  Future<Quotation> updateQuotation(String id, QuotationStatus status, {String? reason}) async => CommerceDto.quotation(Map<String, dynamic>.from(await _client.send('PATCH', 'quotations/${Uri.encodeComponent(id)}/status', {'status': status.name.toUpperCase(), 'reason': reason}) as Map));
  Future<List<Sale>> patientSales(String patientId) async => _list(await _client.get('patients/${Uri.encodeComponent(patientId)}/sales')).map(CommerceDto.sale).toList();
  Future<Sale> sale(String id) async => CommerceDto.sale(Map<String, dynamic>.from(await _client.get('sales/${Uri.encodeComponent(id)}') as Map));
  Future<Sale> registerSale(String quotationId) async => CommerceDto.sale(Map<String, dynamic>.from(await _client.send('POST', 'sales', {'quotationId': quotationId}) as Map));
  Future<Sale> paySaleCash(String id, num amount) async => CommerceDto.sale(Map<String, dynamic>.from(await _client.send('POST', 'sales/${Uri.encodeComponent(id)}/payments', {'amount': amount}) as Map));
  /// Link de Checkout Pro de Mercado Pago para pagar una venta pendiente.
  Future<String> paymentLink(String id) async {
    final json = await _client.send('POST', 'sales/${Uri.encodeComponent(id)}/payment-preference', const {});
    final url = json is Map ? json['initPoint']?.toString() : null;
    if (url == null || url.isEmpty) throw ApiException('No se pudo generar el link de pago.');
    return url;
  }
  Future<Sale> closeSale(String id) async => CommerceDto.sale(Map<String, dynamic>.from(await _client.send('PATCH', 'sales/${Uri.encodeComponent(id)}/status', {'status': 'CLOSED'}) as Map));

  List<Map<String, dynamic>> _list(Object? json) => _client.mapList(json, 'El servidor devolvió una lista del personal inválida.');
}
