/// A supplier belonging to exactly one shop.
class Supplier {
  final String id;
  final String shopId;
  final String name;
  final String phone;
  final String whatsapp;
  final String address;
  final String city;
  final double openingBalance;
  final double totalPurchased;
  final double totalPaid;
  final double outstandingBalance;
  final DateTime? createdAt;

  const Supplier({
    required this.id,
    required this.shopId,
    required this.name,
    this.phone = '',
    this.whatsapp = '',
    this.address = '',
    this.city = '',
    this.openingBalance = 0,
    this.totalPurchased = 0,
    this.totalPaid = 0,
    this.outstandingBalance = 0,
    this.createdAt,
  });

  factory Supplier.fromMap(String id, Map<String, dynamic> d) => Supplier(
        id: id,
        shopId: d['shopId'] as String? ?? '',
        name: d['name'] as String? ?? '',
        phone: d['phone'] as String? ?? '',
        whatsapp: d['whatsapp'] as String? ?? '',
        address: d['address'] as String? ?? '',
        city: d['city'] as String? ?? '',
        openingBalance: (d['openingBalance'] as num?)?.toDouble() ?? 0,
        totalPurchased: (d['totalPurchased'] as num?)?.toDouble() ?? 0,
        totalPaid: (d['totalPaid'] as num?)?.toDouble() ?? 0,
        outstandingBalance:
            (d['outstandingBalance'] as num?)?.toDouble() ?? 0,
        createdAt: (d['createdAt'] as dynamic)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'name': name,
        'phone': phone,
        'whatsapp': whatsapp,
        'address': address,
        'city': city,
        'openingBalance': openingBalance,
        'totalPurchased': totalPurchased,
        'totalPaid': totalPaid,
        'outstandingBalance': outstandingBalance,
      };
}
