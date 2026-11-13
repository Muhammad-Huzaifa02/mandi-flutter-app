import 'package:flutter/material.dart';

/// Origin countries for imported fruits, vegetables, and dry fruits.
enum OriginCountry {
  afghanistan,
  iran,
  centralAsia,
  other,
}

extension OriginCountryExt on OriginCountry {
  String get labelEnglish {
    switch (this) {
      case OriginCountry.afghanistan:
        return 'Afghanistan';
      case OriginCountry.iran:
        return 'Iran';
      case OriginCountry.centralAsia:
        return 'Central Asia (Uzbek/Tajik)';
      case OriginCountry.other:
        return 'Other Origin';
    }
  }

  String get labelUrdu {
    switch (this) {
      case OriginCountry.afghanistan:
        return 'افغانستان';
      case OriginCountry.iran:
        return 'ایران';
      case OriginCountry.centralAsia:
        return 'وسطی ایشیا (ازبکستان/تاجکستان)';
      case OriginCountry.other:
        return 'دیگر ممالک';
    }
  }

  String get flagEmoji {
    switch (this) {
      case OriginCountry.afghanistan:
        return '🇦🇫';
      case OriginCountry.iran:
        return '🇮🇷';
      case OriginCountry.centralAsia:
        return '🇺🇿';
      case OriginCountry.other:
        return '🌐';
    }
  }

  static OriginCountry fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'afghanistan':
        return OriginCountry.afghanistan;
      case 'iran':
        return OriginCountry.iran;
      case 'centralasia':
      case 'central_asia':
        return OriginCountry.centralAsia;
      default:
        return OriginCountry.other;
    }
  }
}

/// Official Border Crossing Terminals & Customs Checkpoints.
enum BorderCrossing {
  torkham, // Khyber Pass / طورخم
  chaman, // Chaman / Spin Boldak / چمن باب دوستی
  taftan, // Taftan / Mirjaveh / تفتان میرجاوہ
  gabd, // Gabd / Rimdan / گبد ریمدان
  khunjerab, // Khunjerab Pass / خنجراب
  other,
}

extension BorderCrossingExt on BorderCrossing {
  String get labelEnglish {
    switch (this) {
      case BorderCrossing.torkham:
        return 'Torkham Border (Khyber)';
      case BorderCrossing.chaman:
        return 'Chaman Border (Bab-e-Dosti)';
      case BorderCrossing.taftan:
        return 'Taftan Border (Balochistan)';
      case BorderCrossing.gabd:
        return 'Gabd-Rimdan Border (Gwadar)';
      case BorderCrossing.khunjerab:
        return 'Khunjerab Pass (Sost Dry Port)';
      case BorderCrossing.other:
        return 'Other Border Terminal';
    }
  }

  String get labelUrdu {
    switch (this) {
      case BorderCrossing.torkham:
        return 'طورخم بارڈر (خیبر پختونخوا)';
      case BorderCrossing.chaman:
        return 'چمن بارڈر (باب دوستی بلوچستان)';
      case BorderCrossing.taftan:
        return 'تفتان بارڈر (پاک ایران سرحد)';
      case BorderCrossing.gabd:
        return 'گبد ریمدان بارڈر (گوادر)';
      case BorderCrossing.khunjerab:
        return 'خنجراب پاس (سوست ڈرائی پورٹ)';
      case BorderCrossing.other:
        return 'دیگر کسٹم چوکی';
    }
  }

  static BorderCrossing fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'torkham':
        return BorderCrossing.torkham;
      case 'chaman':
        return BorderCrossing.chaman;
      case 'taftan':
        return BorderCrossing.taftan;
      case 'gabd':
      case 'gabd_rimdan':
        return BorderCrossing.gabd;
      case 'khunjerab':
        return BorderCrossing.khunjerab;
      default:
        return BorderCrossing.other;
    }
  }
}

/// Major trading currencies in regional cross-border commerce.
enum TradeCurrency {
  usd,
  afn,
  irr,
  pkr,
}

extension TradeCurrencyExt on TradeCurrency {
  String get code {
    switch (this) {
      case TradeCurrency.usd:
        return 'USD';
      case TradeCurrency.afn:
        return 'AFN';
      case TradeCurrency.irr:
        return 'IRR';
      case TradeCurrency.pkr:
        return 'PKR';
    }
  }

  String get symbol {
    switch (this) {
      case TradeCurrency.usd:
        return '\$';
      case TradeCurrency.afn:
        return '؋';
      case TradeCurrency.irr:
        return '﷼';
      case TradeCurrency.pkr:
        return 'Rs';
    }
  }

  String get nameEnglish {
    switch (this) {
      case TradeCurrency.usd:
        return 'US Dollar (\$)';
      case TradeCurrency.afn:
        return 'Afghan Afghani (؋)';
      case TradeCurrency.irr:
        return 'Iranian Rial (﷼)';
      case TradeCurrency.pkr:
        return 'Pakistani Rupee (Rs)';
    }
  }

  double get standardMarketRate {
    switch (this) {
      case TradeCurrency.usd:
        return 278.50;
      case TradeCurrency.afn:
        return 3.95;
      case TradeCurrency.irr:
        return 0.0066;
      case TradeCurrency.pkr:
        return 1.0;
    }
  }

  static TradeCurrency fromString(String? val) {
    switch (val?.toUpperCase().trim()) {
      case 'AFN':
        return TradeCurrency.afn;
      case 'IRR':
        return TradeCurrency.irr;
      case 'PKR':
        return TradeCurrency.pkr;
      case 'USD':
      default:
        return TradeCurrency.usd;
    }
  }
}

/// Lifecycle status of an international cargo consignment.
enum CrossBorderShipmentStatus {
  inTransit, // Dispatched from source, on highway to border
  clearedAtBorder, // Customs GD passed, duty & freight paid
  arrivedInMandi, // Physical vehicle reached Mandi yard (Pharr)
  auctioned, // Boli completed, goods sold to wholesale buyers
  settled, // Foreign supplier paid in full, profits realized
}

extension CrossBorderShipmentStatusExt on CrossBorderShipmentStatus {
  String get labelEnglish {
    switch (this) {
      case CrossBorderShipmentStatus.inTransit:
        return 'In Transit (Highway)';
      case CrossBorderShipmentStatus.clearedAtBorder:
        return 'Customs Cleared';
      case CrossBorderShipmentStatus.arrivedInMandi:
        return 'Arrived in Mandi';
      case CrossBorderShipmentStatus.auctioned:
        return 'Auctioned (Sold)';
      case CrossBorderShipmentStatus.settled:
        return 'Fully Settled';
    }
  }

  String get labelUrdu {
    switch (this) {
      case CrossBorderShipmentStatus.inTransit:
        return 'راستے میں';
      case CrossBorderShipmentStatus.clearedAtBorder:
        return 'کسٹم ڈیوٹی کلیئرڈ';
      case CrossBorderShipmentStatus.arrivedInMandi:
        return 'منڈی آمد';
      case CrossBorderShipmentStatus.auctioned:
        return 'نیلام شدہ';
      case CrossBorderShipmentStatus.settled:
        return 'مکمل کھاتہ بیباق';
    }
  }

  Color get color {
    switch (this) {
      case CrossBorderShipmentStatus.inTransit:
        return Colors.orange;
      case CrossBorderShipmentStatus.clearedAtBorder:
        return Colors.blue;
      case CrossBorderShipmentStatus.arrivedInMandi:
        return Colors.teal;
      case CrossBorderShipmentStatus.auctioned:
        return Colors.purple;
      case CrossBorderShipmentStatus.settled:
        return const Color(0xFF2E7D32); // Green
    }
  }

  static CrossBorderShipmentStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'cleared_at_border':
      case 'clearedatborder':
        return CrossBorderShipmentStatus.clearedAtBorder;
      case 'arrived_in_mandi':
      case 'arrivedinmandi':
        return CrossBorderShipmentStatus.arrivedInMandi;
      case 'auctioned':
        return CrossBorderShipmentStatus.auctioned;
      case 'settled':
        return CrossBorderShipmentStatus.settled;
      case 'in_transit':
      case 'intransit':
      default:
        return CrossBorderShipmentStatus.inTransit;
    }
  }
}

/// Model representing a Cross-Border Cargo Shipment and Dual-Currency Ledger.
class CrossBorderShipment {
  final String id;
  final String shopId;
  final String shipmentNumber;
  final OriginCountry originCountry;
  final String originCity;
  final BorderCrossing borderCrossing;
  final String vehicleNumber;
  final String driverName;
  final String driverPhone;
  final String customsGdNumber;
  final DateTime? customsClearanceDate;
  final String clearingAgentName;
  final String? supplierId;
  final String supplierName;
  final String commodity;
  final String packageType; // e.g. Wooden Crate, Corrugated Carton, Jute Sack
  final int packageCount;
  final double grossWeightKg;
  final TradeCurrency currency;
  final double exchangeRateToPkr;
  final double foreignContractAmount;
  final double basePkrAmount;
  final double customsDutyPkr;
  final double borderFreightPkr;
  final double clearingChargesPkr;
  final double otherExpensesPkr;
  final double totalLandedCostPkr;
  final double paidToSupplierForeign;
  final double remainingSupplierForeign;
  final CrossBorderShipmentStatus status;
  final String? consignmentLotId;
  final String notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CrossBorderShipment({
    required this.id,
    required this.shopId,
    required this.shipmentNumber,
    this.originCountry = OriginCountry.afghanistan,
    this.originCity = '',
    this.borderCrossing = BorderCrossing.torkham,
    this.vehicleNumber = '',
    this.driverName = '',
    this.driverPhone = '',
    this.customsGdNumber = '',
    this.customsClearanceDate,
    this.clearingAgentName = '',
    this.supplierId,
    this.supplierName = '',
    this.commodity = '',
    this.packageType = 'Wooden Crate',
    this.packageCount = 0,
    this.grossWeightKg = 0.0,
    this.currency = TradeCurrency.usd,
    this.exchangeRateToPkr = 278.50,
    this.foreignContractAmount = 0.0,
    this.basePkrAmount = 0.0,
    this.customsDutyPkr = 0.0,
    this.borderFreightPkr = 0.0,
    this.clearingChargesPkr = 0.0,
    this.otherExpensesPkr = 0.0,
    this.totalLandedCostPkr = 0.0,
    this.paidToSupplierForeign = 0.0,
    this.remainingSupplierForeign = 0.0,
    this.status = CrossBorderShipmentStatus.inTransit,
    this.consignmentLotId,
    this.notes = '',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  // --- Computed Mathematical Properties ---

  /// Base contract cost in PKR converted at shipment exchange rate
  double get computedBasePkr => foreignContractAmount * exchangeRateToPkr;

  /// Total extra clearance and border transport costs in PKR
  double get totalBorderExpensesPkr =>
      customsDutyPkr + borderFreightPkr + clearingChargesPkr + otherExpensesPkr;

  /// True final landed cost in Mandi: Base Cargo + Customs + Freight + Port Fees
  double get computedTotalLandedCostPkr =>
      computedBasePkr + totalBorderExpensesPkr;

  /// Mandi Maunds (من = 40 KG)
  double get maunds => grossWeightKg > 0 ? (grossWeightKg / 40.0) : 0.0;

  /// Effective landed cost per KG in PKR
  double get costPerKgPkr =>
      grossWeightKg > 0 ? (computedTotalLandedCostPkr / grossWeightKg) : 0.0;

  /// Effective landed cost per 40 KG Maund in PKR
  double get costPerMaundPkr => costPerKgPkr * 40.0;

  /// Effective landed cost per package / crate in PKR
  double get costPerPackagePkr =>
      packageCount > 0 ? (computedTotalLandedCostPkr / packageCount) : 0.0;

  /// Remaining foreign currency debt owed to foreign grower / exporter
  double get computedRemainingSupplierForeign {
    final rem = foreignContractAmount - paidToSupplierForeign;
    return rem < 0 ? 0.0 : rem;
  }

  /// Remaining foreign debt expressed in PKR equivalent
  double get computedRemainingSupplierPkr =>
      computedRemainingSupplierForeign * exchangeRateToPkr;

  /// Payment settlement progress (0.0 to 1.0)
  double get settlementRatio => foreignContractAmount > 0
      ? (paidToSupplierForeign / foreignContractAmount).clamp(0.0, 1.0)
      : 1.0;

  factory CrossBorderShipment.fromMap(String id, Map<String, dynamic> map) {
    return CrossBorderShipment(
      id: id,
      shopId: map['shop_id']?.toString() ?? '',
      shipmentNumber: map['shipment_number']?.toString() ?? '',
      originCountry:
          OriginCountryExt.fromString(map['origin_country']?.toString()),
      originCity: map['origin_city']?.toString() ?? '',
      borderCrossing:
          BorderCrossingExt.fromString(map['border_crossing']?.toString()),
      vehicleNumber: map['vehicle_number']?.toString() ?? '',
      driverName: map['driver_name']?.toString() ?? '',
      driverPhone: map['driver_phone']?.toString() ?? '',
      customsGdNumber: map['customs_gd_number']?.toString() ?? '',
      customsClearanceDate: map['customs_clearance_date'] != null
          ? DateTime.tryParse(map['customs_clearance_date'].toString())
          : null,
      clearingAgentName: map['clearing_agent_name']?.toString() ?? '',
      supplierId: map['supplier_id']?.toString(),
      supplierName: map['supplier_name']?.toString() ?? '',
      commodity: map['commodity']?.toString() ?? '',
      packageType: map['package_type']?.toString() ?? 'Wooden Crate',
      packageCount: (map['package_count'] as num?)?.toInt() ?? 0,
      grossWeightKg: (map['gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      currency: TradeCurrencyExt.fromString(map['currency']?.toString()),
      exchangeRateToPkr:
          (map['exchange_rate_to_pkr'] as num?)?.toDouble() ?? 278.50,
      foreignContractAmount:
          (map['foreign_contract_amount'] as num?)?.toDouble() ?? 0.0,
      basePkrAmount: (map['base_pkr_amount'] as num?)?.toDouble() ?? 0.0,
      customsDutyPkr: (map['customs_duty_pkr'] as num?)?.toDouble() ?? 0.0,
      borderFreightPkr:
          (map['border_freight_pkr'] as num?)?.toDouble() ?? 0.0,
      clearingChargesPkr:
          (map['clearing_charges_pkr'] as num?)?.toDouble() ?? 0.0,
      otherExpensesPkr:
          (map['other_expenses_pkr'] as num?)?.toDouble() ?? 0.0,
      totalLandedCostPkr:
          (map['total_landed_cost_pkr'] as num?)?.toDouble() ?? 0.0,
      paidToSupplierForeign:
          (map['paid_to_supplier_foreign'] as num?)?.toDouble() ?? 0.0,
      remainingSupplierForeign:
          (map['remaining_supplier_foreign'] as num?)?.toDouble() ?? 0.0,
      status: CrossBorderShipmentStatusExt.fromString(
          map['status']?.toString()),
      consignmentLotId: map['consignment_lot_id']?.toString(),
      notes: map['notes']?.toString() ?? '',
      createdBy: map['created_by']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'shipment_number': shipmentNumber,
      'origin_country': originCountry.name,
      'origin_city': originCity,
      'border_crossing': borderCrossing.name,
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'customs_gd_number': customsGdNumber,
      'customs_clearance_date': customsClearanceDate?.toIso8601String(),
      'clearing_agent_name': clearingAgentName,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'commodity': commodity,
      'package_type': packageType,
      'package_count': packageCount,
      'gross_weight_kg': grossWeightKg,
      'currency': currency.code,
      'exchange_rate_to_pkr': exchangeRateToPkr,
      'foreign_contract_amount': foreignContractAmount,
      'base_pkr_amount': computedBasePkr,
      'customs_duty_pkr': customsDutyPkr,
      'border_freight_pkr': borderFreightPkr,
      'clearing_charges_pkr': clearingChargesPkr,
      'other_expenses_pkr': otherExpensesPkr,
      'total_landed_cost_pkr': computedTotalLandedCostPkr,
      'paid_to_supplier_foreign': paidToSupplierForeign,
      'remaining_supplier_foreign': computedRemainingSupplierForeign,
      'status': status.name,
      'consignment_lot_id': consignmentLotId,
      'notes': notes,
      'created_by': createdBy,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  CrossBorderShipment copyWith({
    String? shipmentNumber,
    OriginCountry? originCountry,
    String? originCity,
    BorderCrossing? borderCrossing,
    String? vehicleNumber,
    String? driverName,
    String? driverPhone,
    String? customsGdNumber,
    DateTime? customsClearanceDate,
    String? clearingAgentName,
    String? supplierId,
    String? supplierName,
    String? commodity,
    String? packageType,
    int? packageCount,
    double? grossWeightKg,
    TradeCurrency? currency,
    double? exchangeRateToPkr,
    double? foreignContractAmount,
    double? basePkrAmount,
    double? customsDutyPkr,
    double? borderFreightPkr,
    double? clearingChargesPkr,
    double? otherExpensesPkr,
    double? totalLandedCostPkr,
    double? paidToSupplierForeign,
    double? remainingSupplierForeign,
    CrossBorderShipmentStatus? status,
    String? consignmentLotId,
    String? notes,
  }) {
    return CrossBorderShipment(
      id: id,
      shopId: shopId,
      shipmentNumber: shipmentNumber ?? this.shipmentNumber,
      originCountry: originCountry ?? this.originCountry,
      originCity: originCity ?? this.originCity,
      borderCrossing: borderCrossing ?? this.borderCrossing,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      customsGdNumber: customsGdNumber ?? this.customsGdNumber,
      customsClearanceDate: customsClearanceDate ?? this.customsClearanceDate,
      clearingAgentName: clearingAgentName ?? this.clearingAgentName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      commodity: commodity ?? this.commodity,
      packageType: packageType ?? this.packageType,
      packageCount: packageCount ?? this.packageCount,
      grossWeightKg: grossWeightKg ?? this.grossWeightKg,
      currency: currency ?? this.currency,
      exchangeRateToPkr: exchangeRateToPkr ?? this.exchangeRateToPkr,
      foreignContractAmount:
          foreignContractAmount ?? this.foreignContractAmount,
      basePkrAmount: basePkrAmount ?? this.basePkrAmount,
      customsDutyPkr: customsDutyPkr ?? this.customsDutyPkr,
      borderFreightPkr: borderFreightPkr ?? this.borderFreightPkr,
      clearingChargesPkr: clearingChargesPkr ?? this.clearingChargesPkr,
      otherExpensesPkr: otherExpensesPkr ?? this.otherExpensesPkr,
      totalLandedCostPkr: totalLandedCostPkr ?? this.totalLandedCostPkr,
      paidToSupplierForeign:
          paidToSupplierForeign ?? this.paidToSupplierForeign,
      remainingSupplierForeign:
          remainingSupplierForeign ?? this.remainingSupplierForeign,
      status: status ?? this.status,
      consignmentLotId: consignmentLotId ?? this.consignmentLotId,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Aggregated metrics for cross-border import shipments.
class CrossBorderSummary {
  final int totalShipments;
  final int activeShipments;
  final double totalCargoMaunds;
  final double totalLandedCostPkr;
  final double totalCustomsFreightPkr;
  final double totalOutstandingSupplierPkr;

  const CrossBorderSummary({
    this.totalShipments = 0,
    this.activeShipments = 0,
    this.totalCargoMaunds = 0.0,
    this.totalLandedCostPkr = 0.0,
    this.totalCustomsFreightPkr = 0.0,
    this.totalOutstandingSupplierPkr = 0.0,
  });

  factory CrossBorderSummary.fromShipments(List<CrossBorderShipment> list) {
    int active = 0;
    double maunds = 0.0;
    double landed = 0.0;
    double customsFreight = 0.0;
    double outstandingPkr = 0.0;

    for (final s in list) {
      if (s.status != CrossBorderShipmentStatus.settled) {
        active++;
      }
      maunds += s.maunds;
      landed += s.computedTotalLandedCostPkr;
      customsFreight += s.totalBorderExpensesPkr;
      outstandingPkr += s.computedRemainingSupplierPkr;
    }

    return CrossBorderSummary(
      totalShipments: list.length,
      activeShipments: active,
      totalCargoMaunds: maunds,
      totalLandedCostPkr: landed,
      totalCustomsFreightPkr: customsFreight,
      totalOutstandingSupplierPkr: outstandingPkr,
    );
  }
}
