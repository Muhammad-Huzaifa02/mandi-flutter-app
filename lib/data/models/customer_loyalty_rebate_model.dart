// Domain models for Customer Loyalty, Volume Rebate & Seasonal Brokerage Incentives
// (*گاہک رعایت، والیم بونس اور سالانہ انعامات*).

enum RebateTierLevel {
  standard,
  silver,
  gold,
  platinum;

  String toDbString() {
    switch (this) {
      case RebateTierLevel.standard:
        return 'standard';
      case RebateTierLevel.silver:
        return 'silver';
      case RebateTierLevel.gold:
        return 'gold';
      case RebateTierLevel.platinum:
        return 'platinum';
    }
  }

  String get labelUrdu {
    switch (this) {
      case RebateTierLevel.standard:
        return 'سٹینڈرڈ گاہک';
      case RebateTierLevel.silver:
        return 'سلور ٹریڈر (Silver)';
      case RebateTierLevel.gold:
        return 'گولڈ خریدار (Gold)';
      case RebateTierLevel.platinum:
        return 'پلاٹینم والیم پارٹنر (Platinum)';
    }
  }

  String get labelEnglish {
    switch (this) {
      case RebateTierLevel.standard:
        return 'Standard';
      case RebateTierLevel.silver:
        return 'Silver (1.0%)';
      case RebateTierLevel.gold:
        return 'Gold (2.0%)';
      case RebateTierLevel.platinum:
        return 'Platinum (3.0%)';
    }
  }

  double get defaultPercentage {
    switch (this) {
      case RebateTierLevel.standard:
        return 0.5;
      case RebateTierLevel.silver:
        return 1.0;
      case RebateTierLevel.gold:
        return 2.0;
      case RebateTierLevel.platinum:
        return 3.0;
    }
  }

  static RebateTierLevel fromMaunds(double maunds) {
    if (maunds >= 10000) return RebateTierLevel.platinum;
    if (maunds >= 5000) return RebateTierLevel.gold;
    if (maunds >= 1000) return RebateTierLevel.silver;
    return RebateTierLevel.standard;
  }

  static RebateTierLevel fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'silver':
        return RebateTierLevel.silver;
      case 'gold':
        return RebateTierLevel.gold;
      case 'platinum':
        return RebateTierLevel.platinum;
      case 'standard':
      default:
        return RebateTierLevel.standard;
    }
  }
}

enum RebateStatus {
  accruing,
  approved,
  credited,
  cancelled;

  String toDbString() {
    switch (this) {
      case RebateStatus.accruing:
        return 'accruing';
      case RebateStatus.approved:
        return 'approved';
      case RebateStatus.credited:
        return 'credited';
      case RebateStatus.cancelled:
        return 'cancelled';
    }
  }

  String get labelUrdu {
    switch (this) {
      case RebateStatus.accruing:
        return 'سیزن دوران جمع ہو رہا ہے';
      case RebateStatus.approved:
        return 'منظور شدہ (کریڈٹ تیار)';
      case RebateStatus.credited:
        return 'کھاتہ میں منتقل شدہ (کریڈٹ نوٹ جاری)';
      case RebateStatus.cancelled:
        return 'منسوخ';
    }
  }

  String get labelEnglish {
    switch (this) {
      case RebateStatus.accruing:
        return 'Accruing';
      case RebateStatus.approved:
        return 'Approved';
      case RebateStatus.credited:
        return 'Credited to Khata';
      case RebateStatus.cancelled:
        return 'Cancelled';
    }
  }

  static RebateStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'approved':
        return RebateStatus.approved;
      case 'credited':
        return RebateStatus.credited;
      case 'cancelled':
        return RebateStatus.cancelled;
      case 'accruing':
      default:
        return RebateStatus.accruing;
    }
  }
}

class CustomerLoyaltyRebate {
  final String id;
  final String shopId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String programName;
  final String seasonYear; // e.g. "Rabi 2026", "Kharif 2026"
  final double qualifyingMaunds;
  final double qualifyingTurnoverPkr;
  final RebateTierLevel tierLevel;
  final double rebatePercentage;
  final double rebateAmountPkr;
  final String creditNoteNumber;
  final RebateStatus status;
  final DateTime? creditedAt;
  final String notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CustomerLoyaltyRebate({
    this.id = '',
    required this.shopId,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    this.programName = 'Seasonal Volume Rebate',
    this.seasonYear = '2026',
    this.qualifyingMaunds = 0.0,
    this.qualifyingTurnoverPkr = 0.0,
    this.tierLevel = RebateTierLevel.standard,
    this.rebatePercentage = 1.0,
    this.rebateAmountPkr = 0.0,
    this.creditNoteNumber = '',
    this.status = RebateStatus.accruing,
    this.creditedAt,
    this.notes = '',
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  /// Computed rebate payout based on turnover and percentage.
  static double computeRebateAmount(double turnoverPkr, double percentage) {
    if (turnoverPkr <= 0 || percentage <= 0) return 0.0;
    return turnoverPkr * (percentage / 100.0);
  }

  factory CustomerLoyaltyRebate.fromMap(String id, Map<String, dynamic> map) {
    return CustomerLoyaltyRebate(
      id: id,
      shopId: map['shop_id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      customerName: map['customer_name']?.toString() ?? 'Buyer',
      customerPhone: map['customer_phone']?.toString() ?? '',
      programName: map['program_name']?.toString() ?? 'Seasonal Volume Rebate',
      seasonYear: map['season_year']?.toString() ?? '2026',
      qualifyingMaunds: (map['qualifying_maunds'] as num?)?.toDouble() ?? 0.0,
      qualifyingTurnoverPkr:
          (map['qualifying_turnover_pkr'] as num?)?.toDouble() ?? 0.0,
      tierLevel:
          RebateTierLevel.fromString(map['tier_level']?.toString() ?? 'standard'),
      rebatePercentage: (map['rebate_percentage'] as num?)?.toDouble() ?? 1.0,
      rebateAmountPkr: (map['rebate_amount_pkr'] as num?)?.toDouble() ?? 0.0,
      creditNoteNumber: map['credit_note_number']?.toString() ?? '',
      status: RebateStatus.fromString(map['status']?.toString() ?? 'accruing'),
      creditedAt: map['credited_at'] != null
          ? DateTime.tryParse(map['credited_at'].toString())
          : null,
      notes: map['notes']?.toString() ?? '',
      createdBy: map['created_by']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'program_name': programName,
      'season_year': seasonYear,
      'qualifying_maunds': qualifyingMaunds,
      'qualifying_turnover_pkr': qualifyingTurnoverPkr,
      'tier_level': tierLevel.toDbString(),
      'rebate_percentage': rebatePercentage,
      'rebate_amount_pkr': rebateAmountPkr,
      'credit_note_number': creditNoteNumber,
      'status': status.toDbString(),
      'credited_at': creditedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  CustomerLoyaltyRebate copyWith({
    String? id,
    String? shopId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? programName,
    String? seasonYear,
    double? qualifyingMaunds,
    double? qualifyingTurnoverPkr,
    RebateTierLevel? tierLevel,
    double? rebatePercentage,
    double? rebateAmountPkr,
    String? creditNoteNumber,
    RebateStatus? status,
    DateTime? creditedAt,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerLoyaltyRebate(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      programName: programName ?? this.programName,
      seasonYear: seasonYear ?? this.seasonYear,
      qualifyingMaunds: qualifyingMaunds ?? this.qualifyingMaunds,
      qualifyingTurnoverPkr:
          qualifyingTurnoverPkr ?? this.qualifyingTurnoverPkr,
      tierLevel: tierLevel ?? this.tierLevel,
      rebatePercentage: rebatePercentage ?? this.rebatePercentage,
      rebateAmountPkr: rebateAmountPkr ?? this.rebateAmountPkr,
      creditNoteNumber: creditNoteNumber ?? this.creditNoteNumber,
      status: status ?? this.status,
      creditedAt: creditedAt ?? this.creditedAt,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
