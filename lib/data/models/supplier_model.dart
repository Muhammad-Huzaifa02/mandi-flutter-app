/// A supplier belonging to exactly one shop.
class Supplier {
  final String id;
  final String shopId;
  final String? userId;
  final String name;
  final String phone;
  final String email;
  final String productsSupplied;
  final double openingBalance;
  final double runningBalance;
  final DateTime? createdAt;

  const Supplier({
    required this.id,
    required this.shopId,
    this.userId,
    required this.name,
    this.phone = '',
    this.email = '',
    this.productsSupplied = '',
    this.openingBalance = 0,
    this.runningBalance = 0,
    this.createdAt,
  });

  factory Supplier.fromMap(String id, Map<String, dynamic> d) => Supplier(
        id: id,
        shopId: d['shop_id'] as String? ?? '',
        userId: d['user_id'] as String?,
        name: d['name'] as String? ?? '',
        phone: d['phone'] as String? ?? '',
        email: d['email'] as String? ?? '',
        productsSupplied: d['products_supplied'] as String? ?? '',
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
        'products_supplied': productsSupplied,
        'opening_balance': openingBalance,
        'running_balance': runningBalance,
      };

  Supplier copyWith({
    String? name,
    String? phone,
    String? email,
    String? productsSupplied,
    double? openingBalance,
    double? runningBalance,
  }) =>
      Supplier(
        id: id,
        shopId: shopId,
        userId: userId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        productsSupplied: productsSupplied ?? this.productsSupplied,
        openingBalance: openingBalance ?? this.openingBalance,
        runningBalance: runningBalance ?? this.runningBalance,
        createdAt: createdAt,
      );
}
