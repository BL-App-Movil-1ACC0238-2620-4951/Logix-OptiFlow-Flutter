import '../entities/clinical_record.dart';
import '../entities/commerce.dart';
import '../entities/frame.dart';
import '../entities/inventory.dart';
import '../entities/staff_patient.dart';

abstract class CommerceRepository {
  Future<StaffPatient> patient(String id);
  Future<List<ClinicalRecord>> records(String patientId);
  Future<List<FrameItem>> frames();
  Future<StoreInventory> stock(String storeId);
  Future<List<Quotation>> quotations(String recordId);
  Future<Quotation> quotation(String id);
  Future<Quotation> generate(String recordId, List<QuotationItem> items);
  Future<Quotation> discount(String id, String type, num value, String? reason);
  Future<Quotation> updateQuotation(String id, QuotationStatus status, {String? reason});
  Future<List<Sale>> sales(String patientId);
  Future<Sale> sale(String id);
  Future<Sale> register(String quotationId);
  Future<Sale> payCash(String saleId, num amount);
  Future<Sale> close(String saleId);
}
