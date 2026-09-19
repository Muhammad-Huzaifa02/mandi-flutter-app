/// One line item inside an invoice.
class InvoiceItem {
  final String productId;
  final String productName;
  final double quantity; // number of units (e.g. bags)
  final double weightPerUnitKg; // kg per unit
  final double pricePerBaseUnit; // price per the product's base pricing unit
  final double baseUnitKg; // e.g. 40 for "per 40kg" pricing

  const InvoiceItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.weightPerUnitKg,
    required this.pricePerBaseUnit,
    this.baseUnitKg = 40,
  });

  /// Product Total = Price per base unit × Quantity × (Weight per unit ÷ base unit)
  /// (spec section 10 — agricultural weight & pricing logic)
  double get total =>
      pricePerBaseUnit * quantity * (weightPerUnitKg / baseUnitKg);

  factory InvoiceItem.fromMap(Map<String, dynamic> d) => InvoiceItem(
        productId: d['productId'] as String? ?? '',
        productName: d['productName'] as String? ?? '',
        quantity: (d['quantity'] as num?)?.toDouble() ?? 0,
        weightPerUnitKg: (d['weightPerUnitKg'] as num?)?.toDouble() ?? 0,
        pricePerBaseUnit: (d['pricePerBaseUnit'] as num?)?.toDouble() ?? 0,
        baseUnitKg: (d['baseUnitKg'] as num?)?.toDouble() ?? 40,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'weightPerUnitKg': weightPerUnitKg,
        'pricePerBaseUnit': pricePerBaseUnit,
        'baseUnitKg': baseUnitKg,
        'total': total,
      };
}

enum PaymentMethod { cash, bankTransfer, jazzCash, easypaisa, other }

extension PaymentMethodX on PaymentMethod {
  static PaymentMethod fromString(String? s) => PaymentMethod.values
      .firstWhere((e) => e.name == s, orElse: () => PaymentMethod.cash);
}

/// A sales invoice belonging to exactly one shop. Holds the full
/// commission-shop calculation breakdown from spec section 11.
class Invoice {
  final String id;
  final String shopId;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final List<InvoiceItem> items;

  final double commissionPercent;
  final double fixedCommission;
  final double laborCharges;
  final double packingCharges;
  final double transportCharges;
  final double otherExpenses;

  final double discountPercent;
  final double discountFlat;
  final double gstPercent;

  final double receivedAmount;
  final PaymentMethod paymentMethod;
  final bool isVoided;
  final DateTime? createdAt;
  final String createdByUid;
  final String createdByName;

  const Invoice({
    required this.id,
    required this.shopId,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    this.items = const [],
    this.commissionPercent = 0,
    this.fixedCommission = 0,
    this.laborCharges = 0,
    this.packingCharges = 0,
    this.transportCharges = 0,
    this.otherExpenses = 0,
    this.discountPercent = 0,
    this.discountFlat = 0,
    this.gstPercent = 0,
    this.receivedAmount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.isVoided = false,
    this.createdAt,
    this.createdByUid = '',
    this.createdByName = '',
  });

  /// Products Total = sum of every line item's total.
  double get productsTotal => items.fold(0, (sum, i) => sum + i.total);

  /// Commission = (Products Total × Commission %) ÷ 100 + Fixed Commission
  double get commission =>
      (productsTotal * commissionPercent / 100) + fixedCommission;

  double get totalExpenses =>
      laborCharges + packingCharges + transportCharges + otherExpenses;

  /// Subtotal = Products Total + Commission + Total Expenses
  double get subtotal => productsTotal + commission + totalExpenses;

  double get discount => discountFlat + (subtotal * discountPercent / 100);

  double get gstAmount => (subtotal - discount) * gstPercent / 100;

  /// Final Amount = Subtotal - Discount + GST
  double get finalAmount => subtotal - discount + gstAmount;

  /// Pending Amount = Final Amount - Received Amount
  double get pendingAmount => finalAmount - receivedAmount;

  factory Invoice.fromMap(String id, Map<String, dynamic> d) => Invoice(
        id: id,
        shopId: d['shopId'] as String? ?? '',
        invoiceNumber: d['invoiceNumber'] as String? ?? '',
        customerId: d['customerId'] as String? ?? '',
        customerName: d['customerName'] as String? ?? '',
        items: ((d['items'] as List?) ?? [])
            .map((e) => InvoiceItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        commissionPercent: (d['commissionPercent'] as num?)?.toDouble() ?? 0,
        fixedCommission: (d['fixedCommission'] as num?)?.toDouble() ?? 0,
        laborCharges: (d['laborCharges'] as num?)?.toDouble() ?? 0,
        packingCharges: (d['packingCharges'] as num?)?.toDouble() ?? 0,
        transportCharges: (d['transportCharges'] as num?)?.toDouble() ?? 0,
        otherExpenses: (d['otherExpenses'] as num?)?.toDouble() ?? 0,
        discountPercent: (d['discountPercent'] as num?)?.toDouble() ?? 0,
        discountFlat: (d['discountFlat'] as num?)?.toDouble() ?? 0,
        gstPercent: (d['gstPercent'] as num?)?.toDouble() ?? 0,
        receivedAmount: (d['receivedAmount'] as num?)?.toDouble() ?? 0,
        paymentMethod:
            PaymentMethodX.fromString(d['paymentMethod'] as String?),
        isVoided: d['isVoided'] as bool? ?? false,
        createdAt: (d['createdAt'] as dynamic)?.toDate(),
        createdByUid: d['createdByUid'] as String? ?? '',
        createdByName: d['createdByName'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'invoiceNumber': invoiceNumber,
        'customerId': customerId,
        'customerName': customerName,
        'items': items.map((i) => i.toMap()).toList(),
        'commissionPercent': commissionPercent,
        'fixedCommission': fixedCommission,
        'laborCharges': laborCharges,
        'packingCharges': packingCharges,
        'transportCharges': transportCharges,
        'otherExpenses': otherExpenses,
        'discountPercent': discountPercent,
        'discountFlat': discountFlat,
        'gstPercent': gstPercent,
        'receivedAmount': receivedAmount,
        'paymentMethod': paymentMethod.name,
        'isVoided': isVoided,
        'createdByUid': createdByUid,
        'createdByName': createdByName,
        // Denormalized so reports/lists don't need to recompute:
        'productsTotal': productsTotal,
        'commission': commission,
        'finalAmount': finalAmount,
        'pendingAmount': pendingAmount,
      };
}
