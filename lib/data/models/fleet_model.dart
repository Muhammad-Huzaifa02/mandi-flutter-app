// Domain models for Fuel & Vehicle Fleet Logistics Ledger
// (*گاڑیوں کا ڈیزل، ٹرپ کرایہ اور ٹرانسپورٹ کھاتہ*).

import 'package:intl/intl.dart';

enum VehicleType {
  tractorTrolley,
  mazdaTruck,
  shehzore,
  pickupDala,
  rickshawLoader,
  trailer10Wheeler;

  String toDbString() {
    switch (this) {
      case VehicleType.tractorTrolley:
        return 'tractor_trolley';
      case VehicleType.mazdaTruck:
        return 'mazda_truck';
      case VehicleType.shehzore:
        return 'shehzore';
      case VehicleType.pickupDala:
        return 'pickup_dala';
      case VehicleType.rickshawLoader:
        return 'rickshaw_loader';
      case VehicleType.trailer10Wheeler:
        return '10_wheeler_trailer';
    }
  }

  String get labelUrdu {
    switch (this) {
      case VehicleType.tractorTrolley:
        return 'ٹریکٹر ٹرالی';
      case VehicleType.mazdaTruck:
        return 'مزدا 6 وہیلر';
      case VehicleType.shehzore:
        return 'شہزور ڈالہ';
      case VehicleType.pickupDala:
        return 'پک اپ ڈالہ';
      case VehicleType.rickshawLoader:
        return 'لوڈر رکشہ';
      case VehicleType.trailer10Wheeler:
        return 'ٹرالر 10 وہیلر';
    }
  }

  String get labelEnglish {
    switch (this) {
      case VehicleType.tractorTrolley:
        return 'Tractor Trolley';
      case VehicleType.mazdaTruck:
        return 'Mazda Truck (6-Wheeler)';
      case VehicleType.shehzore:
        return 'Shehzore Pickup';
      case VehicleType.pickupDala:
        return 'Pickup Dala';
      case VehicleType.rickshawLoader:
        return 'Rickshaw Loader';
      case VehicleType.trailer10Wheeler:
        return '10-Wheeler Trailer';
    }
  }

  static VehicleType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'mazda_truck':
      case 'mazda':
        return VehicleType.mazdaTruck;
      case 'shehzore':
        return VehicleType.shehzore;
      case 'pickup_dala':
      case 'pickup':
        return VehicleType.pickupDala;
      case 'rickshaw_loader':
      case 'rickshaw':
        return VehicleType.rickshawLoader;
      case '10_wheeler_trailer':
      case 'trailer':
        return VehicleType.trailer10Wheeler;
      case 'tractor_trolley':
      case 'tractor':
      default:
        return VehicleType.tractorTrolley;
    }
  }
}

enum OwnershipType {
  shopOwned,
  contractedCarrier,
  rental;

  String toDbString() {
    switch (this) {
      case OwnershipType.shopOwned:
        return 'shop_owned';
      case OwnershipType.contractedCarrier:
        return 'contracted_carrier';
      case OwnershipType.rental:
        return 'rental';
    }
  }

  String get labelUrdu {
    switch (this) {
      case OwnershipType.shopOwned:
        return 'ذاتی گاڑی';
      case OwnershipType.contractedCarrier:
        return 'کنٹریکٹ کیریئر';
      case OwnershipType.rental:
        return 'کرایہ کی گاڑی';
    }
  }

  String get labelEnglish {
    switch (this) {
      case OwnershipType.shopOwned:
        return 'Shop Owned';
      case OwnershipType.contractedCarrier:
        return 'Contracted Carrier';
      case OwnershipType.rental:
        return 'Rental Vehicle';
    }
  }

  static OwnershipType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'contracted_carrier':
      case 'contracted':
        return OwnershipType.contractedCarrier;
      case 'rental':
        return OwnershipType.rental;
      case 'shop_owned':
      default:
        return OwnershipType.shopOwned;
    }
  }
}

class FleetVehicle {
  final String id;
  final String shopId;
  final String registrationNumber;
  final VehicleType vehicleType;
  final OwnershipType ownershipType;
  final String driverName;
  final String driverPhone;
  final double capacityMaunds;
  final double odometerKm;
  final String status;
  final String notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FleetVehicle({
    this.id = '',
    required this.shopId,
    required this.registrationNumber,
    this.vehicleType = VehicleType.tractorTrolley,
    this.ownershipType = OwnershipType.shopOwned,
    this.driverName = '',
    this.driverPhone = '',
    this.capacityMaunds = 0.0,
    this.odometerKm = 0.0,
    this.status = 'active',
    this.notes = '',
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';

  String get displayName =>
      '$registrationNumber (${vehicleType.labelEnglish})';

  factory FleetVehicle.fromMap(String id, Map<String, dynamic> data) {
    return FleetVehicle(
      id: id,
      shopId: data['shop_id']?.toString() ?? '',
      registrationNumber: data['registration_number']?.toString() ?? '',
      vehicleType: VehicleType.fromString(data['vehicle_type']?.toString() ?? ''),
      ownershipType: OwnershipType.fromString(data['ownership_type']?.toString() ?? ''),
      driverName: data['driver_name']?.toString() ?? '',
      driverPhone: data['driver_phone']?.toString() ?? '',
      capacityMaunds: (data['capacity_maunds'] as num?)?.toDouble() ?? 0.0,
      odometerKm: (data['odometer_km'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'active',
      notes: data['notes']?.toString() ?? '',
      createdBy: data['created_by']?.toString(),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'registration_number': registrationNumber,
      'vehicle_type': vehicleType.toDbString(),
      'ownership_type': ownershipType.toDbString(),
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'capacity_maunds': capacityMaunds,
      'odometer_km': odometerKm,
      'status': status,
      'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}

enum TripStatus {
  inTransit,
  completed,
  cancelled;

  String toDbString() {
    switch (this) {
      case TripStatus.inTransit:
        return 'in_transit';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }

  String get labelUrdu {
    switch (this) {
      case TripStatus.inTransit:
        return 'راستے میں';
      case TripStatus.completed:
        return 'مکمل';
      case TripStatus.cancelled:
        return 'منسوخ';
    }
  }

  String get labelEnglish {
    switch (this) {
      case TripStatus.inTransit:
        return 'In Transit';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  static TripStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      case 'in_transit':
      default:
        return TripStatus.inTransit;
    }
  }
}

class FleetTrip {
  final String id;
  final String shopId;
  final String vehicleId;
  final String tripNumber;
  final DateTime tripDate;
  final String origin;
  final String destination;
  final String commodityName;
  final double loadedWeightKg;
  final double loadedWeightMaunds;
  final int bagCount;
  final String partyName;
  final double agreedFreightPkr;
  final double driverAdvancePkr;
  final double dieselExpensePkr;
  final double tollAndTaxPkr;
  final double otherExpensePkr;
  final double netTripProfitPkr;
  final double balanceFreightPayablePkr;
  final TripStatus status;
  final String notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FleetTrip({
    this.id = '',
    required this.shopId,
    required this.vehicleId,
    required this.tripNumber,
    required this.tripDate,
    required this.origin,
    required this.destination,
    this.commodityName = '',
    this.loadedWeightKg = 0.0,
    required this.loadedWeightMaunds,
    this.bagCount = 0,
    this.partyName = '',
    required this.agreedFreightPkr,
    this.driverAdvancePkr = 0.0,
    this.dieselExpensePkr = 0.0,
    this.tollAndTaxPkr = 0.0,
    this.otherExpensePkr = 0.0,
    required this.netTripProfitPkr,
    required this.balanceFreightPayablePkr,
    this.status = TripStatus.inTransit,
    this.notes = '',
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  /// Total operating expenses incurred on this trip (diesel + toll/tax + other).
  double get totalOperatingExpensePkr =>
      dieselExpensePkr + tollAndTaxPkr + otherExpensePkr;

  /// Mathematical calculation helper for fleet trip finances.
  /// Total operating expenses = diesel + tollAndTax + otherExpense.
  /// Net Trip Profit = agreedFreight - Total operating expenses.
  /// Balance Freight Payable to driver/transporter = agreedFreight - driverAdvance.
  static Map<String, double> computeTripFinances({
    required double agreedFreight,
    required double driverAdvance,
    double diesel = 0.0,
    double toll = 0.0,
    double other = 0.0,
  }) {
    final operatingExpenses = diesel + toll + other;
    final netProfit = agreedFreight - operatingExpenses;
    final balanceFreight = (agreedFreight - driverAdvance).clamp(0.0, double.infinity);

    return {
      'operatingExpenses': operatingExpenses,
      'totalExpenses': operatingExpenses,
      'netProfit': netProfit,
      'balanceFreight': balanceFreight,
    };
  }

  factory FleetTrip.fromMap(String id, Map<String, dynamic> data) {
    final kg = (data['loaded_weight_kg'] as num?)?.toDouble() ?? 0.0;
    final maunds = (data['loaded_weight_maunds'] as num?)?.toDouble() ??
        (kg > 0 ? (kg / 40.0) : 0.0);

    return FleetTrip(
      id: id,
      shopId: data['shop_id']?.toString() ?? '',
      vehicleId: data['vehicle_id']?.toString() ?? '',
      tripNumber: data['trip_number']?.toString() ?? '',
      tripDate: data['trip_date'] != null
          ? DateTime.tryParse(data['trip_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      origin: data['origin']?.toString() ?? '',
      destination: data['destination']?.toString() ?? '',
      commodityName: data['commodity_name']?.toString() ?? '',
      loadedWeightKg: kg,
      loadedWeightMaunds: maunds,
      bagCount: (data['bag_count'] as num?)?.toInt() ?? 0,
      partyName: data['party_name']?.toString() ?? '',
      agreedFreightPkr: (data['agreed_freight_pkr'] as num?)?.toDouble() ?? 0.0,
      driverAdvancePkr: (data['driver_advance_pkr'] as num?)?.toDouble() ?? 0.0,
      dieselExpensePkr: (data['diesel_expense_pkr'] as num?)?.toDouble() ?? 0.0,
      tollAndTaxPkr: (data['toll_and_tax_pkr'] as num?)?.toDouble() ?? 0.0,
      otherExpensePkr: (data['other_expense_pkr'] as num?)?.toDouble() ?? 0.0,
      netTripProfitPkr: (data['net_trip_profit_pkr'] as num?)?.toDouble() ?? 0.0,
      balanceFreightPayablePkr: (data['balance_freight_payable_pkr'] as num?)?.toDouble() ?? 0.0,
      status: TripStatus.fromString(data['status']?.toString() ?? 'in_transit'),
      notes: data['notes']?.toString() ?? '',
      createdBy: data['created_by']?.toString(),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'vehicle_id': vehicleId,
      'trip_number': tripNumber,
      'trip_date': DateFormat('yyyy-MM-dd').format(tripDate),
      'origin': origin,
      'destination': destination,
      'commodity_name': commodityName,
      'loaded_weight_kg': loadedWeightKg,
      'loaded_weight_maunds': loadedWeightMaunds,
      'bag_count': bagCount,
      'party_name': partyName,
      'agreed_freight_pkr': agreedFreightPkr,
      'driver_advance_pkr': driverAdvancePkr,
      'diesel_expense_pkr': dieselExpensePkr,
      'toll_and_tax_pkr': tollAndTaxPkr,
      'other_expense_pkr': otherExpensePkr,
      'net_trip_profit_pkr': netTripProfitPkr,
      'balance_freight_payable_pkr': balanceFreightPayablePkr,
      'status': status.toDbString(),
      'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}

class FleetFuelLog {
  final String id;
  final String shopId;
  final String vehicleId;
  final String? tripId;
  final DateTime logDate;
  final String fuelType;
  final String pumpOrVendorName;
  final double liters;
  final double ratePerLiter;
  final double totalCostPkr;
  final double odometerKm;
  final String receiptVoucherNumber;
  final String notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FleetFuelLog({
    this.id = '',
    required this.shopId,
    required this.vehicleId,
    this.tripId,
    required this.logDate,
    this.fuelType = 'diesel',
    required this.pumpOrVendorName,
    required this.liters,
    required this.ratePerLiter,
    required this.totalCostPkr,
    this.odometerKm = 0.0,
    this.receiptVoucherNumber = '',
    this.notes = '',
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory FleetFuelLog.fromMap(String id, Map<String, dynamic> data) {
    return FleetFuelLog(
      id: id,
      shopId: data['shop_id']?.toString() ?? '',
      vehicleId: data['vehicle_id']?.toString() ?? '',
      tripId: data['trip_id']?.toString(),
      logDate: data['log_date'] != null
          ? DateTime.tryParse(data['log_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      fuelType: data['fuel_type']?.toString() ?? 'diesel',
      pumpOrVendorName: data['pump_or_vendor_name']?.toString() ?? '',
      liters: (data['liters'] as num?)?.toDouble() ?? 0.0,
      ratePerLiter: (data['rate_per_liter'] as num?)?.toDouble() ?? 0.0,
      totalCostPkr: (data['total_cost_pkr'] as num?)?.toDouble() ?? 0.0,
      odometerKm: (data['odometer_km'] as num?)?.toDouble() ?? 0.0,
      receiptVoucherNumber: data['receipt_voucher_number']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
      createdBy: data['created_by']?.toString(),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'vehicle_id': vehicleId,
      if (tripId != null && tripId!.isNotEmpty) 'trip_id': tripId,
      'log_date': DateFormat('yyyy-MM-dd').format(logDate),
      'fuel_type': fuelType,
      'pump_or_vendor_name': pumpOrVendorName,
      'liters': liters,
      'rate_per_liter': ratePerLiter,
      'total_cost_pkr': totalCostPkr,
      'odometer_km': odometerKm,
      'receipt_voucher_number': receiptVoucherNumber,
      'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}
