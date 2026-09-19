/// A product belonging to exactly one shop.
///
/// `shopId` is set once at creation and never changes. Every query for
/// products MUST filter by shopId — see SupabaseService.productsStream.
class Product {
  final String id;
  final String shopId;
  final String name;
  final String category;
  final String? imageUrl;
  final String sku;
  final String description;

  /// The pricing/weight unit this product is bought and sold in,
  /// e.g. "40kg", "50kg", "kg", "mann", "bag". Free text so shops can
  /// define their own custom units (spec section 4/10).
  final String unit;
  final double weightPerUnitKg;

  final double purchasePrice;
  final double sellingPrice;
  final double minStockLevel;
  final double currentStock;

  final String? supplierId;
  final bool isActive;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    this.category = 'Other Grains',
    this.imageUrl,
    this.sku = '',
    this.description = '',
    this.unit = '40kg',
    this.weightPerUnitKg = 40,
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.minStockLevel = 0,
    this.currentStock = 0,
    this.supplierId,
    this.isActive = true,
    this.createdAt,
  });

  bool get isLowStock => currentStock <= minStockLevel;

  factory Product.fromMap(String id, Map<String, dynamic> d) => Product(
        id: id,
        shopId: d['shopId'] as String? ?? '',
        name: d['name'] as String? ?? '',
        category: d['category'] as String? ?? 'Other Grains',
        imageUrl: d['imageUrl'] as String?,
        sku: d['sku'] as String? ?? '',
        description: d['description'] as String? ?? '',
        unit: d['unit'] as String? ?? '40kg',
        weightPerUnitKg: (d['weightPerUnitKg'] as num?)?.toDouble() ?? 40,
        purchasePrice: (d['purchasePrice'] as num?)?.toDouble() ?? 0,
        sellingPrice: (d['sellingPrice'] as num?)?.toDouble() ?? 0,
        minStockLevel: (d['minStockLevel'] as num?)?.toDouble() ?? 0,
        currentStock: (d['currentStock'] as num?)?.toDouble() ?? 0,
        supplierId: d['supplierId'] as String?,
        isActive: d['isActive'] as bool? ?? true,
        createdAt: (d['createdAt'] as dynamic)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'name': name,
        'category': category,
        'imageUrl': imageUrl,
        'sku': sku,
        'description': description,
        'unit': unit,
        'weightPerUnitKg': weightPerUnitKg,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'minStockLevel': minStockLevel,
        'currentStock': currentStock,
        'supplierId': supplierId,
        'isActive': isActive,
      };

  Product copyWith({
    String? name,
    String? category,
    String? imageUrl,
    String? sku,
    String? description,
    String? unit,
    double? weightPerUnitKg,
    double? purchasePrice,
    double? sellingPrice,
    double? minStockLevel,
    double? currentStock,
    String? supplierId,
    bool? isActive,
  }) =>
      Product(
        id: id,
        shopId: shopId,
        name: name ?? this.name,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        sku: sku ?? this.sku,
        description: description ?? this.description,
        unit: unit ?? this.unit,
        weightPerUnitKg: weightPerUnitKg ?? this.weightPerUnitKg,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        minStockLevel: minStockLevel ?? this.minStockLevel,
        currentStock: currentStock ?? this.currentStock,
        supplierId: supplierId ?? this.supplierId,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  /// Common Pakistani mandi products offered as *default suggestions* only
  /// — shops can add any custom product on top of these (spec section 8).
  static const List<String> defaultSuggestions = [
    'Rice 1121',
    'Super Basmati Rice',
    'IRRI-9 Rice',
    'Wheat',
    'Barseem',
    'Monji',
    'Jui',
    'Corn',
    'Maize',
    'Other Grains',
  ];

  /// Common weight/quantity units offered as defaults — shops can add a
  /// custom unit too (spec section 4).
  static const List<String> defaultUnits = [
    'KG', '40 KG', '50 KG', '60 KG', '100 KG', 'Bag', 'Mann', 'Ton',
  ];
}
