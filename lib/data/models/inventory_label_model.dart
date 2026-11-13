// Domain models for Mandi Inventory Labels, Barcodes & Pallet QR Tracking
// (*بارکوڈ، کیو آر انوینٹری لیبلز، گودام پیلیٹ اور چٹہ ٹریکنگ*).

import 'dart:convert';

enum InventoryLabelType {
  lot,
  palletStack,
  godownBay,
  dispatchChallan;

  String toDbString() {
    switch (this) {
      case InventoryLabelType.lot:
        return 'lot';
      case InventoryLabelType.palletStack:
        return 'pallet_stack';
      case InventoryLabelType.godownBay:
        return 'godown_bay';
      case InventoryLabelType.dispatchChallan:
        return 'dispatch_challan';
    }
  }

  String get labelUrdu {
    switch (this) {
      case InventoryLabelType.lot:
        return 'ڈھیری مال';
      case InventoryLabelType.palletStack:
        return 'پیلیٹ / چٹہ';
      case InventoryLabelType.godownBay:
        return 'گودام بلاک';
      case InventoryLabelType.dispatchChallan:
        return 'روانگی چالان';
    }
  }

  String get labelEnglish {
    switch (this) {
      case InventoryLabelType.lot:
        return 'Consignment Lot';
      case InventoryLabelType.palletStack:
        return 'Warehouse Pallet / Stack';
      case InventoryLabelType.godownBay:
        return 'Godown Bay / Chamber';
      case InventoryLabelType.dispatchChallan:
        return 'Dispatch Challan / Gate Pass';
    }
  }

  static InventoryLabelType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'pallet_stack':
      case 'pallet':
      case 'stack':
        return InventoryLabelType.palletStack;
      case 'godown_bay':
      case 'bay':
      case 'chamber':
        return InventoryLabelType.godownBay;
      case 'dispatch_challan':
      case 'challan':
      case 'dispatch':
        return InventoryLabelType.dispatchChallan;
      case 'lot':
      default:
        return InventoryLabelType.lot;
    }
  }
}

enum PackageType {
  juteBag,
  ppBag,
  woodenCrate,
  plasticCrate,
  bulk;

  String toDbString() {
    switch (this) {
      case PackageType.juteBag:
        return 'jute_bag';
      case PackageType.ppBag:
        return 'pp_bag';
      case PackageType.woodenCrate:
        return 'wooden_crate';
      case PackageType.plasticCrate:
        return 'plastic_crate';
      case PackageType.bulk:
        return 'bulk';
    }
  }

  String get labelUrdu {
    switch (this) {
      case PackageType.juteBag:
        return 'پٹ سن بوری (100 کلو)';
      case PackageType.ppBag:
        return 'پلاسٹک تھیلا (50 کلو)';
      case PackageType.woodenCrate:
        return 'لکڑی کی پیٹی';
      case PackageType.plasticCrate:
        return 'پلاسٹک کریٹ';
      case PackageType.bulk:
        return 'کھلا مال (بلک)';
    }
  }

  String get labelEnglish {
    switch (this) {
      case PackageType.juteBag:
        return 'Jute Sacks (100 KG)';
      case PackageType.ppBag:
        return 'PP Woven Bags (50 KG)';
      case PackageType.woodenCrate:
        return 'Wooden Crates';
      case PackageType.plasticCrate:
        return 'Reusable Plastic Crates';
      case PackageType.bulk:
        return 'Bulk / Loose Goods';
    }
  }

  double get defaultTareKg {
    switch (this) {
      case PackageType.juteBag:
        return 1.0;
      case PackageType.ppBag:
        return 0.15;
      case PackageType.woodenCrate:
        return 1.8;
      case PackageType.plasticCrate:
        return 1.4;
      case PackageType.bulk:
        return 0.0;
    }
  }

  static PackageType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'pp_bag':
      case 'plastic_bag':
      case 'thela':
        return PackageType.ppBag;
      case 'wooden_crate':
      case 'wooden':
      case 'peti':
        return PackageType.woodenCrate;
      case 'plastic_crate':
      case 'crate':
        return PackageType.plasticCrate;
      case 'bulk':
      case 'loose':
        return PackageType.bulk;
      case 'jute_bag':
      case 'bori':
      default:
        return PackageType.juteBag;
    }
  }
}

enum LabelStatus {
  active,
  dispatched,
  damaged,
  archived;

  String toDbString() {
    switch (this) {
      case LabelStatus.active:
        return 'active';
      case LabelStatus.dispatched:
        return 'dispatched';
      case LabelStatus.damaged:
        return 'damaged';
      case LabelStatus.archived:
        return 'archived';
    }
  }

  String get labelUrdu {
    switch (this) {
      case LabelStatus.active:
        return 'موجود';
      case LabelStatus.dispatched:
        return 'روانہ شدہ';
      case LabelStatus.damaged:
        return 'خراب / ضائع شدہ';
      case LabelStatus.archived:
        return 'محفوظ شدہ';
    }
  }

  String get labelEnglish {
    switch (this) {
      case LabelStatus.active:
        return 'Active / In Stock';
      case LabelStatus.dispatched:
        return 'Dispatched / Sold';
      case LabelStatus.damaged:
        return 'Damaged / Written Off';
      case LabelStatus.archived:
        return 'Archived';
    }
  }

  static LabelStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'dispatched':
      case 'sold':
        return LabelStatus.dispatched;
      case 'damaged':
        return LabelStatus.damaged;
      case 'archived':
        return LabelStatus.archived;
      case 'active':
      default:
        return LabelStatus.active;
    }
  }
}

class InventoryLabel {
  final String id;
  final String shopId;
  final String? lotId;
  final String? storageId;
  final String labelCode;
  final String barcodeValue;
  final String qrPayload;
  final InventoryLabelType labelType;
  final String commodityName;
  final String variety;
  final String partyName;
  final String vehicleNumber;
  final int bagCount;
  final PackageType packageType;
  final double grossWeightKg;
  final double netWeightKg;
  final double netWeightMaunds;
  final String qualityGrade; // 'grade_a_super', 'grade_b_faq', 'grade_c_substandard', 'rejected'
  final String facilityName;
  final String bayOrStack;
  final String notes;
  final LabelStatus status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const InventoryLabel({
    this.id = '',
    required this.shopId,
    this.lotId,
    this.storageId,
    required this.labelCode,
    required this.barcodeValue,
    required this.qrPayload,
    this.labelType = InventoryLabelType.lot,
    required this.commodityName,
    this.variety = '',
    this.partyName = '',
    this.vehicleNumber = '',
    this.bagCount = 0,
    this.packageType = PackageType.juteBag,
    this.grossWeightKg = 0.0,
    required this.netWeightKg,
    required this.netWeightMaunds,
    this.qualityGrade = 'grade_b_faq',
    this.facilityName = '',
    this.bayOrStack = '',
    this.notes = '',
    this.status = LabelStatus.active,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == LabelStatus.active;
  bool get isDispatched => status == LabelStatus.dispatched;

  String get displayCommodity =>
      variety.isNotEmpty ? '$commodityName ($variety)' : commodityName;

  String get displayLocation =>
      bayOrStack.isNotEmpty ? '$facilityName • $bayOrStack' : facilityName;

  /// Helper to calculate tare and net weight in KG and Maunds ($KG / 40.0$).
  static Map<String, double> computeWeightMath({
    required double grossWeightKg,
    required int bagCount,
    required PackageType packageType,
    double? customTarePerBag,
  }) {
    final tarePerBag = customTarePerBag ?? packageType.defaultTareKg;
    final totalTareKg = (bagCount * tarePerBag).clamp(0.0, grossWeightKg);
    final netWeightKg =
        (grossWeightKg - totalTareKg).clamp(0.0, grossWeightKg);
    final netWeightMaunds = netWeightKg / 40.0;

    return {
      'totalTareKg': totalTareKg,
      'netWeightKg': netWeightKg,
      'netWeightMaunds': netWeightMaunds,
    };
  }

  /// Helper to construct a structured JSON payload for high-density 2D QR codes
  /// that can be verified offline by scanning with camera / mobile readers.
  static String generateQrPayload({
    required String shopId,
    required String labelCode,
    required String commodityName,
    required int bagCount,
    required double netWeightKg,
    required double netWeightMaunds,
    required String qualityGrade,
    required String facilityName,
    required String bayOrStack,
    DateTime? date,
  }) {
    final map = {
      'app': 'MandiERP',
      'shop': shopId,
      'code': labelCode,
      'crop': commodityName,
      'bags': bagCount,
      'kg': netWeightKg.toStringAsFixed(1),
      'maunds': netWeightMaunds.toStringAsFixed(2),
      'grade': qualityGrade,
      'loc': '$facilityName:$bayOrStack',
      'ts': (date ?? DateTime.now()).toIso8601String(),
    };
    return jsonEncode(map);
  }

  factory InventoryLabel.fromMap(String id, Map<String, dynamic> data) {
    final grossKg = (data['gross_weight_kg'] as num?)?.toDouble() ?? 0.0;
    final netKg = (data['net_weight_kg'] as num?)?.toDouble() ?? grossKg;
    final netMaunds = (data['net_weight_maunds'] as num?)?.toDouble() ??
        (netKg > 0 ? (netKg / 40.0) : 0.0);

    return InventoryLabel(
      id: id,
      shopId: data['shop_id']?.toString() ?? '',
      lotId: data['lot_id']?.toString(),
      storageId: data['storage_id']?.toString(),
      labelCode: data['label_code']?.toString() ?? '',
      barcodeValue: data['barcode_value']?.toString() ?? '',
      qrPayload: data['qr_payload']?.toString() ?? '',
      labelType: InventoryLabelType.fromString(
          data['label_type']?.toString() ?? 'lot'),
      commodityName: data['commodity_name']?.toString() ?? '',
      variety: data['variety']?.toString() ?? '',
      partyName: data['party_name']?.toString() ?? '',
      vehicleNumber: data['vehicle_number']?.toString() ?? '',
      bagCount: (data['bag_count'] as num?)?.toInt() ?? 0,
      packageType: PackageType.fromString(
          data['package_type']?.toString() ?? 'jute_bag'),
      grossWeightKg: grossKg,
      netWeightKg: netKg,
      netWeightMaunds: netMaunds,
      qualityGrade: data['quality_grade']?.toString() ?? 'grade_b_faq',
      facilityName: data['facility_name']?.toString() ?? '',
      bayOrStack: data['bay_or_stack']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
      status:
          LabelStatus.fromString(data['status']?.toString() ?? 'active'),
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
      if (storageId != null && storageId!.isNotEmpty) 'storage_id': storageId,
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
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}
