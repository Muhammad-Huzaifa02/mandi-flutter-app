// Domain models for Mandi Grain & Produce Quality Inspection Lab,
// Moisture Content Testing, and Cold Chain Storage Monitoring
// (*جنس نمی، لیب کوالٹی گریڈنگ، کٹوتی سرٹیفکیٹ اور کولڈ سٹوریج لاگ*).

enum QualityGrade {
  gradeASuper,
  gradeBFaq,
  gradeCSubstandard,
  rejected;

  String toDbString() {
    switch (this) {
      case QualityGrade.gradeASuper:
        return 'grade_a_super';
      case QualityGrade.gradeBFaq:
        return 'grade_b_faq';
      case QualityGrade.gradeCSubstandard:
        return 'grade_c_substandard';
      case QualityGrade.rejected:
        return 'rejected';
    }
  }

  String get labelUrdu {
    switch (this) {
      case QualityGrade.gradeASuper:
        return 'گریڈ اے (اعلیٰ کوالٹی / سپر)';
      case QualityGrade.gradeBFaq:
        return 'گریڈ بی (اوسط منڈی معیار / FAQ)';
      case QualityGrade.gradeCSubstandard:
        return 'گریڈ سی (زیادہ نمی / کٹوتی)';
      case QualityGrade.rejected:
        return 'مسترد شدہ (ناقص مال)';
    }
  }

  String get labelEnglish {
    switch (this) {
      case QualityGrade.gradeASuper:
        return 'Grade A (Super / Premium)';
      case QualityGrade.gradeBFaq:
        return 'Grade B (Standard / FAQ)';
      case QualityGrade.gradeCSubstandard:
        return 'Grade C (High Moisture / Substandard)';
      case QualityGrade.rejected:
        return 'Rejected / Unfit';
    }
  }

  static QualityGrade fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'grade_a_super':
      case 'grade_a':
      case 'super':
        return QualityGrade.gradeASuper;
      case 'grade_c_substandard':
      case 'grade_c':
      case 'substandard':
        return QualityGrade.gradeCSubstandard;
      case 'rejected':
        return QualityGrade.rejected;
      case 'grade_b_faq':
      case 'grade_b':
      case 'faq':
      default:
        return QualityGrade.gradeBFaq;
    }
  }
}

enum ColdChainStatus {
  optimal,
  warning,
  critical;

  String toDbString() {
    switch (this) {
      case ColdChainStatus.optimal:
        return 'optimal';
      case ColdChainStatus.warning:
        return 'warning';
      case ColdChainStatus.critical:
        return 'critical';
    }
  }

  String get labelUrdu {
    switch (this) {
      case ColdChainStatus.optimal:
        return 'بہترین (Optimal)';
      case ColdChainStatus.warning:
        return 'توجہ طلب (Warning)';
      case ColdChainStatus.critical:
        return 'خرابی خطرہ (Critical)';
    }
  }

  String get labelEnglish {
    switch (this) {
      case ColdChainStatus.optimal:
        return 'Optimal';
      case ColdChainStatus.warning:
        return 'Warning';
      case ColdChainStatus.critical:
        return 'Critical';
    }
  }

  static ColdChainStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'warning':
        return ColdChainStatus.warning;
      case 'critical':
        return ColdChainStatus.critical;
      case 'optimal':
      default:
        return ColdChainStatus.optimal;
    }
  }
}

class QualityInspection {
  final String id;
  final String shopId;
  final String? lotId;
  final String certificateNumber;
  final DateTime inspectionDate;
  final String commodityName;
  final String variety;
  final String vehicleNumber;
  final String partyName;
  final double sampleWeightGrams;
  final double moisturePercentage;
  final double baseMoisturePercentage;
  final double foreignMatterPercentage;
  final double brokenGrainPercentage;
  final double damagedGrainPercentage;
  final double totalDeductionPercentage;
  final double grossWeightKg;
  final double deductionWeightKg;
  final double netWeightKg;
  final double netWeightMaunds;
  final QualityGrade qualityGrade;
  final double? temperatureCelsius;
  final double? humidityPercentage;
  final String chamberOrLocation;
  final String testerName;
  final String notes;
  final String status; // 'certified', 'pending', 'rejected'
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const QualityInspection({
    this.id = '',
    required this.shopId,
    this.lotId,
    required this.certificateNumber,
    required this.inspectionDate,
    required this.commodityName,
    this.variety = '',
    this.vehicleNumber = '',
    this.partyName = '',
    this.sampleWeightGrams = 500.0,
    required this.moisturePercentage,
    this.baseMoisturePercentage = 14.0,
    this.foreignMatterPercentage = 0.0,
    this.brokenGrainPercentage = 0.0,
    this.damagedGrainPercentage = 0.0,
    required this.totalDeductionPercentage,
    this.grossWeightKg = 0.0,
    required this.deductionWeightKg,
    required this.netWeightKg,
    required this.netWeightMaunds,
    this.qualityGrade = QualityGrade.gradeBFaq,
    this.temperatureCelsius,
    this.humidityPercentage,
    this.chamberOrLocation = '',
    this.testerName = '',
    this.notes = '',
    this.status = 'certified',
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isCertified => status == 'certified';
  bool get isRejected => qualityGrade == QualityGrade.rejected || status == 'rejected';

  /// Mathematical calculation helper for crop moisture & refraction deductions:
  /// - Excess moisture = max(0, moisture% - baseMoisture%).
  /// - Total Deduction % = excessMoisture + foreignMatter% + (brokenGrain% * 0.5) + (damagedGrain% * 0.75).
  /// - Deduction KG = grossWeightKg * (Total Deduction % / 100.0).
  /// - Net Weight KG = grossWeightKg - Deduction KG.
  /// - Net Weight Maunds = Net Weight KG / 40.0.
  static Map<String, dynamic> computeDeductions({
    required double moisturePercentage,
    required double baseMoisturePercentage,
    double foreignMatterPercentage = 0.0,
    double brokenGrainPercentage = 0.0,
    double damagedGrainPercentage = 0.0,
    required double grossWeightKg,
  }) {
    final excessMoisture =
        (moisturePercentage - baseMoisturePercentage).clamp(0.0, 50.0);

    final totalDeductionPct = excessMoisture +
        foreignMatterPercentage +
        (brokenGrainPercentage * 0.5) +
        (damagedGrainPercentage * 0.75);

    final deductionKg = (grossWeightKg * (totalDeductionPct / 100.0))
        .clamp(0.0, grossWeightKg);
    final netWeightKg =
        (grossWeightKg - deductionKg).clamp(0.0, grossWeightKg);
    final netMaunds = netWeightKg / 40.0;

    QualityGrade suggestedGrade;
    if (moisturePercentage > 24.0 ||
        foreignMatterPercentage > 8.0 ||
        damagedGrainPercentage > 10.0) {
      suggestedGrade = QualityGrade.rejected;
    } else if (excessMoisture > 4.0 || totalDeductionPct > 7.0) {
      suggestedGrade = QualityGrade.gradeCSubstandard;
    } else if (excessMoisture > 0.0 || totalDeductionPct > 2.0) {
      suggestedGrade = QualityGrade.gradeBFaq;
    } else {
      suggestedGrade = QualityGrade.gradeASuper;
    }

    return {
      'excessMoisture': excessMoisture,
      'totalDeductionPct': totalDeductionPct,
      'deductionKg': deductionKg,
      'netWeightKg': netWeightKg,
      'netWeightMaunds': netMaunds,
      'suggestedGrade': suggestedGrade,
    };
  }

  factory QualityInspection.fromMap(String id, Map<String, dynamic> data) {
    final grossKg = (data['gross_weight_kg'] as num?)?.toDouble() ?? 0.0;
    final dedKg = (data['deduction_weight_kg'] as num?)?.toDouble() ?? 0.0;
    final netKg = (data['net_weight_kg'] as num?)?.toDouble() ??
        (grossKg - dedKg).clamp(0.0, grossKg);
    final netMaunds = (data['net_weight_maunds'] as num?)?.toDouble() ??
        (netKg > 0 ? (netKg / 40.0) : 0.0);

    return QualityInspection(
      id: id,
      shopId: data['shop_id']?.toString() ?? '',
      lotId: data['lot_id']?.toString(),
      certificateNumber: data['certificate_number']?.toString() ?? '',
      inspectionDate: data['inspection_date'] != null
          ? DateTime.tryParse(data['inspection_date'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      commodityName: data['commodity_name']?.toString() ?? '',
      variety: data['variety']?.toString() ?? '',
      vehicleNumber: data['vehicle_number']?.toString() ?? '',
      partyName: data['party_name']?.toString() ?? '',
      sampleWeightGrams:
          (data['sample_weight_grams'] as num?)?.toDouble() ?? 500.0,
      moisturePercentage:
          (data['moisture_percentage'] as num?)?.toDouble() ?? 0.0,
      baseMoisturePercentage:
          (data['base_moisture_percentage'] as num?)?.toDouble() ?? 14.0,
      foreignMatterPercentage:
          (data['foreign_matter_percentage'] as num?)?.toDouble() ?? 0.0,
      brokenGrainPercentage:
          (data['broken_grain_percentage'] as num?)?.toDouble() ?? 0.0,
      damagedGrainPercentage:
          (data['damaged_grain_percentage'] as num?)?.toDouble() ?? 0.0,
      totalDeductionPercentage:
          (data['total_deduction_percentage'] as num?)?.toDouble() ?? 0.0,
      grossWeightKg: grossKg,
      deductionWeightKg: dedKg,
      netWeightKg: netKg,
      netWeightMaunds: netMaunds,
      qualityGrade: QualityGrade.fromString(
          data['quality_grade']?.toString() ?? 'grade_b_faq'),
      temperatureCelsius:
          (data['temperature_celsius'] as num?)?.toDouble(),
      humidityPercentage:
          (data['humidity_percentage'] as num?)?.toDouble(),
      chamberOrLocation: data['chamber_or_location']?.toString() ?? '',
      testerName: data['tester_name']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
      status: data['status']?.toString() ?? 'certified',
      createdBy: data['created_by']?.toString(),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      if (lotId != null && lotId!.isNotEmpty) 'lot_id': lotId,
      'certificate_number': certificateNumber,
      'inspection_date': inspectionDate.toIso8601String(),
      'commodity_name': commodityName,
      'variety': variety,
      'vehicle_number': vehicleNumber,
      'party_name': partyName,
      'sample_weight_grams': sampleWeightGrams,
      'moisture_percentage': moisturePercentage,
      'base_moisture_percentage': baseMoisturePercentage,
      'foreign_matter_percentage': foreignMatterPercentage,
      'broken_grain_percentage': brokenGrainPercentage,
      'damaged_grain_percentage': damagedGrainPercentage,
      'total_deduction_percentage': totalDeductionPercentage,
      'gross_weight_kg': grossWeightKg,
      'deduction_weight_kg': deductionWeightKg,
      'net_weight_kg': netWeightKg,
      'net_weight_maunds': netWeightMaunds,
      'quality_grade': qualityGrade.toDbString(),
      if (temperatureCelsius != null) 'temperature_celsius': temperatureCelsius,
      if (humidityPercentage != null) 'humidity_percentage': humidityPercentage,
      'chamber_or_location': chamberOrLocation,
      'tester_name': testerName,
      'notes': notes,
      'status': status,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}

class ColdChainLog {
  final String id;
  final String shopId;
  final String? storageId;
  final String chamberName;
  final DateTime recordedAt;
  final double temperatureCelsius;
  final double humidityPercentage;
  final double minTempThreshold;
  final double maxTempThreshold;
  final ColdChainStatus status;
  final String sensorDeviceId;
  final String inspectorName;
  final String correctiveAction;
  final DateTime createdAt;

  const ColdChainLog({
    this.id = '',
    required this.shopId,
    this.storageId,
    required this.chamberName,
    required this.recordedAt,
    required this.temperatureCelsius,
    required this.humidityPercentage,
    this.minTempThreshold = 0.0,
    this.maxTempThreshold = 4.0,
    this.status = ColdChainStatus.optimal,
    this.sensorDeviceId = '',
    this.inspectorName = '',
    this.correctiveAction = '',
    required this.createdAt,
  });

  static ColdChainStatus evaluateStatus({
    required double temp,
    required double minT,
    required double maxT,
  }) {
    if (temp < (minT - 3.0) || temp > (maxT + 3.0)) {
      return ColdChainStatus.critical;
    } else if (temp < minT || temp > maxT) {
      return ColdChainStatus.warning;
    }
    return ColdChainStatus.optimal;
  }

  factory ColdChainLog.fromMap(String id, Map<String, dynamic> data) {
    return ColdChainLog(
      id: id,
      shopId: data['shop_id']?.toString() ?? '',
      storageId: data['storage_id']?.toString(),
      chamberName: data['chamber_name']?.toString() ?? '',
      recordedAt: data['recorded_at'] != null
          ? DateTime.tryParse(data['recorded_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      temperatureCelsius:
          (data['temperature_celsius'] as num?)?.toDouble() ?? 0.0,
      humidityPercentage:
          (data['humidity_percentage'] as num?)?.toDouble() ?? 0.0,
      minTempThreshold:
          (data['min_temp_threshold'] as num?)?.toDouble() ?? 0.0,
      maxTempThreshold:
          (data['max_temp_threshold'] as num?)?.toDouble() ?? 4.0,
      status: ColdChainStatus.fromString(data['status']?.toString() ?? 'optimal'),
      sensorDeviceId: data['sensor_device_id']?.toString() ?? '',
      inspectorName: data['inspector_name']?.toString() ?? '',
      correctiveAction: data['corrective_action']?.toString() ?? '',
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      if (storageId != null && storageId!.isNotEmpty) 'storage_id': storageId,
      'chamber_name': chamberName,
      'recorded_at': recordedAt.toIso8601String(),
      'temperature_celsius': temperatureCelsius,
      'humidity_percentage': humidityPercentage,
      'min_temp_threshold': minTempThreshold,
      'max_temp_threshold': maxTempThreshold,
      'status': status.toDbString(),
      'sensor_device_id': sensorDeviceId,
      'inspector_name': inspectorName,
      'corrective_action': correctiveAction,
    };
  }
}
