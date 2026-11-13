import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/domain/repositories/invoice_repository_interface.dart';

/// Production Supabase Implementation of [IInvoiceRepository]
class InvoiceRepository implements IInvoiceRepository {
  @override
  Stream<List<Map<String, dynamic>>> invoicesStream(String shopId) {
    return SupabaseService.invoicesStream(shopId);
  }

  @override
  Future<String> createInvoiceWithStockDeduction({
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> items,
  }) async {
    return SupabaseService.createInvoiceWithStockDeduction(
      invoiceData: invoiceData,
      items: items,
    );
  }

  @override
  Future<void> cancelInvoice({
    required String invoiceId,
    required String shopId,
    required String actorId,
    required String actorName,
    String reason = '',
  }) async {
    await SupabaseService.cancelInvoice(
      invoiceId: invoiceId,
      shopId: shopId,
      actorId: actorId,
      actorName: actorName,
      reason: reason,
    );
  }
}
