import '../../domain/entities/clinical_record.dart';
import '../../domain/entities/commerce.dart';
import '../../domain/entities/frame.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/entities/staff_patient.dart';
import '../../domain/repositories/commerce_repository.dart';
import '../datasources/optiflow_api.dart';

class CommerceRepositoryImpl implements CommerceRepository {
  const CommerceRepositoryImpl(this._api);
  final OptiFlowApi _api;
  @override
  Future<StaffPatient> patient(String id) => _api.staffPatient(id);
  @override
  Future<List<ClinicalRecord>> records(String patientId) async => (await _api.clinicalRecords(patientId)).map((dto) => dto.toEntity()).toList();
  @override
  Future<List<FrameItem>> frames() async => (await _api.frameCatalog()).map((dto) => dto.toEntity()).toList();
  @override
  Future<StoreInventory> stock(String storeId) => _api.inventoryStock(storeId);
  @override
  Future<List<Quotation>> quotations(String recordId) => _api.recordQuotations(recordId);
  @override
  Future<Quotation> quotation(String id) => _api.quotation(id);
  @override
  Future<Quotation> generate(String recordId, List<QuotationItem> items) => _api.generateQuotation(recordId, items);
  @override
  Future<Quotation> discount(String id, String type, num value, String? reason) => _api.discountQuotation(id, type, value, reason);
  @override
  Future<Quotation> updateQuotation(String id, QuotationStatus status, {String? reason}) => _api.updateQuotation(id, status, reason: reason);
  @override
  Future<List<Sale>> sales(String patientId) => _api.patientSales(patientId);
  @override
  Future<Sale> sale(String id) => _api.sale(id);
  @override
  Future<Sale> register(String quotationId) => _api.registerSale(quotationId);
  @override
  Future<Sale> payCash(String saleId, num amount) => _api.paySaleCash(saleId, amount);
  @override
  Future<Sale> close(String saleId) => _api.closeSale(saleId);
}
