/// A product belonging to exactly one shop.
class Product {
  final String id;
  final String shopId;
  final String? supplierId;
  final String supplierName;
  final String name;
  final String category;
  final String sku;
  final String description;
  final String unit;
  final double weightPerUnitKg;
  final double purchasePrice;
  final double sellingPrice; // Price per 40kg (Maund / Mann)
  final double minStockLevel;
  final double currentStock;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.shopId,
    this.supplierId,
    this.supplierName = '',
    required this.name,
    this.category = 'Grains',
    this.sku = '',
    this.description = '',
    this.unit = '40 KG (Maund)',
    this.weightPerUnitKg = 40,
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.minStockLevel = 0,
    this.currentStock = 0,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
  });

  bool get isLowStock => currentStock <= minStockLevel;

  factory Product.fromMap(String id, Map<String, dynamic> d) => Product(
        id: id,
        shopId: d['shop_id'] as String? ?? '',
        supplierId: d['supplier_id'] as String?,
        supplierName: d['supplier_name'] as String? ?? '',
        name: d['name'] as String? ?? '',
        category: d['category'] as String? ?? 'Grains',
        sku: d['sku'] as String? ?? '',
        description: d['description'] as String? ?? '',
        unit: d['unit'] as String? ?? '40 KG (Maund)',
        weightPerUnitKg: (d['weight_per_unit_kg'] as num?)?.toDouble() ?? 40,
        purchasePrice: (d['purchase_price'] as num?)?.toDouble() ?? 0,
        sellingPrice: (d['selling_price'] as num?)?.toDouble() ?? 0,
        minStockLevel: (d['min_stock_level'] as num?)?.toDouble() ?? 0,
        currentStock: (d['current_stock'] as num?)?.toDouble() ?? 0,
        imageUrl: d['image_url'] as String?,
        isActive: d['is_active'] as bool? ?? true,
        createdAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toMap() => {
        'shop_id': shopId,
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'name': name,
        'category': category,
        'sku': sku,
        'description': description,
        'unit': unit,
        'weight_per_unit_kg': weightPerUnitKg,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'min_stock_level': minStockLevel,
        'current_stock': currentStock,
        'image_url': imageUrl,
        'is_active': isActive,
      };

  Product copyWith({
    String? name,
    String? category,
    String? sku,
    String? description,
    String? unit,
    double? weightPerUnitKg,
    double? purchasePrice,
    double? sellingPrice,
    double? minStockLevel,
    double? currentStock,
    String? imageUrl,
    bool? isActive,
  }) =>
      Product(
        id: id,
        shopId: shopId,
        name: name ?? this.name,
        category: category ?? this.category,
        sku: sku ?? this.sku,
        description: description ?? this.description,
        unit: unit ?? this.unit,
        weightPerUnitKg: weightPerUnitKg ?? this.weightPerUnitKg,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        minStockLevel: minStockLevel ?? this.minStockLevel,
        currentStock: currentStock ?? this.currentStock,
        imageUrl: imageUrl ?? this.imageUrl,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  static const List<String> defaultSuggestions = [
    'Rice 1121 Kainat',
    'Super Basmati Rice',
    'IRRI-9 Rice',
    'Wheat (Gandum)',
    'Maize (Makai)',
    'Barley (Jau)',
    'Canola',
    'Mustard (Sarson)',
    'Cotton (Kapas)',
    'Other Grains',
  ];

  static const List<String> defaultUnits = [
    '40 KG (Maund)',
    '50 KG Bag',
    '100 KG Bag',
    'KG',
  ];
}
