// Provider for Mandi Gate Pass, Inward Token & Unloading Queue
// (*گیٹ پاس، ٹوکن اور ٹریکٹر لائن نمبر*).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mandi/data/models/gate_pass_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

class GatePassProvider extends ChangeNotifier {
  String? _shopId;
  List<GatePassModel> _passes = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _subscription;

  String _filterStatus = 'all';
  String? _lastAnnouncedCallout;

  String? get shopId => _shopId;
  List<GatePassModel> get passes => List.unmodifiable(_passes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;
  String? get lastAnnouncedCallout => _lastAnnouncedCallout;

  List<GatePassModel> get filteredPasses {
    if (_filterStatus == 'all') return _passes;
    return _passes.where((p) => p.status.toDbString() == _filterStatus).toList();
  }

  List<GatePassModel> get activeQueuePasses {
    return _passes.where((p) => p.status == GatePassStatus.queued).toList();
  }

  List<GatePassModel> get unloadingPasses {
    return _passes.where((p) => p.status == GatePassStatus.unloading).toList();
  }

  void updateShop(String? shopId) {
    if (_shopId != shopId) {
      _shopId = shopId;
      _subscription?.cancel();
      _passes = [];
      if (_shopId != null && _shopId!.isNotEmpty) {
        _subscribeToPasses();
      } else {
        notifyListeners();
      }
    }
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void _subscribeToPasses() {
    if (_shopId == null) return;
    _isLoading = true;
    notifyListeners();

    _subscription = SupabaseService.gatePassesStream(_shopId!).listen(
      (rows) {
        _passes = rows.map((r) => GatePassModel.fromJson(r)).toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  String generateNextToken() {
    final todayCount = _passes.where((p) {
      final now = DateTime.now();
      return p.createdAt.year == now.year &&
          p.createdAt.month == now.month &&
          p.createdAt.day == now.day;
    }).length;
    final nextNum = todayCount + 1;
    return 'TKN-${nextNum.toString().padLeft(3, '0')}';
  }

  Future<String?> issueGatePass({
    required String vehicleNumber,
    required String driverName,
    String? driverPhone,
    String? farmerSupplierId,
    required String farmerName,
    required String commodityName,
    required int estimatedBags,
    String? assignedPlatform,
    double? grossWeightKg,
    String? notes,
  }) async {
    if (_shopId == null) return null;

    final token = generateNextToken();
    final now = DateTime.now();

    final data = <String, dynamic>{
      'shop_id': _shopId,
      'token_number': token,
      'vehicle_number': vehicleNumber.trim().toUpperCase(),
      'driver_name': driverName.trim(),
      'driver_phone': driverPhone?.trim(),
      'farmer_supplier_id': farmerSupplierId,
      'farmer_name': farmerName.trim(),
      'commodity_name': commodityName.trim(),
      'estimated_bags': estimatedBags,
      'inward_time': now.toIso8601String(),
      'assigned_platform': assignedPlatform?.trim(),
      'gross_weight_kg': grossWeightKg,
      'status': 'queued',
      'notes': notes?.trim(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    try {
      final id = await SupabaseService.createGatePass(data);
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> calloutForUnloading({
    required String passId,
    required String platformName, // e.g. پھڑ نمبر 3
  }) async {
    if (_shopId == null) return false;

    try {
      final pass = _passes.firstWhere((p) => p.id == passId);
      final announcement =
          'ٹوکن نمبر ${pass.tokenNumber} گاڑی ${pass.vehicleNumber} براہ کرم $platformName پر تشریف لائیں!';
      _lastAnnouncedCallout = announcement;

      await SupabaseService.updateGatePassStatus(
        id: passId,
        shopId: _shopId!,
        status: 'unloading',
        assignedPlatform: platformName,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordWeighment({
    required String passId,
    required double tareWeightKg,
    double? grossWeightOverride,
  }) async {
    if (_shopId == null) return false;

    try {
      final pass = _passes.firstWhere((p) => p.id == passId);
      final gross = grossWeightOverride ?? (pass.grossWeightKg ?? 0.0);
      final net = gross - tareWeightKg;

      await SupabaseService.updateGatePassStatus(
        id: passId,
        shopId: _shopId!,
        status: 'weighed',
        grossWeight: gross,
        tareWeight: tareWeightKg,
        netWeight: net > 0 ? net : 0,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearGateOut(String passId) async {
    if (_shopId == null) return false;

    try {
      await SupabaseService.updateGatePassStatus(
        id: passId,
        shopId: _shopId!,
        status: 'cleared_gate_out',
        outwardTime: DateTime.now(),
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelPass(String passId) async {
    if (_shopId == null) return false;

    try {
      await SupabaseService.updateGatePassStatus(
        id: passId,
        shopId: _shopId!,
        status: 'cancelled',
      );
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
