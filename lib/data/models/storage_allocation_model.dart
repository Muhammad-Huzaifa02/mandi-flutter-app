/// Status of a crop stock allocation in Godown / Cold Store.
enum AllocationStatus {
  inStore, // Stored and currently accruing rent
  dispatched, // Dispatched out for sale/auction
  released, // Released back to farmer or customer
  partiallyDispatched, // Some bags dispatched, remainder in store
}

/// Model representing a batch of bags/crops allocated into a specific godown or cold store.
class StorageAllocation {
  final String id;
  final String shopId;
  final String storageLocationId;
  final String? storageLocationName;
  final String? productId;
  final String productName;
  final String lotNumber;
  final String partyName; // Farmer or Buyer name
  final int bagCount;
  final double weightKg;
  final DateTime inwardDate;
  final DateTime? outwardDate;
  final AllocationStatus status;
  final double rentRatePerBag;
  final double totalRentCharged;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StorageAllocation({
    required this.id,
    required this.shopId,
    required this.storageLocationId,
    this.storageLocationName,
    this.productId,
    this.productName = '',
    this.lotNumber = '',
    this.partyName = '',
    required this.bagCount,
    this.weightKg = 0.0,
    required this.inwardDate,
    this.outwardDate,
    this.status = AllocationStatus.inStore,
    this.rentRatePerBag = 0.0,
    this.totalRentCharged = 0.0,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Mandi weight in Maunds (من = 40 KG)
  double get maunds => weightKg > 0 ? weightKg / 40.0 : 0.0;

  /// Number of days this batch has been kept in storage
  int get daysInStorage {
    final end = outwardDate ?? DateTime.now();
    final diff = end.difference(inwardDate).inDays;
    return diff < 1 ? 1 : diff;
  }

  /// Estimated rent based on monthly rate prorated by 30 days
  double get estimatedAccruedRent {
    if (rentRatePerBag <= 0 || bagCount <= 0) return 0.0;
    final months = daysInStorage / 30.0;
    return bagCount * rentRatePerBag * months;
  }

  String get statusLabelUrdu {
    switch (status) {
      case AllocationStatus.inStore:
        return 'گودام میں موجود';
      case AllocationStatus.dispatched:
        return 'روانہ شدہ (فروخت)';
      case AllocationStatus.released:
        return 'واپس شدہ';
      case AllocationStatus.partiallyDispatched:
        return 'جزوی روانہ شدہ';
    }
  }

  String get statusLabelEnglish {
    switch (status) {
      case AllocationStatus.inStore:
        return 'In-Store';
      case AllocationStatus.dispatched:
        return 'Dispatched';
      case AllocationStatus.released:
        return 'Released';
      case AllocationStatus.partiallyDispatched:
        return 'Partial';
    }
  }

  factory StorageAllocation.fromMap(String id, Map<String, dynamic> map) {
    AllocationStatus parseStatus(String? val) {
      switch (val) {
        case 'dispatched':
          return AllocationStatus.dispatched;
        case 'released':
          return AllocationStatus.released;
        case 'partially_dispatched':
          return AllocationStatus.partiallyDispatched;
        case 'in_store':
        default:
          return AllocationStatus.inStore;
      }
    }

    return StorageAllocation(
      id: id,
      shopId: map['shop_id'] as String? ?? '',
      storageLocationId: map['storage_location_id'] as String? ?? '',
      storageLocationName: map['storage_location_name'] as String?,
      productId: map['product_id'] as String?,
      productName: map['product_name'] as String? ?? '',
      lotNumber: map['lot_number'] as String? ?? '',
      partyName: map['party_name'] as String? ?? '',
      bagCount: (map['bag_count'] as num?)?.toInt() ?? 0,
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0.0,
      inwardDate: map['inward_date'] != null
          ? DateTime.tryParse(map['inward_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      outwardDate: map['outward_date'] != null
          ? DateTime.tryParse(map['outward_date'].toString())
          : null,
      status: parseStatus(map['status'] as String?),
      rentRatePerBag: (map['rent_rate_per_bag'] as num?)?.toDouble() ?? 0.0,
      totalRentCharged: (map['total_rent_charged'] as num?)?.toDouble() ?? 0.0,
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
    String statusString(AllocationStatus s) {
      switch (s) {
        case AllocationStatus.inStore:
          return 'in_store';
        case AllocationStatus.dispatched:
          return 'dispatched';
        case AllocationStatus.released:
          return 'released';
        case AllocationStatus.partiallyDispatched:
          return 'partially_dispatched';
      }
    }

    return {
      'shop_id': shopId,
      'storage_location_id': storageLocationId,
      'product_id': productId,
      'product_name': productName,
      'lot_number': lotNumber,
      'party_name': partyName,
      'bag_count': bagCount,
      'weight_kg': weightKg,
      'inward_date': inwardDate.toIso8601String(),
      'outward_date': outwardDate?.toIso8601String(),
      'status': statusString(status),
      'rent_rate_per_bag': rentRatePerBag,
      'total_rent_charged': totalRentCharged,
      'notes': notes,
    };
  }

  StorageAllocation copyWith({
    String? id,
    String? shopId,
    String? storageLocationId,
    String? storageLocationName,
    String? productId,
    String? productName,
    String? lotNumber,
    String? partyName,
    int? bagCount,
    double? weightKg,
    DateTime? inwardDate,
    DateTime? outwardDate,
    AllocationStatus? status,
    double? rentRatePerBag,
    double? totalRentCharged,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StorageAllocation(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      storageLocationId: storageLocationId ?? this.storageLocationId,
      storageLocationName: storageLocationName ?? this.storageLocationName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      lotNumber: lotNumber ?? this.lotNumber,
      partyName: partyName ?? this.partyName,
      bagCount: bagCount ?? this.bagCount,
      weightKg: weightKg ?? this.weightKg,
      inwardDate: inwardDate ?? this.inwardDate,
      outwardDate: outwardDate ?? this.outwardDate,
      status: status ?? this.status,
      rentRatePerBag: rentRatePerBag ?? this.rentRatePerBag,
      totalRentCharged: totalRentCharged ?? this.totalRentCharged,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
