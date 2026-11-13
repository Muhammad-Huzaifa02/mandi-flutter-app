/// Categories of pre-harvest financing and agricultural inputs advanced to farmers.
enum FarmerAdvanceType {
  cash, // Direct cash advance (نقد ایڈوانس)
  fertilizer, // Fertilizer sacks DAP/Urea (کھاد بوری)
  seed, // Certified agricultural seed (بیج)
  pesticide, // Insecticide / Pesticide Spray (سپرے / زرعی ادویات)
  diesel, // Fuel for tractor / tube-well (ڈیزل / ایندھن)
  other,
}

extension FarmerAdvanceTypeExt on FarmerAdvanceType {
  String get labelEnglish {
    switch (this) {
      case FarmerAdvanceType.cash:
        return 'Cash Advance';
      case FarmerAdvanceType.fertilizer:
        return 'Fertilizer';
      case FarmerAdvanceType.seed:
        return 'Seed';
      case FarmerAdvanceType.pesticide:
        return 'Pesticide';
      case FarmerAdvanceType.diesel:
        return 'Diesel';
      case FarmerAdvanceType.other:
        return 'Other Input';
    }
  }

  String get labelUrdu {
    switch (this) {
      case FarmerAdvanceType.cash:
        return 'نقد رقم ایڈوانس';
      case FarmerAdvanceType.fertilizer:
        return 'کھاد بوری';
      case FarmerAdvanceType.seed:
        return 'زرعی بیج';
      case FarmerAdvanceType.pesticide:
        return 'سپرے زرعی ادویات';
      case FarmerAdvanceType.diesel:
        return 'ڈیزل ایندھن';
      case FarmerAdvanceType.other:
        return 'دیگر زرعی اخراجات';
    }
  }
}

/// Recovery lifecycle status of a farmer crop loan.
enum FarmerAdvanceStatus {
  active, // Outstanding, awaiting harvest
  partiallyRecovered, // Some recovery deducted, remainder pending
  fullyRecovered, // 100% recovered from crop sales
  writtenOff, // Bad debt write-off
}

extension FarmerAdvanceStatusExt on FarmerAdvanceStatus {
  String get labelEnglish {
    switch (this) {
      case FarmerAdvanceStatus.active:
        return 'Active';
      case FarmerAdvanceStatus.partiallyRecovered:
        return 'Partially Recovered';
      case FarmerAdvanceStatus.fullyRecovered:
        return 'Fully Recovered';
      case FarmerAdvanceStatus.writtenOff:
        return 'Written Off';
    }
  }

  String get labelUrdu {
    switch (this) {
      case FarmerAdvanceStatus.active:
        return 'واپسی واجب الادا';
      case FarmerAdvanceStatus.partiallyRecovered:
        return 'جزوی وصول شدہ';
      case FarmerAdvanceStatus.fullyRecovered:
        return 'مکمل بیباق';
      case FarmerAdvanceStatus.writtenOff:
        return 'ختم شدہ کھاتہ';
    }
  }
}

/// Model representing a pre-harvest crop financing advance to a farmer.
class FarmerAdvance {
  final String id;
  final String shopId;
  final String supplierId;
  final String farmerName;
  final String farmerPhone;
  final FarmerAdvanceType advanceType;
  final String description;
  final double principalAmount;
  final double markupPercent;
  final double markupAmount;
  final double totalPayable;
  final double recoveredAmount;
  final double remainingBalance;
  final DateTime disbursementDate;
  final DateTime? expectedHarvestDate;
  final String targetCrop;
  final FarmerAdvanceStatus status;
  final String paymentMethod;
  final String? bankAccountId;
  final String notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FarmerAdvance({
    required this.id,
    required this.shopId,
    required this.supplierId,
    required this.farmerName,
    this.farmerPhone = '',
    this.advanceType = FarmerAdvanceType.cash,
    this.description = '',
    required this.principalAmount,
    this.markupPercent = 0.0,
    this.markupAmount = 0.0,
    required this.totalPayable,
    this.recoveredAmount = 0.0,
    required this.remainingBalance,
    required this.disbursementDate,
    this.expectedHarvestDate,
    this.targetCrop = '',
    this.status = FarmerAdvanceStatus.active,
    this.paymentMethod = 'cash',
    this.bankAccountId,
    this.notes = '',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  /// Computed markup amount if not explicitly passed
  double get computedMarkupAmount {
    if (markupAmount > 0) return markupAmount;
    if (markupPercent > 0) {
      return principalAmount * (markupPercent / 100.0);
    }
    return 0.0;
  }

  /// Computed total payable (principal + markup)
  double get computedTotalPayable {
    if (totalPayable > 0) return totalPayable;
    return principalAmount + computedMarkupAmount;
  }

  /// Computed outstanding balance remaining
  double get computedRemainingBalance {
    final rem = computedTotalPayable - recoveredAmount;
    return rem < 0 ? 0.0 : rem;
  }

  /// Recovery percentage ratio (0.0 to 1.0)
  double get recoveryRatio {
    final tot = computedTotalPayable;
    if (tot <= 0) return 0.0;
    final r = recoveredAmount / tot;
    return r > 1.0 ? 1.0 : (r < 0 ? 0.0 : r);
  }

  /// True if expected harvest date has passed and remaining balance is > 0
  bool get isOverdue {
    if (status == FarmerAdvanceStatus.fullyRecovered ||
        status == FarmerAdvanceStatus.writtenOff) {
      return false;
    }
    if (expectedHarvestDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final harvest = DateTime(
      expectedHarvestDate!.year,
      expectedHarvestDate!.month,
      expectedHarvestDate!.day,
    );
    return harvest.isBefore(today) && computedRemainingBalance > 0;
  }

  factory FarmerAdvance.fromMap(String id, Map<String, dynamic> map) {
    FarmerAdvanceType parseType(String? val) {
      switch (val) {
        case 'fertilizer':
          return FarmerAdvanceType.fertilizer;
        case 'seed':
          return FarmerAdvanceType.seed;
        case 'pesticide':
          return FarmerAdvanceType.pesticide;
        case 'diesel':
          return FarmerAdvanceType.diesel;
        case 'other':
          return FarmerAdvanceType.other;
        case 'cash':
        default:
          return FarmerAdvanceType.cash;
      }
    }

    FarmerAdvanceStatus parseStatus(String? val) {
      switch (val) {
        case 'partially_recovered':
          return FarmerAdvanceStatus.partiallyRecovered;
        case 'fully_recovered':
          return FarmerAdvanceStatus.fullyRecovered;
        case 'written_off':
          return FarmerAdvanceStatus.writtenOff;
        case 'active':
        default:
          return FarmerAdvanceStatus.active;
      }
    }

    return FarmerAdvance(
      id: id,
      shopId: map['shop_id'] as String? ?? '',
      supplierId: map['supplier_id'] as String? ?? '',
      farmerName: map['farmer_name'] as String? ?? '',
      farmerPhone: map['farmer_phone'] as String? ?? '',
      advanceType: parseType(map['advance_type'] as String?),
      description: map['description'] as String? ?? '',
      principalAmount:
          (map['principal_amount'] as num?)?.toDouble() ?? 0.0,
      markupPercent:
          (map['markup_percent'] as num?)?.toDouble() ?? 0.0,
      markupAmount:
          (map['markup_amount'] as num?)?.toDouble() ?? 0.0,
      totalPayable:
          (map['total_payable'] as num?)?.toDouble() ?? 0.0,
      recoveredAmount:
          (map['recovered_amount'] as num?)?.toDouble() ?? 0.0,
      remainingBalance:
          (map['remaining_balance'] as num?)?.toDouble() ?? 0.0,
      disbursementDate: map['disbursement_date'] != null
          ? DateTime.tryParse(map['disbursement_date'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      expectedHarvestDate: map['expected_harvest_date'] != null
          ? DateTime.tryParse(map['expected_harvest_date'].toString())
          : null,
      targetCrop: map['target_crop'] as String? ?? '',
      status: parseStatus(map['status'] as String?),
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      bankAccountId: map['bank_account_id'] as String?,
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
    String typeToString(FarmerAdvanceType t) {
      switch (t) {
        case FarmerAdvanceType.fertilizer:
          return 'fertilizer';
        case FarmerAdvanceType.seed:
          return 'seed';
        case FarmerAdvanceType.pesticide:
          return 'pesticide';
        case FarmerAdvanceType.diesel:
          return 'diesel';
        case FarmerAdvanceType.other:
          return 'other';
        case FarmerAdvanceType.cash:
          return 'cash';
      }
    }

    String statusToString(FarmerAdvanceStatus s) {
      switch (s) {
        case FarmerAdvanceStatus.partiallyRecovered:
          return 'partially_recovered';
        case FarmerAdvanceStatus.fullyRecovered:
          return 'fully_recovered';
        case FarmerAdvanceStatus.writtenOff:
          return 'written_off';
        case FarmerAdvanceStatus.active:
          return 'active';
      }
    }

    return {
      'shop_id': shopId,
      'supplier_id': supplierId,
      'farmer_name': farmerName,
      'farmer_phone': farmerPhone,
      'advance_type': typeToString(advanceType),
      'description': description,
      'principal_amount': principalAmount,
      'markup_percent': markupPercent,
      'markup_amount': markupAmount,
      'total_payable': totalPayable,
      'recovered_amount': recoveredAmount,
      'remaining_balance': remainingBalance,
      'disbursement_date': disbursementDate.toIso8601String(),
      'expected_harvest_date': expectedHarvestDate?.toIso8601String(),
      'target_crop': targetCrop,
      'status': statusToString(status),
      'payment_method': paymentMethod,
      'bank_account_id': bankAccountId,
      'notes': notes,
      'created_by': createdBy,
    };
  }

  FarmerAdvance copyWith({
    String? id,
    String? shopId,
    String? supplierId,
    String? farmerName,
    String? farmerPhone,
    FarmerAdvanceType? advanceType,
    String? description,
    double? principalAmount,
    double? markupPercent,
    double? markupAmount,
    double? totalPayable,
    double? recoveredAmount,
    double? remainingBalance,
    DateTime? disbursementDate,
    DateTime? expectedHarvestDate,
    String? targetCrop,
    FarmerAdvanceStatus? status,
    String? paymentMethod,
    String? bankAccountId,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmerAdvance(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      supplierId: supplierId ?? this.supplierId,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      advanceType: advanceType ?? this.advanceType,
      description: description ?? this.description,
      principalAmount: principalAmount ?? this.principalAmount,
      markupPercent: markupPercent ?? this.markupPercent,
      markupAmount: markupAmount ?? this.markupAmount,
      totalPayable: totalPayable ?? this.totalPayable,
      recoveredAmount: recoveredAmount ?? this.recoveredAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
      targetCrop: targetCrop ?? this.targetCrop,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Record of an individual recovery deduction made against a farmer advance.
class FarmerAdvanceRecovery {
  final String id;
  final String shopId;
  final String advanceId;
  final String? consignmentLotId;
  final String? invoiceId;
  final double recoveredAmount;
  final DateTime recoveryDate;
  final String recoveryMethod; // 'consignment_deduction', 'cash_payment', 'bank_transfer'
  final String notes;
  final String? createdBy;
  final DateTime? createdAt;

  const FarmerAdvanceRecovery({
    required this.id,
    required this.shopId,
    required this.advanceId,
    this.consignmentLotId,
    this.invoiceId,
    required this.recoveredAmount,
    required this.recoveryDate,
    this.recoveryMethod = 'consignment_deduction',
    this.notes = '',
    this.createdBy,
    this.createdAt,
  });

  factory FarmerAdvanceRecovery.fromMap(String id, Map<String, dynamic> map) {
    return FarmerAdvanceRecovery(
      id: id,
      shopId: map['shop_id'] as String? ?? '',
      advanceId: map['advance_id'] as String? ?? '',
      consignmentLotId: map['consignment_lot_id'] as String?,
      invoiceId: map['invoice_id'] as String?,
      recoveredAmount:
          (map['recovered_amount'] as num?)?.toDouble() ?? 0.0,
      recoveryDate: map['recovery_date'] != null
          ? DateTime.tryParse(map['recovery_date'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      recoveryMethod:
          map['recovery_method'] as String? ?? 'consignment_deduction',
      notes: map['notes'] as String? ?? '',
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'advance_id': advanceId,
      'consignment_lot_id': consignmentLotId,
      'invoice_id': invoiceId,
      'recovered_amount': recoveredAmount,
      'recovery_date': recoveryDate.toIso8601String(),
      'recovery_method': recoveryMethod,
      'notes': notes,
      'created_by': createdBy,
    };
  }
}

/// Portfolio summary of farmer advances and crop financing.
class FarmerAdvanceSummary {
  final int totalAdvancesCount;
  final int activeCount;
  final int fullyRecoveredCount;
  final int overdueCount;
  final double totalPrincipalDisbursed;
  final double totalMarkupAccrued;
  final double totalPayable;
  final double totalRecovered;
  final double netOutstandingBalance;

  const FarmerAdvanceSummary({
    this.totalAdvancesCount = 0,
    this.activeCount = 0,
    this.fullyRecoveredCount = 0,
    this.overdueCount = 0,
    this.totalPrincipalDisbursed = 0.0,
    this.totalMarkupAccrued = 0.0,
    this.totalPayable = 0.0,
    this.totalRecovered = 0.0,
    this.netOutstandingBalance = 0.0,
  });

  factory FarmerAdvanceSummary.fromAdvances(List<FarmerAdvance> advances) {
    int active = 0;
    int recovered = 0;
    int overdue = 0;
    double principal = 0.0;
    double markup = 0.0;
    double payable = 0.0;
    double rec = 0.0;

    for (final a in advances) {
      if (a.status == FarmerAdvanceStatus.writtenOff) continue;

      principal += a.principalAmount;
      markup += a.computedMarkupAmount;
      payable += a.computedTotalPayable;
      rec += a.recoveredAmount;

      if (a.status == FarmerAdvanceStatus.fullyRecovered) {
        recovered++;
      } else {
        active++;
        if (a.isOverdue) overdue++;
      }
    }

    final netOut = payable - rec;

    return FarmerAdvanceSummary(
      totalAdvancesCount: advances
          .where((a) => a.status != FarmerAdvanceStatus.writtenOff)
          .length,
      activeCount: active,
      fullyRecoveredCount: recovered,
      overdueCount: overdue,
      totalPrincipalDisbursed: principal,
      totalMarkupAccrued: markup,
      totalPayable: payable,
      totalRecovered: rec,
      netOutstandingBalance: netOut < 0 ? 0.0 : netOut,
    );
  }
}
