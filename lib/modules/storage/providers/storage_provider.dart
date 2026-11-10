import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/bardana_model.dart';
import 'package:mandi/data/models/storage_allocation_model.dart';
import 'package:mandi/data/models/storage_location_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Provider managing Godowns, Cold Storage facilities, stock allocations,
/// and the revolving Bardana (Bags / Sacks / Crates) ledger.
class StorageProvider extends ChangeNotifier {
  StreamSubscription? _locationsSub;
  StreamSubscription? _allocationsSub;
  StreamSubscription? _bardanaSub;
  String? _shopId;

  List<StorageLocation> _locations = [];
  List<StorageAllocation> _allocations = [];
  List<BardanaTransaction> _bardanaTransactions = [];
  bool _isLoading = true;

  List<StorageLocation> get locations => List.unmodifiable(_locations);
  List<StorageAllocation> get allocations => List.unmodifiable(_allocations);
  List<BardanaTransaction> get bardanaTransactions =>
      List.unmodifiable(_bardanaTransactions);
  bool get isLoading => _isLoading;

  /// Aggregated metrics for Bardana
  BardanaSummary get bardanaSummary =>
      BardanaSummary.fromTransactions(_bardanaTransactions);

  /// Total bags currently stored across all facilities
  int get totalBagsInStorage =>
      _locations.fold<int>(0, (sum, l) => sum + l.currentBags);

  /// Total capacity across all facilities
  int get totalStorageCapacity =>
      _locations.fold<int>(0, (sum, l) => sum + l.capacityBags);

  /// Total bags stored specifically in Cold Storage
  int get totalColdStorageBags => _locations
      .where((l) => l.type == StorageLocationType.coldStorage)
      .fold<int>(0, (sum, l) => sum + l.currentBags);

  /// Total bags stored in Godowns
  int get totalGodownBags => _locations
      .where((l) => l.type == StorageLocationType.godown)
      .fold<int>(0, (sum, l) => sum + l.currentBags);

  /// Overall capacity utilization percentage (0.0 to 1.0)
  double get overallUtilization {
    if (totalStorageCapacity <= 0) return 0.0;
    final r = totalBagsInStorage / totalStorageCapacity;
    return r > 1.0 ? 1.0 : r;
  }

  /// Active allocations currently residing in storage
  List<StorageAllocation> get activeAllocations => _allocations
      .where((a) =>
          a.status == AllocationStatus.inStore ||
          a.status == AllocationStatus.partiallyDispatched)
      .toList();

  /// Total estimated rent accrued on active allocations
  double get totalEstimatedAccruedRent => activeAllocations.fold<double>(
      0.0, (sum, a) => sum + a.estimatedAccruedRent);

  /// Automatically invoked when active shop changes
  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _locationsSub?.cancel();
    _allocationsSub?.cancel();
    _bardanaSub?.cancel();
    _locations = [];
    _allocations = [];
    _bardanaTransactions = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _locationsSub =
        SupabaseService.storageLocationsStream(shopId).listen((rows) {
      _locations = rows
          .map((r) => StorageLocation.fromMap(r['id'] as String, r))
          .toList();
      _mapLocationNamesToAllocations();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });

    _allocationsSub =
        SupabaseService.storageAllocationsStream(shopId).listen((rows) {
      _allocations = rows
          .map((r) => StorageAllocation.fromMap(r['id'] as String, r))
          .toList();
      _mapLocationNamesToAllocations();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });

    _bardanaSub =
        SupabaseService.bardanaTransactionsStream(shopId).listen((rows) {
      _bardanaTransactions = rows
          .map((r) => BardanaTransaction.fromMap(r['id'] as String, r))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  void _mapLocationNamesToAllocations() {
    if (_locations.isEmpty || _allocations.isEmpty) return;
    final locMap = {for (final l in _locations) l.id: l.name};
    _allocations = _allocations.map((a) {
      if (locMap.containsKey(a.storageLocationId)) {
        return a.copyWith(storageLocationName: locMap[a.storageLocationId]);
      }
      return a;
    }).toList();
  }

  // ── Storage Location Operations ───────────────────────────────────────────

  Future<void> addLocation(StorageLocation loc) async {
    if (_shopId == null) return;
    await SupabaseService.addStorageLocation(loc.toMap());
  }

  Future<void> updateLocation(StorageLocation loc) async {
    if (_shopId == null) return;
    await SupabaseService.updateStorageLocation(
      id: loc.id,
      shopId: _shopId!,
      data: loc.toMap(),
    );
  }

  Future<void> deleteLocation(String id) async {
    if (_shopId == null) return;
    await SupabaseService.deleteStorageLocation(id: id, shopId: _shopId!);
  }

  // ── Stock Allocation & Transfer Operations ────────────────────────────────

  Future<void> allocateStock(StorageAllocation allocation) async {
    if (_shopId == null) return;
    await SupabaseService.addStorageAllocation(allocation.toMap());

    // Update location's current bags count
    final loc = _locations.where((l) => l.id == allocation.storageLocationId).firstOrNull;
    if (loc != null) {
      final updatedBags = loc.currentBags + allocation.bagCount;
      await SupabaseService.updateStorageLocation(
        id: loc.id,
        shopId: _shopId!,
        data: {'current_bags': updatedBags},
      );
    }
  }

  Future<void> dispatchOrReleaseStock({
    required String allocationId,
    required String locationId,
    required int bagsDispatched,
    required String newStatus,
    double? totalRentCharged,
  }) async {
    if (_shopId == null) return;
    await SupabaseService.updateStorageAllocationStatus(
      id: allocationId,
      shopId: _shopId!,
      status: newStatus,
      outwardDate: DateTime.now(),
      totalRentCharged: totalRentCharged,
    );

    // Decrement location bags count
    final loc = _locations.where((l) => l.id == locationId).firstOrNull;
    if (loc != null) {
      final updatedBags = (loc.currentBags - bagsDispatched).clamp(0, 9999999);
      await SupabaseService.updateStorageLocation(
        id: loc.id,
        shopId: _shopId!,
        data: {'current_bags': updatedBags},
      );
    }
  }

  // ── Bardana Ledger Operations ─────────────────────────────────────────────

  Future<void> recordBardana(BardanaTransaction tx) async {
    if (_shopId == null) return;
    await SupabaseService.addBardanaTransaction(tx.toMap());
  }

  Future<void> updateBardanaStatus({
    required String id,
    required String status,
  }) async {
    if (_shopId == null) return;
    await SupabaseService.updateBardanaStatus(
      id: id,
      shopId: _shopId!,
      status: status,
    );
  }

  @override
  void dispose() {
    _locationsSub?.cancel();
    _allocationsSub?.cancel();
    _bardanaSub?.cancel();
    super.dispose();
  }
}
