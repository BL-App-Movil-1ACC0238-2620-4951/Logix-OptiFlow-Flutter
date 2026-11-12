import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logix_optiflow/data/datasources/optiflow_api.dart';
import 'package:logix_optiflow/data/repositories/commerce_repository_impl.dart';
import 'package:logix_optiflow/domain/entities/commerce.dart';
import 'package:logix_optiflow/presentation/state/quote_flow.dart';
import 'package:logix_optiflow/presentation/state/sale_flow.dart';

void commerceCheck(bool value, String message) { if (!value) throw StateError(message); }
http.Response commerceResponse(Object body, [int status = 200]) => http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

class CommerceServer {
  final quotations = <Map<String, dynamic>>[];
  Map<String, dynamic>? currentSale;
  List<Map<String, dynamic>> items = [];
  bool hasPrescription = true, wrongRecordPatient = false, wrongSalePatient = false;
  bool catalogUnavailable = false, stockUnavailable = false, quotesUnavailable = false;
  bool droppedQuote = false, droppedSale = false, saleConflict = false, droppedPayment = false, droppedClose = false;
  bool incompletePayment = false, incompleteClose = false;
  int closeFailures = 0, quotePosts = 0, salePosts = 0, payments = 0, closes = 0;
  Completer<http.Response>? pendingQuote;

  Map<String, dynamic> get quote => quotations.last;
  num get subtotal => items.fold<num>(0, (sum, i) => sum + (i['unitPrice'] as num) * (i['quantity'] as num));
  Map<String, dynamic> makeQuote() => {'id': 'quote-${quotations.length + 1}', 'clinicalRecordId': 'record-new', 'items': items, 'subtotal': subtotal, 'total': subtotal, 'currency': 'PEN', 'status': 'DRAFT', 'discount': null, 'rejectionReason': null};
  Map<String, dynamic> makeSale() => {'id': 'sale-1', 'quotationId': quote['id'], 'patientId': 'patient-1', 'status': 'PENDING_PAYMENT', 'payment': null, 'receipt': null, 'closedAt': null};
  void seed({String quoteStatus = 'APPROVED', String saleStatus = 'PENDING_PAYMENT'}) {
    items = [{'itemType': 'LENS', 'productSku': null, 'description': 'Lentes Monofocal 1.56', 'unitPrice': 120.35, 'quantity': 1}];
    quotations.add(makeQuote()..['status'] = quoteStatus);
    currentSale = makeSale()..['status'] = saleStatus;
    if (saleStatus != 'PENDING_PAYMENT') currentSale!['payment'] = {'method': 'CARD', 'amount': quote['total'], 'status': 'APPROVED'};
  }
  Future<http.Response> respond(http.Request request) async {
    commerceCheck(request.headers['Authorization'] == 'Bearer staff-token', 'Commerce must retain the staff token');
    final path = request.url.path.replaceFirst('/api/v1/', '');
    if (request.method == 'GET') {
      if (path == 'patients/patient-1') return commerceResponse({'id': 'patient-1', 'name': 'Paciente real', 'phone': '999888777', 'email': 'patient@example.test'});
      if (path == 'patients/patient-1/clinical-records') return commerceResponse([
        {'id': 'record-old', 'patientId': 'patient-1', 'examinationDate': '2025-01-01T15:00:00Z', 'prescription': hasPrescription ? {'sphereOD': -1} : null},
        {'id': 'record-new', 'patientId': wrongRecordPatient ? 'another-patient' : 'patient-1', 'examinationDate': '2026-11-12T15:00:00Z', 'prescription': hasPrescription ? {'sphereOD': -2, 'treatment': 'Antirreflejo'} : null},
      ]);
      if (path == 'inventory/frames') return catalogUnavailable ? commerceResponse({'message': 'Catálogo no disponible'}, 503) : commerceResponse([
        {'sku': 'FRAME-1', 'name': 'Montura del catálogo', 'price': 104.35, 'currency': 'PEN', 'material': 'Acetato'},
        {'sku': 'FRAME-0', 'name': 'Montura agotada', 'price': 80.50, 'currency': 'PEN'},
      ]);
      if (path == 'inventory/stock') {
        commerceCheck(request.url.queryParameters['opticalStoreId'] == 'store-1', 'Query must use assigned store');
        return stockUnavailable ? commerceResponse({'message': 'Stock no disponible'}, 503) : commerceResponse({'opticalStoreId': 'store-1', 'stocks': [
          {'sku': 'FRAME-1', 'quantity': 3, 'minimumStock': 1}, {'sku': 'FRAME-0', 'quantity': 0, 'minimumStock': 1},
        ]});
      }
      if (path == 'clinical-records/record-new/quotations') return quotesUnavailable ? commerceResponse({'message': 'Consulta de cotizaciones fallida'}, 503) : commerceResponse(quotations);
      if (path.startsWith('quotations/')) return commerceResponse(quotations.firstWhere((q) => q['id'] == path.split('/')[1]));
      if (path == 'patients/patient-1/sales') return commerceResponse([if (currentSale != null) {...currentSale!, if (wrongSalePatient) 'patientId': 'another-patient'}]);
      if (path == 'sales/sale-1') return commerceResponse({...currentSale!, if (wrongSalePatient) 'patientId': 'another-patient'});
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    if (request.method == 'POST' && path == 'quotations') {
      quotePosts++;
      commerceCheck(body['clinicalRecordId'] == 'record-new', 'Quote must use the newest prescribed record');
      items = (body['items'] as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
      quotations.add(makeQuote());
      if (pendingQuote != null) return pendingQuote!.future;
      if (droppedQuote) { droppedQuote = false; throw http.ClientException('Lost quote acknowledgement'); }
      return commerceResponse(quote, 201);
    }
    if (request.method == 'PATCH' && path.endsWith('/discount')) {
      commerceCheck(quote['status'] == 'DRAFT', 'Only draft discounts are editable');
      final amount = body['type'] == 'PERCENTAGE' ? (subtotal * (body['value'] as num)).round() / 100 : body['value'];
      quote['discount'] = {...body, 'amount': amount}; quote['total'] = subtotal - (amount as num);
      return commerceResponse(quote);
    }
    if (request.method == 'PATCH' && path.startsWith('quotations/') && path.endsWith('/status')) {
      commerceCheck(quote['status'] == 'DRAFT', 'Quote status only changes from draft');
      commerceCheck(body['status'] == 'APPROVED' || body['status'] == 'REJECTED', 'Use backend status values');
      quote['status'] = body['status']; quote['rejectionReason'] = body['reason']; return commerceResponse(quote);
    }
    if (request.method == 'POST' && path == 'sales') {
      salePosts++;
      commerceCheck(body.length == 1 && body['quotationId'] == quote['id'] && quote['status'] == 'APPROVED', 'Sale must reference an approved quote');
      currentSale ??= makeSale();
      if (saleConflict) { saleConflict = false; return commerceResponse({'message': 'Venta existente'}, 409); }
      if (droppedSale) { droppedSale = false; throw http.ClientException('Lost sale acknowledgement'); }
      return commerceResponse(currentSale!, 201);
    }
    if (request.method == 'POST' && path == 'sales/sale-1/payments') {
      payments++;
      commerceCheck(currentSale!['status'] == 'PENDING_PAYMENT', 'Never charge a paid sale');
      commerceCheck(body.length == 1 && body['amount'] == quote['total'], 'Cash amount must equal server total with decimals; never send a card method');
      if (incompletePayment) return commerceResponse(currentSale!, 201);
      currentSale!['status'] = 'PAID'; currentSale!['payment'] = {'method': 'CASH', 'amount': body['amount'], 'status': 'APPROVED'};
      if (droppedPayment) { droppedPayment = false; throw http.ClientException('Lost payment acknowledgement'); }
      return commerceResponse(currentSale!, 201);
    }
    if (request.method == 'PATCH' && path == 'sales/sale-1/status') {
      closes++;
      commerceCheck(body['status'] == 'CLOSED' && currentSale!['status'] == 'PAID', 'Only a paid sale may close');
      if (closeFailures > 0) { closeFailures--; return commerceResponse({'message': 'Error de cierre'}, 503); }
      if (incompleteClose) return commerceResponse(currentSale!);
      currentSale!['status'] = 'CLOSED'; currentSale!['receipt'] = {'receiptNumber': 'B001-000001'}; currentSale!['closedAt'] = '2026-11-12T17:00:00Z';
      if (droppedClose) { droppedClose = false; throw http.ClientException('Lost close acknowledgement'); }
      return commerceResponse(currentSale!);
    }
    throw StateError('Unexpected commerce HTTP request: ${request.method} $path');
  }
  CommerceRepositoryImpl repository() => CommerceRepositoryImpl(OptiFlowApi(client: MockClient(respond))..token = 'staff-token');
  QuoteFlow quoteFlow({bool Function()? active, void Function()? onChanged}) => QuoteFlow(repository: repository(), patientId: 'patient-1', storeId: 'store-1', isActive: active, onChanged: onChanged);
  SaleFlow saleFlow({bool Function()? active, Future<void> Function()? onClosed}) => SaleFlow(repository: repository(), patientId: 'patient-1', saleId: 'sale-1', isActive: active, onClosed: onClosed);
}

Future<void> runCommerceFlowChecks() async {
  final server = CommerceServer();
  final quote = server.quoteFlow();
  await quote.load();
  commerceCheck(quote.loadError == null && quote.record!.id == 'record-new' && quote.treatments.contains('Antirreflejo'), 'Load newest prescription and its suggested treatment');
  quote.selectFrame('FRAME-0'); commerceCheck(quote.frameSku == null && quote.error != null, 'Known zero stock blocks frame selection');
  quote.selectFrame('FRAME-1'); quote.selectLens(1); quote.lensPrice = '180,25';
  await Future.wait([quote.generate(), quote.generate()]);
  commerceCheck(server.quotePosts == 1 && quote.quotation!.subtotal == 344.60 && server.items.length == 3, 'One persisted quote contains real frame price, custom lens decimals and treatment');
  final frameItem = server.items.first;
  commerceCheck(frameItem['itemType'] == 'FRAME' && frameItem['productSku'] == 'FRAME-1' && frameItem['quantity'] == 1, 'Frame item contract uses SKU and quantity');
  quote.discountValue = '10'; quote.discountReason = 'Campaña'; await quote.applyDiscount();
  commerceCheck(quote.quotation!.discount!.amount == 34.46 && quote.quotation!.total == 310.14, 'Use persisted discount total');
  await quote.approve();
  final registered = await quote.startSale();
  commerceCheck(registered?.status == SaleStatus.pendingPayment && server.salePosts == 1, 'Approved quote starts a pending sale');
  await quote.startSale(); commerceCheck(server.salePosts == 1, 'Opening an existing sale never posts another');
  var closedCallbacks = 0;
  final sale = server.saleFlow(onClosed: () async { closedCallbacks++; throw StateError('Follow-up read failed'); });
  await sale.refresh(); await Future.wait([sale.payCashAndClose(), sale.payCashAndClose()]);
  commerceCheck(sale.sale!.status == SaleStatus.closed && sale.sale!.receiptNumber == 'B001-000001' && sale.error == null && server.payments == 1 && server.closes == 1 && closedCallbacks == 1, 'Pay once, close once, keep committed close despite refresh failure');
  await sale.payCashAndClose(); commerceCheck(server.payments == 1, 'Closed sales are immutable');

  final resumed = server.quoteFlow(); await resumed.load();
  commerceCheck(resumed.quotation!.status == QuotationStatus.approved && resumed.sale!.id == 'sale-1', 'Resume approved quote and its sale');
  final listing = SaleFlow(repository: server.repository(), patientId: 'patient-1'); await listing.refresh();
  commerceCheck(listing.sales.single.status == SaleStatus.closed, 'Patient sales list reads persisted sales');

  final rejectedServer = CommerceServer()..seed(quoteStatus: 'DRAFT'); rejectedServer.currentSale = null;
  final rejected = rejectedServer.quoteFlow(); await rejected.load(); rejected.rejectReason = ' '; await rejected.reject();
  commerceCheck(rejected.quotation!.status == QuotationStatus.draft && rejected.error != null, 'Rejection requires reason');
  rejected.rejectReason = 'El paciente lo pensará'; await rejected.reject();
  commerceCheck(rejected.quotation == null && rejected.lastRejectedReason == 'El paciente lo pensará', 'Rejection opens a new builder with persisted reason');
  rejected.selectLens(0); await rejected.generate(); commerceCheck(rejectedServer.quotations.length == 2, 'A rejected quote permits a new one');
  rejected.discountIsPercentage = false; rejected.discountValue = '20,35'; await rejected.applyDiscount();
  commerceCheck(rejected.quotation!.discount!.type == 'FIXED_AMOUNT' && rejected.quotation!.discount!.amount == 20.35, 'Fixed amount discount contract');
  rejected.discountValue = '99999'; await rejected.applyDiscount(); commerceCheck(rejected.error != null && rejected.quotation!.discount!.amount == 20.35, 'Fixed discount cannot exceed subtotal');

  final lostQuote = CommerceServer()..droppedQuote = true;
  final lostQuoteFlow = lostQuote.quoteFlow(); await lostQuoteFlow.load(); lostQuoteFlow.selectLens(0); await lostQuoteFlow.generate();
  commerceCheck(lostQuoteFlow.error != null && lostQuoteFlow.quotation == null, 'Lost quote response is not shown as success');
  await lostQuoteFlow.generate(); commerceCheck(lostQuote.quotePosts == 1 && lostQuoteFlow.quotation != null, 'Retry recovers a persisted draft without duplicating it');

  for (final conflict in [false, true]) {
    final registration = CommerceServer()..seed(); registration.currentSale = null;
    registration.droppedSale = !conflict; registration.saleConflict = conflict;
    final flow = registration.quoteFlow(); await flow.load(); await flow.startSale();
    if (!conflict) await flow.startSale();
    commerceCheck(flow.sale != null && registration.salePosts == 1, 'Recover lost sale acknowledgement or 409 using patient sales');
  }

  final partial = CommerceServer()..seed()..closeFailures = 1;
  final partialFlow = partial.saleFlow(); await partialFlow.refresh(); await partialFlow.payCashAndClose();
  commerceCheck(partialFlow.sale!.status == SaleStatus.paid && partialFlow.error != null, 'Payment survives failed closing');
  await partialFlow.closePaidSale(); commerceCheck(partialFlow.sale!.status == SaleStatus.closed && partial.payments == 1 && partial.closes == 2, 'Retry only closes a paid sale');

  for (final losePayment in [true, false]) {
    final lost = CommerceServer()..seed(); lost.droppedPayment = losePayment; lost.droppedClose = !losePayment;
    final flow = lost.saleFlow(); await flow.refresh(); await flow.payCashAndClose(); await flow.payCashAndClose();
    commerceCheck(flow.sale!.status == SaleStatus.closed && lost.payments == 1 && lost.closes == 1, 'Read server status before retrying lost payment/close acknowledgements');
  }
  final gateway = CommerceServer()..seed(saleStatus: 'PAID');
  final gatewayFlow = gateway.saleFlow(); await gatewayFlow.refresh(); await gatewayFlow.closePaidSale();
  commerceCheck(gateway.payments == 0 && gatewayFlow.sale!.paymentMethod == 'CARD' && gatewayFlow.sale!.status == SaleStatus.closed, 'Gateway-paid card sale closes without cash');

  for (final payment in [true, false]) {
    final incomplete = CommerceServer()..seed(); incomplete.incompletePayment = payment; incomplete.incompleteClose = !payment;
    final flow = incomplete.saleFlow(); await flow.refresh(); await flow.payCashAndClose();
    commerceCheck(flow.sale!.status != SaleStatus.closed && flow.error != null && (payment ? incomplete.closes == 0 : incomplete.payments == 1), 'Incomplete acknowledgement must not announce success or close unpaid sales');
  }

  final noRx = CommerceServer()..hasPrescription = false;
  final noRxFlow = noRx.quoteFlow(); await noRxFlow.load(); await noRxFlow.generate();
  commerceCheck(noRxFlow.loadError != null && noRx.quotePosts == 0, 'No prescription blocks quoting');
  final unavailable = CommerceServer()..quotesUnavailable = true;
  final unavailableFlow = unavailable.quoteFlow(); await unavailableFlow.load(); await unavailableFlow.generate();
  commerceCheck(unavailableFlow.loadError != null && unavailable.quotePosts == 0, 'Failed draft lookup never means no drafts');
  final optional = CommerceServer()..catalogUnavailable = true..stockUnavailable = true;
  final optionalFlow = optional.quoteFlow(); await optionalFlow.load(); optionalFlow.selectLens(0); await optionalFlow.generate();
  commerceCheck(optionalFlow.catalogWarning != null && optionalFlow.stockWarning != null && optionalFlow.quotation != null, 'Like Movile, unavailable catalogue/stock does not block lenses');

  final wrongRecord = CommerceServer()..wrongRecordPatient = true;
  final wrongRecordFlow = wrongRecord.quoteFlow(); await wrongRecordFlow.load();
  commerceCheck(wrongRecordFlow.loadError != null && !wrongRecordFlow.canSave, 'Cross-patient clinical data blocked');
  final wrongSale = CommerceServer()..seed()..wrongSalePatient = true;
  final wrongSaleFlow = wrongSale.saleFlow(); await wrongSaleFlow.refresh(); await wrongSaleFlow.payCashAndClose();
  commerceCheck(wrongSaleFlow.loadError != null && wrongSale.payments == 0, 'Cross-patient sale blocks payment');

  final paused = CommerceServer()..pendingQuote = Completer<http.Response>();
  var active = true, notifications = 0;
  final pausedFlow = paused.quoteFlow(active: () => active, onChanged: () => notifications++);
  await pausedFlow.load(); pausedFlow.selectLens(0); final pending = pausedFlow.generate();
  while (paused.quotePosts == 0) { await Future<void>.delayed(Duration.zero); }
  final previousNotifications = notifications; active = false; paused.pendingQuote!.complete(commerceResponse(paused.quote)); await pending;
  await pausedFlow.approve();
  commerceCheck(notifications == previousNotifications && pausedFlow.quotation == null && paused.quote['status'] == 'DRAFT', 'Session change discards pending replies and blocks subsequent writes');
  pausedFlow.dispose(); commerceCheck(!pausedFlow.active, 'Disposal disables old flow');

  for (final invalid in ['NaN', 'Infinity', '-1', '1.001', '1e2', '999999999', '1,2,3']) { commerceCheck(commerceAmount(invalid) == null, 'Reject invalid monetary input: $invalid'); }
  commerceCheck(commerceAmount('0') == 0 && commerceAmount('104,35') == 104.35, 'Allow API-supported zero item price and comma decimals');
  // ignore: avoid_print
  print('Commerce workflow, HTTP contracts and retry checks passed (simulated backend).');
}

Future<void> main() => runCommerceFlowChecks();
