// Domain models for Multi-Partner Mandi Shop Profit Sharing & Drawings
// (*شراکت داری اور منافع تقسیم کھاتہ*).

import 'package:intl/intl.dart';

enum PartnerTransactionType {
  capitalInjection,
  drawing,
  profitDistribution,
  capitalWithdrawal;

  static PartnerTransactionType fromString(String val) {
    switch (val.toLowerCase().replaceAll('-', '_')) {
      case 'drawing':
      case 'personal_drawing':
        return PartnerTransactionType.drawing;
      case 'profit_distribution':
      case 'profit':
        return PartnerTransactionType.profitDistribution;
      case 'capital_withdrawal':
      case 'withdrawal':
        return PartnerTransactionType.capitalWithdrawal;
      case 'capital_injection':
      case 'capital':
      default:
        return PartnerTransactionType.capitalInjection;
    }
  }

  String toDbString() {
    switch (this) {
      case PartnerTransactionType.capitalInjection:
        return 'capital_injection';
      case PartnerTransactionType.drawing:
        return 'drawing';
      case PartnerTransactionType.profitDistribution:
        return 'profit_distribution';
      case PartnerTransactionType.capitalWithdrawal:
        return 'capital_withdrawal';
    }
  }

  String get labelUrdu {
    switch (this) {
      case PartnerTransactionType.capitalInjection:
        return 'سرمایہ اضافہ';
      case PartnerTransactionType.drawing:
        return 'ذاتی خرچ یا نکلوانا';
      case PartnerTransactionType.profitDistribution:
        return 'منافع تقسیم';
      case PartnerTransactionType.capitalWithdrawal:
        return 'سرمایہ واپسی';
    }
  }

  String get labelEnglish {
    switch (this) {
      case PartnerTransactionType.capitalInjection:
        return 'Capital Injection';
      case PartnerTransactionType.drawing:
        return 'Personal Drawing';
      case PartnerTransactionType.profitDistribution:
        return 'Profit Distribution';
      case PartnerTransactionType.capitalWithdrawal:
        return 'Capital Withdrawal';
    }
  }
}

class ShopPartnerModel {
  final String id;
  final String shopId;
  final String name;
  final String? cnic;
  final String? phone;
  final double profitSharingRatio; // percentage, e.g. 50.0 for 50%
  final double openingCapital;
  final double currentCapital;
  final double totalDrawings;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopPartnerModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.cnic,
    this.phone,
    required this.profitSharingRatio,
    required this.openingCapital,
    required this.currentCapital,
    required this.totalDrawings,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get profitRatioFormatted => '${profitSharingRatio.toStringAsFixed(1)}%';

  factory ShopPartnerModel.fromJson(Map<String, dynamic> json) {
    return ShopPartnerModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String? ?? '',
      cnic: json['cnic'] as String?,
      phone: json['phone'] as String?,
      profitSharingRatio: (json['profit_sharing_ratio'] as num?)?.toDouble() ?? 0.0,
      openingCapital: (json['opening_capital'] as num?)?.toDouble() ?? 0.0,
      currentCapital: (json['current_capital'] as num?)?.toDouble() ?? 0.0,
      totalDrawings: (json['total_drawings'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'cnic': cnic,
      'phone': phone,
      'profit_sharing_ratio': profitSharingRatio,
      'opening_capital': openingCapital,
      'current_capital': currentCapital,
      'total_drawings': totalDrawings,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ShopPartnerModel copyWith({
    String? id,
    String? shopId,
    String? name,
    String? cnic,
    String? phone,
    double? profitSharingRatio,
    double? openingCapital,
    double? currentCapital,
    double? totalDrawings,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopPartnerModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      cnic: cnic ?? this.cnic,
      phone: phone ?? this.phone,
      profitSharingRatio: profitSharingRatio ?? this.profitSharingRatio,
      openingCapital: openingCapital ?? this.openingCapital,
      currentCapital: currentCapital ?? this.currentCapital,
      totalDrawings: totalDrawings ?? this.totalDrawings,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PartnerTransactionModel {
  final String id;
  final String shopId;
  final String partnerId;
  final String? partnerName;
  final PartnerTransactionType type;
  final double amount;
  final String paymentMethod; // cash, bank_transfer, cheque
  final String? reference;
  final String? description;
  final DateTime transactionDate;
  final DateTime createdAt;

  PartnerTransactionModel({
    required this.id,
    required this.shopId,
    required this.partnerId,
    this.partnerName,
    required this.type,
    required this.amount,
    this.paymentMethod = 'cash',
    this.reference,
    this.description,
    required this.transactionDate,
    required this.createdAt,
  });

  String get formattedDate =>
      DateFormat('dd-MMM-yyyy').format(transactionDate);

  factory PartnerTransactionModel.fromJson(Map<String, dynamic> json) {
    return PartnerTransactionModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      partnerId: json['partner_id'] as String,
      partnerName: json['partner_name'] as String?,
      type: PartnerTransactionType.fromString(json['type'] as String? ?? 'drawing'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      reference: json['reference'] as String?,
      description: json['description'] as String?,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'type': type.toDbString(),
      'amount': amount,
      'payment_method': paymentMethod,
      'reference': reference,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
