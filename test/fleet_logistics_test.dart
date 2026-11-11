import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/fleet_logistics_pdf_generator.dart';
import 'package:mandi/data/models/fleet_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fleet Logistics Domain & Financial Math Tests', () {
    test('FleetVehicle serialization and type conversions', () {
      final vehicle = FleetVehicle(
        id: 'veh-101',
        shopId: 'shop-01',
        registrationNumber: 'FD-8921',
        vehicleType: VehicleType.mazdaTruck,
        ownershipType: OwnershipType.shopOwned,
        driverName: 'Muhammad Aslam',
        driverPhone: '0300-1234567',
        capacityMaunds: 450.0,
        odometerKm: 65400.0,
        status: 'active',
        notes: 'Grain hauler for Punjab sector',
        createdAt: DateTime(2026, 11, 10, 8, 30),
        updatedAt: DateTime(2026, 11, 10, 8, 30),
      );

      expect(vehicle.isActive, isTrue);
      expect(vehicle.displayName, contains('FD-8921'));
      expect(vehicle.displayName, contains('Mazda'));

      final map = vehicle.toMap();
      expect(map['registration_number'], equals('FD-8921'));
      expect(map['vehicle_type'], equals('mazda_truck'));
      expect(map['ownership_type'], equals('shop_owned'));
      expect(map['capacity_maunds'], equals(450.0));

      final restored = FleetVehicle.fromMap('veh-101', map);
      expect(restored.registrationNumber, equals('FD-8921'));
      expect(restored.vehicleType, equals(VehicleType.mazdaTruck));
      expect(restored.ownershipType, equals(OwnershipType.shopOwned));
      expect(restored.driverName, equals('Muhammad Aslam'));
    });

    test('VehicleType and OwnershipType enum roundtrips and localized labels', () {
      for (final type in VehicleType.values) {
        final dbStr = type.toDbString();
        final parsed = VehicleType.fromString(dbStr);
        expect(parsed, equals(type));
        expect(type.labelEnglish.isNotEmpty, isTrue);
        expect(type.labelUrdu.isNotEmpty, isTrue);
      }

      for (final own in OwnershipType.values) {
        final dbStr = own.toDbString();
        final parsed = OwnershipType.fromString(dbStr);
        expect(parsed, equals(own));
        expect(own.labelEnglish.isNotEmpty, isTrue);
        expect(own.labelUrdu.isNotEmpty, isTrue);
      }
    });

    test('FleetTrip.computeTripFinances accurately calculates profit and balances', () {
      // Scenario 1: Profitable trip
      // Agreed Freight: 85,000 PKR
      // Driver Advance: 25,000 PKR
      // Diesel: 32,000 PKR, Toll: 3,500 PKR, Other: 1,500 PKR
      // Total operating expenses = 32,000 + 3,500 + 1,500 = 37,000 PKR
      // Net Profit = 85,000 - 37,000 = 48,000 PKR
      // Balance Payable = 85,000 - 25,000 = 60,000 PKR
      final fin1 = FleetTrip.computeTripFinances(
        agreedFreight: 85000,
        driverAdvance: 25000,
        diesel: 32000,
        toll: 3500,
        other: 1500,
      );

      expect(fin1['totalExpenses'], equals(37000.0));
      expect(fin1['netProfit'], equals(48000.0));
      expect(fin1['balanceFreight'], equals(60000.0));

      // Scenario 2: Loss making trip (High fuel & low freight)
      // Agreed: 20,000, Diesel: 22,000, Toll: 2,000 -> Expenses: 24,000 -> Net Profit: -4,000
      final fin2 = FleetTrip.computeTripFinances(
        agreedFreight: 20000,
        driverAdvance: 10000,
        diesel: 22000,
        toll: 2000,
      );
      expect(fin2['totalExpenses'], equals(24000.0));
      expect(fin2['netProfit'], equals(-4000.0));
      expect(fin2['balanceFreight'], equals(10000.0));
    });

    test('FleetTrip serialization and Maund conversion', () {
      // 16,000 KG / 40.0 = 400 Maunds
      const kg = 16000.0;
      const calculatedMaunds = kg / 40.0;
      expect(calculatedMaunds, equals(400.0));

      final trip = FleetTrip(
        id: 'trip-901',
        shopId: 'shop-01',
        vehicleId: 'veh-101',
        tripNumber: 'TRIP-2611-901',
        tripDate: DateTime(2026, 11, 10),
        origin: 'Arifwala Grain Mandi',
        destination: 'Karachi Port Terminal 2',
        commodityName: 'Super Basmati Rice',
        loadedWeightKg: kg,
        loadedWeightMaunds: calculatedMaunds,
        bagCount: 320,
        partyName: 'Al-Madina Rice Traders',
        agreedFreightPkr: 145000.0,
        driverAdvancePkr: 50000.0,
        dieselExpensePkr: 48000.0,
        tollAndTaxPkr: 7500.0,
        otherExpensePkr: 2500.0,
        netTripProfitPkr: 87000.0,
        balanceFreightPayablePkr: 95000.0,
        status: TripStatus.inTransit,
        notes: 'Handle with care; export consignment',
        createdAt: DateTime(2026, 11, 10, 10, 0),
        updatedAt: DateTime(2026, 11, 10, 10, 0),
      );

      expect(trip.totalOperatingExpensePkr, equals(48000.0 + 7500.0 + 2500.0));
      expect(trip.totalOperatingExpensePkr, equals(58000.0));
      expect(trip.agreedFreightPkr - trip.totalOperatingExpensePkr,
          equals(trip.netTripProfitPkr));

      final map = trip.toMap();
      expect(map['trip_number'], equals('TRIP-2611-901'));
      expect(map['status'], equals('in_transit'));
      expect(map['loaded_weight_maunds'], equals(400.0));

      final restored = FleetTrip.fromMap('trip-901', map);
      expect(restored.tripNumber, equals(trip.tripNumber));
      expect(restored.status, equals(TripStatus.inTransit));
      expect(restored.agreedFreightPkr, equals(145000.0));
      expect(restored.balanceFreightPayablePkr, equals(95000.0));
    });

    test('FleetFuelLog serialization and expense calculation', () {
      final log = FleetFuelLog(
        id: 'fuel-501',
        shopId: 'shop-01',
        vehicleId: 'veh-101',
        tripId: 'trip-901',
        logDate: DateTime(2026, 11, 10),
        fuelType: 'diesel',
        pumpOrVendorName: 'PSO National Highway Station',
        liters: 120.0,
        ratePerLiter: 285.0,
        totalCostPkr: 120.0 * 285.0, // 34,200 PKR
        odometerKm: 65800.0,
        receiptVoucherNumber: 'PSO-9921',
        notes: 'Full tank refuel before highway transit',
        createdAt: DateTime(2026, 11, 10, 14, 0),
      );

      expect(log.totalCostPkr, equals(34200.0));

      final map = log.toMap();
      expect(map['fuel_type'], equals('diesel'));
      expect(map['liters'], equals(120.0));
      expect(map['total_cost_pkr'], equals(34200.0));
      expect(map['receipt_voucher_number'], equals('PSO-9921'));

      final restored = FleetFuelLog.fromMap('fuel-501', map);
      expect(restored.id, equals('fuel-501'));
      expect(restored.pumpOrVendorName,
          equals('PSO National Highway Station'));
      expect(restored.totalCostPkr, equals(34200.0));
    });
  });

  group('FleetLogisticsPdfGenerator Tests', () {
    test('generateTripChallanPdf builds valid non-empty A4 Bilty bytes', () async {
      final vehicle = FleetVehicle(
        id: 'v-1',
        shopId: 's-1',
        registrationNumber: 'FD-8921',
        vehicleType: VehicleType.shehzore,
        ownershipType: OwnershipType.shopOwned,
        driverName: 'Muhammad Aslam',
        driverPhone: '0300-1234567',
        capacityMaunds: 180.0,
        odometerKm: 42000.0,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final trip = FleetTrip(
        id: 't-1',
        shopId: 's-1',
        vehicleId: 'v-1',
        tripNumber: 'TRIP-2611-1001',
        tripDate: DateTime(2026, 11, 10),
        origin: 'Arifwala Mandi',
        destination: 'Faisalabad Flour Mills',
        commodityName: 'Wheat (گندم)',
        loadedWeightKg: 8000.0,
        loadedWeightMaunds: 200.0,
        bagCount: 160,
        partyName: 'Al-Hafiz Flour Mills',
        agreedFreightPkr: 45000.0,
        driverAdvancePkr: 15000.0,
        dieselExpensePkr: 14000.0,
        tollAndTaxPkr: 2000.0,
        otherExpensePkr: 1000.0,
        netTripProfitPkr: 28000.0,
        balanceFreightPayablePkr: 30000.0,
        status: TripStatus.inTransit,
        notes: 'Urgent morning delivery',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final pdfBytes = await FleetLogisticsPdfGenerator.generateTripChallanPdf(
        trip: trip,
        vehicle: vehicle,
        shopName: 'Chaudhry & Sons Grain Commission',
        shopAddress: 'Shop # 45, Grain Market Arifwala',
        shopPhone: '0300-7654321',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('generateVehicleLedgerPdf builds valid non-empty A4 Landscape Ledger bytes', () async {
      final vehicle = FleetVehicle(
        id: 'v-1',
        shopId: 's-1',
        registrationNumber: 'FD-8921',
        vehicleType: VehicleType.mazdaTruck,
        ownershipType: OwnershipType.shopOwned,
        driverName: 'Muhammad Aslam',
        driverPhone: '0300-1234567',
        capacityMaunds: 450.0,
        odometerKm: 68000.0,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final trips = [
        FleetTrip(
          id: 't-1',
          shopId: 's-1',
          vehicleId: 'v-1',
          tripNumber: 'TRIP-2611-1001',
          tripDate: DateTime(2026, 11, 8),
          origin: 'Arifwala Mandi',
          destination: 'Lahore Badami Bagh',
          commodityName: 'Corn (مکئی)',
          loadedWeightKg: 14000.0,
          loadedWeightMaunds: 350.0,
          bagCount: 280,
          partyName: 'Lahore Feed Industries',
          agreedFreightPkr: 65000.0,
          driverAdvancePkr: 20000.0,
          dieselExpensePkr: 22000.0,
          tollAndTaxPkr: 3000.0,
          otherExpensePkr: 1000.0,
          netTripProfitPkr: 39000.0,
          balanceFreightPayablePkr: 45000.0,
          status: TripStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final fuelLogs = [
        FleetFuelLog(
          id: 'f-1',
          shopId: 's-1',
          vehicleId: 'v-1',
          tripId: 't-1',
          logDate: DateTime(2026, 11, 8),
          fuelType: 'diesel',
          pumpOrVendorName: 'PSO Highway Filling Station',
          liters: 80.0,
          ratePerLiter: 280.0,
          totalCostPkr: 22400.0,
          odometerKm: 68150.0,
          receiptVoucherNumber: 'V-1102',
          createdAt: DateTime.now(),
        ),
      ];

      final pdfBytes = await FleetLogisticsPdfGenerator.generateVehicleLedgerPdf(
        vehicle: vehicle,
        trips: trips,
        fuelLogs: fuelLogs,
        shopName: 'Chaudhry & Sons Grain Commission',
        shopAddress: 'Shop # 45, Grain Market Arifwala',
        shopPhone: '0300-7654321',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
