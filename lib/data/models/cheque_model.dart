/// Cheque transaction direction.
enum ChequeType {
  received, // Incoming cheque from a customer / buyer
  issued, // Outgoing cheque issued to a farmer / supplier / expense
}

/// Lifecycle statuses of a cheque in Mandi operations.
enum ChequeStatus {
  inHand, // Received and held in vault / safe (PDC waiting for maturity)
  deposited, // Deposited in bank, awaiting clearing
  cleared, // Cleared and credited to bank balance
  bounced, // Returned unpaid / dishonored by the drawer's bank
  returned, // Returned or cancelled before deposit
}

/// Model representing a Cheque or Post-Dated Cheque (PDC) in Mandi accounting.
class Cheque {
  final String id;
  final String shopId;
  final String chequeNumber;
  final ChequeType type;
  final String partyType; // 'customer', 'supplier', 'other'
  final String? partyId;
  final String partyName;
  final String bankName; // Drawn on bank (e.g. "Bank Alfalah")
  final String? targetBankAccountId; // Our shop's bank account where deposited
  final String? targetBankAccountName; // Helper for display
  final double amount;
  final DateTime issueDate;
  final DateTime dueDate; // PDC maturity date
  final DateTime? depositDate;
  final DateTime? clearanceDate;
  final ChequeStatus status;
  final String bounceReason;
  final String notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Cheque({
    required this.id,
    required this.shopId,
    required this.chequeNumber,
    required this.type,
    this.partyType = 'customer',
    this.partyId,
    this.partyName = '',
    this.bankName = '',
    this.targetBankAccountId,
    this.targetBankAccountName,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    this.depositDate,
    this.clearanceDate,
    this.status = ChequeStatus.inHand,
    this.bounceReason = '',
    this.notes = '',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  /// True if due date is in the future compared to issue date (PDC)
  bool get isPdc {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isAfter(today);
  }

  /// True if due date is today
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  /// True if cheque is in hand or deposited but past due date
  bool get isOverdue {
    if (status != ChequeStatus.inHand && status != ChequeStatus.deposited) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  String get typeLabelUrdu =>
      type == ChequeType.received ? 'وصولی چیک' : 'ادائیگی چیک';

  String get typeLabelEnglish =>
      type == ChequeType.received ? 'Received' : 'Issued';

  String get statusLabelUrdu {
    switch (status) {
      case ChequeStatus.inHand:
        return isPdc ? 'پی ڈی سی چیک' : 'پاس موجود';
      case ChequeStatus.deposited:
        return 'بینک میں جمع شدہ';
      case ChequeStatus.cleared:
        return 'کلیئر شدہ';
      case ChequeStatus.bounced:
        return 'باؤنس شدہ';
      case ChequeStatus.returned:
        return 'واپس شدہ';
    }
  }

  String get statusLabelEnglish {
    switch (status) {
      case ChequeStatus.inHand:
        return isPdc ? 'PDC (In-Hand)' : 'In-Hand';
      case ChequeStatus.deposited:
        return 'Deposited';
      case ChequeStatus.cleared:
        return 'Cleared';
      case ChequeStatus.bounced:
        return 'Bounced';
      case ChequeStatus.returned:
        return 'Returned';
    }
  }

  factory Cheque.fromMap(String id, Map<String, dynamic> map) {
    ChequeType parseType(String? val) {
      if (val == 'issued') return ChequeType.issued;
      return ChequeType.received;
    }

    ChequeStatus parseStatus(String? val) {
      switch (val) {
        case 'deposited':
          return ChequeStatus.deposited;
        case 'cleared':
          return ChequeStatus.cleared;
        case 'bounced':
          return ChequeStatus.bounced;
        case 'returned':
          return ChequeStatus.returned;
        case 'in_hand':
        default:
          return ChequeStatus.inHand;
      }
    }

    return Cheque(
      id: id,
      shopId: map['shop_id'] as String? ?? '',
      chequeNumber: map['cheque_number'] as String? ?? '',
      type: parseType(map['type'] as String?),
      partyType: map['party_type'] as String? ?? 'customer',
      partyId: map['party_id'] as String?,
      partyName: map['party_name'] as String? ?? '',
      bankName: map['bank_name'] as String? ?? '',
      targetBankAccountId: map['target_bank_account_id'] as String?,
      targetBankAccountName: map['target_bank_account_name'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      issueDate: map['issue_date'] != null
          ? DateTime.tryParse(map['issue_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      depositDate: map['deposit_date'] != null
          ? DateTime.tryParse(map['deposit_date'].toString())
          : null,
      clearanceDate: map['clearance_date'] != null
          ? DateTime.tryParse(map['clearance_date'].toString())
          : null,
      status: parseStatus(map['status'] as String?),
      bounceReason: map['bounce_reason'] as String? ?? '',
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
    String statusString(ChequeStatus s) {
      switch (s) {
        case ChequeStatus.inHand:
          return 'in_hand';
        case ChequeStatus.deposited:
          return 'deposited';
        case ChequeStatus.cleared:
          return 'cleared';
        case ChequeStatus.bounced:
          return 'bounced';
        case ChequeStatus.returned:
          return 'returned';
      }
    }

    return {
      'shop_id': shopId,
      'cheque_number': chequeNumber,
      'type': type == ChequeType.issued ? 'issued' : 'received',
      'party_type': partyType,
      'party_id': partyId,
      'party_name': partyName,
      'bank_name': bankName,
      'target_bank_account_id': targetBankAccountId,
      'amount': amount,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'deposit_date': depositDate?.toIso8601String(),
      'clearance_date': clearanceDate?.toIso8601String(),
      'status': statusString(status),
      'bounce_reason': bounceReason,
      'notes': notes,
      'created_by': createdBy,
    };
  }

  Cheque copyWith({
    String? id,
    String? shopId,
    String? chequeNumber,
    ChequeType? type,
    String? partyType,
    String? partyId,
    String? partyName,
    String? bankName,
    String? targetBankAccountId,
    String? targetBankAccountName,
    double? amount,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? depositDate,
    DateTime? clearanceDate,
    ChequeStatus? status,
    String? bounceReason,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cheque(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      type: type ?? this.type,
      partyType: partyType ?? this.partyType,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      bankName: bankName ?? this.bankName,
      targetBankAccountId: targetBankAccountId ?? this.targetBankAccountId,
      targetBankAccountName:
          targetBankAccountName ?? this.targetBankAccountName,
      amount: amount ?? this.amount,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      depositDate: depositDate ?? this.depositDate,
      clearanceDate: clearanceDate ?? this.clearanceDate,
      status: status ?? this.status,
      bounceReason: bounceReason ?? this.bounceReason,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Aggregated metrics for cheques and PDCs.
class ChequeSummary {
  final int totalCount;
  final int inHandCount;
  final double inHandAmount;
  final int depositedCount;
  final double depositedAmount;
  final int clearedCount;
  final double clearedAmount;
  final int bouncedCount;
  final double bouncedAmount;
  final int dueTodayCount;
  final double dueTodayAmount;
  final int overdueCount;
  final double overdueAmount;
  final double totalReceivedAmount;
  final double totalIssuedAmount;

  const ChequeSummary({
    this.totalCount = 0,
    this.inHandCount = 0,
    this.inHandAmount = 0.0,
    this.depositedCount = 0,
    this.depositedAmount = 0.0,
    this.clearedCount = 0,
    this.clearedAmount = 0.0,
    this.bouncedCount = 0,
    this.bouncedAmount = 0.0,
    this.dueTodayCount = 0,
    this.dueTodayAmount = 0.0,
    this.overdueCount = 0,
    this.overdueAmount = 0.0,
    this.totalReceivedAmount = 0.0,
    this.totalIssuedAmount = 0.0,
  });

  factory ChequeSummary.fromCheques(List<Cheque> cheques) {
    int totalCount = cheques.length;
    int inHandCount = 0;
    double inHandAmount = 0.0;
    int depositedCount = 0;
    double depositedAmount = 0.0;
    int clearedCount = 0;
    double clearedAmount = 0.0;
    int bouncedCount = 0;
    double bouncedAmount = 0.0;
    int dueTodayCount = 0;
    double dueTodayAmount = 0.0;
    int overdueCount = 0;
    double overdueAmount = 0.0;
    double totalReceivedAmount = 0.0;
    double totalIssuedAmount = 0.0;

    for (final c in cheques) {
      if (c.type == ChequeType.received) {
        totalReceivedAmount += c.amount;
      } else {
        totalIssuedAmount += c.amount;
      }

      switch (c.status) {
        case ChequeStatus.inHand:
          inHandCount++;
          inHandAmount += c.amount;
          if (c.isDueToday) {
            dueTodayCount++;
            dueTodayAmount += c.amount;
          } else if (c.isOverdue) {
            overdueCount++;
            overdueAmount += c.amount;
          }
          break;
        case ChequeStatus.deposited:
          depositedCount++;
          depositedAmount += c.amount;
          if (c.isOverdue) {
            overdueCount++;
            overdueAmount += c.amount;
          }
          break;
        case ChequeStatus.cleared:
          clearedCount++;
          clearedAmount += c.amount;
          break;
        case ChequeStatus.bounced:
          bouncedCount++;
          bouncedAmount += c.amount;
          break;
        case ChequeStatus.returned:
          break;
      }
    }

    return ChequeSummary(
      totalCount: totalCount,
      inHandCount: inHandCount,
      inHandAmount: inHandAmount,
      depositedCount: depositedCount,
      depositedAmount: depositedAmount,
      clearedCount: clearedCount,
      clearedAmount: clearedAmount,
      bouncedCount: bouncedCount,
      bouncedAmount: bouncedAmount,
      dueTodayCount: dueTodayCount,
      dueTodayAmount: dueTodayAmount,
      overdueCount: overdueCount,
      overdueAmount: overdueAmount,
      totalReceivedAmount: totalReceivedAmount,
      totalIssuedAmount: totalIssuedAmount,
    );
  }
}
