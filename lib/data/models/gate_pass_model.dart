// Domain model for Mandi Gate Pass, Inward Token & Unloading Queue
// (*گیٹ پاس، ٹوکن اور ٹریکٹر لائن نمبر*).

import 'package:intl/intl.dart';

enum GatePassStatus {
  queued,
  unloading,
  weighed,
  clearedGateOut,
  cancelled;

  static GatePassStatus fromString(String val) {
    switch (val.toLowerCase().replaceAll('-', '_')) {
      case 'unloading':
        return GatePassStatus.unloading;
      case 'weighed':
        return GatePassStatus.weighed;
      case 'cleared_gate_out':
      case 'cleared':
        return GatePassStatus.clearedGateOut;
      case 'cancelled':
        return GatePassStatus.cancelled;
      case 'queued':
      default:
        return GatePassStatus.queued;
    }
  }

  String toDbString() {
    switch (this) {
      case GatePassStatus.queued:
        return 'queued';
      case GatePassStatus.unloading:
        return 'unloading';
      case GatePassStatus.weighed:
        return 'weighed';
      case GatePassStatus.clearedGateOut:
        return 'cleared_gate_out';
      case GatePassStatus.cancelled:
        return 'cancelled';
    }
  }

  String get labelUrdu {
    switch (this) {
      case GatePassStatus.queued:
        return 'قطار میں موجود';
      case GatePassStatus.unloading:
        return 'پھڑ پر ان لوڈنگ';
      case GatePassStatus.weighed:
        return 'وزن مکمل';
      case GatePassStatus.clearedGateOut:
        return 'گیٹ آؤٹ کلیئر';
      case GatePassStatus.cancelled:
        return 'منسوخ';
    }
  }

  String get labelEnglish {
    switch (this) {
      case GatePassStatus.queued:
        return 'In Queue';
      case GatePassStatus.unloading:
        return 'Unloading at Platform';
      case GatePassStatus.weighed:
        return 'Weighed (Tare Done)';
      case GatePassStatus.clearedGateOut:
        return 'Gate-Out Cleared';
      case GatePassStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class GatePassModel {
  final String id;
  final String shopId;
  final String tokenNumber; // e.g. TKN-001
  final String vehicleNumber; // e.g. LHR-8912 or Tractor #3
  final String driverName;
  final String? driverPhone;
  final String? farmerSupplierId;
  final String farmerName;
  final String commodityName;
  final int estimatedBags;
  final DateTime inwardTime;
  final String? assignedPlatform; // e.g. پھڑ نمبر 3
  final double? grossWeightKg;
  final double? tareWeightKg;
  final double? netWeightKg;
  final GatePassStatus status;
  final DateTime? outwardTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  GatePassModel({
    required this.id,
    required this.shopId,
    required this.tokenNumber,
    required this.vehicleNumber,
    required this.driverName,
    this.driverPhone,
    this.farmerSupplierId,
    required this.farmerName,
    required this.commodityName,
    required this.estimatedBags,
    required this.inwardTime,
    this.assignedPlatform,
    this.grossWeightKg,
    this.tareWeightKg,
    this.netWeightKg,
    this.status = GatePassStatus.queued,
    this.outwardTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double? get netMaunds =>
      netWeightKg != null ? (netWeightKg! / 40.0) : null;

  String get inwardTimeFormatted =>
      DateFormat('dd-MMM-yyyy hh:mm a').format(inwardTime);

  String? get outwardTimeFormatted =>
      outwardTime != null ? DateFormat('dd-MMM-yyyy hh:mm a').format(outwardTime!) : null;

  factory GatePassModel.fromJson(Map<String, dynamic> json) {
    return GatePassModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      tokenNumber: json['token_number'] as String? ?? 'TKN-000',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      driverName: json['driver_name'] as String? ?? '',
      driverPhone: json['driver_phone'] as String?,
      farmerSupplierId: json['farmer_supplier_id'] as String?,
      farmerName: json['farmer_name'] as String? ?? '',
      commodityName: json['commodity_name'] as String? ?? '',
      estimatedBags: (json['estimated_bags'] as num?)?.toInt() ?? 0,
      inwardTime: json['inward_time'] != null
          ? DateTime.parse(json['inward_time'] as String)
          : DateTime.now(),
      assignedPlatform: json['assigned_platform'] as String?,
      grossWeightKg: (json['gross_weight_kg'] as num?)?.toDouble(),
      tareWeightKg: (json['tare_weight_kg'] as num?)?.toDouble(),
      netWeightKg: (json['net_weight_kg'] as num?)?.toDouble(),
      status: GatePassStatus.fromString(json['status'] as String? ?? 'queued'),
      outwardTime: json['outward_time'] != null
          ? DateTime.parse(json['outward_time'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'token_number': tokenNumber,
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'farmer_supplier_id': farmerSupplierId,
      'farmer_name': farmerName,
      'commodity_name': commodityName,
      'estimated_bags': estimatedBags,
      'inward_time': inwardTime.toIso8601String(),
      'assigned_platform': assignedPlatform,
      'gross_weight_kg': grossWeightKg,
      'tare_weight_kg': tareWeightKg,
      'net_weight_kg': netWeightKg,
      'status': status.toDbString(),
      'outward_time': outwardTime?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GatePassModel copyWith({
    String? id,
    String? shopId,
    String? tokenNumber,
    String? vehicleNumber,
    String? driverName,
    String? driverPhone,
    String? farmerSupplierId,
    String? farmerName,
    String? commodityName,
    int? estimatedBags,
    DateTime? inwardTime,
    String? assignedPlatform,
    double? grossWeightKg,
    double? tareWeightKg,
    double? netWeightKg,
    GatePassStatus? status,
    DateTime? outwardTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GatePassModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      farmerSupplierId: farmerSupplierId ?? this.farmerSupplierId,
      farmerName: farmerName ?? this.farmerName,
      commodityName: commodityName ?? this.commodityName,
      estimatedBags: estimatedBags ?? this.estimatedBags,
      inwardTime: inwardTime ?? this.inwardTime,
      assignedPlatform: assignedPlatform ?? this.assignedPlatform,
      grossWeightKg: grossWeightKg ?? this.grossWeightKg,
      tareWeightKg: tareWeightKg ?? this.tareWeightKg,
      netWeightKg: netWeightKg ?? this.netWeightKg,
      status: status ?? this.status,
      outwardTime: outwardTime ?? this.outwardTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
