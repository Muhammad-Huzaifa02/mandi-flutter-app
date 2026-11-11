import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:mandi/data/models/quality_inspection_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Central provider managing Mandi Commodity Testing, Moisture Katoti Deductions,
/// Quality Grading Certificates, and Cold Chain Storage Logs
/// (*جنس لیب کوالٹی گریڈنگ، نمی کٹوتی اور کولڈ سٹوریج لاگ*).
class QualityProvider extends ChangeNotifier {
  String? _currentShopId;

  List<QualityInspection> _inspections = [];
  List<ColdChainLog> _coldChainLogs = [];

  bool _isLoading = false;
  String _searchQuery = '';
  QualityGrade? _selectedGrade;
  String? _selectedCommodity;
  String? _selectedChamber;

  StreamSubscription? _inspectionsSub;
  StreamSubscription? _coldChainSub;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<QualityInspection> get inspections => _inspections;
  List<ColdChainLog> get coldChainLogs => _coldChainLogs;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  QualityGrade? get selectedGrade => _selectedGrade;
  String? get selectedCommodity => _selectedCommodity;
  String? get selectedChamber => _selectedChamber;

  List<QualityInspection> get filteredInspections {
    return _inspections.where((q) {
      if (_selectedGrade != null && q.qualityGrade != _selectedGrade) {
        return false;
      }
      if (_selectedCommodity != null &&
          _selectedCommodity!.isNotEmpty &&
          q.commodityName.toLowerCase() != _selectedCommodity!.toLowerCase()) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final term = _searchQuery.trim().toLowerCase();
        final matchCert = q.certificateNumber.toLowerCase().contains(term);
        final matchParty = q.partyName.toLowerCase().contains(term);
        final matchCargo = q.commodityName.toLowerCase().contains(term);
        final matchVehicle = q.vehicleNumber.toLowerCase().contains(term);
        if (!matchCert && !matchParty && !matchCargo && !matchVehicle) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<ColdChainLog> get filteredColdChainLogs {
    if (_selectedChamber == null || _selectedChamber!.isEmpty) {
      return _coldChainLogs;
    }
    return _coldChainLogs
        .where((c) =>
            c.chamberName.toLowerCase() == _selectedChamber!.toLowerCase())
        .toList();
  }

  List<String> get availableCommodities {
    final set = <String>{};
    for (final i in _inspections) {
      if (i.commodityName.isNotEmpty) set.add(i.commodityName);
    }
    return set.toList();
  }

  List<String> get availableChambers {
    final set = <String>{};
    for (final c in _coldChainLogs) {
      if (c.chamberName.isNotEmpty) set.add(c.chamberName);
    }
    return set.toList();
  }

  // ── KPI Metrics ──────────────────────────────────────────────────────────

  int get totalInspectionsCount => _inspections.length;

  int get certifiedCount =>
      _inspections.where((i) => i.status == 'certified').length;

  int get rejectedCount =>
      _inspections.where((i) => i.isRejected).length;

  double get averageMoisture {
    if (_inspections.isEmpty) return 0.0;
    final sum = _inspections.fold(0.0, (acc, i) => acc + i.moisturePercentage);
    return sum / _inspections.length;
  }

  double get totalGrossWeightKg =>
      _inspections.fold(0.0, (acc, i) => acc + i.grossWeightKg);

  double get totalDeductionWeightKg =>
      _inspections.fold(0.0, (acc, i) => acc + i.deductionWeightKg);

  double get totalNetWeightKg =>
      _inspections.fold(0.0, (acc, i) => acc + i.netWeightKg);

  double get totalNetWeightMaunds =>
      _inspections.fold(0.0, (acc, i) => acc + i.netWeightMaunds);

  int get activeColdChainAlerts =>
      _coldChainLogs.where((c) => c.status != ColdChainStatus.optimal).length;

  // ── Shop Life-cycle ──────────────────────────────────────────────────────

  void updateShop(String? shopId) {
    if (_currentShopId != shopId) {
      _currentShopId = shopId;
      _cancelSubscriptions();
      if (shopId != null && shopId.isNotEmpty) {
        loadQualityData();
        _subscribeToStreams(shopId);
      } else {
        _inspections = [];
        _coldChainLogs = [];
        notifyListeners();
      }
    }
  }

  void _subscribeToStreams(String shopId) {
    _cancelSubscriptions();

    _inspectionsSub =
        SupabaseService.qualityInspectionsStream(shopId).listen(
      (rows) {
        _inspections = rows
            .map((r) =>
                QualityInspection.fromMap(r['id']?.toString() ?? '', r))
            .toList();
        notifyListeners();
      },
      onError: (err) =>
          debugPrint('[QualityProvider] Inspections stream error: $err'),
    );

    _coldChainSub = SupabaseService.coldChainLogsStream(shopId).listen(
      (rows) {
        _coldChainLogs = rows
            .map((r) => ColdChainLog.fromMap(r['id']?.toString() ?? '', r))
            .toList();
        notifyListeners();
      },
      onError: (err) =>
          debugPrint('[QualityProvider] Cold chain stream error: $err'),
    );
  }

  void _cancelSubscriptions() {
    _inspectionsSub?.cancel();
    _inspectionsSub = null;
    _coldChainSub?.cancel();
    _coldChainSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  // ── Data Loading & Operations ────────────────────────────────────────────

  Future<void> loadQualityData() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final iRows = await SupabaseService.getQualityInspections(shopId);
      _inspections = iRows
          .map((r) => QualityInspection.fromMap(r['id']?.toString() ?? '', r))
          .toList();

      final cRows = await SupabaseService.getColdChainLogs(shopId);
      _coldChainLogs = cRows
          .map((r) => ColdChainLog.fromMap(r['id']?.toString() ?? '', r))
          .toList();
    } catch (e) {
      debugPrint('[QualityProvider] Error loading quality data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordInspection({
    String? lotId,
    required DateTime inspectionDate,
    required String commodityName,
    String variety = '',
    String vehicleNumber = '',
    String partyName = '',
    double sampleWeightGrams = 500.0,
    required double moisturePercentage,
    double baseMoisturePercentage = 14.0,
    double foreignMatterPercentage = 0.0,
    double brokenGrainPercentage = 0.0,
    double damagedGrainPercentage = 0.0,
    required double grossWeightKg,
    QualityGrade? qualityGrade,
    double? temperatureCelsius,
    double? humidityPercentage,
    String chamberOrLocation = '',
    String testerName = '',
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    final ded = QualityInspection.computeDeductions(
      moisturePercentage: moisturePercentage,
      baseMoisturePercentage: baseMoisturePercentage,
      foreignMatterPercentage: foreignMatterPercentage,
      brokenGrainPercentage: brokenGrainPercentage,
      damagedGrainPercentage: damagedGrainPercentage,
      grossWeightKg: grossWeightKg,
    );

    final grade = qualityGrade ?? (ded['suggestedGrade'] as QualityGrade);

    final randomSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
    final certNum = 'QC-${DateFormat("yyMM").format(DateTime.now())}-$randomSuffix';

    final data = {
      'shop_id': shopId,
      if (lotId != null && lotId.isNotEmpty) 'lot_id': lotId,
      'certificate_number': certNum,
      'inspection_date': inspectionDate.toIso8601String(),
      'commodity_name': commodityName.trim(),
      'variety': variety.trim(),
      'vehicle_number': vehicleNumber.toUpperCase().trim(),
      'party_name': partyName.trim(),
      'sample_weight_grams': sampleWeightGrams,
      'moisture_percentage': moisturePercentage,
      'base_moisture_percentage': baseMoisturePercentage,
      'foreign_matter_percentage': foreignMatterPercentage,
      'broken_grain_percentage': brokenGrainPercentage,
      'damaged_grain_percentage': damagedGrainPercentage,
      'total_deduction_percentage': ded['totalDeductionPct'],
      'gross_weight_kg': grossWeightKg,
      'deduction_weight_kg': ded['deductionKg'],
      'net_weight_kg': ded['netWeightKg'],
      'net_weight_maunds': ded['netWeightMaunds'],
      'quality_grade': grade.toDbString(),
      if (temperatureCelsius != null)
        'temperature_celsius': temperatureCelsius,
      if (humidityPercentage != null)
        'humidity_percentage': humidityPercentage,
      'chamber_or_location': chamberOrLocation.trim(),
      'tester_name': testerName.trim(),
      'notes': notes.trim(),
      'status': grade == QualityGrade.rejected ? 'rejected' : 'certified',
    };

    try {
      await SupabaseService.createQualityInspection(data);
      await loadQualityData();
      return true;
    } catch (e) {
      debugPrint('[QualityProvider] Error recording inspection: $e');
      return false;
    }
  }

  Future<bool> logColdChainReading({
    String? storageId,
    required String chamberName,
    required DateTime recordedAt,
    required double temperatureCelsius,
    required double humidityPercentage,
    double minTempThreshold = 0.0,
    double maxTempThreshold = 4.0,
    String sensorDeviceId = '',
    String inspectorName = '',
    String correctiveAction = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    final status = ColdChainLog.evaluateStatus(
      temp: temperatureCelsius,
      minT: minTempThreshold,
      maxT: maxTempThreshold,
    );

    final data = {
      'shop_id': shopId,
      if (storageId != null && storageId.isNotEmpty) 'storage_id': storageId,
      'chamber_name': chamberName.trim(),
      'recorded_at': recordedAt.toIso8601String(),
      'temperature_celsius': temperatureCelsius,
      'humidity_percentage': humidityPercentage,
      'min_temp_threshold': minTempThreshold,
      'max_temp_threshold': maxTempThreshold,
      'status': status.toDbString(),
      'sensor_device_id': sensorDeviceId.trim(),
      'inspector_name': inspectorName.trim(),
      'corrective_action': correctiveAction.trim(),
    };

    try {
      await SupabaseService.createColdChainLog(data);
      await loadQualityData();
      return true;
    } catch (e) {
      debugPrint('[QualityProvider] Error logging cold chain reading: $e');
      return false;
    }
  }

  Future<bool> updateInspectionStatus(String id, String status) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    try {
      await SupabaseService.updateQualityInspectionStatus(
        id: id,
        shopId: shopId,
        status: status,
      );
      await loadQualityData();
      return true;
    } catch (e) {
      debugPrint('[QualityProvider] Error updating inspection status: $e');
      return false;
    }
  }

  // ── Filters & Selectors ──────────────────────────────────────────────────

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setGradeFilter(QualityGrade? g) {
    _selectedGrade = g;
    notifyListeners();
  }

  void setCommodityFilter(String? c) {
    _selectedCommodity = c;
    notifyListeners();
  }

  void setChamberFilter(String? chamber) {
    _selectedChamber = chamber;
    notifyListeners();
  }
}
