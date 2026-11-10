/// Type of Mandi storage facility.
enum StorageLocationType {
  godown, // Local warehouse / Mandi Godown (شاپ گودام)
  coldStorage, // External commercial cold store (کولڈ سٹوریج)
  shopPharr, // Mandi shop front auction platform (دکان / پھڑ)
}

/// Model representing a storage warehouse, godown, or cold store.
class StorageLocation {
  final String id;
  final String shopId;
  final String name;
  final StorageLocationType type;
  final String address;
  final String contactPerson;
  final String phone;
  final int capacityBags;
  final int currentBags;
  final double monthlyRentPerBag;
  final bool isActive;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StorageLocation({
    required this.id,
    required this.shopId,
    required this.name,
    this.type = StorageLocationType.godown,
    this.address = '',
    this.contactPerson = '',
    this.phone = '',
    this.capacityBags = 0,
    this.currentBags = 0,
    this.monthlyRentPerBag = 0.0,
    this.isActive = true,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Remaining capacity in bags
  int get availableCapacityBags {
    final rem = capacityBags - currentBags;
    return rem < 0 ? 0 : rem;
  }

  /// Utilization ratio (0.0 to 1.0)
  double get utilizationRatio {
    if (capacityBags <= 0) return 0.0;
    final r = currentBags / capacityBags;
    return r > 1.0 ? 1.0 : r;
  }

  String get typeLabelUrdu {
    switch (type) {
      case StorageLocationType.coldStorage:
        return 'کولڈ سٹوریج';
      case StorageLocationType.godown:
        return 'منڈی گودام';
      case StorageLocationType.shopPharr:
        return 'دکان / پھڑ';
    }
  }

  String get typeLabelEnglish {
    switch (type) {
      case StorageLocationType.coldStorage:
        return 'Cold Storage';
      case StorageLocationType.godown:
        return 'Godown / Warehouse';
      case StorageLocationType.shopPharr:
        return 'Shop Front / Pharr';
    }
  }

  factory StorageLocation.fromMap(String id, Map<String, dynamic> map) {
    StorageLocationType parseType(String? val) {
      switch (val) {
        case 'cold_storage':
          return StorageLocationType.coldStorage;
        case 'shop_pharr':
          return StorageLocationType.shopPharr;
        case 'godown':
        default:
          return StorageLocationType.godown;
      }
    }

    return StorageLocation(
      id: id,
      shopId: map['shop_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: parseType(map['location_type'] as String?),
      address: map['address'] as String? ?? '',
      contactPerson: map['contact_person'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      capacityBags: (map['capacity_bags'] as num?)?.toInt() ?? 0,
      currentBags: (map['current_bags'] as num?)?.toInt() ?? 0,
      monthlyRentPerBag:
          (map['monthly_rent_per_bag'] as num?)?.toDouble() ?? 0.0,
      isActive: map['is_active'] as bool? ?? true,
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    String typeString(StorageLocationType t) {
      switch (t) {
        case StorageLocationType.coldStorage:
          return 'cold_storage';
        case StorageLocationType.shopPharr:
          return 'shop_pharr';
        case StorageLocationType.godown:
          return 'godown';
      }
    }

    return {
      'shop_id': shopId,
      'name': name,
      'location_type': typeString(type),
      'address': address,
      'contact_person': contactPerson,
      'phone': phone,
      'capacity_bags': capacityBags,
      'current_bags': currentBags,
      'monthly_rent_per_bag': monthlyRentPerBag,
      'is_active': isActive,
      'notes': notes,
    };
  }

  StorageLocation copyWith({
    String? id,
    String? shopId,
    String? name,
    StorageLocationType? type,
    String? address,
    String? contactPerson,
    String? phone,
    int? capacityBags,
    int? currentBags,
    double? monthlyRentPerBag,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StorageLocation(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      capacityBags: capacityBags ?? this.capacityBags,
      currentBags: currentBags ?? this.currentBags,
      monthlyRentPerBag: monthlyRentPerBag ?? this.monthlyRentPerBag,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
