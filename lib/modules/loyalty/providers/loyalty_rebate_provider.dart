import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:mandi/data/models/customer_loyalty_rebate_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Summary statistics for shop-wide volume rebate and customer loyalty programs.
class LoyaltySummary {
  final int totalProgramsCount;
  final int activeAccruingCount;
  final int creditedCount;
  final double totalQualifyingMaunds;
  final double totalQualifyingTurnoverPkr;
  final double totalRebatesAccruedPkr;
  final double totalRebatesCreditedPkr;

  const LoyaltySummary({
    this.totalProgramsCount = 0,
    this.activeAccruingCount = 0,
    this.creditedCount = 0,
    this.totalQualifyingMaunds = 0.0,
    this.totalQualifyingTurnoverPkr = 0.0,
    this.totalRebatesAccruedPkr = 0.0,
    this.totalRebatesCreditedPkr = 0.0,
  });
}

/// Central provider managing seasonal customer volume rebates and loyalty incentives.
class LoyaltyRebateProvider extends ChangeNotifier {
  String? _currentShopId;

  List<CustomerLoyaltyRebate> _rebates = [];
  bool _isLoading = false;
  StreamSubscription? _rebatesSub;

  RebateStatus? _statusFilter;
  RebateTierLevel? _tierFilter;
  String _searchQuery = '';

  // ── Getters ──────────────────────────────────────────────────────────────

  List<CustomerLoyaltyRebate> get rebates => _rebates;
  bool get isLoading => _isLoading;
  RebateStatus? get statusFilter => _statusFilter;
  RebateTierLevel? get tierFilter => _tierFilter;
  String get searchQuery => _searchQuery;

  List<CustomerLoyaltyRebate> get filteredRebates {
    return _rebates.where((r) {
      if (_statusFilter != null && r.status != _statusFilter) {
        return false;
      }
      if (_tierFilter != null && r.tierLevel != _tierFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchName = r.customerName.toLowerCase().contains(q);
        final matchPhone = r.customerPhone.toLowerCase().contains(q);
        final matchNote = r.creditNoteNumber.toLowerCase().contains(q);
        final matchProg = r.programName.toLowerCase().contains(q);
        if (!matchName && !matchPhone && !matchNote && !matchProg) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  LoyaltySummary get summary {
    double maunds = 0.0;
    double turnover = 0.0;
    double accrued = 0.0;
    double credited = 0.0;
    int accruing = 0;
    int creditedN = 0;

    for (final r in _rebates) {
      maunds += r.qualifyingMaunds;
      turnover += r.qualifyingTurnoverPkr;
      if (r.status == RebateStatus.credited) {
        credited += r.rebateAmountPkr;
        creditedN++;
      } else if (r.status == RebateStatus.accruing ||
          r.status == RebateStatus.approved) {
        accrued += r.rebateAmountPkr;
        accruing++;
      }
    }

    return LoyaltySummary(
      totalProgramsCount: _rebates.length,
      activeAccruingCount: accruing,
      creditedCount: creditedN,
      totalQualifyingMaunds: maunds,
      totalQualifyingTurnoverPkr: turnover,
      totalRebatesAccruedPkr: accrued,
      totalRebatesCreditedPkr: credited,
    );
  }

  // ── Shop Life-cycle ──────────────────────────────────────────────────────

  void updateShop(String? shopId) {
    if (_currentShopId != shopId) {
      _currentShopId = shopId;
      _cancelSubscription();
      if (shopId != null && shopId.isNotEmpty) {
        _subscribeToRebates(shopId);
        loadRebates();
      } else {
        _rebates = [];
        notifyListeners();
      }
    }
  }

  void _subscribeToRebates(String shopId) {
    _rebatesSub = SupabaseService.customerLoyaltyRebatesStream(shopId).listen(
      (rows) {
        _rebates = rows
            .map((r) =>
                CustomerLoyaltyRebate.fromMap(r['id']?.toString() ?? '', r))
            .toList();
        notifyListeners();
      },
      onError: (err) => debugPrint('[LoyaltyRebateProvider] Stream error: $err'),
    );
  }

  void _cancelSubscription() {
    _rebatesSub?.cancel();
    _rebatesSub = null;
  }

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }

  // ── CRUD Operations ──────────────────────────────────────────────────────

  Future<void> loadRebates() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.getCustomerLoyaltyRebates(shopId);
      _rebates = rows
          .map((r) =>
              CustomerLoyaltyRebate.fromMap(r['id']?.toString() ?? '', r))
          .toList();
    } catch (e) {
      debugPrint('[LoyaltyRebateProvider] Error loading rebates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRebateProgram({
    required String customerId,
    required String customerName,
    String customerPhone = '',
    String programName = 'Seasonal Volume Rebate',
    String seasonYear = '2026',
    required double qualifyingMaunds,
    required double qualifyingTurnoverPkr,
    double? customRebatePercentage,
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    try {
      final tier = RebateTierLevel.fromMaunds(qualifyingMaunds);
      final percent = customRebatePercentage ?? tier.defaultPercentage;
      final rebateAmount =
          CustomerLoyaltyRebate.computeRebateAmount(qualifyingTurnoverPkr, percent);

      final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 10000)
          .toString()
          .padLeft(4, '0');
      final creditNoteNum = 'CRN-${DateTime.now().year}-$randomSuffix';

      final data = {
        'shop_id': shopId,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'program_name': programName,
        'season_year': seasonYear,
        'qualifying_maunds': qualifyingMaunds,
        'qualifying_turnover_pkr': qualifyingTurnoverPkr,
        'tier_level': tier.toDbString(),
        'rebate_percentage': percent,
        'rebate_amount_pkr': rebateAmount,
        'credit_note_number': creditNoteNum,
        'status': RebateStatus.approved.toDbString(),
        'notes': notes,
      };

      await SupabaseService.createCustomerLoyaltyRebate(data);
      await loadRebates();
      return true;
    } catch (e) {
      debugPrint('[LoyaltyRebateProvider] Error creating rebate: $e');
      return false;
    }
  }

  Future<bool> creditRebateToKhata(CustomerLoyaltyRebate rebate) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    try {
      await SupabaseService.creditRebateToCustomerKhata(
        rebateId: rebate.id,
        shopId: shopId,
        customerId: rebate.customerId,
        rebateAmount: rebate.rebateAmountPkr,
        creditNoteNumber: rebate.creditNoteNumber,
        notes: 'Seasonal loyalty volume rebate (${rebate.tierLevel.labelEnglish}) credited to customer ledger',
      );
      await loadRebates();
      return true;
    } catch (e) {
      debugPrint('[LoyaltyRebateProvider] Error crediting rebate: $e');
      return false;
    }
  }

  // ── Filters ──────────────────────────────────────────────────────────────

  void setStatusFilter(RebateStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setTierFilter(RebateTierLevel? tier) {
    _tierFilter = tier;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void resetFilters() {
    _statusFilter = null;
    _tierFilter = null;
    _searchQuery = '';
    notifyListeners();
  }
}
