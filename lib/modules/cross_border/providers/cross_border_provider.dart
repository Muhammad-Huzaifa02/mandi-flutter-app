import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:mandi/data/models/cross_border_shipment_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Provider managing Cross-Border Cargo Shipments & Multi-Currency Portfolios.
class CrossBorderProvider extends ChangeNotifier {
  String? _shopId;

  List<CrossBorderShipment> _shipments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, inTransit, clearedAtBorder, arrivedInMandi, settled
  String _countryFilter = 'all'; // all, afghanistan, iran, centralAsia

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  CrossBorderProvider({String? shopId}) : _shopId = shopId {
    if (_shopId != null && _shopId!.isNotEmpty) {
      _initStream();
    } else {
      _isLoading = false;
    }
  }

  String get shopId => _shopId ?? '';

  void updateShop(String? newShopId) {
    if (_shopId == newShopId) return;
    _shopId = newShopId;
    _shipments = [];
    _subscription?.cancel();
    _subscription = null;
    if (_shopId != null && _shopId!.isNotEmpty) {
      _initStream();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<CrossBorderShipment> get shipments => _shipments;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get countryFilter => _countryFilter;

  CrossBorderSummary get summary => CrossBorderSummary.fromShipments(_shipments);

  List<CrossBorderShipment> get filteredShipments {
    return _shipments.where((s) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesNum = s.shipmentNumber.toLowerCase().contains(q);
        final matchesVehicle = s.vehicleNumber.toLowerCase().contains(q);
        final matchesDriver = s.driverName.toLowerCase().contains(q);
        final matchesSupplier = s.supplierName.toLowerCase().contains(q);
        final matchesGd = s.customsGdNumber.toLowerCase().contains(q);
        final matchesCommodity = s.commodity.toLowerCase().contains(q);

        if (!matchesNum &&
            !matchesVehicle &&
            !matchesDriver &&
            !matchesSupplier &&
            !matchesGd &&
            !matchesCommodity) {
          return false;
        }
      }

      // 2. Status Filter
      if (_statusFilter != 'all') {
        if (_statusFilter == 'inTransit' &&
            s.status != CrossBorderShipmentStatus.inTransit) {
          return false;
        }
        if (_statusFilter == 'clearedAtBorder' &&
            s.status != CrossBorderShipmentStatus.clearedAtBorder) {
          return false;
        }
        if (_statusFilter == 'arrivedInMandi' &&
            s.status != CrossBorderShipmentStatus.arrivedInMandi) {
          return false;
        }
        if (_statusFilter == 'settled' &&
            s.status != CrossBorderShipmentStatus.settled) {
          return false;
        }
      }

      // 3. Country Filter
      if (_countryFilter != 'all') {
        if (_countryFilter == 'afghanistan' &&
            s.originCountry != OriginCountry.afghanistan) {
          return false;
        }
        if (_countryFilter == 'iran' && s.originCountry != OriginCountry.iran) {
          return false;
        }
        if (_countryFilter == 'centralAsia' &&
            s.originCountry != OriginCountry.centralAsia) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _initStream() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription =
        SupabaseService.crossBorderShipmentsStream(shopId).listen(
      (data) {
        _shipments = data
            .map((map) => CrossBorderShipment.fromMap(
                map['id']?.toString() ?? '', map))
            .toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('CrossBorderProvider stream error: $err');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void setSearchQuery(String q) {
    _searchQuery = q.trim();
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setCountryFilter(String filter) {
    _countryFilter = filter;
    notifyListeners();
  }

  Future<String> createShipment(CrossBorderShipment shipment) async {
    final map = shipment.toMap();
    map['shop_id'] = shopId;
    final id = await SupabaseService.createCrossBorderShipment(map);
    return id;
  }

  Future<void> updateShipment(CrossBorderShipment shipment) async {
    await SupabaseService.updateCrossBorderShipment(
      id: shipment.id,
      shopId: shopId,
      data: shipment.toMap(),
    );
  }

  Future<void> updateShipmentStatus({
    required String id,
    required CrossBorderShipmentStatus newStatus,
    String? consignmentLotId,
  }) async {
    final updateData = <String, dynamic>{
      'status': newStatus.name,
    };
    if (consignmentLotId != null) {
      updateData['consignment_lot_id'] = consignmentLotId;
    }
    await SupabaseService.updateCrossBorderShipment(
      id: id,
      shopId: shopId,
      data: updateData,
    );
  }

  Future<void> recordSupplierPayment({
    required CrossBorderShipment shipment,
    required double additionalForeignAmount,
  }) async {
    final newPaid = shipment.paidToSupplierForeign + additionalForeignAmount;
    final newRemaining =
        (shipment.foreignContractAmount - newPaid).clamp(0.0, double.infinity);
    final newStatus = newRemaining <= 0
        ? CrossBorderShipmentStatus.settled
        : shipment.status;

    await SupabaseService.updateCrossBorderShipment(
      id: shipment.id,
      shopId: shopId,
      data: {
        'paid_to_supplier_foreign': newPaid,
        'remaining_supplier_foreign': newRemaining,
        'status': newStatus.name,
      },
    );
  }

  Future<void> deleteShipment(String id) async {
    await SupabaseService.deleteCrossBorderShipment(id: id, shopId: shopId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
