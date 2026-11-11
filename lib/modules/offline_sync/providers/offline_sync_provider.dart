import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/models/offline_sync_model.dart';
import '../../../data/services/offline_sync_service.dart';
import '../../../data/services/supabase_service.dart';

class OfflineSyncProvider with ChangeNotifier {
  final _service = OfflineSyncService.instance;

  String? _shopId;
  String _deviceId = '';
  bool _isOnline = true;
  bool _isSyncing = false;
  bool _simulatedOffline = false;
  DateTime? _lastSyncTime;

  List<SyncMutation> _pendingQueue = [];
  List<SyncMutation> _syncedHistory = [];
  List<SyncMutation> _activeConflicts = [];
  List<SyncAuditLog> _auditLogs = [];

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<List<Map<String, dynamic>>>? _auditLogsSub;

  String? get shopId => _shopId;
  String get deviceId => _deviceId;
  bool get isOnline => _isOnline && !_simulatedOffline;
  bool get isSyncing => _isSyncing;
  bool get simulatedOffline => _simulatedOffline;
  DateTime? get lastSyncTime => _lastSyncTime;

  List<SyncMutation> get pendingQueue => List.unmodifiable(_pendingQueue);
  List<SyncMutation> get syncedHistory => List.unmodifiable(_syncedHistory);
  List<SyncMutation> get activeConflicts => List.unmodifiable(_activeConflicts);
  List<SyncAuditLog> get auditLogs => List.unmodifiable(_auditLogs);

  int get pendingCount => _pendingQueue.length;
  int get conflictsCount => _activeConflicts.length;
  int get historyCount => _syncedHistory.length;

  /// Updates shop context from proxy provider
  void updateShop(String? shopId) {
    if (shopId != null && shopId.isNotEmpty) {
      init(shopId);
    }
  }

  /// Initializes offline sync engine for active shop
  Future<void> init(String shopId) async {
    if (_shopId == shopId && _deviceId.isNotEmpty) return;
    _shopId = shopId;

    _deviceId = await _service.getDeviceId();
    _isOnline = await _service.isNetworkAvailable();
    _simulatedOffline = _service.simulatedOffline;

    await refreshState();

    // Listen to network changes
    _connectivitySub?.cancel();
    _connectivitySub = _service.onConnectivityChanged.listen((online) async {
      _isOnline = online;
      notifyListeners();
      if (_isOnline && !_simulatedOffline && _pendingQueue.isNotEmpty) {
        await triggerSync();
      }
    });

    // Listen to Supabase audit logs stream
    _auditLogsSub?.cancel();
    _auditLogsSub = SupabaseService.syncAuditLogsStream(shopId).listen((rows) {
      _auditLogs = rows.map((r) => SyncAuditLog.fromMap(r)).toList();
      notifyListeners();
    });
  }

  /// Reloads queue, history, and conflicts from local persistent storage
  Future<void> refreshState() async {
    if (_shopId == null) return;
    final queue = await _service.loadQueue(_shopId!);
    final history = await _service.loadHistory(_shopId!);

    _pendingQueue = queue;
    _syncedHistory = history;
    _activeConflicts = queue.where((m) => m.status == SyncMutationStatus.conflict).toList();
    _isSyncing = _service.isSyncing;
    notifyListeners();
  }

  /// Toggles simulated offline mode (for testing or rural cellular blackouts)
  Future<void> toggleSimulatedOffline() async {
    _simulatedOffline = !_simulatedOffline;
    _service.setSimulatedOffline(_simulatedOffline);
    _isOnline = await _service.isNetworkAvailable();
    notifyListeners();

    if (_isOnline && !_simulatedOffline && _pendingQueue.isNotEmpty) {
      await triggerSync();
    }
  }

  /// Enqueues a new mutation locally into persistent queue
  Future<SyncMutation?> enqueueMutation({
    required SyncEntityType entityType,
    required SyncOperation operation,
    String? entityId,
    required Map<String, dynamic> payload,
  }) async {
    if (_shopId == null) return null;

    final mutation = await _service.enqueueMutation(
      shopId: _shopId!,
      entityType: entityType,
      operation: operation,
      entityId: entityId,
      payload: payload,
    );

    await refreshState();

    // Auto-trigger sync if currently online
    if (isOnline) {
      triggerSync();
    }

    return mutation;
  }

  /// Manually triggers processing of pending queue
  Future<SyncProcessResult?> triggerSync() async {
    if (_shopId == null || _isSyncing) return null;

    _isSyncing = true;
    notifyListeners();

    final result = await _service.processQueue(_shopId!);

    _lastSyncTime = DateTime.now();
    _isSyncing = false;
    await refreshState();

    return result;
  }

  /// Resolves an active data conflict
  Future<void> resolveConflict({
    required String mutationId,
    required ConflictStrategy strategy,
    Map<String, dynamic>? customMergedPayload,
  }) async {
    if (_shopId == null) return;

    await _service.resolveConflict(
      shopId: _shopId!,
      mutationId: mutationId,
      strategy: strategy,
      customMergedPayload: customMergedPayload,
    );

    await refreshState();
  }

  /// Clears completed sync history
  Future<void> clearHistory() async {
    if (_shopId == null) return;
    await _service.clearHistory(_shopId!);
    await refreshState();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _auditLogsSub?.cancel();
    super.dispose();
  }
}
