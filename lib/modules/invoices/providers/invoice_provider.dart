import 'dart:async';
import 'package:flutter/material.dart';

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

    // The Postgres function create_invoice_with_stock_deduction now
    // credits the customer's (and, for a consignment sale, the
    // supplier's) running_balance itself, atomically with the invoice
    // insert and stock deduction — see supabase/schema.sql. Doing it
    // here as a second client-side step used to race with a concurrent
    // invoice for the same customer (read balance, then write it back —
    // no lock in between) and silently dropped the update entirely if
    // anything failed (catch (_) {}), which is a real way for a
    // customer's Khata to drift from their actual invoices.
    final id = await SupabaseService.createInvoiceWithStockDeduction(
      invoiceData: invoiceData,
      items: itemsData,
    );

    try {
      await NotificationService.showInvoiceCreatedNotification(
        invoiceNumber: invoice.invoiceNumber,
        totalAmount: invoice.total,
      );
    } catch (_) {}

    return id;
  }

  Future<void> cancelInvoice({
    required String invoiceId,
    required String actorId,
    required String actorName,
    String reason = '',
  }) async {
    if (_shopId == null) return;
    await SupabaseService.cancelInvoice(
      invoiceId: invoiceId,
      shopId: _shopId!,
      actorId: actorId,
      actorName: actorName,
      reason: reason,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
