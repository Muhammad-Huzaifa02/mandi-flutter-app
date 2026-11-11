// Provider for Visual 2D Godown & Cold Storage Floor Grid
// (*گودام اور کولڈ سٹوریج کا تصویری نقشہ*).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mandi/data/models/warehouse_grid_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

class WarehouseGridProvider extends ChangeNotifier {
  String? _shopId;
  String _selectedChamber = 'CH-1';
  List<WarehouseGridBayModel> _bays = [];
  WarehouseGridBayModel? _selectedBay;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _subscription;

  String? get shopId => _shopId;
  String get selectedChamber => _selectedChamber;
  List<WarehouseGridBayModel> get bays => List.unmodifiable(_bays);
  WarehouseGridBayModel? get selectedBay => _selectedBay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Occupancy metrics
  int get totalCapacityBags =>
      _bays.fold(0, (sum, b) => sum + b.maxCapacityBags);

  int get totalStoredBags =>
      _bays.fold(0, (sum, b) => sum + b.currentBags);

  double get overallOccupancyPercent => totalCapacityBags > 0
      ? (totalStoredBags / totalCapacityBags * 100.0)
      : 0.0;

  int get occupiedBaysCount => _bays.where((b) => b.currentBags > 0).length;
  int get emptyBaysCount => _bays.where((b) => b.currentBags == 0).length;
  int get overdueBaysCount => _bays.where((b) => b.isOverdue).length;

  void updateShop(String? shopId) {
    if (_shopId != shopId) {
      _shopId = shopId;
      _subscription?.cancel();
      _bays = [];
      _selectedBay = null;
      if (_shopId != null && _shopId!.isNotEmpty) {
        _subscribeToBays();
      } else {
        notifyListeners();
      }
    }
  }

  void switchChamber(String chamber) {
    _selectedChamber = chamber;
    _selectedBay = null;
    _subscription?.cancel();
    _subscribeToBays();
  }

  void selectBay(WarehouseGridBayModel? bay) {
    _selectedBay = bay;
    notifyListeners();
  }

  void _subscribeToBays() {
    if (_shopId == null) return;
    _isLoading = true;
    notifyListeners();

    _subscription = SupabaseService.warehouseGridBaysStream(
      _shopId!,
      chamberCode: _selectedChamber,
    ).listen(
      (rows) {
        _bays = rows.map((r) => WarehouseGridBayModel.fromJson(r)).toList();
        if (_bays.isEmpty) {
          _initializeDefaultGrid();
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _initializeDefaultGrid() {
    // If no bays exist in DB yet, generate a standard 4x6 (24 bays) visual grid
    const defaultRows = ['A', 'B', 'C', 'D'];
    const defaultCols = 6;
    final generated = <WarehouseGridBayModel>[];

    for (int r = 0; r < defaultRows.length; r++) {
      for (int c = 1; c <= defaultCols; c++) {
        final bayCode = '${defaultRows[r]}$c';
        // Add some realistic seed state
        final isSampleOccupied = (r == 0 && c <= 3) || (r == 1 && c == 2);
        final isOverdueSample = (r == 0 && c == 1);

        generated.add(
          WarehouseGridBayModel(
            id: 'bay_${_selectedChamber}_$bayCode',
            shopId: _shopId ?? '',
            chamberCode: _selectedChamber,
            bayCode: bayCode,
            rowCoord: r + 1,
            colCoord: c,
            maxCapacityBags: 200,
            currentBags: isSampleOccupied ? (isOverdueSample ? 200 : 150) : 0,
            cropName: isSampleOccupied ? 'Basmati Super Rice (دھان)' : null,
            farmerName: isSampleOccupied ? 'Malik Aslam Farm' : null,
            lotCode: isSampleOccupied ? 'LOT-$_selectedChamber-$bayCode' : null,
            storageStartDate: isSampleOccupied
                ? (isOverdueSample
                    ? DateTime.now().subtract(const Duration(days: 95))
                    : DateTime.now().subtract(const Duration(days: 14)))
                : null,
            status: isSampleOccupied
                ? (isOverdueSample ? BayStatus.full : BayStatus.partiallyStored)
                : BayStatus.empty,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
    _bays = generated;
  }

  Future<bool> storeCropInBay({
    required String bayId,
    required String cropName,
    required String farmerName,
    String? farmerSupplierId,
    required String lotCode,
    required int bags,
    required int maxCapacityBags,
  }) async {
    if (_shopId == null) return false;

    try {
      final now = DateTime.now();
      final status = bags >= maxCapacityBags ? 'full' : 'partially_stored';

      final bay = _bays.firstWhere((b) => b.id == bayId);
      final updateData = <String, dynamic>{
        'shop_id': _shopId,
        'chamber_code': _selectedChamber,
        'bay_code': bay.bayCode,
        'row_coord': bay.rowCoord,
        'col_coord': bay.colCoord,
        'max_capacity_bags': maxCapacityBags,
        'current_bags': bags,
        'crop_name': cropName.trim(),
        'farmer_supplier_id': farmerSupplierId,
        'farmer_name': farmerName.trim(),
        'lot_code': lotCode.trim(),
        'storage_start_date': now.toIso8601String(),
        'status': status,
        'updated_at': now.toIso8601String(),
      };

      await SupabaseService.upsertWarehouseGridBay(updateData);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> relocateStock({
    required String sourceBayId,
    required String targetBayId,
  }) async {
    if (_shopId == null) return false;

    try {
      final source = _bays.firstWhere((b) => b.id == sourceBayId);
      final target = _bays.firstWhere((b) => b.id == targetBayId);

      // Move source payload to target
      final now = DateTime.now();
      final targetUpdate = <String, dynamic>{
        'shop_id': _shopId,
        'chamber_code': _selectedChamber,
        'bay_code': target.bayCode,
        'row_coord': target.rowCoord,
        'col_coord': target.colCoord,
        'max_capacity_bags': target.maxCapacityBags,
        'current_bags': source.currentBags,
        'crop_name': source.cropName,
        'farmer_name': source.farmerName,
        'farmer_supplier_id': source.farmerSupplierId,
        'lot_code': source.lotCode,
        'storage_start_date': source.storageStartDate?.toIso8601String() ?? now.toIso8601String(),
        'status': source.status.toDbString(),
        'updated_at': now.toIso8601String(),
      };

      final sourceClear = <String, dynamic>{
        'shop_id': _shopId,
        'chamber_code': _selectedChamber,
        'bay_code': source.bayCode,
        'row_coord': source.rowCoord,
        'col_coord': source.colCoord,
        'max_capacity_bags': source.maxCapacityBags,
        'current_bags': 0,
        'crop_name': null,
        'farmer_name': null,
        'farmer_supplier_id': null,
        'lot_code': null,
        'storage_start_date': null,
        'status': 'empty',
        'updated_at': now.toIso8601String(),
      };

      await SupabaseService.upsertWarehouseGridBay(targetUpdate);
      await SupabaseService.upsertWarehouseGridBay(sourceClear);
      _selectedBay = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearBay(String bayId) async {
    if (_shopId == null) return false;

    try {
      final bay = _bays.firstWhere((b) => b.id == bayId);
      final now = DateTime.now();
      final clearData = <String, dynamic>{
        'shop_id': _shopId,
        'chamber_code': _selectedChamber,
        'bay_code': bay.bayCode,
        'row_coord': bay.rowCoord,
        'col_coord': bay.colCoord,
        'max_capacity_bags': bay.maxCapacityBags,
        'current_bags': 0,
        'crop_name': null,
        'farmer_name': null,
        'farmer_supplier_id': null,
        'lot_code': null,
        'storage_start_date': null,
        'status': 'empty',
        'updated_at': now.toIso8601String(),
      };

      await SupabaseService.upsertWarehouseGridBay(clearData);
      _selectedBay = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
