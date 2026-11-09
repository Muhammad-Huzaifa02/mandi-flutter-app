import 'package:flutter/material.dart';

enum ConsignmentLotStatus {
  arrived,
  auctioning,
  sold,
  settled,
  cancelled,
}

extension ConsignmentLotStatusX on ConsignmentLotStatus {
  static ConsignmentLotStatus fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'auctioning':
        return ConsignmentLotStatus.auctioning;
      case 'sold':
        return ConsignmentLotStatus.sold;
      case 'settled':
        return ConsignmentLotStatus.settled;
      case 'cancelled':
        return ConsignmentLotStatus.cancelled;
      case 'arrived':
      default:
        return ConsignmentLotStatus.arrived;
    }
  }

  String toDbString() {
    switch (this) {
      case ConsignmentLotStatus.arrived:
        return 'arrived';
      case ConsignmentLotStatus.auctioning:
        return 'auctioning';
      case ConsignmentLotStatus.sold:
        return 'sold';
      case ConsignmentLotStatus.settled:
        return 'settled';
      case ConsignmentLotStatus.cancelled:
        return 'cancelled';
    }
  }

  String get englishName {
    switch (this) {
      case ConsignmentLotStatus.arrived:
        return 'Arrived';
      case ConsignmentLotStatus.auctioning:
        return 'In Auction';
      case ConsignmentLotStatus.sold:
        return 'Sold';
      case ConsignmentLotStatus.settled:
        return 'Settled';
      case ConsignmentLotStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get urduName {
    switch (this) {
      case ConsignmentLotStatus.arrived:
        return 'آمد شدہ';
      case ConsignmentLotStatus.auctioning:
        return 'بولی جاری ہے';
      case ConsignmentLotStatus.sold:
        return 'نیلام شدہ';
      case ConsignmentLotStatus.settled:
        return 'کھاتہ کلیئر';
      case ConsignmentLotStatus.cancelled:
        return 'منسوخ';
    }
  }

  Color get color {
    switch (this) {
      case ConsignmentLotStatus.arrived:
        return const Color(0xFF1976D2); // Blue
      case ConsignmentLotStatus.auctioning:
        return const Color(0xFFF57C00); // Orange
      case ConsignmentLotStatus.sold:
        return const Color(0xFF388E3C); // Green
      case ConsignmentLotStatus.settled:
        return const Color(0xFF7B1FA2); // Purple
      case ConsignmentLotStatus.cancelled:
        return const Color(0xFFD32F2F); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case ConsignmentLotStatus.arrived:
        return Icons.local_shipping_outlined;
      case ConsignmentLotStatus.auctioning:
        return Icons.gavel_outlined;
      case ConsignmentLotStatus.sold:
        return Icons.check_circle_outline;
      case ConsignmentLotStatus.settled:
        return Icons.verified_outlined;
      case ConsignmentLotStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

/// Represents an incoming crop consignment lot (Aawak & Dheri / آمد و ڈھیری).
class ConsignmentLot {
  final String id;
  final String shopId;
  final String lotNumber;
  final String? supplierId;
  final String supplierName;
  final String? productId;
  final String productName;
  final String vehicleNumber;
  final int bagCount;
  final double weightKg;
  final double ratePerMaund; // price per 40kg (Maund)
  final String? winningBuyerId;
  final String winningBuyerName;
  final String? invoiceId;
  final ConsignmentLotStatus status;
  final String notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ConsignmentLot({
    required this.id,
    required this.shopId,
    required this.lotNumber,
    this.supplierId,
    this.supplierName = '',
    this.productId,
    this.productName = '',
    this.vehicleNumber = '',
    this.bagCount = 0,
    this.weightKg = 0,
    this.ratePerMaund = 0,
    this.winningBuyerId,
    this.winningBuyerName = '',
    this.invoiceId,
    this.status = ConsignmentLotStatus.arrived,
    this.notes = '',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  /// 40 KG per Maund (من)
  double get maunds => weightKg > 0 ? (weightKg / 40.0) : 0.0;

  /// Estimated auction value: Maunds * ratePerMaund
  double get estimatedTotal => maunds * ratePerMaund;

  bool get isAuctionActive => status == ConsignmentLotStatus.auctioning;
  bool get isSold =>
      status == ConsignmentLotStatus.sold ||
      status == ConsignmentLotStatus.settled;

  factory ConsignmentLot.fromMap(String id, Map<String, dynamic> d) {
    return ConsignmentLot(
      id: id,
      shopId: d['shop_id'] as String? ?? '',
      lotNumber: d['lot_number'] as String? ?? '',
      supplierId: d['supplier_id'] as String?,
      supplierName: d['supplier_name'] as String? ?? '',
      productId: d['product_id'] as String?,
      productName: d['product_name'] as String? ?? '',
      vehicleNumber: d['vehicle_number'] as String? ?? '',
      bagCount: (d['bag_count'] as num?)?.toInt() ?? 0,
      weightKg: (d['weight_kg'] as num?)?.toDouble() ?? 0,
      ratePerMaund: (d['rate_per_maund'] as num?)?.toDouble() ?? 0,
      winningBuyerId: d['winning_buyer_id'] as String?,
      winningBuyerName: d['winning_buyer_name'] as String? ?? '',
      invoiceId: d['invoice_id'] as String?,
      status: ConsignmentLotStatusX.fromString(d['status'] as String?),
      notes: d['notes'] as String? ?? '',
      createdBy: d['created_by'] as String?,
      createdAt: d['created_at'] != null
          ? DateTime.tryParse(d['created_at'].toString())
          : null,
      updatedAt: d['updated_at'] != null
          ? DateTime.tryParse(d['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'lot_number': lotNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'product_id': productId,
      'product_name': productName,
      'vehicle_number': vehicleNumber,
      'bag_count': bagCount,
      'weight_kg': weightKg,
      'rate_per_maund': ratePerMaund,
      'winning_buyer_id': winningBuyerId,
      'winning_buyer_name': winningBuyerName,
      'invoice_id': invoiceId,
      'status': status.toDbString(),
      'notes': notes,
    };
  }

  ConsignmentLot copyWith({
    String? id,
    String? shopId,
    String? lotNumber,
    String? supplierId,
    String? supplierName,
    String? productId,
    String? productName,
    String? vehicleNumber,
    int? bagCount,
    double? weightKg,
    double? ratePerMaund,
    String? winningBuyerId,
    String? winningBuyerName,
    String? invoiceId,
    ConsignmentLotStatus? status,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsignmentLot(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      lotNumber: lotNumber ?? this.lotNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      bagCount: bagCount ?? this.bagCount,
      weightKg: weightKg ?? this.weightKg,
      ratePerMaund: ratePerMaund ?? this.ratePerMaund,
      winningBuyerId: winningBuyerId ?? this.winningBuyerId,
      winningBuyerName: winningBuyerName ?? this.winningBuyerName,
      invoiceId: invoiceId ?? this.invoiceId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
