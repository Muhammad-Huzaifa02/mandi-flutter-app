/// A procurement purchase order for grain/produce received from a supplier.
class PurchaseOrder {
  final String id;
  final String shopId;
  final String? supplierId;
  final String supplierName;
  final String status; // 'pending' | 'received' | 'cancelled'
  final double total;
  final double paidAmount;
  final double pendingAmount;
  final String? createdBy;
  final DateTime? createdAt;

  const PurchaseOrder({
    required this.id,
    required this.shopId,
    this.supplierId,
    this.supplierName = '',
    this.status = 'pending',
    required this.total,
    this.paidAmount = 0,
    double? pendingAmount,
    this.createdBy,
    this.createdAt,
  }) : pendingAmount = pendingAmount ?? (total - paidAmount);

  factory PurchaseOrder.fromMap(String id, Map<String, dynamic> d) {
    final tot = (d['total'] as num?)?.toDouble() ?? 0;
    final paid = (d['paid_amount'] as num?)?.toDouble() ?? 0;
    final pend = (d['pending_amount'] as num?)?.toDouble() ?? (tot - paid);

    return PurchaseOrder(
      id: id,
      shopId: d['shop_id'] as String? ?? '',
      supplierId: d['supplier_id'] as String?,
      supplierName: d['supplier_name'] as String? ?? 'Direct Supplier',
      status: d['status'] as String? ?? 'pending',
      total: tot,
      paidAmount: paid,
      pendingAmount: pend,
      createdBy: d['created_by'] as String?,
      createdAt: d['created_at'] != null
          ? DateTime.tryParse(d['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'shop_id': shopId,
        'supplier_id': supplierId,
        'status': status,
        'total': total,
        'paid_amount': paidAmount,
        'pending_amount': pendingAmount,
      };
}
