import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:mandi/data/models/fleet_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Central provider managing Mandi Vehicle Fleet, Freight Trips,
/// Diesel Fuel Logs, and Vehicle Profit & Loss Statements
/// (*گاڑیوں کا ڈیزل، ٹرپ کرایہ اور ٹرانسپورٹ کھاتہ*).
class FleetProvider extends ChangeNotifier {
  String? _currentShopId;

  List<FleetVehicle> _vehicles = [];
  List<FleetTrip> _trips = [];
  List<FleetFuelLog> _fuelLogs = [];

  bool _isLoading = false;
  String _searchQuery = '';
  TripStatus? _statusFilter;
  String? _selectedVehicleId;

  StreamSubscription? _vehiclesSub;
  StreamSubscription? _tripsSub;
  StreamSubscription? _fuelLogsSub;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<FleetVehicle> get vehicles => _vehicles;
  List<FleetTrip> get trips => _trips;
  List<FleetFuelLog> get fuelLogs => _fuelLogs;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  TripStatus? get statusFilter => _statusFilter;
  String? get selectedVehicleId => _selectedVehicleId;

  FleetVehicle? get selectedVehicle {
    if (_selectedVehicleId == null) return null;
    try {
      return _vehicles.firstWhere((v) => v.id == _selectedVehicleId);
    } catch (_) {
      return null;
    }
  }

  List<FleetTrip> get filteredTrips {
    return _trips.where((t) {
      if (_selectedVehicleId != null && t.vehicleId != _selectedVehicleId) {
        return false;
      }
      if (_statusFilter != null && t.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchTrip = t.tripNumber.toLowerCase().contains(q);
        final matchParty = t.partyName.toLowerCase().contains(q);
        final matchOrigin = t.origin.toLowerCase().contains(q);
        final matchDest = t.destination.toLowerCase().contains(q);
        final matchCargo = t.commodityName.toLowerCase().contains(q);
        if (!matchTrip && !matchParty && !matchOrigin && !matchDest && !matchCargo) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<FleetFuelLog> get filteredFuelLogs {
    if (_selectedVehicleId == null) return _fuelLogs;
    return _fuelLogs.where((f) => f.vehicleId == _selectedVehicleId).toList();
  }

  // ── KPI Metrics ──────────────────────────────────────────────────────────

  int get totalVehiclesCount => _vehicles.length;
  int get activeVehiclesCount => _vehicles.where((v) => v.isActive).length;
  int get inTransitTripsCount =>
      _trips.where((t) => t.status == TripStatus.inTransit).length;

  double get totalFreightRevenue =>
      _trips.fold(0.0, (sum, t) => sum + t.agreedFreightPkr);

  double get totalDriverAdvances =>
      _trips.fold(0.0, (sum, t) => sum + t.driverAdvancePkr);

  double get totalFuelExpense =>
      _fuelLogs.fold(0.0, (sum, f) => sum + f.totalCostPkr);

  double get totalFuelLiters =>
      _fuelLogs.fold(0.0, (sum, f) => sum + f.liters);

  double get totalNetProfit =>
      _trips.fold(0.0, (sum, t) => sum + t.netTripProfitPkr);

  double get totalPendingFreightPayable =>
      _trips.fold(0.0, (sum, t) => sum + t.balanceFreightPayablePkr);

  // ── Shop Life-cycle ──────────────────────────────────────────────────────

  void updateShop(String? shopId) {
    if (_currentShopId != shopId) {
      _currentShopId = shopId;
      _cancelSubscriptions();
      if (shopId != null && shopId.isNotEmpty) {
        loadFleetData();
        _subscribeToStreams(shopId);
      } else {
        _vehicles = [];
        _trips = [];
        _fuelLogs = [];
        notifyListeners();
      }
    }
  }

  void _subscribeToStreams(String shopId) {
    _cancelSubscriptions();

    _vehiclesSub = SupabaseService.fleetVehiclesStream(shopId).listen(
      (rows) {
        _vehicles = rows
            .map((r) => FleetVehicle.fromMap(r['id']?.toString() ?? '', r))
            .toList();
        notifyListeners();
      },
      onError: (err) =>
          debugPrint('[FleetProvider] Vehicles stream error: $err'),
    );

    _tripsSub = SupabaseService.fleetTripsStream(shopId).listen(
      (rows) {
        _trips = rows
            .map((r) => FleetTrip.fromMap(r['id']?.toString() ?? '', r))
            .toList();
        notifyListeners();
      },
      onError: (err) => debugPrint('[FleetProvider] Trips stream error: $err'),
    );

    _fuelLogsSub = SupabaseService.fleetFuelLogsStream(shopId).listen(
      (rows) {
        _fuelLogs = rows
            .map((r) => FleetFuelLog.fromMap(r['id']?.toString() ?? '', r))
            .toList();
        notifyListeners();
      },
      onError: (err) =>
          debugPrint('[FleetProvider] Fuel logs stream error: $err'),
    );
  }

  void _cancelSubscriptions() {
    _vehiclesSub?.cancel();
    _vehiclesSub = null;
    _tripsSub?.cancel();
    _tripsSub = null;
    _fuelLogsSub?.cancel();
    _fuelLogsSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  // ── Data Loading & CRUD ──────────────────────────────────────────────────

  Future<void> loadFleetData() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final vRows = await SupabaseService.getFleetVehicles(shopId);
      _vehicles = vRows
          .map((r) => FleetVehicle.fromMap(r['id']?.toString() ?? '', r))
          .toList();

      final tRows = await SupabaseService.getFleetTrips(shopId);
      _trips = tRows
          .map((r) => FleetTrip.fromMap(r['id']?.toString() ?? '', r))
          .toList();

      final fRows = await SupabaseService.getFleetFuelLogs(shopId);
      _fuelLogs = fRows
          .map((r) => FleetFuelLog.fromMap(r['id']?.toString() ?? '', r))
          .toList();
    } catch (e) {
      debugPrint('[FleetProvider] Error loading fleet data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Vehicle Operations ───────────────────────────────────────────────────

  Future<bool> registerVehicle({
    required String registrationNumber,
    required VehicleType vehicleType,
    OwnershipType ownershipType = OwnershipType.shopOwned,
    String driverName = '',
    String driverPhone = '',
    double capacityMaunds = 0.0,
    double odometerKm = 0.0,
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    final data = {
      'shop_id': shopId,
      'registration_number': registrationNumber.toUpperCase().trim(),
      'vehicle_type': vehicleType.toDbString(),
      'ownership_type': ownershipType.toDbString(),
      'driver_name': driverName.trim(),
      'driver_phone': driverPhone.trim(),
      'capacity_maunds': capacityMaunds,
      'odometer_km': odometerKm,
      'status': 'active',
      'notes': notes.trim(),
    };

    try {
      await SupabaseService.createFleetVehicle(data);
      await loadFleetData();
      return true;
    } catch (e) {
      debugPrint('[FleetProvider] Error registering vehicle: $e');
      return false;
    }
  }

  // ── Trip Operations ──────────────────────────────────────────────────────

  Future<bool> recordTrip({
    required String vehicleId,
    required DateTime tripDate,
    required String origin,
    required String destination,
    String commodityName = '',
    double loadedWeightKg = 0.0,
    double? loadedWeightMaunds,
    int bagCount = 0,
    String partyName = '',
    required double agreedFreightPkr,
    double driverAdvancePkr = 0.0,
    double dieselExpensePkr = 0.0,
    double tollAndTaxPkr = 0.0,
    double otherExpensePkr = 0.0,
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    final maunds = loadedWeightMaunds ??
        (loadedWeightKg > 0 ? (loadedWeightKg / 40.0) : 0.0);

    final fin = FleetTrip.computeTripFinances(
      agreedFreight: agreedFreightPkr,
      driverAdvance: driverAdvancePkr,
      diesel: dieselExpensePkr,
      toll: tollAndTaxPkr,
      other: otherExpensePkr,
    );

    final randomSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
    final tripNum = 'TRIP-${DateFormat("yyMM").format(DateTime.now())}-$randomSuffix';

    final data = {
      'shop_id': shopId,
      'vehicle_id': vehicleId,
      'trip_number': tripNum,
      'trip_date': DateFormat('yyyy-MM-dd').format(tripDate),
      'origin': origin.trim(),
      'destination': destination.trim(),
      'commodity_name': commodityName.trim(),
      'loaded_weight_kg': loadedWeightKg,
      'loaded_weight_maunds': maunds,
      'bag_count': bagCount,
      'party_name': partyName.trim(),
      'agreed_freight_pkr': agreedFreightPkr,
      'driver_advance_pkr': driverAdvancePkr,
      'diesel_expense_pkr': dieselExpensePkr,
      'toll_and_tax_pkr': tollAndTaxPkr,
      'other_expense_pkr': otherExpensePkr,
      'net_trip_profit_pkr': fin['netProfit'],
      'balance_freight_payable_pkr': fin['balanceFreight'],
      'status': TripStatus.inTransit.toDbString(),
      'notes': notes.trim(),
    };

    try {
      await SupabaseService.createFleetTrip(data);
      await loadFleetData();
      return true;
    } catch (e) {
      debugPrint('[FleetProvider] Error recording trip: $e');
      return false;
    }
  }

  Future<bool> completeTrip(String tripId, {
    double? finalDiesel,
    double? finalToll,
    double? finalOther,
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    try {
      final trip = _trips.firstWhere((t) => t.id == tripId);
      final diesel = finalDiesel ?? trip.dieselExpensePkr;
      final toll = finalToll ?? trip.tollAndTaxPkr;
      final other = finalOther ?? trip.otherExpensePkr;

      final fin = FleetTrip.computeTripFinances(
        agreedFreight: trip.agreedFreightPkr,
        driverAdvance: trip.driverAdvancePkr,
        diesel: diesel,
        toll: toll,
        other: other,
      );

      await SupabaseService.updateFleetTripStatus(
        tripId: tripId,
        shopId: shopId,
        status: TripStatus.completed.toDbString(),
        dieselExpense: diesel,
        tollTax: toll,
        otherExpense: other,
        netProfit: fin['netProfit'],
      );
      await loadFleetData();
      return true;
    } catch (e) {
      debugPrint('[FleetProvider] Error completing trip: $e');
      return false;
    }
  }

  // ── Fuel & Maintenance Operations ────────────────────────────────────────

  Future<bool> logFuelOrExpense({
    required String vehicleId,
    String? tripId,
    required DateTime logDate,
    String fuelType = 'diesel',
    required String pumpOrVendorName,
    required double liters,
    required double ratePerLiter,
    double odometerKm = 0.0,
    String receiptVoucherNumber = '',
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    final totalCost = liters * ratePerLiter;

    final data = {
      'shop_id': shopId,
      'vehicle_id': vehicleId,
      if (tripId != null && tripId.isNotEmpty) 'trip_id': tripId,
      'log_date': DateFormat('yyyy-MM-dd').format(logDate),
      'fuel_type': fuelType,
      'pump_or_vendor_name': pumpOrVendorName.trim(),
      'liters': liters,
      'rate_per_liter': ratePerLiter,
      'total_cost_pkr': totalCost,
      'odometer_km': odometerKm,
      'receipt_voucher_number': receiptVoucherNumber.trim(),
      'notes': notes.trim(),
    };

    try {
      await SupabaseService.createFleetFuelLog(data);

      // If vehicle odometer is updated, also update vehicle row
      if (odometerKm > 0) {
        await SupabaseService.updateFleetVehicle(
          id: vehicleId,
          shopId: shopId,
          data: {'odometer_km': odometerKm},
        );
      }

      await loadFleetData();
      return true;
    } catch (e) {
      debugPrint('[FleetProvider] Error logging fuel: $e');
      return false;
    }
  }

  // ── Filters & Selectors ──────────────────────────────────────────────────

  void setSelectedVehicleId(String? id) {
    _selectedVehicleId = id;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setStatusFilter(TripStatus? s) {
    _statusFilter = s;
    notifyListeners();
  }

  FleetVehicle? getVehicleById(String vehicleId) {
    try {
      return _vehicles.firstWhere((v) => v.id == vehicleId);
    } catch (_) {
      return null;
    }
  }
}
