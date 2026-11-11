import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/offline_sync_model.dart';
import 'supabase_service.dart';

/// Result summary of a queue processing run
class SyncProcessResult {
  final int totalProcessed;
  final int successCount;
  final int conflictCount;
  final int failureCount;
  final List<SyncMutation> conflicts;

  const SyncProcessResult({
    required this.totalProcessed,
    required this.successCount,
    required this.conflictCount,
    required this.failureCount,
    required this.conflicts,
  });
}

/// Offline-first synchronization engine with persistent mutation queue and conflict resolution
class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._internal();
  OfflineSyncService._internal();

  final _uuid = const Uuid();
  final _connectivity = Connectivity();

  bool _isSyncing = false;
  bool _simulatedOffline = false;
  String? _cachedDeviceId;

  bool get isSyncing => _isSyncing;
  bool get simulatedOffline => _simulatedOffline;

  void setSimulatedOffline(bool value) {
    _simulatedOffline = value;
  }

  /// Returns unique persistent device ID
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('mandi_device_id');
    if (id == null || id.isEmpty) {
      id = 'DEV-${_uuid.v4().substring(0, 8).toUpperCase()}';
      await prefs.setString('mandi_device_id', id);
    }
    _cachedDeviceId = id;
    return id;
  }

  /// Checks if real network connectivity is available
  Future<bool> isNetworkAvailable() async {
    if (_simulatedOffline) return false;
    final results = await _connectivity.checkConnectivity();
    final hasNet = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);

    return hasNet;
  }

  /// Listens to real-time network connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      if (_simulatedOffline) return false;
      return results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
    });
  }

  // --------------------------------------------------------------------------
  // QUEUE STORAGE HELPERS
  // --------------------------------------------------------------------------

  String _queueKey(String shopId) => 'offline_sync_queue_$shopId';
  String _historyKey(String shopId) => 'offline_sync_history_$shopId';

  /// Loads pending mutations from local device disk
  Future<List<SyncMutation>> loadQueue(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_queueKey(shopId)) ?? [];
    final list = <SyncMutation>[];
    for (final item in jsonList) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        list.add(SyncMutation.fromMap(map));
      } catch (_) {}
    }
    return list;
  }

  /// Saves mutation queue to local device disk
  Future<void> saveQueue(String shopId, List<SyncMutation> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = queue.map((m) => jsonEncode(m.toMap())).toList();
    await prefs.setStringList(_queueKey(shopId), jsonList);
  }

  /// Loads historical synced mutations
  Future<List<SyncMutation>> loadHistory(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey(shopId)) ?? [];
    final list = <SyncMutation>[];
    for (final item in jsonList) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        list.add(SyncMutation.fromMap(map));
      } catch (_) {}
    }
    return list;
  }

  /// Saves historical synced mutations (limited to last 100 items)
  Future<void> saveHistory(String shopId, List<SyncMutation> history) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = history.take(100).map((m) => jsonEncode(m.toMap())).toList();
    await prefs.setStringList(_historyKey(shopId), trimmed);
  }

  // --------------------------------------------------------------------------
  // ENQUEUE MUTATION
  // --------------------------------------------------------------------------

  /// Enqueues a new mutation locally with client timestamp and idempotency key
  Future<SyncMutation> enqueueMutation({
    required String shopId,
    required SyncEntityType entityType,
    required SyncOperation operation,
    String? entityId,
    required Map<String, dynamic> payload,
  }) async {
    final mutation = SyncMutation(
      id: _uuid.v4(),
      shopId: shopId,
      entityType: entityType,
      operation: operation,
      entityId: entityId,
      payload: payload,
      idempotencyKey: 'IDEMP-${_uuid.v4().substring(0, 12)}',
      clientTimestamp: DateTime.now(),
      status: SyncMutationStatus.pending,
    );

    final queue = await loadQueue(shopId);
    queue.add(mutation);
    await saveQueue(shopId, queue);

    return mutation;
  }

  // --------------------------------------------------------------------------
  // QUEUE PROCESSING WITH CONFLICT DETECTION
  // --------------------------------------------------------------------------

  /// Processes the pending mutation queue against Supabase
  Future<SyncProcessResult> processQueue(String shopId) async {
    if (_isSyncing) {
      return const SyncProcessResult(
        totalProcessed: 0,
        successCount: 0,
        conflictCount: 0,
        failureCount: 0,
        conflicts: [],
      );
    }

    final isOnline = await isNetworkAvailable();
    if (!isOnline) {
      return const SyncProcessResult(
        totalProcessed: 0,
        successCount: 0,
        conflictCount: 0,
        failureCount: 0,
        conflicts: [],
      );
    }

    _isSyncing = true;
    final deviceId = await getDeviceId();
    final sessionId = 'SYNC-${DateTime.now().millisecondsSinceEpoch}';

    final queue = await loadQueue(shopId);
    final history = await loadHistory(shopId);

    int successCount = 0;
    int conflictCount = 0;
    int failureCount = 0;
    final activeConflicts = <SyncMutation>[];
    final updatedQueue = <SyncMutation>[];

    for (final mutation in queue) {
      // If already flagged as conflict, wait for user resolution
      if (mutation.status == SyncMutationStatus.conflict) {
        updatedQueue.add(mutation);
        activeConflicts.add(mutation);
        conflictCount++;
        continue;
      }

      try {
        final conflictServerRow = await _detectConflict(mutation);
        if (conflictServerRow != null) {
          final conflicted = mutation.copyWith(
            status: SyncMutationStatus.conflict,
            conflictServerPayload: conflictServerRow,
            errorMessage: 'Server row was modified at ${conflictServerRow['updated_at']}',
          );
          updatedQueue.add(conflicted);
          activeConflicts.add(conflicted);
          conflictCount++;
          continue;
        }

        // Apply mutation to Supabase
        await _applyMutation(mutation);

        final synced = mutation.copyWith(
          status: SyncMutationStatus.synced,
          serverTimestamp: DateTime.now(),
        );
        history.insert(0, synced);
        successCount++;
      } catch (e) {
        failureCount++;
        final failed = mutation.copyWith(
          status: SyncMutationStatus.failed,
          retryCount: mutation.retryCount + 1,
          errorMessage: e.toString(),
        );
        updatedQueue.add(failed);
      }
    }

    await saveQueue(shopId, updatedQueue);
    await saveHistory(shopId, history);

    // Write audit log to Supabase if anything was processed
    final totalProcessed = successCount + conflictCount + failureCount;
    if (totalProcessed > 0) {
      try {
        final auditLog = SyncAuditLog(
          id: _uuid.v4(),
          shopId: shopId,
          deviceId: deviceId,
          syncSessionId: sessionId,
          mutationCount: successCount,
          conflictsCount: conflictCount,
          status: conflictCount > 0 ? 'partial' : (failureCount > 0 ? 'partial' : 'completed'),
          clientPlatform: Platform.isAndroid ? 'android' : (Platform.isWindows ? 'windows' : 'other'),
          details: {
            'success_count': successCount,
            'conflict_count': conflictCount,
            'failure_count': failureCount,
            'total_in_queue': updatedQueue.length,
          },
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        await SupabaseService.createSyncAuditLog(auditLog.toMap());
      } catch (_) {}
    }

    _isSyncing = false;
    return SyncProcessResult(
      totalProcessed: totalProcessed,
      successCount: successCount,
      conflictCount: conflictCount,
      failureCount: failureCount,
      conflicts: activeConflicts,
    );
  }

  /// Inspects if server entity was updated after the client's mutation timestamp
  Future<Map<String, dynamic>?> _detectConflict(SyncMutation mutation) async {
    if (mutation.operation != SyncOperation.update || mutation.entityId == null) {
      return null;
    }

    final tableName = _resolveTableName(mutation.entityType);
    try {
      final rows = await SupabaseService.client
          .from(tableName)
          .select('*')
          .eq('id', mutation.entityId!)
          .limit(1);

      if (rows.isNotEmpty) {
        final serverRow = rows.first;
        final serverUpdated = serverRow['updated_at'] != null
            ? DateTime.tryParse(serverRow['updated_at'].toString())
            : null;

        if (serverUpdated != null &&
            serverUpdated.isAfter(mutation.clientTimestamp.add(const Duration(seconds: 1)))) {
          return Map<String, dynamic>.from(serverRow);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Applies the mutation to the target Supabase table
  Future<void> _applyMutation(SyncMutation mutation) async {
    final tableName = _resolveTableName(mutation.entityType);
    final client = SupabaseService.client;

    switch (mutation.operation) {
      case SyncOperation.create:
        final data = Map<String, dynamic>.from(mutation.payload);
        data['shop_id'] = mutation.shopId;
        await client.from(tableName).insert(data);
        break;

      case SyncOperation.update:
        if (mutation.entityId == null) {
          throw ArgumentError('Entity ID is required for update mutation');
        }
        final data = Map<String, dynamic>.from(mutation.payload);
        data['updated_at'] = DateTime.now().toIso8601String();
        await client
            .from(tableName)
            .update(data)
            .eq('id', mutation.entityId!)
            .eq('shop_id', mutation.shopId);
        break;

      case SyncOperation.delete:
        if (mutation.entityId == null) {
          throw ArgumentError('Entity ID is required for delete mutation');
        }
        await client
            .from(tableName)
            .delete()
            .eq('id', mutation.entityId!)
            .eq('shop_id', mutation.shopId);
        break;
    }
  }

  /// Resolves entity type to Supabase table name
  String _resolveTableName(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.commodityRates:
        return 'mandi_commodity_rates';
      case SyncEntityType.inventoryLabels:
        return 'inventory_labels';
      case SyncEntityType.weighbridgeTickets:
        return 'weighbridge_tickets';
      case SyncEntityType.staffAttendance:
        return 'staff_attendance';
      case SyncEntityType.salesInvoices:
        return 'invoices';
      case SyncEntityType.consignmentLots:
        return 'consignment_lots';
      case SyncEntityType.farmerAdvances:
        return 'farmer_advances';
      case SyncEntityType.expenses:
        return 'expenses';
      case SyncEntityType.custom:
        return 'audit_logs';
    }
  }

  // --------------------------------------------------------------------------
  // CONFLICT RESOLUTION
  // --------------------------------------------------------------------------

  /// Resolves an existing conflict with a chosen strategy
  Future<void> resolveConflict({
    required String shopId,
    required String mutationId,
    required ConflictStrategy strategy,
    Map<String, dynamic>? customMergedPayload,
  }) async {
    final queue = await loadQueue(shopId);
    final history = await loadHistory(shopId);
    final index = queue.indexWhere((m) => m.id == mutationId);
    if (index == -1) return;

    final conflicted = queue[index];

    if (strategy == ConflictStrategy.serverWins) {
      // Discard local change, accept server version
      queue.removeAt(index);
      history.insert(
        0,
        conflicted.copyWith(
          status: SyncMutationStatus.synced,
          serverTimestamp: DateTime.now(),
          errorMessage: 'Resolved: Cloud Server State Accepted (Client Discarded)',
        ),
      );
    } else {
      // Client wins or manual merge: force apply payload
      final winningPayload = strategy == ConflictStrategy.clientWins
          ? conflicted.payload
          : (customMergedPayload ?? conflicted.payload);

      final resolvedMutation = conflicted.copyWith(
        payload: winningPayload,
        clientTimestamp: DateTime.now(), // update timestamp so it surpasses server
        status: SyncMutationStatus.pending,
        conflictServerPayload: null,
        errorMessage: null,
      );

      queue[index] = resolvedMutation;
    }

    await saveQueue(shopId, queue);
    await saveHistory(shopId, history);

    // Process immediately if online
    if (await isNetworkAvailable()) {
      await processQueue(shopId);
    }
  }

  /// Clears completed history logs
  Future<void> clearHistory(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey(shopId));
  }
}
