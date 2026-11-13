/// Vehicle category arriving at the Mandi Weighbridge.
enum VehicleType {
  trolley, // Tractor Trolley (ٹریکٹر ٹرالی)
  truckMazda, // 6-Wheeler Mazda / Isuzu Truck (شہزور / مزدا ٹرک)
  shehzore, // Hyundai Shehzore / Small Truck (شہزور)
  pickupDala, // Dala Pickup / Toyota Hilux (ڈالہ پک اپ)
  rickshawLoader, // 3-Wheeler Chingchi / Loader Rickshaw (لوڈر رکشہ)
  other,
}

extension VehicleTypeExt on VehicleType {
  String get labelEnglish {
    switch (this) {
      case VehicleType.trolley:
        return 'Tractor Trolley';
      case VehicleType.truckMazda:
        return 'Mazda / 6-Wheeler Truck';
      case VehicleType.shehzore:
        return 'Hyundai Shehzore';
      case VehicleType.pickupDala:
        return 'Pickup Dala';
      case VehicleType.rickshawLoader:
        return 'Loader Rickshaw';
      case VehicleType.other:
        return 'Other Vehicle';
    }
  }

  String get labelUrdu {
    switch (this) {
      case VehicleType.trolley:
        return 'ٹریکٹر ٹرالی';
      case VehicleType.truckMazda:
        return 'مزدا / 6 ویلر ٹرک';
      case VehicleType.shehzore:
        return 'شہزور ڈالہ';
      case VehicleType.pickupDala:
        return 'ڈالہ پک اپ';
      case VehicleType.rickshawLoader:
        return 'لوڈر رکشہ';
      case VehicleType.other:
        return 'دیگر سواری';
    }
  }
}

/// Lifecycle status of a weighbridge ticket.
enum WeighbridgeStatus {
  grossRecorded, // 1st weight recorded, waiting for unloading & tare weight
  completed, // Both gross and tare recorded, net calculated and certified
  cancelled, // Ticket cancelled
}

extension WeighbridgeStatusExt on WeighbridgeStatus {
  String get labelEnglish {
    switch (this) {
      case WeighbridgeStatus.grossRecorded:
        return 'Awaiting Tare Weight';
      case WeighbridgeStatus.completed:
        return 'Completed';
      case WeighbridgeStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get labelUrdu {
    switch (this) {
      case WeighbridgeStatus.grossRecorded:
        return 'وزن بھرا (خالی گاڑی باقی)';
      case WeighbridgeStatus.completed:
        return 'مکمل کنڈا پرچی';
      case WeighbridgeStatus.cancelled:
        return 'منسوخ شدہ';
    }
  }
}

/// Category of the party associated with the weighment.
enum WeighbridgePartyType {
  farmer, // Supplier / Farmer selling crop (زمیندار)
  buyer, // Customer / Trader / Mill buying (بیوپاری / مل)
  other,
}

extension WeighbridgePartyTypeExt on WeighbridgePartyType {
  String get labelEnglish {
    switch (this) {
      case WeighbridgePartyType.farmer:
        return 'Farmer';
      case WeighbridgePartyType.buyer:
        return 'Buyer';
      case WeighbridgePartyType.other:
        return 'Other';
    }
  }

  String get labelUrdu {
    switch (this) {
      case WeighbridgePartyType.farmer:
        return 'زمیندار';
      case WeighbridgePartyType.buyer:
        return 'خریدار';
      case WeighbridgePartyType.other:
        return 'دیگر';
    }
  }
}

/// Payer for the weighbridge service fee.
enum WeighbridgeFeePaidBy {
  farmer,
  buyer,
  shop,
  waived,
}

extension WeighbridgeFeePaidByExt on WeighbridgeFeePaidBy {
  String get labelEnglish {
    switch (this) {
      case WeighbridgeFeePaidBy.farmer:
        return 'Farmer';
      case WeighbridgeFeePaidBy.buyer:
        return 'Buyer';
      case WeighbridgeFeePaidBy.shop:
        return 'Shop';
      case WeighbridgeFeePaidBy.waived:
        return 'Waived';
    }
  }

  String get labelUrdu {
    switch (this) {
      case WeighbridgeFeePaidBy.farmer:
        return 'زمیندار';
      case WeighbridgeFeePaidBy.buyer:
        return 'خریدار';
      case WeighbridgeFeePaidBy.shop:
        return 'دکان';
      case WeighbridgeFeePaidBy.waived:
        return 'معاف';
    }
  }
}

/// Model representing a single Weighbridge Slip / Ticket (دھرم کنڈا وزن پرچی).
class WeighbridgeTicket {
  final String id;
  final String shopId;
  final String ticketNumber;
  final String vehicleNumber;
  final VehicleType vehicleType;
  final String driverName;
  final String driverPhone;
  final String partyName;
  final WeighbridgePartyType partyType;
  final String? partyId;
  final String commodityName;
  final double grossWeightKg;
  final double tareWeightKg;
  final double netWeightKg;
  final double deductionKg;
  final String deductionReason;
  final double finalWeightKg;
  final int bagCount;
  final double kandaFee;
  final WeighbridgeFeePaidBy feePaidBy;
  final WeighbridgeStatus status;
  final DateTime grossWeighedAt;
  final DateTime? tareWeighedAt;
  final String operatorName;
  final String? consignmentLotId;
  final String notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WeighbridgeTicket({
    required this.id,
    required this.shopId,
    required this.ticketNumber,
    required this.vehicleNumber,
    this.vehicleType = VehicleType.trolley,
    this.driverName = '',
    this.driverPhone = '',
    this.partyName = '',
    this.partyType = WeighbridgePartyType.farmer,
    this.partyId,
    this.commodityName = '',
    this.grossWeightKg = 0.0,
    this.tareWeightKg = 0.0,
    this.netWeightKg = 0.0,
    this.deductionKg = 0.0,
    this.deductionReason = '',
    this.finalWeightKg = 0.0,
    this.bagCount = 0,
    this.kandaFee = 0.0,
    this.feePaidBy = WeighbridgeFeePaidBy.farmer,
    this.status = WeighbridgeStatus.grossRecorded,
    required this.grossWeighedAt,
    this.tareWeighedAt,
    this.operatorName = '',
    this.consignmentLotId,
    this.notes = '',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  /// True if waiting for vehicle to empty and record tare weight
  bool get isAwaitingTare =>
      status == WeighbridgeStatus.grossRecorded && tareWeightKg <= 0;

  /// Calculated net weight (Gross - Tare)
  double get computedNetWeightKg {
    if (grossWeightKg > tareWeightKg && tareWeightKg > 0) {
      return grossWeightKg - tareWeightKg;
    }
    return netWeightKg;
  }

  /// Calculated final billable weight (Net - Deductions)
  double get computedFinalWeightKg {
    final net = computedNetWeightKg;
    final finalW = net - deductionKg;
    return finalW < 0 ? 0.0 : finalW;
  }

  /// Mandi Maunds (من = 40 KG) for final billable weight
  double get maunds => computedFinalWeightKg / 40.0;

  /// Mandi Maunds for gross weight
  double get grossMaunds => grossWeightKg / 40.0;

  /// Mandi Maunds for tare weight
  double get tareMaunds => tareWeightKg / 40.0;

  /// Mandi Maunds for net weight
  double get netMaunds => computedNetWeightKg / 40.0;

  factory WeighbridgeTicket.fromMap(String id, Map<String, dynamic> map) {
    VehicleType parseVehicle(String? val) {
      switch (val) {
        case 'truck_mazda':
          return VehicleType.truckMazda;
        case 'shehzore':
          return VehicleType.shehzore;
        case 'pickup_dala':
          return VehicleType.pickupDala;
        case 'rickshaw_loader':
          return VehicleType.rickshawLoader;
        case 'other':
          return VehicleType.other;
        case 'trolley':
        default:
          return VehicleType.trolley;
      }
    }

    WeighbridgeStatus parseStatus(String? val) {
      switch (val) {
        case 'completed':
          return WeighbridgeStatus.completed;
        case 'cancelled':
          return WeighbridgeStatus.cancelled;
        case 'gross_recorded':
        default:
          return WeighbridgeStatus.grossRecorded;
      }
    }

    WeighbridgePartyType parsePartyType(String? val) {
      switch (val) {
        case 'buyer':
          return WeighbridgePartyType.buyer;
        case 'other':
          return WeighbridgePartyType.other;
        case 'farmer':
        default:
          return WeighbridgePartyType.farmer;
      }
    }

    WeighbridgeFeePaidBy parseFeePayer(String? val) {
      switch (val) {
        case 'buyer':
          return WeighbridgeFeePaidBy.buyer;
        case 'shop':
          return WeighbridgeFeePaidBy.shop;
        case 'waived':
          return WeighbridgeFeePaidBy.waived;
        case 'farmer':
        default:
          return WeighbridgeFeePaidBy.farmer;
      }
    }

    return WeighbridgeTicket(
      id: id,
      shopId: map['shop_id'] as String? ?? '',
      ticketNumber: map['ticket_number'] as String? ?? '',
      vehicleNumber: map['vehicle_number'] as String? ?? '',
      vehicleType: parseVehicle(map['vehicle_type'] as String?),
      driverName: map['driver_name'] as String? ?? '',
      driverPhone: map['driver_phone'] as String? ?? '',
      partyName: map['party_name'] as String? ?? '',
      partyType: parsePartyType(map['party_type'] as String?),
      partyId: map['party_id'] as String?,
      commodityName: map['commodity_name'] as String? ?? '',
      grossWeightKg: (map['gross_weight_kg'] as num?)?.toDouble() ?? 0.0,
      tareWeightKg: (map['tare_weight_kg'] as num?)?.toDouble() ?? 0.0,
      netWeightKg: (map['net_weight_kg'] as num?)?.toDouble() ?? 0.0,
      deductionKg: (map['deduction_kg'] as num?)?.toDouble() ?? 0.0,
      deductionReason: map['deduction_reason'] as String? ?? '',
      finalWeightKg: (map['final_weight_kg'] as num?)?.toDouble() ?? 0.0,
      bagCount: (map['bag_count'] as num?)?.toInt() ?? 0,
      kandaFee: (map['kanda_fee'] as num?)?.toDouble() ?? 0.0,
      feePaidBy: parseFeePayer(map['fee_paid_by'] as String?),
      status: parseStatus(map['status'] as String?),
      grossWeighedAt: map['gross_weighed_at'] != null
          ? DateTime.tryParse(map['gross_weighed_at'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      tareWeighedAt: map['tare_weighed_at'] != null
          ? DateTime.tryParse(map['tare_weighed_at'].toString())
          : null,
      operatorName: map['operator_name'] as String? ?? '',
      consignmentLotId: map['consignment_lot_id'] as String?,
      notes: map['notes'] as String? ?? '',
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    String vehicleToString(VehicleType v) {
      switch (v) {
        case VehicleType.truckMazda:
          return 'truck_mazda';
        case VehicleType.shehzore:
          return 'shehzore';
        case VehicleType.pickupDala:
          return 'pickup_dala';
        case VehicleType.rickshawLoader:
          return 'rickshaw_loader';
        case VehicleType.other:
          return 'other';
        case VehicleType.trolley:
          return 'trolley';
      }
    }

    String statusToString(WeighbridgeStatus s) {
      switch (s) {
        case WeighbridgeStatus.completed:
          return 'completed';
        case WeighbridgeStatus.cancelled:
          return 'cancelled';
        case WeighbridgeStatus.grossRecorded:
          return 'gross_recorded';
      }
    }

    String partyTypeToString(WeighbridgePartyType p) {
      switch (p) {
        case WeighbridgePartyType.buyer:
          return 'buyer';
        case WeighbridgePartyType.other:
          return 'other';
        case WeighbridgePartyType.farmer:
          return 'farmer';
      }
    }

    String feePayerToString(WeighbridgeFeePaidBy f) {
      switch (f) {
        case WeighbridgeFeePaidBy.buyer:
          return 'buyer';
        case WeighbridgeFeePaidBy.shop:
          return 'shop';
        case WeighbridgeFeePaidBy.waived:
          return 'waived';
        case WeighbridgeFeePaidBy.farmer:
          return 'farmer';
      }
    }

    return {
      'shop_id': shopId,
      'ticket_number': ticketNumber,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleToString(vehicleType),
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'party_name': partyName,
      'party_type': partyTypeToString(partyType),
      'party_id': partyId,
      'commodity_name': commodityName,
      'gross_weight_kg': grossWeightKg,
      'tare_weight_kg': tareWeightKg,
      'net_weight_kg': netWeightKg,
      'deduction_kg': deductionKg,
      'deduction_reason': deductionReason,
      'final_weight_kg': finalWeightKg,
      'bag_count': bagCount,
      'kanda_fee': kandaFee,
      'fee_paid_by': feePayerToString(feePaidBy),
      'status': statusToString(status),
      'gross_weighed_at': grossWeighedAt.toIso8601String(),
      'tare_weighed_at': tareWeighedAt?.toIso8601String(),
      'operator_name': operatorName,
      'consignment_lot_id': consignmentLotId,
      'notes': notes,
      'created_by': createdBy,
    };
  }

  WeighbridgeTicket copyWith({
    String? id,
    String? shopId,
    String? ticketNumber,
    String? vehicleNumber,
    VehicleType? vehicleType,
    String? driverName,
    String? driverPhone,
    String? partyName,
    WeighbridgePartyType? partyType,
    String? partyId,
    String? commodityName,
    double? grossWeightKg,
    double? tareWeightKg,
    double? netWeightKg,
    double? deductionKg,
    String? deductionReason,
    double? finalWeightKg,
    int? bagCount,
    double? kandaFee,
    WeighbridgeFeePaidBy? feePaidBy,
    WeighbridgeStatus? status,
    DateTime? grossWeighedAt,
    DateTime? tareWeighedAt,
    String? operatorName,
    String? consignmentLotId,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeighbridgeTicket(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      partyName: partyName ?? this.partyName,
      partyType: partyType ?? this.partyType,
      partyId: partyId ?? this.partyId,
      commodityName: commodityName ?? this.commodityName,
      grossWeightKg: grossWeightKg ?? this.grossWeightKg,
      tareWeightKg: tareWeightKg ?? this.tareWeightKg,
      netWeightKg: netWeightKg ?? this.netWeightKg,
      deductionKg: deductionKg ?? this.deductionKg,
      deductionReason: deductionReason ?? this.deductionReason,
      finalWeightKg: finalWeightKg ?? this.finalWeightKg,
      bagCount: bagCount ?? this.bagCount,
      kandaFee: kandaFee ?? this.kandaFee,
      feePaidBy: feePaidBy ?? this.feePaidBy,
      status: status ?? this.status,
      grossWeighedAt: grossWeighedAt ?? this.grossWeighedAt,
      tareWeighedAt: tareWeighedAt ?? this.tareWeighedAt,
      operatorName: operatorName ?? this.operatorName,
      consignmentLotId: consignmentLotId ?? this.consignmentLotId,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Aggregates weighbridge operation metrics for a shop.
class WeighbridgeSummary {
  final int totalTicketsCount;
  final int awaitingTareCount;
  final int completedCount;
  final double totalGrossWeightKg;
  final double totalNetWeightKg;
  final double totalFinalWeightKg;
  final double totalFinalMaunds;
  final double totalKandaFee;

  const WeighbridgeSummary({
    this.totalTicketsCount = 0,
    this.awaitingTareCount = 0,
    this.completedCount = 0,
    this.totalGrossWeightKg = 0.0,
    this.totalNetWeightKg = 0.0,
    this.totalFinalWeightKg = 0.0,
    this.totalFinalMaunds = 0.0,
    this.totalKandaFee = 0.0,
  });

  factory WeighbridgeSummary.fromTickets(List<WeighbridgeTicket> tickets) {
    int awaiting = 0;
    int completed = 0;
    double gross = 0.0;
    double net = 0.0;
    double finalW = 0.0;
    double fee = 0.0;

    for (final t in tickets) {
      if (t.status == WeighbridgeStatus.cancelled) continue;

      gross += t.grossWeightKg;
      fee += t.kandaFee;

      if (t.isAwaitingTare) {
        awaiting++;
      } else if (t.status == WeighbridgeStatus.completed) {
        completed++;
        net += t.computedNetWeightKg;
        finalW += t.computedFinalWeightKg;
      }
    }

    return WeighbridgeSummary(
      totalTicketsCount: tickets.where((t) => t.status != WeighbridgeStatus.cancelled).length,
      awaitingTareCount: awaiting,
      completedCount: completed,
      totalGrossWeightKg: gross,
      totalNetWeightKg: net,
      totalFinalWeightKg: finalW,
      totalFinalMaunds: finalW / 40.0,
      totalKandaFee: fee,
    );
  }
}
