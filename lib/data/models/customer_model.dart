/// A customer belonging to exactly one shop.
class Customer {
  final String id;
  final String shopId;
  final String name;
  final String phone;
  final String whatsapp;
  final String address;
  final String city;
  final String? cnic;
  final String customerType; // e.g. "Retail", "Wholesale"
  final double openingBalance;
  final double totalPurchased;
  final double totalPaid;
  final double totalPending;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    required this.shopId,
    required this.name,
    this.phone = '',
    this.whatsapp = '',
    this.address = '',
    this.city = '',
    this.cnic,
    this.customerType = 'Retail',
    this.openingBalance = 0,
    this.totalPurchased = 0,
    this.totalPaid = 0,
    this.totalPending = 0,
    this.createdAt,
  });

  factory Customer.fromMap(String id, Map<String, dynamic> d) => Customer(
        id: id,
        shopId: d['shopId'] as String? ?? '',
        name: d['name'] as String? ?? '',
        phone: d['phone'] as String? ?? '',
        whatsapp: d['whatsapp'] as String? ?? '',
        address: d['address'] as String? ?? '',
        city: d['city'] as String? ?? '',
        cnic: d['cnic'] as String?,
        customerType: d['customerType'] as String? ?? 'Retail',
        openingBalance: (d['openingBalance'] as num?)?.toDouble() ?? 0,
        totalPurchased: (d['totalPurchased'] as num?)?.toDouble() ?? 0,
        totalPaid: (d['totalPaid'] as num?)?.toDouble() ?? 0,
        totalPending: (d['totalPending'] as num?)?.toDouble() ?? 0,
        createdAt: (d['createdAt'] as dynamic)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'name': name,
        'phone': phone,
        'whatsapp': whatsapp,
        'address': address,
        'city': city,
        'cnic': cnic,
        'customerType': customerType,
        'openingBalance': openingBalance,
        'totalPurchased': totalPurchased,
        'totalPaid': totalPaid,
        'totalPending': totalPending,
      };

  Customer copyWith({
    String? name,
    String? phone,
    String? whatsapp,
    String? address,
    String? city,
    String? cnic,
    String? customerType,
    double? openingBalance,
    double? totalPurchased,
    double? totalPaid,
    double? totalPending,
  }) =>
      Customer(
        id: id,
        shopId: shopId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        address: address ?? this.address,
        city: city ?? this.city,
        cnic: cnic ?? this.cnic,
        customerType: customerType ?? this.customerType,
        openingBalance: openingBalance ?? this.openingBalance,
        totalPurchased: totalPurchased ?? this.totalPurchased,
        totalPaid: totalPaid ?? this.totalPaid,
        totalPending: totalPending ?? this.totalPending,
        createdAt: createdAt,
      );
}
