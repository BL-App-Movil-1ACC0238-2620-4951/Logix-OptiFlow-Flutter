import '../../core/errors/api_exception.dart';
import '../../domain/entities/clinical_record.dart';
import '../../domain/entities/commerce.dart';
import '../../domain/entities/frame.dart';
import '../../domain/entities/staff_patient.dart';
import '../../domain/repositories/commerce_repository.dart';

/// Movile's QuoteViewModel, with persisted drafts and guarded HTTP retries.
class QuoteFlow {
  QuoteFlow({required this.repository, required this.patientId, this.storeId, this.onChanged, bool Function()? isActive}) : _isActive = isActive ?? (() => true);
  final CommerceRepository repository;
  final String patientId;
  final String? storeId;
  final bool Function() _isActive;
  void Function()? onChanged;
  bool _disposed = false, _loaded = false;
  bool loading = false, saving = false;
  String? loadError, error, catalogWarning, stockWarning, lastRejectedReason;
  StaffPatient? patient;
  ClinicalRecord? record;
  List<FrameItem> frames = [];
  Map<String, int> stock = {};
  Quotation? quotation;
  Sale? sale;
  String? frameSku;
  int? lensIndex;
  String lensPrice = '', discountValue = '', discountReason = '', rejectReason = '';
  bool discountIsPercentage = true, showReject = false;
  Set<String> treatments = {};

  bool get active => !_disposed && _isActive();
  bool get canSave => active && _loaded && !loading && !saving && loadError == null;
  bool get editable => canSave && quotation == null;
  FrameItem? get selectedFrame => frames.where((f) => f.sku == frameSku).firstOrNull;
  void _emit() { if (active) onChanged?.call(); }
  void changed() { if (!saving) { error = null; _emit(); } }
  void dispose() { _disposed = true; onChanged = null; }
  String _message(Object e) => e is ApiException ? e.message : e is FormatException ? e.message.toString() : 'No se pudo completar la cotización. Intenta nuevamente.';

  void _checkQuote(Quotation value, {String? id}) {
    if (value.recordId != record?.id || (id != null && value.id != id) || value.currency != 'PEN') throw ApiException('La cotización recibida no corresponde a esta receta o moneda.');
  }
  void _checkSale(Sale value, String quotationId) {
    if (value.patientId != patientId || value.quotationId != quotationId) throw ApiException('La venta recibida no corresponde a este paciente y cotización.');
  }
  Quotation? _current(List<Quotation> values) {
    for (final value in values) { _checkQuote(value); }
    return values.where((q) => q.status == QuotationStatus.draft).lastOrNull ?? values.where((q) => q.status == QuotationStatus.approved).lastOrNull;
  }
  Future<void> load() async {
    if (!active || loading || saving) return;
    loading = true; _loaded = false; loadError = null; error = null; _emit();
    try {
      final profile = await repository.patient(patientId);
      if (!active) return;
      if (profile.id != patientId) throw ApiException('No se encontró al paciente solicitado.');
      patient = profile;
      final records = await repository.records(patientId);
      if (!active) return;
      if (records.any((r) => r.patientId != patientId)) throw ApiException('Las fichas recibidas no corresponden al paciente.');
      final prescribed = records.where((r) => r.prescription != null && r.id?.isNotEmpty == true).toList()..sort((a, b) => (b.examinationDate ?? DateTime.utc(1970)).compareTo(a.examinationDate ?? DateTime.utc(1970)));
      record = prescribed.firstOrNull;
      if (record == null) throw ApiException('El paciente todavía no tiene receta. Primero debe pasar por la atención clínica.');
      final values = await repository.quotations(record!.id!);
      if (!active) return;
      quotation = _current(values);
      lastRejectedReason = quotation == null ? values.where((q) => q.status == QuotationStatus.rejected).lastOrNull?.rejectionReason : null;
      sale = null;
      if (quotation != null) {
        final sales = await repository.sales(patientId);
        if (!active) return;
        if (sales.any((s) => s.patientId != patientId)) throw ApiException('Las ventas recibidas no corresponden al paciente.');
        sale = sales.where((s) => s.quotationId == quotation!.id).firstOrNull;
      }
      try {
        final catalog = await repository.frames();
        if (!active) return;
        frames = catalog; catalogWarning = null;
      } catch (e) { if (!active) return; frames = []; catalogWarning = _message(e); }
      stock = {}; stockWarning = null;
      if (storeId?.isNotEmpty == true) {
        try {
          final inventory = await repository.stock(storeId!);
          if (!active) return;
          if (inventory.opticalStoreId != storeId) throw ApiException('El stock no corresponde a tu óptica.');
          stock = {for (final level in inventory.stocks) level.sku: level.quantity};
        } catch (e) { if (!active) return; stockWarning = _message(e); }
      } else { stockWarning = 'Tu cuenta no tiene una óptica asignada para consultar stock.'; }
      final suggested = record!.prescription?.treatment?.toLowerCase() ?? '';
      treatments = treatmentOptions.where((o) => suggested.contains(o.name.toLowerCase())).map((o) => o.name).toSet();
      _loaded = true;
    } catch (e) { if (active) loadError = _message(e); }
    finally { if (active) { loading = false; _emit(); } }
  }

  void selectFrame(String sku) {
    if (!editable) return;
    if (!frames.any((f) => f.sku == sku)) return;
    if (stock[sku] == 0) { error = 'Esa montura no tiene stock en esta óptica.'; _emit(); return; }
    frameSku = frameSku == sku ? null : sku; changed();
  }
  void selectLens(int index) {
    if (!editable || index < 0 || index >= lensOptions.length) return;
    lensIndex = lensIndex == index ? null : index;
    lensPrice = lensIndex == null ? '' : lensOptions[index].price.toStringAsFixed(2); changed();
  }
  void toggleTreatment(String name) {
    if (!editable || !treatmentOptions.any((o) => o.name == name)) return;
    treatments.contains(name) ? treatments.remove(name) : treatments.add(name); changed();
  }
  List<QuotationItem> get draftItems => [
    if (selectedFrame case final frame?) QuotationItem(type: 'FRAME', sku: frame.sku, description: 'Montura ${frame.name}', unitPrice: frame.price),
    if (lensIndex != null && commerceAmount(lensPrice) != null) QuotationItem(type: 'LENS', description: 'Lentes ${lensOptions[lensIndex!].name}', unitPrice: commerceAmount(lensPrice)!),
    for (final option in treatmentOptions.where((o) => treatments.contains(o.name))) QuotationItem(type: 'TREATMENT', description: option.name, unitPrice: option.price),
  ];

  Future<void> generate() async {
    if (!editable) return;
    if (lensIndex != null && commerceAmount(lensPrice) == null) { error = 'Escribe un precio válido para los lentes, con hasta dos decimales.'; _emit(); return; }
    final items = draftItems;
    if (items.isEmpty) { error = 'Elige al menos una montura, un lente o un tratamiento.'; _emit(); return; }
    if (items.any((i) => !i.unitPrice.isFinite || i.unitPrice < 0 || i.unitPrice > 99999999.99 || i.description.length > 255)) { error = 'Revisa los precios y descripciones de los productos.'; _emit(); return; }
    await _save(() async {
      // Re-read before POST: a lost acknowledgement must not create another draft.
      final existing = await repository.quotations(record!.id!);
      if (!active) return null;
      return _current(existing) ?? await repository.generate(record!.id!, items);
    });
  }
  Future<void> applyDiscount() async {
    final quote = quotation;
    if (!canSave || quote?.status != QuotationStatus.draft) return;
    final value = commerceAmount(discountValue);
    if (value == null || value <= 0 || (discountIsPercentage ? value > 100 : value > quote!.subtotal)) { error = discountIsPercentage ? 'Escribe un descuento mayor que cero y de hasta 100 %.' : 'El descuento debe ser mayor que cero y no superar el subtotal.'; _emit(); return; }
    if (discountReason.trim().length > 255) { error = 'El motivo admite hasta 255 caracteres.'; _emit(); return; }
    await _save(() => repository.discount(quote!.id, discountIsPercentage ? 'PERCENTAGE' : 'FIXED_AMOUNT', value, discountReason.trim().isEmpty ? null : discountReason.trim()), expectedId: quote!.id);
  }
  Future<void> approve() async {
    final quote = quotation;
    if (!canSave || quote?.status != QuotationStatus.draft) return;
    await _save(() => repository.updateQuotation(quote!.id, QuotationStatus.approved), expectedId: quote!.id);
  }
  Future<void> reject() async {
    final quote = quotation;
    if (!canSave || quote?.status != QuotationStatus.draft) return;
    final reason = rejectReason.trim();
    if (reason.isEmpty || reason.length > 255) { error = 'Escribe un motivo del rechazo de hasta 255 caracteres.'; _emit(); return; }
    await _save(() => repository.updateQuotation(quote!.id, QuotationStatus.rejected, reason: reason), expectedId: quote!.id);
  }
  Future<void> _save(Future<Quotation?> Function() call, {String? expectedId}) async {
    if (!canSave) return;
    saving = true; error = null; _emit();
    try {
      final result = await call();
      if (!active || result == null) return;
      _checkQuote(result, id: expectedId);
      if (result.status == QuotationStatus.rejected) {
        lastRejectedReason = result.rejectionReason; quotation = null; sale = null; showReject = false;
      } else { quotation = result; lastRejectedReason = null; }
      discountValue = ''; discountReason = '';
    } catch (e) {
      if (active) {
        error = _message(e);
        // A stale draft can have been accepted on another device.
        if (e is ApiException && e.statusCode == 409 && quotation != null) {
          try { final fresh = await repository.quotation(quotation!.id); if (active) { _checkQuote(fresh, id: quotation!.id); quotation = fresh; } } catch (_) {}
        }
      }
    } finally { if (active) { saving = false; _emit(); } }
  }
  Future<Sale?> startSale() async {
    final quote = quotation;
    if (!canSave || quote?.status != QuotationStatus.approved) return null;
    saving = true; error = null; _emit();
    try {
      final existing = await repository.sales(patientId);
      if (!active) return null;
      if (existing.any((s) => s.patientId != patientId)) throw ApiException('Las ventas no corresponden al paciente.');
      var result = existing.where((s) => s.quotationId == quote!.id).firstOrNull;
      if (result == null) {
        try { result = await repository.register(quote!.id); }
        on ApiException catch (e) {
          if (!active || e.statusCode != 409) rethrow;
          result = (await repository.sales(patientId)).where((s) => s.quotationId == quote!.id).firstOrNull;
          if (result == null) rethrow;
        }
      }
      if (!active) return null;
      _checkSale(result, quote!.id); sale = result; return result;
    } catch (e) { if (active) error = _message(e); return null; }
    finally { if (active) { saving = false; _emit(); } }
  }
}
