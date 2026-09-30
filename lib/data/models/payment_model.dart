/// A cash/bank payment voucher received from a customer or paid to a supplier.
class Payment {
  final String id;
  final String shopId;
  final String partyType; // 'customer' or 'supplier'
  final String partyId;
  final String partyName;
  final double amount;
  final String method; // 'cash', 'bank', 'jazzCash', 'easypaisa'
  final String reference;
  final String? createdBy;
  final DateTime? createdAt;

  const Payment({
    required this.id,
    required this.shopId,
    required this.partyType,
    required this.partyId,
    this.partyName = '',
    required this.amount,
    this.method = 'cash',
    this.reference = '',
    this.createdBy,
    this.createdAt,
  });

  factory Payment.fromMap(String id, Map<String, dynamic> d) => Payment(
        id: id,
        shopId: d['shop_id'] as String? ?? '',
        partyType: d['party_type'] as String? ?? 'customer',
        partyId: d['party_id'] as String? ?? '',
        partyName: d['party_name'] as String? ?? '',
        amount: (d['amount'] as num?)?.toDouble() ?? 0,
        method: d['method'] as String? ?? 'cash',
        reference: d['reference'] as String? ?? '',
        createdBy: d['created_by'] as String?,
        createdAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toMap() => {
        'shop_id': shopId,
        'party_type': partyType,
        'party_id': partyId,
        'amount': amount,
        'method': method,
        'reference': reference,
      };
}
