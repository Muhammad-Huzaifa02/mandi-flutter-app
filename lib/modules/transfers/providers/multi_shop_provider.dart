import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:mandi/data/models/multi_shop_transfer_model.dart';
import 'package:mandi/data/models/shop_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Central provider managing Inter-Shop Inventory Transfers and
/// Multi-Branch Consolidated Balance Sheet aggregations.
class MultiShopProvider extends ChangeNotifier {
  String? _currentShopId;
  List<Shop> _userShops = [];

  List<InterShopTransfer> _transfers = [];
  bool _isLoadingTransfers = false;

  ConsolidatedBalanceSheet? _balanceSheet;
  bool _isLoadingBalanceSheet = false;

  String _searchQuery = '';
  StockTransferStatus? _statusFilter;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<InterShopTransfer> get allTransfers => _transfers;
  bool get isLoadingTransfers => _isLoadingTransfers;
  ConsolidatedBalanceSheet? get balanceSheet => _balanceSheet;
  bool get isLoadingBalanceSheet => _isLoadingBalanceSheet;
  String get searchQuery => _searchQuery;
  StockTransferStatus? get statusFilter => _statusFilter;
  List<Shop> get userShops => _userShops;

  List<InterShopTransfer> get filteredTransfers {
    return _transfers.where((t) {
      if (_statusFilter != null && t.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchNum = t.transferNumber.toLowerCase().contains(q);
        final matchCommodity = t.commodityName.toLowerCase().contains(q);
        final matchVehicle = t.vehicleNumber.toLowerCase().contains(q);
        final matchDriver = t.driverName.toLowerCase().contains(q);
        final matchSrc = t.sourceShopName.toLowerCase().contains(q);
        final matchDest = t.destinationShopName.toLowerCase().contains(q);
        if (!matchNum &&
            !matchCommodity &&
            !matchVehicle &&
            !matchDriver &&
            !matchSrc &&
            !matchDest) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ── Shop Life-Cycle Binding ──────────────────────────────────────────────

  void updateShopContext({
    required String? activeShopId,
    required List<Shop> availableShops,
  }) {
    final changed = _currentShopId != activeShopId ||
        _userShops.length != availableShops.length;
    _currentShopId = activeShopId;
    _userShops = List.from(availableShops);

    if (changed && activeShopId != null && activeShopId.isNotEmpty) {
      loadTransfers();
      loadConsolidatedBalanceSheet();
    }
  }

  // ── Inter-Shop Transfer CRUD ─────────────────────────────────────────────

  Future<void> loadTransfers() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return;

    _isLoadingTransfers = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.getInterShopTransfersForShop(shopId);

      _transfers = rows.map((r) {
        final srcId = r['source_shop_id']?.toString() ?? '';
        final destId = r['destination_shop_id']?.toString() ?? '';

        final srcShop = _userShops.where((s) => s.id == srcId).toList();
        final destShop = _userShops.where((s) => s.id == destId).toList();

        final srcName = srcShop.isNotEmpty ? srcShop.first.name : 'Branch Shop';
        final destName =
            destShop.isNotEmpty ? destShop.first.name : 'Branch Shop';

        return InterShopTransfer.fromMap(
          r['id']?.toString() ?? '',
          r,
          sourceName: srcName,
          destinationName: destName,
        );
      }).toList();
    } catch (e) {
      debugPrint('[MultiShopProvider] Error loading transfers: $e');
    } finally {
      _isLoadingTransfers = false;
      notifyListeners();
    }
  }

  Future<bool> createTransfer({
    required String destinationShopId,
    String? productId,
    required String commodityName,
    required double quantityKg,
    required double quantityMaunds,
    String packageType = 'Bag',
    int packageCount = 0,
    required double unitCostPkr,
    required double totalValuePkr,
    double transitFreightPkr = 0.0,
    String vehicleNumber = '',
    String driverName = '',
    String driverPhone = '',
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    try {
      final transferNum =
          'TRF-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 100000}';

      final data = {
        'transfer_number': transferNum,
        'source_shop_id': shopId,
        'destination_shop_id': destinationShopId,
        'product_id': productId,
        'commodity_name': commodityName,
        'quantity_kg': quantityKg,
        'quantity_maunds': quantityMaunds,
        'package_type': packageType,
        'package_count': packageCount,
        'unit_cost_pkr': unitCostPkr,
        'total_value_pkr': totalValuePkr,
        'transit_freight_pkr': transitFreightPkr,
        'vehicle_number': vehicleNumber,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'dispatched_at': DateTime.now().toIso8601String(),
        'status': StockTransferStatus.inTransit.toDbString(),
        'notes': notes,
      };

      await SupabaseService.createInterShopTransfer(data);
      await loadTransfers();
      return true;
    } catch (e) {
      debugPrint('[MultiShopProvider] Error creating transfer: $e');
      return false;
    }
  }

  Future<bool> acknowledgeReceipt(String transferId) async {
    try {
      await SupabaseService.updateInterShopTransferStatus(
        transferId: transferId,
        status: StockTransferStatus.received.toDbString(),
        receivedAt: DateTime.now(),
      );
      await loadTransfers();
      return true;
    } catch (e) {
      debugPrint('[MultiShopProvider] Error acknowledging receipt: $e');
      return false;
    }
  }

  Future<bool> cancelTransfer(String transferId) async {
    try {
      await SupabaseService.updateInterShopTransferStatus(
        transferId: transferId,
        status: StockTransferStatus.cancelled.toDbString(),
      );
      await loadTransfers();
      return true;
    } catch (e) {
      debugPrint('[MultiShopProvider] Error cancelling transfer: $e');
      return false;
    }
  }

  // ── Consolidated Balance Sheet ───────────────────────────────────────────

  Future<void> loadConsolidatedBalanceSheet() async {
    if (_userShops.isEmpty) return;

    _isLoadingBalanceSheet = true;
    notifyListeners();

    try {
      final List<ShopBranchFinancialMetrics> branchMetrics = [];

      for (final shop in _userShops) {
        final metricsMap =
            await SupabaseService.getShopFinancialMetrics(shop.id);

        branchMetrics.add(
          ShopBranchFinancialMetrics(
            shopId: shop.id,
            shopName: shop.name,
            city: shop.city,
            totalSalesPkr: metricsMap['totalSales'] ?? 0.0,
            totalCommissionPkr: metricsMap['totalCommission'] ?? 0.0,
            totalExpensesPkr: metricsMap['totalExpenses'] ?? 0.0,
            totalReceivablesPkr: metricsMap['totalReceivables'] ?? 0.0,
            totalPayablesPkr: metricsMap['totalPayables'] ?? 0.0,
            stockValuePkr: metricsMap['totalStockValue'] ?? 0.0,
          ),
        );
      }

      _balanceSheet = ConsolidatedBalanceSheet(
        branches: branchMetrics,
        asOfDate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[MultiShopProvider] Error loading consolidated balance sheet: $e');
    } finally {
      _isLoadingBalanceSheet = false;
      notifyListeners();
    }
  }

  // ── Filters ──────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(StockTransferStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _statusFilter = null;
    notifyListeners();
  }
}
