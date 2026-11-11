// Domain model for Visual 2D Godown & Cold Storage Floor Grid
// (*گودام اور کولڈ سٹوریج کا تصویری نقشہ*).

import 'package:intl/intl.dart';

enum BayStatus {
  empty,
  partiallyStored,
  full,
  maintenance;

  static BayStatus fromString(String val) {
    switch (val.toLowerCase().replaceAll('-', '_')) {
      case 'partially_stored':
      case 'partial':
        return BayStatus.partiallyStored;
      case 'full':
        return BayStatus.full;
      case 'maintenance':
        return BayStatus.maintenance;
      case 'empty':
      default:
        return BayStatus.empty;
    }
  }

  String toDbString() {
    switch (this) {
      case BayStatus.empty:
        return 'empty';
      case BayStatus.partiallyStored:
        return 'partially_stored';
      case BayStatus.full:
        return 'full';
      case BayStatus.maintenance:
        return 'maintenance';
    }
  }

  String get labelUrdu {
    switch (this) {
      case BayStatus.empty:
        return 'خالی (Empty)';
      case BayStatus.partiallyStored:
        return 'جزوی بھرا ہوا (Partially Stored)';
      case BayStatus.full:
        return 'مکمل بھرا ہوا (Full)';
      case BayStatus.maintenance:
        return 'مرمت / بند (Maintenance)';
    }
  }

  String get labelEnglish {
    switch (this) {
      case BayStatus.empty:
        return 'Empty';
      case BayStatus.partiallyStored:
        return 'Partially Stored';
      case BayStatus.full:
        return 'Full';
      case BayStatus.maintenance:
        return 'Maintenance';
    }
  }
}

class WarehouseGridBayModel {
  final String id;
  final String shopId;
  final String chamberCode; // e.g. Chamber 1, Cold Store A
  final String bayCode; // e.g. A1, B4
  final int rowCoord; // 0-based or 1-based row index
  final int colCoord; // 0-based or 1-based col index
  final int maxCapacityBags;
  final int currentBags;
  final String? cropName;
  final String? farmerSupplierId;
  final String? farmerName;
  final String? lotCode; // e.g. LOT-WHT-089
  final DateTime? storageStartDate;
  final BayStatus status;
  final String? notes;
  final DateTime updatedAt;

  WarehouseGridBayModel({
    required this.id,
    required this.shopId,
    required this.chamberCode,
    required this.bayCode,
    required this.rowCoord,
    required this.colCoord,
    this.maxCapacityBags = 200,
    this.currentBags = 0,
    this.cropName,
    this.farmerSupplierId,
    this.farmerName,
    this.lotCode,
    this.storageStartDate,
    this.status = BayStatus.empty,
    this.notes,
    required this.updatedAt,
  });

  double get occupancyRatio =>
      maxCapacityBags > 0 ? (currentBags / maxCapacityBags).clamp(0.0, 1.0) : 0.0;

  double get occupancyPercent => occupancyRatio * 100.0;

  int get daysInStorage => storageStartDate != null
      ? DateTime.now().difference(storageStartDate!).inDays
      : 0;

  bool get isOverdue => daysInStorage > 90;

  bool get isEmpty => currentBags == 0;

  bool get isFull => currentBags >= maxCapacityBags;

  String get formattedStartDate => storageStartDate != null
      ? DateFormat('dd-MMM-yyyy').format(storageStartDate!)
      : '-';

  factory WarehouseGridBayModel.fromJson(Map<String, dynamic> json) {
    return WarehouseGridBayModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      chamberCode: json['chamber_code'] as String? ?? 'CH-1',
      bayCode: json['bay_code'] as String? ?? 'A1',
      rowCoord: (json['row_coord'] as num?)?.toInt() ?? 1,
      colCoord: (json['col_coord'] as num?)?.toInt() ?? 1,
      maxCapacityBags: (json['max_capacity_bags'] as num?)?.toInt() ?? 200,
      currentBags: (json['current_bags'] as num?)?.toInt() ?? 0,
      cropName: json['crop_name'] as String?,
      farmerSupplierId: json['farmer_supplier_id'] as String?,
      farmerName: json['farmer_name'] as String?,
      lotCode: json['lot_code'] as String?,
      storageStartDate: json['storage_start_date'] != null
          ? DateTime.parse(json['storage_start_date'] as String)
          : null,
      status: BayStatus.fromString(json['status'] as String? ?? 'empty'),
      notes: json['notes'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'chamber_code': chamberCode,
      'bay_code': bayCode,
      'row_coord': rowCoord,
      'col_coord': colCoord,
      'max_capacity_bags': maxCapacityBags,
      'current_bags': currentBags,
      'crop_name': cropName,
      'farmer_supplier_id': farmerSupplierId,
      'farmer_name': farmerName,
      'lot_code': lotCode,
      'storage_start_date': storageStartDate?.toIso8601String(),
      'status': status.toDbString(),
      'notes': notes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  WarehouseGridBayModel copyWith({
    String? id,
    String? shopId,
    String? chamberCode,
    String? bayCode,
    int? rowCoord,
    int? colCoord,
    int? maxCapacityBags,
    int? currentBags,
    String? cropName,
    String? farmerSupplierId,
    String? farmerName,
    String? lotCode,
    DateTime? storageStartDate,
    BayStatus? status,
    String? notes,
    DateTime? updatedAt,
  }) {
    return WarehouseGridBayModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      chamberCode: chamberCode ?? this.chamberCode,
      bayCode: bayCode ?? this.bayCode,
      rowCoord: rowCoord ?? this.rowCoord,
      colCoord: colCoord ?? this.colCoord,
      maxCapacityBags: maxCapacityBags ?? this.maxCapacityBags,
      currentBags: currentBags ?? this.currentBags,
      cropName: cropName ?? this.cropName,
      farmerSupplierId: farmerSupplierId ?? this.farmerSupplierId,
      farmerName: farmerName ?? this.farmerName,
      lotCode: lotCode ?? this.lotCode,
      storageStartDate: storageStartDate ?? this.storageStartDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
