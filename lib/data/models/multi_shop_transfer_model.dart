/// Status of an inter-shop inventory transfer.
enum StockTransferStatus {
  inTransit, // Dispatched from source, on the road
  received, // Acknowledged & added to destination inventory
  cancelled; // Cancelled before delivery

  String get labelEnglish {
    switch (this) {
      case StockTransferStatus.inTransit:
        return 'In Transit';
      case StockTransferStatus.received:
        return 'Received';
      case StockTransferStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get labelUrdu {
    switch (this) {
      case StockTransferStatus.inTransit:
        return 'راستہ میں / روانہ شدہ';
      case StockTransferStatus.received:
        return 'موصول شدہ';
      case StockTransferStatus.cancelled:
        return 'منسوخ شدہ';
    }
  }

  static StockTransferStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'received':
        return StockTransferStatus.received;
      case 'cancelled':
        return StockTransferStatus.cancelled;
      case 'in_transit':
      case 'intransit':
      default:
        return StockTransferStatus.inTransit;
    }
  }

  String toDbString() {
    switch (this) {
      case StockTransferStatus.inTransit:
        return 'in_transit';
      case StockTransferStatus.received:
        return 'received';
      case StockTransferStatus.cancelled:
        return 'cancelled';
    }
  }
}

/// Represents an inter-shop crop stock transfer consignment between branches.
class InterShopTransfer {
  final String id;
  final String transferNumber;
  final String sourceShopId;
  final String sourceShopName;
  final String destinationShopId;
  final String destinationShopName;
  final String? productId;
  final String commodityName;
  final double quantityKg;
  final double quantityMaunds;
  final String packageType; // Bag, Crate, Carton, Loose
  final int packageCount;
  final double unitCostPkr;
  final double totalValuePkr;
  final double transitFreightPkr;
  final String vehicleNumber;
  final String driverName;
  final String driverPhone;
  final DateTime dispatchedAt;
  final DateTime? receivedAt;
  final StockTransferStatus status;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InterShopTransfer({
    this.id = '',
    required this.transferNumber,
    required this.sourceShopId,
    this.sourceShopName = '',
    required this.destinationShopId,
    this.destinationShopName = '',
    this.productId,
    required this.commodityName,
    required this.quantityKg,
    required this.quantityMaunds,
    this.packageType = 'Bag',
    this.packageCount = 0,
    required this.unitCostPkr,
    required this.totalValuePkr,
    this.transitFreightPkr = 0.0,
    this.vehicleNumber = '',
    this.driverName = '',
    this.driverPhone = '',
    required this.dispatchedAt,
    this.receivedAt,
    this.status = StockTransferStatus.inTransit,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Computed total delivered cost including inter-city freight carriage.
  double get totalDeliveredCostPkr => totalValuePkr + transitFreightPkr;

  /// Effective landed cost per Maund (40 KG) at destination mandi shop.
  double get effectiveCostPerMaundPkr {
    if (quantityMaunds <= 0) return 0.0;
    return totalDeliveredCostPkr / quantityMaunds;
  }

  /// Effective landed cost per KG at destination mandi shop.
  double get landedCostPerKgPkr {
    if (quantityKg <= 0) return 0.0;
    return totalDeliveredCostPkr / quantityKg;
  }

  factory InterShopTransfer.fromMap(
    String id,
    Map<String, dynamic> map, {
    String sourceName = '',
    String destinationName = '',
  }) {
    return InterShopTransfer(
      id: id,
      transferNumber: map['transfer_number']?.toString() ?? '',
      sourceShopId: map['source_shop_id']?.toString() ?? '',
      sourceShopName: sourceName.isNotEmpty
          ? sourceName
          : (map['source_shop_name']?.toString() ?? ''),
      destinationShopId: map['destination_shop_id']?.toString() ?? '',
      destinationShopName: destinationName.isNotEmpty
          ? destinationName
          : (map['destination_shop_name']?.toString() ?? ''),
      productId: map['product_id']?.toString(),
      commodityName: map['commodity_name']?.toString() ?? '',
      quantityKg: (map['quantity_kg'] as num?)?.toDouble() ?? 0.0,
      quantityMaunds: (map['quantity_maunds'] as num?)?.toDouble() ?? 0.0,
      packageType: map['package_type']?.toString() ?? 'Bag',
      packageCount: (map['package_count'] as num?)?.toInt() ?? 0,
      unitCostPkr: (map['unit_cost_pkr'] as num?)?.toDouble() ?? 0.0,
      totalValuePkr: (map['total_value_pkr'] as num?)?.toDouble() ?? 0.0,
      transitFreightPkr: (map['transit_freight_pkr'] as num?)?.toDouble() ?? 0.0,
      vehicleNumber: map['vehicle_number']?.toString() ?? '',
      driverName: map['driver_name']?.toString() ?? '',
      driverPhone: map['driver_phone']?.toString() ?? '',
      dispatchedAt: map['dispatched_at'] != null
          ? DateTime.tryParse(map['dispatched_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      receivedAt: map['received_at'] != null
          ? DateTime.tryParse(map['received_at'].toString())
          : null,
      status: StockTransferStatus.fromString(map['status']?.toString() ?? 'in_transit'),
      notes: map['notes']?.toString() ?? '',
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
      'transfer_number': transferNumber,
      'source_shop_id': sourceShopId,
      'destination_shop_id': destinationShopId,
      'product_id': productId,
      'commodity_name': commodityName,
      'quantity_kg': quantityKg,
      'quantity_maunds': quantityMaunds,
      'package_type': packageType,
      'package_count': packageCount,
      'unit_cost_pkr': unitCostPkr,
      'total_value_pkr': totalValuePkr,
      'transit_freight_pkr': transitFreightPkr,
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'dispatched_at': dispatchedAt.toIso8601String(),
      'received_at': receivedAt?.toIso8601String(),
      'status': status.toDbString(),
      'notes': notes,
    };
  }

  InterShopTransfer copyWith({
    String? id,
    String? transferNumber,
    String? sourceShopId,
    String? sourceShopName,
    String? destinationShopId,
    String? destinationShopName,
    String? productId,
    String? commodityName,
    double? quantityKg,
    double? quantityMaunds,
    String? packageType,
    int? packageCount,
    double? unitCostPkr,
    double? totalValuePkr,
    double? transitFreightPkr,
    String? vehicleNumber,
    String? driverName,
    String? driverPhone,
    DateTime? dispatchedAt,
    DateTime? receivedAt,
    StockTransferStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InterShopTransfer(
      id: id ?? this.id,
      transferNumber: transferNumber ?? this.transferNumber,
      sourceShopId: sourceShopId ?? this.sourceShopId,
      sourceShopName: sourceShopName ?? this.sourceShopName,
      destinationShopId: destinationShopId ?? this.destinationShopId,
      destinationShopName: destinationShopName ?? this.destinationShopName,
      productId: productId ?? this.productId,
      commodityName: commodityName ?? this.commodityName,
      quantityKg: quantityKg ?? this.quantityKg,
      quantityMaunds: quantityMaunds ?? this.quantityMaunds,
      packageType: packageType ?? this.packageType,
      packageCount: packageCount ?? this.packageCount,
      unitCostPkr: unitCostPkr ?? this.unitCostPkr,
      totalValuePkr: totalValuePkr ?? this.totalValuePkr,
      transitFreightPkr: transitFreightPkr ?? this.transitFreightPkr,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Balance Sheet overview for an individual shop branch.
class ShopBranchFinancialMetrics {
  final String shopId;
  final String shopName;
  final String city;
  final double totalSalesPkr;
  final double totalCommissionPkr;
  final double totalExpensesPkr;
  final double totalReceivablesPkr;
  final double totalPayablesPkr;
  final double liquidCashPkr;
  final double stockValuePkr;

  const ShopBranchFinancialMetrics({
    required this.shopId,
    required this.shopName,
    this.city = '',
    this.totalSalesPkr = 0.0,
    this.totalCommissionPkr = 0.0,
    this.totalExpensesPkr = 0.0,
    this.totalReceivablesPkr = 0.0,
    this.totalPayablesPkr = 0.0,
    this.liquidCashPkr = 0.0,
    this.stockValuePkr = 0.0,
  });

  /// Net operating profit of the shop branch.
  double get netProfitPkr => totalCommissionPkr - totalExpensesPkr;
  double get netOperatingProfitPkr => netProfitPkr;

  /// Net equity / asset value of this individual shop branch.
  double get netBranchEquityPkr =>
      (liquidCashPkr + totalReceivablesPkr + stockValuePkr) - totalPayablesPkr;
}

/// Consolidated multi-shop group balance sheet aggregating all Mandi branches.
class ConsolidatedBalanceSheet {
  final List<ShopBranchFinancialMetrics> branches;
  final DateTime asOfDate;

  const ConsolidatedBalanceSheet({
    required this.branches,
    required this.asOfDate,
  });

  int get totalBranchesCount => branches.length;

  double get aggregateSalesPkr =>
      branches.fold(0.0, (sum, b) => sum + b.totalSalesPkr);

  double get aggregateCommissionPkr =>
      branches.fold(0.0, (sum, b) => sum + b.totalCommissionPkr);

  double get aggregateExpensesPkr =>
      branches.fold(0.0, (sum, b) => sum + b.totalExpensesPkr);

  double get aggregateNetProfitPkr =>
      branches.fold(0.0, (sum, b) => sum + b.netProfitPkr);

  double get aggregateReceivablesPkr =>
      branches.fold(0.0, (sum, b) => sum + b.totalReceivablesPkr);

  double get aggregatePayablesPkr =>
      branches.fold(0.0, (sum, b) => sum + b.totalPayablesPkr);

  double get aggregateLiquidCashPkr =>
      branches.fold(0.0, (sum, b) => sum + b.liquidCashPkr);

  double get aggregateStockValuePkr =>
      branches.fold(0.0, (sum, b) => sum + b.stockValuePkr);

  /// Total enterprise network net equity.
  double get aggregateEnterpriseEquityPkr =>
      (aggregateLiquidCashPkr + aggregateReceivablesPkr + aggregateStockValuePkr) -
      aggregatePayablesPkr;

  // Convenience aliases for UI bindings
  double get totalEnterpriseSalesPkr => aggregateSalesPkr;
  double get totalEnterpriseCommissionPkr => aggregateCommissionPkr;
  double get totalEnterpriseExpensesPkr => aggregateExpensesPkr;
  double get totalEnterpriseOperatingProfitPkr => aggregateNetProfitPkr;
  double get totalEnterpriseReceivablesPkr => aggregateReceivablesPkr;
  double get totalEnterprisePayablesPkr => aggregatePayablesPkr;
  double get totalEnterpriseStockValuePkr => aggregateStockValuePkr;
  double get totalNetEnterpriseEquityPkr => aggregateEnterpriseEquityPkr;
}
