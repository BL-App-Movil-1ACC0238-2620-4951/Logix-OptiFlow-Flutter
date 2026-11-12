import '../../core/errors/api_exception.dart';
import '../../domain/entities/commerce.dart';

abstract final class CommerceDto {
  static String _id(Map json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) throw ApiException('El servidor devolvió un identificador comercial inválido.');
    return value;
  }
  static num _amount(Object? value) {
    if (value is! num || !value.isFinite || value < 0) throw ApiException('El servidor devolvió un importe inválido.');
    return value;
  }
  static Quotation quotation(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'DRAFT' => QuotationStatus.draft, 'APPROVED' => QuotationStatus.approved, 'REJECTED' => QuotationStatus.rejected,
      _ => throw ApiException('El servidor devolvió un estado de cotización desconocido.'),
    };
    final rawItems = json['items'];
    if (rawItems is! List || rawItems.isEmpty) throw ApiException('La cotización recibida no tiene productos.');
    final discount = json['discount'] as Map?;
    return Quotation(
      id: _id(json, 'id'), recordId: _id(json, 'clinicalRecordId'), status: status,
      items: List.unmodifiable(rawItems.map((raw) {
        final item = raw as Map;
        final qty = item['quantity'];
        if (qty is! num || qty != qty.toInt() || qty < 1 || qty > 100) throw ApiException('La cantidad recibida no es válida.');
        return QuotationItem(type: _id(item, 'itemType'), sku: item['productSku'] as String?, description: _id(item, 'description'), unitPrice: _amount(item['unitPrice']), quantity: qty.toInt());
      })),
      subtotal: _amount(json['subtotal']), total: _amount(json['total']), currency: _id(json, 'currency'),
      rejectionReason: json['rejectionReason'] as String?,
      discount: discount == null ? null : QuotationDiscount(type: _id(discount, 'type'), value: _amount(discount['value']), amount: _amount(discount['amount']), reason: discount['reason'] as String?),
    );
  }
  static Sale sale(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'PENDING_PAYMENT' => SaleStatus.pendingPayment, 'PAID' => SaleStatus.paid, 'CLOSED' => SaleStatus.closed,
      _ => throw ApiException('El servidor devolvió un estado de venta desconocido.'),
    };
    final payment = json['payment'] as Map?;
    final receipt = json['receipt'] as Map?;
    return Sale(
      id: _id(json, 'id'), quotationId: _id(json, 'quotationId'), patientId: _id(json, 'patientId'), status: status,
      closedAt: json['closedAt'] == null ? null : DateTime.parse(json['closedAt'] as String),
      paymentMethod: payment?['method'] as String?, paymentStatus: payment?['status'] as String?,
      amount: payment?['amount'] == null ? null : _amount(payment!['amount']), receiptNumber: receipt?['receiptNumber'] as String?,
    );
  }
  static Map<String, Object?> item(QuotationItem item) => {'itemType': item.type, 'productSku': item.sku, 'description': item.description, 'unitPrice': item.unitPrice, 'quantity': item.quantity};
}
