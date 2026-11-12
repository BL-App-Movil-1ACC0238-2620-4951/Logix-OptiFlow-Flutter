enum QuotationStatus { draft, approved, rejected }
enum SaleStatus { pendingPayment, paid, closed }

class QuotationItem {
  const QuotationItem({required this.type, this.sku, required this.description, required this.unitPrice, this.quantity = 1});
  final String type;
  final String? sku;
  final String description;
  final num unitPrice;
  final int quantity;
  num get subtotal => unitPrice * quantity;
}

class QuotationDiscount {
  const QuotationDiscount({required this.type, required this.value, required this.amount, this.reason});
  final String type;
  final num value;
  final num amount;
  final String? reason;
}

class Quotation {
  const Quotation({required this.id, required this.recordId, required this.items, required this.subtotal, required this.total, required this.currency, required this.status, this.discount, this.rejectionReason});
  final String id;
  final String recordId;
  final List<QuotationItem> items;
  final num subtotal;
  final num total;
  final String currency;
  final QuotationStatus status;
  final QuotationDiscount? discount;
  final String? rejectionReason;
}

class Sale {
  const Sale({required this.id, required this.quotationId, required this.patientId, required this.status, this.closedAt, this.paymentMethod, this.paymentStatus, this.amount, this.receiptNumber});
  final String id;
  final String quotationId;
  final String patientId;
  final SaleStatus status;
  final DateTime? closedAt;
  final String? paymentMethod;
  final String? paymentStatus;
  final num? amount;
  final String? receiptNumber;
}

class QuoteOption {
  const QuoteOption(this.name, this.price);
  final String name;
  final num price;
}

// Movile's suggested options: the API has no lens or treatment catalogue.
const lensOptions = [QuoteOption('Monofocal 1.56', 120), QuoteOption('Monofocal 1.60 delgado', 180), QuoteOption('Bifocal', 250), QuoteOption('Progresivo', 420)];
const treatmentOptions = [QuoteOption('Antirreflejo', 60), QuoteOption('Filtro de luz azul', 80), QuoteOption('Fotocromático', 150)];

num? commerceAmount(String input) {
  final value = input.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(value)) return null;
  return num.tryParse(value);
}

String soles(num amount) => 'S/ ${amount.toStringAsFixed(2)}';
String saleStatusLabel(SaleStatus status) => switch (status) {
  SaleStatus.pendingPayment => 'Pendiente de pago', SaleStatus.paid => 'Pagada', SaleStatus.closed => 'Cerrada',
};
String paymentMethodLabel(String? method) => switch (method) { 'CASH' => 'Efectivo', 'CARD' => 'Tarjeta', 'YAPE' => 'Yape', null => '-', _ => method };
