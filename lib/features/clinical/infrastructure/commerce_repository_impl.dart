import 'package:logix_optiflow/features/clinical/domain/clinical_record.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce.dart';
import 'package:logix_optiflow/features/clinical/domain/commerce_repository.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/clinical_api.dart';
import 'package:logix_optiflow/features/clinical/infrastructure/commerce_api.dart';
import 'package:logix_optiflow/features/inventory/domain/frame.dart';
import 'package:logix_optiflow/features/inventory/domain/inventory.dart';
import 'package:logix_optiflow/features/inventory/infrastructure/inventory_api.dart';
import 'package:logix_optiflow/features/searchbooking/domain/staff_patient.dart';
import 'package:logix_optiflow/features/searchbooking/infrastructure/search_booking_api.dart';

/// Cotizaciones y ventas; el paciente, las historias, las monturas y el stock vienen de su propia API.
class CommerceRepositoryImpl implements CommerceRepository {
  const CommerceRepositoryImpl({required this.api, required this.clinicalApi, required this.bookingApi, required this.inventoryApi});

  final CommerceApi api;
  final ClinicalApi clinicalApi;
  final SearchBookingApi bookingApi;
  final InventoryApi inventoryApi;

  @override
  Future<StaffPatient> patient(String id) => bookingApi.staffPatient(id);
  @override
  Future<List<ClinicalRecord>> records(String patientId) async => (await clinicalApi.clinicalRecords(patientId)).map((dto) => dto.toEntity()).toList();
  @override
  Future<List<FrameItem>> frames() async => (await inventoryApi.frameCatalog()).map((dto) => dto.toEntity()).toList();
  @override
  Future<StoreInventory> stock(String storeId) => inventoryApi.inventoryStock(storeId);
  @override
  Future<List<Quotation>> quotations(String recordId) => api.recordQuotations(recordId);
  @override
  Future<Quotation> quotation(String id) => api.quotation(id);
  @override
  Future<Quotation> generate(String recordId, List<QuotationItem> items) => api.generateQuotation(recordId, items);
  @override
  Future<Quotation> discount(String id, String type, num value, String? reason) => api.discountQuotation(id, type, value, reason);
  @override
  Future<Quotation> updateQuotation(String id, QuotationStatus status, {String? reason}) => api.updateQuotation(id, status, reason: reason);
  @override
  Future<List<Sale>> sales(String patientId) => api.patientSales(patientId);
  @override
  Future<Sale> sale(String id) => api.sale(id);
  @override
  Future<Sale> register(String quotationId) => api.registerSale(quotationId);
  @override
  Future<Sale> payCash(String saleId, num amount) => api.paySaleCash(saleId, amount);
  @override
  Future<Sale> close(String saleId) => api.closeSale(saleId);
}
