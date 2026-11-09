/// Model representing a commercial bank or digital wallet account
/// maintained by the Commission Shop / Arhti (e.g. Meezan, HBL, MCB, Raast).
class BankAccount {
  final String id;
  final String shopId;
  final String bankName;
  final String accountTitle;
  final String accountNumber;
  final String iban;
  final String branchName;
  final String branchCode;
  final double openingBalance;
  final double currentBalance;
  final bool isDefault;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BankAccount({
    required this.id,
    required this.shopId,
    required this.bankName,
    this.accountTitle = '',
    this.accountNumber = '',
    this.iban = '',
    this.branchName = '',
    this.branchCode = '',
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.isDefault = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BankAccount.fromMap(String id, Map<String, dynamic> map) {
    return BankAccount(
      id: id,
      shopId: map['shop_id'] as String? ?? '',
      bankName: map['bank_name'] as String? ?? '',
      accountTitle: map['account_title'] as String? ?? '',
      accountNumber: map['account_number'] as String? ?? '',
      iban: map['iban'] as String? ?? '',
      branchName: map['branch_name'] as String? ?? '',
      branchCode: map['branch_code'] as String? ?? '',
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      isDefault: map['is_default'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
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
      'bank_name': bankName,
      'account_title': accountTitle,
      'account_number': accountNumber,
      'iban': iban,
      'branch_name': branchName,
      'branch_code': branchCode,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }

  BankAccount copyWith({
    String? id,
    String? shopId,
    String? bankName,
    String? accountTitle,
    String? accountNumber,
    String? iban,
    String? branchName,
    String? branchCode,
    double? openingBalance,
    double? currentBalance,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      bankName: bankName ?? this.bankName,
      accountTitle: accountTitle ?? this.accountTitle,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      branchName: branchName ?? this.branchName,
      branchCode: branchCode ?? this.branchCode,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    if (accountTitle.isNotEmpty) {
      return '$bankName - $accountTitle';
    }
    return bankName;
  }
}
