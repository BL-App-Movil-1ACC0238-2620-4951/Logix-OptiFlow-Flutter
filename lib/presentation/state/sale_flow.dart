import '../../core/errors/api_exception.dart';
import '../../domain/entities/commerce.dart';
import '../../domain/entities/staff_patient.dart';
import '../../domain/repositories/commerce_repository.dart';

/// Movile's SaleViewModel. A confirmed payment survives a failed close.
class SaleFlow {
  SaleFlow({required this.repository, required this.patientId, this.saleId, this.onChanged, this.onClosed, bool Function()? isActive}) : _isActive = isActive ?? (() => true);
  final CommerceRepository repository;
  final String patientId;
  final String? saleId;
  final bool Function() _isActive;
  void Function()? onChanged;
  final Future<void> Function()? onClosed;
  bool _disposed = false, _loaded = false;
  bool loading = false, saving = false;
  String? loadError, error;
  StaffPatient? patient;
  List<Sale> sales = [];
  Sale? sale;
  Quotation? quotation;
  bool get active => !_disposed && _isActive();
  bool get canSave => active && _loaded && !loading && !saving && loadError == null && sale != null && sale!.status != SaleStatus.closed;
  void _emit() { if (active) onChanged?.call(); }
  void dispose() { _disposed = true; onChanged = null; }
  String _message(Object e) => e is ApiException ? e.message : 'No se pudo completar la venta. Intenta nuevamente.';
  void _checkSale(Sale value) {
    if (value.id != saleId || value.patientId != patientId || (sale != null && value.quotationId != sale!.quotationId)) throw ApiException('La venta recibida no corresponde al paciente o cotización solicitados.');
  }
  Future<void> refresh() async {
    if (!active || loading || saving) return;
    loading = true; _loaded = false; loadError = null; error = null; _emit();
    try {
      final profile = await repository.patient(patientId);
      if (!active) return;
      if (profile.id != patientId) throw ApiException('No se encontró al paciente solicitado.');
      patient = profile;
      if (saleId == null) {
        final values = await repository.sales(patientId);
        if (!active) return;
        if (values.any((s) => s.patientId != patientId)) throw ApiException('Las ventas recibidas no corresponden al paciente.');
        sales = [...values]..sort((a, b) => a.status.index.compareTo(b.status.index));
      } else {
        await _readSale();
      }
      if (active) _loaded = true;
    } catch (e) { if (active) loadError = _message(e); }
    finally { if (active) { loading = false; _emit(); } }
  }
  Future<void> _readSale() async {
    final fresh = await repository.sale(saleId!);
    if (!active) return;
    _checkSale(fresh); sale = fresh;
    final quote = await repository.quotation(fresh.quotationId);
    if (!active) return;
    if (quote.id != fresh.quotationId || quote.currency != 'PEN' || quote.status != QuotationStatus.approved) throw ApiException('La cotización recibida no coincide con esta venta aprobada.');
    quotation = quote;
  }
  Future<void> payCashAndClose() => _finish(allowCash: true);
  Future<void> closePaidSale() => _finish(allowCash: false);
  Future<void> _finish({required bool allowCash}) async {
    if (!canSave) return;
    saving = true; error = null; _emit();
    try {
      // Refresh first: another device or an earlier lost response may have paid it.
      await _readSale();
      if (!active) return;
      if (sale!.status == SaleStatus.pendingPayment) {
        if (!allowCash) throw ApiException('La venta todavía está pendiente de pago.');
        final amount = quotation!.total;
        if (!amount.isFinite || amount <= 0 || amount > 99999999.99) throw ApiException('El total no es válido para registrar un pago en efectivo.');
        final paid = await repository.payCash(saleId!, amount);
        if (!active) return;
        _checkSale(paid);
        if (paid.status != SaleStatus.paid && paid.status != SaleStatus.closed) throw ApiException('El servidor aún no confirmó el pago. Actualiza el estado antes de continuar.');
        sale = paid; _emit();
      }
      if (sale!.status == SaleStatus.paid) {
        final closed = await repository.close(saleId!);
        if (!active) return;
        _checkSale(closed);
        if (closed.status != SaleStatus.closed) throw ApiException('El servidor aún no confirmó el cierre.');
        sale = closed;
      }
      if (active && sale!.status == SaleStatus.closed) {
        _emit();
        // Follow-up reads never turn a committed close into a failed sale.
        try { await onClosed?.call(); } catch (_) {}
      }
    } catch (e) { if (active) error = _message(e); }
    finally { if (active) { saving = false; _emit(); } }
  }
}
