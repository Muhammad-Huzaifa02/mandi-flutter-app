import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:mandi/data/models/farmer_advance_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Provider managing real-time farmer pre-harvest advances and recovery deductions.
class FarmerAdvanceProvider extends ChangeNotifier {
  String? _shopId;

  List<FarmerAdvance> _advances = [];
  FarmerAdvanceSummary _summary = const FarmerAdvanceSummary();
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // 'all', 'active', 'overdue', 'recovered'
  String _searchQuery = '';

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  FarmerAdvanceProvider({String? shopId}) : _shopId = shopId {
    if (_shopId != null && _shopId!.isNotEmpty) {
      _initStream();
    } else {
      _isLoading = false;
    }
  }

  String? get shopId => _shopId;
  List<FarmerAdvance> get advances => _advances;
  FarmerAdvanceSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;
  String get searchQuery => _searchQuery;

  List<FarmerAdvance> get filteredAdvances {
    return _advances.where((a) {
      if (_filter == 'active' && a.status == FarmerAdvanceStatus.fullyRecovered) {
        return false;
      }
      if (_filter == 'overdue' && !a.isOverdue) return false;
      if (_filter == 'recovered' &&
          a.status != FarmerAdvanceStatus.fullyRecovered) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesFarmer = a.farmerName.toLowerCase().contains(q);
        final matchesPhone = a.farmerPhone.toLowerCase().contains(q);
        final matchesCrop = a.targetCrop.toLowerCase().contains(q);
        final matchesDesc = a.description.toLowerCase().contains(q);
        if (!matchesFarmer && !matchesPhone && !matchesCrop && !matchesDesc) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q.trim();
    notifyListeners();
  }

  void updateShop(String? newShopId) {
    if (newShopId == _shopId) return;
    _shopId = newShopId;
    _subscription?.cancel();
    _advances = [];
    _summary = const FarmerAdvanceSummary();
    if (_shopId != null && _shopId!.isNotEmpty) {
      _initStream();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initStream() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = SupabaseService.farmerAdvancesStream(_shopId!).listen(
      (data) {
        _advances = data
            .map((map) => FarmerAdvance.fromMap(map['id'] as String, map))
            .toList();
        _summary = FarmerAdvanceSummary.fromAdvances(_advances);
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        _error = err.toString();
        notifyListeners();
      },
    );
  }

  /// Create a new pre-harvest loan disbursement to a farmer.
  Future<String> createAdvance({
    required String supplierId,
    required String farmerName,
    String farmerPhone = '',
    FarmerAdvanceType advanceType = FarmerAdvanceType.cash,
    String description = '',
    required double principalAmount,
    double markupPercent = 0.0,
    double markupAmount = 0.0,
    required DateTime disbursementDate,
    DateTime? expectedHarvestDate,
    String targetCrop = '',
    String paymentMethod = 'cash',
    String? bankAccountId,
    String notes = '',
  }) async {
    if (_shopId == null) throw Exception('No active shop context');

    final computedMarkup = markupAmount > 0
        ? markupAmount
        : (markupPercent > 0 ? principalAmount * (markupPercent / 100.0) : 0.0);
    final totalPayable = principalAmount + computedMarkup;

    final advance = FarmerAdvance(
      id: '',
      shopId: _shopId!,
      supplierId: supplierId,
      farmerName: farmerName.trim(),
      farmerPhone: farmerPhone.trim(),
      advanceType: advanceType,
      description: description.trim(),
      principalAmount: principalAmount,
      markupPercent: markupPercent,
      markupAmount: computedMarkup,
      totalPayable: totalPayable,
      recoveredAmount: 0.0,
      remainingBalance: totalPayable,
      disbursementDate: disbursementDate,
      expectedHarvestDate: expectedHarvestDate,
      targetCrop: targetCrop.trim(),
      status: FarmerAdvanceStatus.active,
      paymentMethod: paymentMethod,
      bankAccountId: bankAccountId,
      notes: notes.trim(),
    );

    return await SupabaseService.createFarmerAdvance(advance.toMap());
  }

  /// Record an auction recovery deduction or direct repayment against an advance.
  Future<void> recordRecovery({
    required String advanceId,
    required double recoveryAmount,
    String? consignmentLotId,
    String? invoiceId,
    String recoveryMethod = 'consignment_deduction',
    String notes = '',
  }) async {
    if (_shopId == null) throw Exception('No active shop context');
    if (recoveryAmount <= 0) throw Exception('Recovery amount must be > 0');

    await SupabaseService.recordAdvanceRecovery(
      advanceId: advanceId,
      shopId: _shopId!,
      recoveryAmount: recoveryAmount,
      consignmentLotId: consignmentLotId,
      invoiceId: invoiceId,
      recoveryMethod: recoveryMethod,
      notes: notes.trim(),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
