/// One line item inside an invoice.
class InvoiceItem {
  final String? id;
  final String? invoiceId;
  final String? shopId;
  final String productId;
  final String productName;
  final double quantity; // number of bags / units
  final double weightKg; // total weight in KG
  final double unitPrice; // price per 40kg (Maund)
  final double lineTotal; // (weightKg / 40.0) * unitPrice

  const InvoiceItem({
    this.id,
    this.invoiceId,
    this.shopId,
    required this.productId,
    this.productName = '',
    this.quantity = 1,
    required this.weightKg,
    required this.unitPrice,
    double? lineTotal,
  }) : lineTotal = lineTotal ?? ((weightKg / 40.0) * unitPrice);

  factory InvoiceItem.fromMap(Map<String, dynamic> d) => InvoiceItem(
        id: d['id'] as String?,
        invoiceId: d['invoice_id'] as String?,
        shopId: d['shop_id'] as String?,
        productId: d['product_id'] as String? ?? '',
        productName: d['product_name'] as String? ?? '',
        quantity: (d['quantity'] as num?)?.toDouble() ?? 1,
        weightKg: (d['weight_kg'] as num?)?.toDouble() ?? 0,
        unitPrice: (d['unit_price'] as num?)?.toDouble() ?? 0,
        lineTotal: (d['line_total'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (invoiceId != null) 'invoice_id': invoiceId,
        if (shopId != null) 'shop_id': shopId,
        'productId': productId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'weight_kg': weightKg,
        'weightKg': weightKg,
        'unit_price': unitPrice,
        'unitPrice': unitPrice,
        'line_total': lineTotal,
        'lineTotal': lineTotal,
        'changeKg': -weightKg, // Negative for stock deduction
      };
}

enum PaymentMethod { cash, bankTransfer, jazzCash, easypaisa, other }

extension PaymentMethodX on PaymentMethod {
  static PaymentMethod fromString(String? s) {
    switch (s) {
      case 'bank':
      case 'bankTransfer':
        return PaymentMethod.bankTransfer;
      case 'jazzCash':
        return PaymentMethod.jazzCash;
      case 'easypaisa':
        return PaymentMethod.easypaisa;
      case 'other':
        return PaymentMethod.other;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }

  String toDbString() {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'bank';
      case PaymentMethod.jazzCash:
        return 'jazzCash';
      case PaymentMethod.easypaisa:
        return 'easypaisa';
      case PaymentMethod.other:
        return 'other';
      case PaymentMethod.cash:
        return 'cash';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.jazzCash:
        return 'JazzCash';
      case PaymentMethod.easypaisa:
        return 'Easypaisa';
      case PaymentMethod.other:
        return 'Other';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }
}

/// A sales invoice belonging to exactly one shop.
class Invoice {
  final String id;
  final String shopId;
  final String? customerId;
  final String customerName;
  final String? supplierId;
  final String supplierName;
  final String invoiceNumber;
  final List<InvoiceItem> items;

  final double subtotal;
  final double commission;
  final double expenses;
  final double discount;
  final double total;
  final double receivedAmount;
  final double pendingAmount;
  final PaymentMethod paymentMethod;
  final String status; // 'unpaid' | 'partial' | 'paid' | 'void'
  final String? createdBy;
  final DateTime? createdAt;

  const Invoice({
    required this.id,
    required this.shopId,
    this.customerId,
    this.customerName = '',
    this.supplierId,
    this.supplierName = '',
    required this.invoiceNumber,
    this.items = const [],
    this.subtotal = 0,
    this.commission = 0,
    this.expenses = 0,
    this.discount = 0,
    this.total = 0,
    this.receivedAmount = 0,
    this.pendingAmount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.status = 'unpaid',
    this.createdBy,
    this.createdAt,
  });

  factory Invoice.fromMap(String id, Map<String, dynamic> d) {
    final rec = (d['received_amount'] as num?)?.toDouble() ?? 0;
    final tot = (d['total'] as num?)?.toDouble() ?? 0;
    final pend = (d['pending_amount'] as num?)?.toDouble() ?? (tot - rec);

    return Invoice(
      id: id,
      shopId: d['shop_id'] as String? ?? '',
      customerId: d['customer_id'] as String?,
      customerName: d['customer_name'] as String? ?? '',
      supplierId: d['supplier_id'] as String?,
      supplierName: d['supplier_name'] as String? ?? '',
      invoiceNumber: d['invoice_number'] as String? ?? '',
      items: ((d['items'] as List?) ?? [])
          .map((e) => InvoiceItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0,
      commission: (d['commission'] as num?)?.toDouble() ?? 0,
      expenses: (d['expenses'] as num?)?.toDouble() ?? 0,
      discount: (d['discount'] as num?)?.toDouble() ?? 0,
      total: tot,
      receivedAmount: rec,
      pendingAmount: pend,
      paymentMethod: PaymentMethodX.fromString(d['payment_method'] as String?),
      status: d['status'] as String? ?? 'unpaid',
      createdBy: d['created_by'] as String?,
      createdAt: d['created_at'] != null
          ? DateTime.tryParse(d['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'shop_id': shopId,
        'customerId': customerId,
        'customer_id': customerId,
        'supplierId': supplierId,
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'invoiceNumber': invoiceNumber,
        'invoice_number': invoiceNumber,
        'subtotal': subtotal,
        'commission': commission,
        'expenses': expenses,
        'discount': discount,
        'total': total,
        'receivedAmount': receivedAmount,
        'received_amount': receivedAmount,
        'pendingAmount': pendingAmount,
        'pending_amount': pendingAmount,
        'paymentMethod': paymentMethod.toDbString(),
        'payment_method': paymentMethod.toDbString(),
        'status': status,
      };

  Invoice copyWith({
    List<InvoiceItem>? items,
    String? customerName,
    String? supplierName,
    String? status,
  }) =>
      Invoice(
        id: id,
        shopId: shopId,
        customerId: customerId,
        customerName: customerName ?? this.customerName,
        supplierId: supplierId,
        supplierName: supplierName ?? this.supplierName,
        invoiceNumber: invoiceNumber,
        items: items ?? this.items,
        subtotal: subtotal,
        commission: commission,
        expenses: expenses,
        discount: discount,
        total: total,
        receivedAmount: receivedAmount,
        pendingAmount: pendingAmount,
        paymentMethod: paymentMethod,
        status: status ?? this.status,
        createdBy: createdBy,
        createdAt: createdAt,
      );
}
