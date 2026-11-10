/// Material and packaging type of the Bardana.
enum BardanaType {
  jute, // Traditional Jute Sack (پٹ سن / ٹاٹ کی بوری) - ~100kg/80kg
  plasticPp, // Polypropylene / Woven Plastic Bag (پلاسٹک تھیلا) - ~40kg/50kg
  woodenCrate, // Wooden Crate for fruits/tomatoes (لکڑی کی پیٹی)
  plasticCrate, // Plastic reusable crate for vegetables (پلاسٹک کریٹ)
  other,
}

/// Direction of the Bardana movement.
enum BardanaDirection {
  issued, // Issued empty to farmer/buyer for packing
  returned, // Returned empty by party back to shop
  purchased, // New stock purchased into shop asset inventory
  damaged, // Damaged / torn / written off
}

/// Settlement status of a Bardana transaction.
enum BardanaStatus {
  pending, // Still in party's custody, awaiting return
  returned, // Returned in full
  settled, // Charged to ledger balance or paid in cash
  forfeited, // Deposit forfeited due to non-return
}

/// Model representing a single transaction in the Bardana Ledger.
class BardanaTransaction {
  final String id;
  final String shopId;
  final String partyType; // 'supplier', 'customer', 'other'
  final String? partyId;
  final String partyName;
  final BardanaType bardanaType;
  final BardanaDirection direction;
  final int bagCount;
  final double unitDepositRate;
  final double totalDepositAmount;
  final DateTime transactionDate;
  final DateTime? dueReturnDate;
  final BardanaStatus status;
  final String notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BardanaTransaction({
    required this.id,
    required this.shopId,
    this.partyType = 'supplier',
    this.partyId,
    this.partyName = '',
    this.bardanaType = BardanaType.jute,
    this.direction = BardanaDirection.issued,
    required this.bagCount,
    this.unitDepositRate = 0.0,
    this.totalDepositAmount = 0.0,
    required this.transactionDate,
    this.dueReturnDate,
    this.status = BardanaStatus.pending,
    this.notes = '',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if an issued Bardana is overdue for return
  bool get isOverdue {
    if (direction != BardanaDirection.issued || status != BardanaStatus.pending) {
      return false;
    }
    if (dueReturnDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      dueReturnDate!.year,
      dueReturnDate!.month,
      dueReturnDate!.day,
    );
    return due.isBefore(today);
  }

  String get bardanaTypeLabelUrdu {
    switch (bardanaType) {
      case BardanaType.jute:
        return 'پٹ سن بوری (Jute)';
      case BardanaType.plasticPp:
        return 'پلاسٹک تھیلا (PP)';
      case BardanaType.woodenCrate:
        return 'لکڑی کی پیٹی';
      case BardanaType.plasticCrate:
        return 'پلاسٹک کریٹ';
      case BardanaType.other:
        return 'دیگر باردانہ';
    }
  }

  String get bardanaTypeLabelEnglish {
    switch (bardanaType) {
      case BardanaType.jute:
        return 'Jute Sack';
      case BardanaType.plasticPp:
        return 'Plastic Bag (PP)';
      case BardanaType.woodenCrate:
        return 'Wooden Crate';
      case BardanaType.plasticCrate:
        return 'Plastic Crate';
      case BardanaType.other:
        return 'Other';
    }
  }

  String get directionLabelUrdu {
    switch (direction) {
      case BardanaDirection.issued:
        return 'جاری کردہ (دیا گیا)';
      case BardanaDirection.returned:
        return 'واپس موصول شدہ';
      case BardanaDirection.purchased:
        return 'خریداری (نیا باردانہ)';
      case BardanaDirection.damaged:
        return 'خراب / ضائع شدہ';
    }
  }

  String get directionLabelEnglish {
    switch (direction) {
      case BardanaDirection.issued:
        return 'Issued';
      case BardanaDirection.returned:
        return 'Returned';
      case BardanaDirection.purchased:
        return 'Purchased';
      case BardanaDirection.damaged:
        return 'Damaged';
    }
  }

  String get statusLabelUrdu {
    switch (status) {
      case BardanaStatus.pending:
        return isOverdue ? 'تاخیر شدہ (واپسی باقی)' : 'واپسی باقی';
      case BardanaStatus.returned:
        return 'مکمل واپس شدہ';
      case BardanaStatus.settled:
        return 'کھاتے میں شامل';
      case BardanaStatus.forfeited:
        return 'سیکیورٹی ضبط';
    }
  }

  factory BardanaTransaction.fromMap(String id, Map<String, dynamic> map) {
    BardanaType parseType(String? val) {
      switch (val) {
        case 'plastic_pp':
          return BardanaType.plasticPp;
        case 'wooden_crate':
          return BardanaType.woodenCrate;
        case 'plastic_crate':
          return BardanaType.plasticCrate;
        case 'other':
          return BardanaType.other;
        case 'jute':
        default:
          return BardanaType.jute;
      }
    }

    BardanaDirection parseDirection(String? val) {
      switch (val) {
        case 'returned':
          return BardanaDirection.returned;
        case 'purchased':
          return BardanaDirection.purchased;
        case 'damaged':
          return BardanaDirection.damaged;
        case 'issued':
        default:
          return BardanaDirection.issued;
      }
    }

    BardanaStatus parseStatus(String? val) {
      switch (val) {
        case 'returned':
          return BardanaStatus.returned;
        case 'settled':
          return BardanaStatus.settled;
        case 'forfeited':
          return BardanaStatus.forfeited;
        case 'pending':
        default:
          return BardanaStatus.pending;
      }
    }

    return BardanaTransaction(
      id: id,
      shopId: map['shop_id'] as String? ?? '',
      partyType: map['party_type'] as String? ?? 'supplier',
      partyId: map['party_id'] as String?,
      partyName: map['party_name'] as String? ?? '',
      bardanaType: parseType(map['bardana_type'] as String?),
      direction: parseDirection(map['direction'] as String?),
      bagCount: (map['bag_count'] as num?)?.toInt() ?? 0,
      unitDepositRate:
          (map['unit_deposit_rate'] as num?)?.toDouble() ?? 0.0,
      totalDepositAmount:
          (map['total_deposit_amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: map['transaction_date'] != null
          ? DateTime.tryParse(map['transaction_date'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      dueReturnDate: map['due_return_date'] != null
          ? DateTime.tryParse(map['due_return_date'].toString())
          : null,
      status: parseStatus(map['status'] as String?),
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
    String typeString(BardanaType t) {
      switch (t) {
        case BardanaType.plasticPp:
          return 'plastic_pp';
        case BardanaType.woodenCrate:
          return 'wooden_crate';
        case BardanaType.plasticCrate:
          return 'plastic_crate';
        case BardanaType.other:
          return 'other';
        case BardanaType.jute:
          return 'jute';
      }
    }

    String directionString(BardanaDirection d) {
      switch (d) {
        case BardanaDirection.returned:
          return 'returned';
        case BardanaDirection.purchased:
          return 'purchased';
        case BardanaDirection.damaged:
          return 'damaged';
        case BardanaDirection.issued:
          return 'issued';
      }
    }

    String statusString(BardanaStatus s) {
      switch (s) {
        case BardanaStatus.returned:
          return 'returned';
        case BardanaStatus.settled:
          return 'settled';
        case BardanaStatus.forfeited:
          return 'forfeited';
        case BardanaStatus.pending:
          return 'pending';
      }
    }

    return {
      'shop_id': shopId,
      'party_type': partyType,
      'party_id': partyId,
      'party_name': partyName,
      'bardana_type': typeString(bardanaType),
      'direction': directionString(direction),
      'bag_count': bagCount,
      'unit_deposit_rate': unitDepositRate,
      'total_deposit_amount': totalDepositAmount,
      'transaction_date': transactionDate.toIso8601String(),
      'due_return_date': dueReturnDate?.toIso8601String(),
      'status': statusString(status),
      'notes': notes,
      'created_by': createdBy,
    };
  }

  BardanaTransaction copyWith({
    String? id,
    String? shopId,
    String? partyType,
    String? partyId,
    String? partyName,
    BardanaType? bardanaType,
    BardanaDirection? direction,
    int? bagCount,
    double? unitDepositRate,
    double? totalDepositAmount,
    DateTime? transactionDate,
    DateTime? dueReturnDate,
    BardanaStatus? status,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BardanaTransaction(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      partyType: partyType ?? this.partyType,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      bardanaType: bardanaType ?? this.bardanaType,
      direction: direction ?? this.direction,
      bagCount: bagCount ?? this.bagCount,
      unitDepositRate: unitDepositRate ?? this.unitDepositRate,
      totalDepositAmount: totalDepositAmount ?? this.totalDepositAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      dueReturnDate: dueReturnDate ?? this.dueReturnDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Financial & stock metrics aggregator for the Bardana ledger.
class BardanaSummary {
  final int totalIssuedCount;
  final int totalReturnedCount;
  final int netPendingWithParties;
  final int totalDamagedCount;
  final double totalDepositReceivable;
  final int totalOverdueCount;

  const BardanaSummary({
    this.totalIssuedCount = 0,
    this.totalReturnedCount = 0,
    this.netPendingWithParties = 0,
    this.totalDamagedCount = 0,
    this.totalDepositReceivable = 0.0,
    this.totalOverdueCount = 0,
  });

  factory BardanaSummary.fromTransactions(List<BardanaTransaction> txs) {
    int issued = 0;
    int returned = 0;
    int damaged = 0;
    double depositReceivable = 0.0;
    int overdue = 0;

    for (final tx in txs) {
      if (tx.direction == BardanaDirection.issued) {
        issued += tx.bagCount;
        if (tx.status == BardanaStatus.pending) {
          depositReceivable += tx.totalDepositAmount;
          if (tx.isOverdue) overdue += tx.bagCount;
        }
      } else if (tx.direction == BardanaDirection.returned) {
        returned += tx.bagCount;
      } else if (tx.direction == BardanaDirection.damaged) {
        damaged += tx.bagCount;
      }
    }

    final netPending = issued - returned - damaged;

    return BardanaSummary(
      totalIssuedCount: issued,
      totalReturnedCount: returned,
      netPendingWithParties: netPending < 0 ? 0 : netPending,
      totalDamagedCount: damaged,
      totalDepositReceivable: depositReceivable,
      totalOverdueCount: overdue,
    );
  }
}
