import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/core/utils/offline_sync_pdf_generator.dart';
import 'package:mandi/data/models/offline_sync_model.dart';

void main() {
  group('OfflineSyncModel Tests', () {
    test('SyncEntityType enums and labels are correct', () {
      expect(SyncEntityType.commodityRates.value, 'commodity_rates');
      expect(SyncEntityType.commodityRates.labelUr, 'منڈی ریٹ لسٹ');
      expect(SyncEntityType.inventoryLabels.value, 'inventory_labels');
      expect(SyncEntityType.weighbridgeTickets.value, 'weighbridge_tickets');
      expect(SyncEntityType.staffAttendance.value, 'staff_attendance');

      expect(SyncEntityType.fromString('inventory_labels'), SyncEntityType.inventoryLabels);
      expect(SyncEntityType.fromString('unknown_entity'), SyncEntityType.custom);
    });

    test('SyncOperation and SyncMutationStatus parsing', () {
      expect(SyncOperation.fromString('update'), SyncOperation.update);
      expect(SyncOperation.fromString('delete'), SyncOperation.delete);
      expect(SyncOperation.fromString('create'), SyncOperation.create);

      expect(SyncMutationStatus.fromString('conflict'), SyncMutationStatus.conflict);
      expect(SyncMutationStatus.fromString('synced'), SyncMutationStatus.synced);
      expect(SyncMutationStatus.fromString('pending'), SyncMutationStatus.pending);
    });

    test('ConflictStrategy labels and values', () {
      expect(ConflictStrategy.clientWins.value, 'clientWins');
      expect(ConflictStrategy.serverWins.value, 'serverWins');
      expect(ConflictStrategy.clientWins.labelUr, contains('مقامی آف لائن'));
      expect(ConflictStrategy.serverWins.labelUr, contains('کلاؤڈ سرور'));
    });

    test('SyncMutation toMap and fromMap roundtrip', () {
      final now = DateTime(2026, 11, 11, 12, 0);
      final mutation = SyncMutation(
        id: 'mut-1234',
        shopId: 'shop-5678',
        entityType: SyncEntityType.commodityRates,
        operation: SyncOperation.create,
        entityId: 'rate-999',
        payload: {
          'commodity_name': 'گندم',
          'min_rate': 3900.0,
          'max_rate': 4100.0,
        },
        idempotencyKey: 'IDEMP-ABC123',
        clientTimestamp: now,
        status: SyncMutationStatus.pending,
      );

      final map = mutation.toMap();
      expect(map['id'], 'mut-1234');
      expect(map['entity_type'], 'commodity_rates');
      expect(map['idempotency_key'], 'IDEMP-ABC123');

      final fromMap = SyncMutation.fromMap(map);
      expect(fromMap.id, 'mut-1234');
      expect(fromMap.shopId, 'shop-5678');
      expect(fromMap.entityType, SyncEntityType.commodityRates);
      expect(fromMap.operation, SyncOperation.create);
      expect(fromMap.payload['commodity_name'], 'گندم');
      expect(fromMap.status, SyncMutationStatus.pending);
    });

    test('SyncAuditLog toMap and fromMap roundtrip', () {
      final now = DateTime(2026, 11, 11, 12, 0);
      final audit = SyncAuditLog(
        id: 'audit-001',
        shopId: 'shop-100',
        deviceId: 'DEV-XYZ999',
        syncSessionId: 'SYNC-SESSION-01',
        mutationCount: 5,
        conflictsCount: 1,
        status: 'completed',
        clientPlatform: 'android',
        details: {'success': true},
        startedAt: now,
        completedAt: now.add(const Duration(seconds: 2)),
      );

      final map = audit.toMap();
      expect(map['device_id'], 'DEV-XYZ999');
      expect(map['mutation_count'], 5);

      final reconstructed = SyncAuditLog.fromMap(map);
      expect(reconstructed.id, 'audit-001');
      expect(reconstructed.syncSessionId, 'SYNC-SESSION-01');
      expect(reconstructed.conflictsCount, 1);
      expect(reconstructed.clientPlatform, 'android');
    });

    test('OfflineSyncPdfGenerator generates non-empty PDF bytes', () async {
      final now = DateTime.now();
      final mutation = SyncMutation(
        id: 'mut-1',
        shopId: 'shop-1',
        entityType: SyncEntityType.commodityRates,
        operation: SyncOperation.create,
        payload: {'rate': 4000},
        idempotencyKey: 'IDEMP-TEST-01',
        clientTimestamp: now,
        status: SyncMutationStatus.synced,
      );

      final pdfBytes = await OfflineSyncPdfGenerator.generateSyncAuditReportPdf(
        shopName: 'Al-Madina Grain Commission',
        shopAddress: 'Ghalla Mandi, Faisalabad',
        deviceId: 'DEV-FAISAL-01',
        sessionId: 'SYNC-AUDIT-101',
        syncedMutations: [mutation],
        pendingQueue: [],
        conflicts: [],
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
    });
  });
}
