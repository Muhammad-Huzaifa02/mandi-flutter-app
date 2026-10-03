import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mandi/core/utils/notification_service.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Streams every Invoice for the active shop.
/// Rebuilt via ChangeNotifierProxyProvider whenever ShopContextProvider's
/// currentShopId changes.
class InvoiceProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  String? _shopId;

  List<Invoice> _invoices = [];
  bool _isLoading = true;

  List<Invoice> get invoices => List.unmodifiable(_invoices);
  bool get isLoading => _isLoading;

  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _sub?.cancel();
    _invoices = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _sub = SupabaseService.invoicesStream(shopId).listen((rows) {
      _invoices = rows
          .map((r) => Invoice.fromMap(r['id'] as String, r))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Invoice> search(String query) {
    if (query.trim().isEmpty) return invoices;
    final q = query.toLowerCase();
    return _invoices
        .where((i) =>
            i.invoiceNumber.toLowerCase().contains(q) ||
            i.customerName.toLowerCase().contains(q))
        .toList();
  }

  Future<String> createInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
  }) async {
    final invoiceData = invoice.toMap();
    final itemsData = items.map((item) => item.toMap()).toList();

    final id = await SupabaseService.createInvoiceWithStockDeduction(
      invoiceData: invoiceData,
      items: itemsData,
    );

    // Auto-update customer Khata running_balance if invoice has a pending amount
    if (invoice.customerId != null &&
        invoice.customerId!.isNotEmpty &&
        invoice.pendingAmount > 0) {
      try {
        final client = Supabase.instance.client;
        final customerRow = await client
            .from('customers')
            .select('running_balance')
            .eq('id', invoice.customerId!)
            .maybeSingle();

        if (customerRow != null) {
          final currentBalance =
              (customerRow['running_balance'] as num?)?.toDouble() ?? 0;
          await client
              .from('customers')
              .update({'running_balance': currentBalance + invoice.pendingAmount})
              .eq('id', invoice.customerId!);
        }
      } catch (_) {}
    }

    try {
      await NotificationService.showInvoiceCreatedNotification(
        invoiceNumber: invoice.invoiceNumber,
        totalAmount: invoice.total,
      );
    } catch (_) {}

    return id;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
