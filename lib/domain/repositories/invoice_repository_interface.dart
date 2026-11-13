/// Clean Architecture Contract for Invoicing & Billing
abstract class IInvoiceRepository {
  Stream<List<Map<String, dynamic>>> invoicesStream(String shopId);
  Future<String> createInvoiceWithStockDeduction({
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> items,
  });
  Future<void> cancelInvoice({
    required String invoiceId,
    required String shopId,
    required String actorId,
    required String actorName,
    String reason = '',
  });
}
