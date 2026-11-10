import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/storage_and_bardana_pdf_generator.dart';
import 'package:mandi/data/models/bardana_model.dart';
import 'package:mandi/data/models/storage_allocation_model.dart';
import 'package:mandi/data/models/storage_location_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageLocation Model Tests', () {
    test('serializes toMap and deserializes fromMap correctly', () {
      final now = DateTime.now();
      final loc = StorageLocation(
        id: 'loc-1',
        shopId: 'shop-abc',
        name: 'Godown #3 Railway Road',
        type: StorageLocationType.godown,
        address: 'Near Old Grain Market Gate',
        contactPerson: 'Ustad Aslam',
        phone: '03001234567',
        capacityBags: 5000,
        currentBags: 3200,
        monthlyRentPerBag: 25.0,
        isActive: true,
        notes: 'Ventilated wheat godown',
        createdAt: now,
      );

      final map = loc.toMap();
      expect(map['shop_id'], 'shop-abc');
      expect(map['name'], 'Godown #3 Railway Road');
      expect(map['location_type'], 'godown');
      expect(map['address'], 'Near Old Grain Market Gate');
      expect(map['contact_person'], 'Ustad Aslam');
      expect(map['phone'], '03001234567');
      expect(map['capacity_bags'], 5000);
      expect(map['current_bags'], 3200);
      expect(map['monthly_rent_per_bag'], 25.0);
      expect(map['is_active'], true);

      final parsed = StorageLocation.fromMap('loc-1', map);
      expect(parsed.id, 'loc-1');
      expect(parsed.name, 'Godown #3 Railway Road');
      expect(parsed.type, StorageLocationType.godown);
      expect(parsed.capacityBags, 5000);
      expect(parsed.currentBags, 3200);
      expect(parsed.availableCapacityBags, 1800);
      expect(parsed.utilizationRatio, closeTo(0.64, 0.001));
    });

    test('calculates availableCapacityBags and utilizationRatio correctly with boundary conditions', () {
      const fullLoc = StorageLocation(
        id: 'loc-full',
        shopId: 's1',
        name: 'Cold Storage Room 1',
        type: StorageLocationType.coldStorage,
        capacityBags: 2000,
        currentBags: 2500, // over capacity
      );
      expect(fullLoc.availableCapacityBags, 0); // clamped to >= 0
      expect(fullLoc.utilizationRatio, 1.0); // clamped to <= 1.0

      const zeroCapLoc = StorageLocation(
        id: 'loc-zero',
        shopId: 's1',
        name: 'Empty Yard',
        capacityBags: 0,
      );
      expect(zeroCapLoc.availableCapacityBags, 0);
      expect(zeroCapLoc.utilizationRatio, 0.0);
    });

    test('returns localized type labels properly', () {
      const godown = StorageLocation(
        id: '1',
        shopId: 's1',
        name: 'G1',
        type: StorageLocationType.godown,
      );
      expect(godown.typeLabelEnglish, 'Godown / Warehouse');
      expect(godown.typeLabelUrdu, 'منڈی گودام');

      const cold = StorageLocation(
        id: '2',
        shopId: 's1',
        name: 'C1',
        type: StorageLocationType.coldStorage,
      );
      expect(cold.typeLabelEnglish, 'Cold Storage');
      expect(cold.typeLabelUrdu, 'کولڈ سٹوریج');

      const pharr = StorageLocation(
        id: '3',
        shopId: 's1',
        name: 'P1',
        type: StorageLocationType.shopPharr,
      );
      expect(pharr.typeLabelEnglish, 'Shop Front / Pharr');
      expect(pharr.typeLabelUrdu, 'دکان / پھڑ');
    });

    test('copyWith produces updated instance', () {
      const loc = StorageLocation(
        id: '1',
        shopId: 's1',
        name: 'Old Name',
        currentBags: 100,
      );
      final updated = loc.copyWith(
        name: 'New Name',
        currentBags: 250,
      );
      expect(updated.name, 'New Name');
      expect(updated.currentBags, 250);
      expect(updated.shopId, 's1');
    });
  });

  group('StorageAllocation Model Tests', () {
    test('calculates maunds, daysInStorage, and estimatedAccruedRent correctly', () {
      final inward = DateTime.now().subtract(const Duration(days: 30));
      final alloc = StorageAllocation(
        id: 'alloc-1',
        shopId: 's1',
        storageLocationId: 'loc-1',
        storageLocationName: 'Main Godown',
        productName: 'Basmati Rice (کرنل باسمتی)',
        partyName: 'Chaudhry Tariq',
        bagCount: 100,
        weightKg: 5000.0, // 5000 / 40 = 125 Maunds
        inwardDate: inward,
        rentRatePerBag: 30.0, // 30 Rs per bag per 30 days = 1 Rs/bag/day
        status: AllocationStatus.inStore,
      );

      expect(alloc.maunds, 125.0);
      expect(alloc.daysInStorage, 30);
      // 100 bags * (30 / 30) * 30 days = 3000 Rs
      expect(alloc.estimatedAccruedRent, 3000.0);
      expect(alloc.statusLabelEnglish, 'In-Store');
      expect(alloc.statusLabelUrdu, 'گودام میں موجود');
    });

    test('serializes toMap and deserializes fromMap correctly', () {
      final now = DateTime.now();
      final alloc = StorageAllocation(
        id: 'alloc-2',
        shopId: 's1',
        storageLocationId: 'loc-cold',
        storageLocationName: 'National Cold Store',
        productName: 'Potato (آلو سونا)',
        partyName: 'Malik Ramzan',
        lotNumber: 'LOT-9021',
        bagCount: 500,
        weightKg: 25000.0,
        inwardDate: now,
        rentRatePerBag: 45.0,
        status: AllocationStatus.inStore,
      );

      final map = alloc.toMap();
      expect(map['shop_id'], 's1');
      expect(map['storage_location_id'], 'loc-cold');
      expect(map['product_name'], 'Potato (آلو سونا)');
      expect(map['party_name'], 'Malik Ramzan');
      expect(map['lot_number'], 'LOT-9021');
      expect(map['bag_count'], 500);
      expect(map['weight_kg'], 25000.0);
      expect(map['status'], 'in_store');

      final parsed = StorageAllocation.fromMap('alloc-2', map);
      expect(parsed.id, 'alloc-2');
      expect(parsed.productName, 'Potato (آلو سونا)');
      expect(parsed.partyName, 'Malik Ramzan');
      expect(parsed.status, AllocationStatus.inStore);
    });
  });

  group('Bardana Model & Summary Tests', () {
    test('calculates overdue status and labels correctly', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 10));
      final duePast = DateTime.now().subtract(const Duration(days: 3));

      final txn = BardanaTransaction(
        id: 'tx-1',
        shopId: 's1',
        partyType: 'supplier',
        partyName: 'Haji Asghar Khan',
        bardanaType: BardanaType.jute,
        direction: BardanaDirection.issued,
        bagCount: 200,
        unitDepositRate: 100.0,
        totalDepositAmount: 20000.0,
        transactionDate: pastDate,
        dueReturnDate: duePast,
        status: BardanaStatus.pending,
      );

      expect(txn.isOverdue, isTrue);
      expect(txn.bardanaTypeLabelEnglish, 'Jute Sack');
      expect(txn.bardanaTypeLabelUrdu, 'پٹ سن بوری (Jute)');
      expect(txn.directionLabelEnglish, 'Issued');
      expect(txn.directionLabelUrdu, 'جاری کردہ (دیا گیا)');
      expect(txn.statusLabelUrdu, 'تاخیر شدہ (واپسی باقی)');
    });

    test('BardanaSummary aggregates transaction records accurately', () {
      final now = DateTime.now();
      final txns = [
        BardanaTransaction(
          id: '1',
          shopId: 's1',
          partyName: 'Farmer A',
          bardanaType: BardanaType.jute,
          direction: BardanaDirection.issued,
          bagCount: 100,
          unitDepositRate: 100.0,
          totalDepositAmount: 10000.0,
          transactionDate: now,
          status: BardanaStatus.pending,
        ),
        BardanaTransaction(
          id: '2',
          shopId: 's1',
          partyName: 'Buyer B',
          bardanaType: BardanaType.plasticPp,
          direction: BardanaDirection.issued,
          bagCount: 300,
          unitDepositRate: 30.0,
          totalDepositAmount: 9000.0,
          transactionDate: now.subtract(const Duration(days: 15)),
          dueReturnDate: now.subtract(const Duration(days: 2)), // overdue
          status: BardanaStatus.pending,
        ),
        BardanaTransaction(
          id: '3',
          shopId: 's1',
          partyName: 'Farmer A',
          bardanaType: BardanaType.jute,
          direction: BardanaDirection.returned,
          bagCount: 40,
          transactionDate: now,
          status: BardanaStatus.returned,
        ),
        BardanaTransaction(
          id: '4',
          shopId: 's1',
          partyName: 'Buyer B',
          bardanaType: BardanaType.plasticPp,
          direction: BardanaDirection.damaged,
          bagCount: 10,
          transactionDate: now,
          status: BardanaStatus.settled,
        ),
      ];

      final summary = BardanaSummary.fromTransactions(txns);

      // Issued: 100 + 300 = 400
      expect(summary.totalIssuedCount, 400);
      // Returned: 40
      expect(summary.totalReturnedCount, 40);
      // Damaged: 10
      expect(summary.totalDamagedCount, 10);
      // Net Pending: 400 - 40 - 10 = 350
      expect(summary.netPendingWithParties, 350);

      // Total deposit receivable from pending issued: 10,000 + 9,000 = 19,000
      expect(summary.totalDepositReceivable, 19000.0);

      // Overdue bags count: Txn 2 is overdue with 300 bags
      expect(summary.totalOverdueCount, 300);
    });
  });

  group('StorageAndBardanaPdfGenerator Tests', () {
    test('generates valid non-empty PDF bytes for Storage and Godown Report', () async {
      final now = DateTime.now();
      final locations = [
        const StorageLocation(
          id: 'loc-1',
          shopId: 's1',
          name: 'Main Mandi Godown #1',
          type: StorageLocationType.godown,
          capacityBags: 5000,
          currentBags: 2800,
          monthlyRentPerBag: 20.0,
          contactPerson: 'Khurram Shehzad',
          phone: '03001234567',
        ),
        const StorageLocation(
          id: 'loc-2',
          shopId: 's1',
          name: 'Punjab Cold Storage',
          type: StorageLocationType.coldStorage,
          capacityBags: 3000,
          currentBags: 2900,
          monthlyRentPerBag: 45.0,
          contactPerson: 'Malik Nasir',
          phone: '03007654321',
        ),
      ];

      final allocations = [
        StorageAllocation(
          id: 'alloc-1',
          shopId: 's1',
          storageLocationId: 'loc-1',
          storageLocationName: 'Main Mandi Godown #1',
          productName: 'Wheat (گندم)',
          partyName: 'Rana Bashir',
          bagCount: 800,
          weightKg: 40000.0,
          inwardDate: now.subtract(const Duration(days: 18)),
          rentRatePerBag: 20.0,
          status: AllocationStatus.inStore,
        ),
      ];

      final pdfBytes = await StorageAndBardanaPdfGenerator.generateStorageReportPdf(
        shopName: 'Bismillah Commission Agent',
        locations: locations,
        allocations: allocations,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('generates valid non-empty PDF bytes for Bardana Ledger Statement', () async {
      final now = DateTime.now();
      final txns = [
        BardanaTransaction(
          id: '1',
          shopId: 's1',
          partyType: 'supplier',
          partyName: 'Chaudhry Akram',
          bardanaType: BardanaType.jute,
          direction: BardanaDirection.issued,
          bagCount: 150,
          unitDepositRate: 100.0,
          totalDepositAmount: 15000.0,
          transactionDate: now.subtract(const Duration(days: 10)),
          dueReturnDate: now.add(const Duration(days: 5)),
          status: BardanaStatus.pending,
        ),
      ];

      final pdfBytes = await StorageAndBardanaPdfGenerator.generateBardanaReportPdf(
        shopName: 'Bismillah Commission Agent',
        transactions: txns,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
