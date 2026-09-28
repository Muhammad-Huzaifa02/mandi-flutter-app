/// A customer belonging to exactly one shop.
class Customer {
  final String id;
  final String shopId;
  final String? userId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final double openingBalance;
  final double runningBalance;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    required this.shopId,
    this.userId,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.openingBalance = 0,
    this.runningBalance = 0,
    this.createdAt,
  });

  factory Customer.fromMap(String id, Map<String, dynamic> d) => Customer(
        id: id,
        shopId: d['shop_id'] as String? ?? '',
        userId: d['user_id'] as String?,
        name: d['name'] as String? ?? '',
        phone: d['phone'] as String? ?? '',
        email: d['email'] as String? ?? '',
        address: d['address'] as String? ?? '',
        city: d['city'] as String? ?? '',
        openingBalance: (d['opening_balance'] as num?)?.toDouble() ?? 0,
        runningBalance: (d['running_balance'] as num?)?.toDouble() ?? 0,
        createdAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toMap() => {
        'shop_id': shopId,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'opening_balance': openingBalance,
        'running_balance': runningBalance,
      };

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    double? openingBalance,
    double? runningBalance,
  }) =>
      Customer(
        id: id,
        shopId: shopId,
        userId: userId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        city: city ?? this.city,
        openingBalance: openingBalance ?? this.openingBalance,
        runningBalance: runningBalance ?? this.runningBalance,
        createdAt: createdAt,
      );
}
