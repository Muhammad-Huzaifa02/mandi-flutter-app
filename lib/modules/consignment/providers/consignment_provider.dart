import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/consignment_lot_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Manages real-time incoming crop consignments (Aawak & Dheri / آمد و ڈھیری).
/// Automatically updates when active shop changes.
class ConsignmentProvider extends ChangeNotifier {
  StreamSubscription? _sub;
  String? _shopId;

  List<ConsignmentLot> _lots = [];
  bool _isLoading = true;

  List<ConsignmentLot> get lots => List.unmodifiable(_lots);
  bool get isLoading => _isLoading;

  List<ConsignmentLot> get arrivedLots =>
      _lots.where((l) => l.status == ConsignmentLotStatus.arrived).toList();

  List<ConsignmentLot> get auctioningLots =>
      _lots.where((l) => l.status == ConsignmentLotStatus.auctioning).toList();

  List<ConsignmentLot> get soldLots => _lots
      .where((l) =>
          l.status == ConsignmentLotStatus.sold ||
          l.status == ConsignmentLotStatus.settled)
      .toList();

  List<ConsignmentLot> get todayLots {
    final now = DateTime.now();
    return _lots.where((l) {
      if (l.createdAt == null) return false;
      return l.createdAt!.year == now.year &&
          l.createdAt!.month == now.month &&
          l.createdAt!.day == now.day;
    }).toList();
  }

  int get totalBagsToday =>
      todayLots.fold<int>(0, (sum, l) => sum + l.bagCount);

  double get totalMaundsToday =>
      todayLots.fold<double>(0.0, (sum, l) => sum + l.maunds);

  double get totalSoldAmountToday =>
      todayLots.where((l) => l.isSold).fold<double>(
          0.0, (sum, l) => sum + l.estimatedTotal);

  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _sub?.cancel();
    _lots = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _sub = SupabaseService.consignmentLotsStream(shopId).listen((rows) {
      _lots = rows
          .map((r) => ConsignmentLot.fromMap(r['id'] as String, r))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<ConsignmentLot> search(String query) {
    if (query.trim().isEmpty) return lots;
    final q = query.toLowerCase();
    return _lots
        .where((l) =>
            l.lotNumber.toLowerCase().contains(q) ||
            l.supplierName.toLowerCase().contains(q) ||
            l.productName.toLowerCase().contains(q) ||
            l.vehicleNumber.toLowerCase().contains(q) ||
            l.winningBuyerName.toLowerCase().contains(q))
        .toList();
  }

  Future<String> addLot({
    required String lotNumber,
    String? supplierId,
    String supplierName = '',
    String? productId,
    String productName = '',
    String vehicleNumber = '',
    int bagCount = 0,
    double weightKg = 0,
    double ratePerMaund = 0,
    String notes = '',
  }) async {
    if (_shopId == null) throw StateError('No active shop context.');

    final data = {
      'shop_id': _shopId,
      'lot_number': lotNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'product_id': productId,
      'product_name': productName,
      'vehicle_number': vehicleNumber,
      'bag_count': bagCount,
      'weight_kg': weightKg,
      'rate_per_maund': ratePerMaund,
      'status': 'arrived',
      'notes': notes,
    };

    final id = await SupabaseService.addConsignmentLot(data);
    return id;
  }

  Future<void> updateStatus(String lotId, ConsignmentLotStatus status) async {
    if (_shopId == null) return;
    await SupabaseService.updateConsignmentLot(
      lotId: lotId,
      shopId: _shopId!,
      data: {
        'status': status.toDbString(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> recordBid({
    required String lotId,
    required String winningBuyerId,
    required String winningBuyerName,
    required double ratePerMaund,
    double? finalWeightKg,
  }) async {
    if (_shopId == null) return;
    await SupabaseService.updateLotBid(
      lotId: lotId,
      shopId: _shopId!,
      winningBuyerId: winningBuyerId,
      winningBuyerName: winningBuyerName,
      ratePerMaund: ratePerMaund,
      finalWeightKg: finalWeightKg,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
