// Centralized Provider for Mandi Barcode, QR Code & Pallet Inventory Labels
// (*بارکوڈ و کیو آر انوینٹری لیبلز اور پیلیٹ ٹریکنگ پرووائیڈر*).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:mandi/data/models/inventory_label_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

class InventoryLabelProvider extends ChangeNotifier {
  String? _currentShopId;
  StreamSubscription<List<Map<String, dynamic>>>? _labelsSub;

  List<InventoryLabel> _labels = [];
  bool _isLoading = false;
  String _searchQuery = '';
  InventoryLabelType? _filterType;
  LabelStatus? _filterStatus;
  String? _filterCommodity;

  List<InventoryLabel> get allLabels => _labels;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  InventoryLabelType? get filterType => _filterType;
  LabelStatus? get filterStatus => _filterStatus;
  String? get filterCommodity => _filterCommodity;

  List<InventoryLabel> get filteredLabels {
    return _labels.where((lbl) {
      if (_filterType != null && lbl.labelType != _filterType) {
        return false;
      }
      if (_filterStatus != null && lbl.status != _filterStatus) {
        return false;
      }
      if (_filterCommodity != null &&
          _filterCommodity!.isNotEmpty &&
          lbl.commodityName != _filterCommodity) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchCode = lbl.labelCode.toLowerCase().contains(q);
        final matchBarcode = lbl.barcodeValue.toLowerCase().contains(q);
        final matchCrop = lbl.commodityName.toLowerCase().contains(q) ||
            lbl.variety.toLowerCase().contains(q);
        final matchParty = lbl.partyName.toLowerCase().contains(q);
        final matchVehicle = lbl.vehicleNumber.toLowerCase().contains(q);
        final matchLoc = lbl.facilityName.toLowerCase().contains(q) ||
            lbl.bayOrStack.toLowerCase().contains(q);
        if (!matchCode &&
            !matchBarcode &&
            !matchCrop &&
            !matchParty &&
            !matchVehicle &&
            !matchLoc) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // =========================================================================
  // METRICS & KPIS
  // =========================================================================

  int get totalActiveLabels =>
      _labels.where((e) => e.status == LabelStatus.active).length;

  int get totalActiveBags => _labels
      .where((e) => e.status == LabelStatus.active)
      .fold<int>(0, (sum, e) => sum + e.bagCount);

  double get totalActiveNetKg => _labels
      .where((e) => e.status == LabelStatus.active)
      .fold<double>(0.0, (sum, e) => sum + e.netWeightKg);

  double get totalActiveNetMaunds => _labels
      .where((e) => e.status == LabelStatus.active)
      .fold<double>(0.0, (sum, e) => sum + e.netWeightMaunds);

  int get totalDispatchedLabels =>
      _labels.where((e) => e.status == LabelStatus.dispatched).length;

  List<String> get availableCommodities {
    final set = <String>{};
    for (final l in _labels) {
      if (l.commodityName.isNotEmpty) set.add(l.commodityName);
    }
    return set.toList()..sort();
  }

  // =========================================================================
  // LIFECYCLE & SUBSCRIPTION
  // =========================================================================

  void updateShop(String? shopId) {
    if (_currentShopId == shopId) return;
    _currentShopId = shopId;
    _labelsSub?.cancel();
    _labels = [];
    if (shopId != null && shopId.isNotEmpty) {
      _subscribeLabels(shopId);
    } else {
      notifyListeners();
    }
  }

  void _subscribeLabels(String shopId) {
    _isLoading = true;
    notifyListeners();

    _labelsSub = SupabaseService.inventoryLabelsStream(shopId).listen(
      (rows) {
        _labels = rows
            .map((r) => InventoryLabel.fromMap(r['id'] as String, r))
            .toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('Error streaming inventory labels: $err');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _labelsSub?.cancel();
    super.dispose();
  }

  // =========================================================================
  // FILTERING & SEARCH
  // =========================================================================

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilterType(InventoryLabelType? type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterStatus(LabelStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterCommodity(String? commodity) {
    _filterCommodity = commodity;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterType = null;
    _filterStatus = null;
    _filterCommodity = null;
    notifyListeners();
  }

  // =========================================================================
  // CRUD ACTIONS
  // =========================================================================

  String nextLabelCode({InventoryLabelType type = InventoryLabelType.lot}) {
    final datePrefix = DateFormat('yyMM').format(DateTime.now());
    final typePrefix = type == InventoryLabelType.palletStack
        ? 'PLT'
        : type == InventoryLabelType.godownBay
            ? 'BAY'
            : type == InventoryLabelType.dispatchChallan
                ? 'DSP'
                : 'LBL';
    final count = _labels.length + 1;
    final seqStr = count.toString().padLeft(4, '0');
    return '$typePrefix-$datePrefix-$seqStr';
  }

  String nextBarcodeValue(String labelCode) {
    // Code128 clean alphanumeric string
    return labelCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  }

  Future<String> createLabel({
    String? lotId,
    String? storageId,
    required String labelCode,
    required String barcodeValue,
    required String qrPayload,
    InventoryLabelType labelType = InventoryLabelType.lot,
    required String commodityName,
    String variety = '',
    String partyName = '',
    String vehicleNumber = '',
    int bagCount = 0,
    PackageType packageType = PackageType.juteBag,
    double grossWeightKg = 0.0,
    required double netWeightKg,
    required double netWeightMaunds,
    String qualityGrade = 'grade_b_faq',
    String facilityName = '',
    String bayOrStack = '',
    String notes = '',
    LabelStatus status = LabelStatus.active,
  }) async {
    if (_currentShopId == null) throw Exception('No active shop selected');

    final data = {
      'shop_id': _currentShopId,
      if (lotId != null && lotId.isNotEmpty) 'lot_id': lotId,
      if (storageId != null && storageId.isNotEmpty) 'storage_id': storageId,
      'label_code': labelCode,
      'barcode_value': barcodeValue,
      'qr_payload': qrPayload,
      'label_type': labelType.toDbString(),
      'commodity_name': commodityName,
      'variety': variety,
      'party_name': partyName,
      'vehicle_number': vehicleNumber,
      'bag_count': bagCount,
      'package_type': packageType.toDbString(),
      'gross_weight_kg': grossWeightKg,
      'net_weight_kg': netWeightKg,
      'net_weight_maunds': netWeightMaunds,
      'quality_grade': qualityGrade,
      'facility_name': facilityName,
      'bay_or_stack': bayOrStack,
      'notes': notes,
      'status': status.toDbString(),
    };

    final id = await SupabaseService.createInventoryLabel(data);
    return id;
  }

  Future<void> updateLabelStatus(String id, LabelStatus status) async {
    if (_currentShopId == null) throw Exception('No active shop selected');
    await SupabaseService.updateInventoryLabelStatus(
      id: id,
      shopId: _currentShopId!,
      status: status.toDbString(),
    );
  }

  Future<void> deleteLabel(String id) async {
    if (_currentShopId == null) throw Exception('No active shop selected');
    await SupabaseService.deleteInventoryLabel(
      id: id,
      shopId: _currentShopId!,
    );
  }

  /// Looks up an existing label by scanned barcode, QR payload string, or label code.
  InventoryLabel? findLabelByScan(String scannedText) {
    final clean = scannedText.trim();
    if (clean.isEmpty) return null;

    for (final l in _labels) {
      if (l.labelCode.equalsIgnoreCase(clean) ||
          l.barcodeValue.equalsIgnoreCase(clean) ||
          l.qrPayload == clean) {
        return l;
      }
      // Check if scannedText is substring of QR or contains labelCode
      if (clean.contains(l.labelCode) || clean.contains(l.barcodeValue)) {
        return l;
      }
    }
    return null;
  }
}

extension _StringExt on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}
