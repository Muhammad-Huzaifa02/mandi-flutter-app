import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/offline_sync_pdf_generator.dart';
import '../../../data/models/offline_sync_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import '../providers/offline_sync_provider.dart';
import 'resolve_conflict_dialog.dart';

class OfflineSyncPage extends StatefulWidget {
  const OfflineSyncPage({super.key});

  @override
  State<OfflineSyncPage> createState() => _OfflineSyncPageState();
}

class _OfflineSyncPageState extends State<OfflineSyncPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopId = context.read<ShopContextProvider>().currentShopId;
      if (shopId != null) {
        context.read<OfflineSyncProvider>().init(shopId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final syncProvider = context.watch<OfflineSyncProvider>();
    final activeShop = shopCtx.currentShop;

    if (activeShop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offline Sync Engine')),
        body: const Center(child: Text('Please select an active shop')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offline Sync Engine', style: TextStyle(fontSize: 16)),
            Text('آف لائن سنک اور مقامی ڈیٹا بیس', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          // Simulated Offline Mode Toggle
          Row(
            children: [
              Text(
                syncProvider.simulatedOffline ? 'Sim Offline' : 'Live Net',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              Switch(
                value: syncProvider.simulatedOffline,
                activeThumbColor: Colors.amber,
                onChanged: (_) => syncProvider.toggleSimulatedOffline(),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Sync Audit Report',
            onPressed: () {
              OfflineSyncPdfGenerator.printSyncAuditReport(
                shopName: activeShop.name,
                shopAddress: activeShop.address,
                deviceId: syncProvider.deviceId,
                sessionId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
                syncedMutations: syncProvider.syncedHistory,
                pendingQueue: syncProvider.pendingQueue,
                conflicts: syncProvider.activeConflicts,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (syncProvider.pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Badge(label: Text('${syncProvider.pendingCount}')),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Conflicts'),
                  if (syncProvider.conflictsCount > 0) ...[
                    const SizedBox(width: 6),
                    Badge(
                      backgroundColor: Colors.red,
                      label: Text('${syncProvider.conflictsCount}'),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Audit Log'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusBar(syncProvider),
          _buildKpiBanner(syncProvider),
          _buildActionToolbar(context, syncProvider),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingQueueTab(syncProvider),
                _buildConflictsTab(syncProvider),
                _buildAuditLogTab(syncProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(OfflineSyncProvider provider) {
    Color bg;
    IconData icon;
    String statusText;

    if (provider.isSyncing) {
      bg = Colors.amber.shade700;
      icon = Icons.sync;
      statusText = 'Syncing offline records to cloud... (کلاؤڈ پر منتقل ہو رہا ہے)';
    } else if (provider.isOnline) {
      bg = Colors.green.shade700;
      icon = Icons.cloud_done;
      statusText = 'Connected to Supabase Cloud • Live Sync Active (آن لائن)';
    } else {
      bg = Colors.red.shade700;
      icon = Icons.cloud_off;
      statusText = 'Operating in Offline Mode • Changes queued locally (آف لائن)';
    }

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          if (provider.lastSyncTime != null)
            Text(
              'Last: ${DateFormat('hh:mm a').format(provider.lastSyncTime!)}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _buildKpiBanner(OfflineSyncProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          _buildKpiTile('Pending Queue', '${provider.pendingCount}', Colors.amber.shade900, Icons.queue),
          const SizedBox(width: 8),
          _buildKpiTile('Conflicts', '${provider.conflictsCount}', Colors.red.shade800, Icons.merge_type),
          const SizedBox(width: 8),
          _buildKpiTile('Synced History', '${provider.historyCount}', Colors.green.shade800, Icons.done_all),
          const SizedBox(width: 8),
          _buildKpiTile('Device ID', provider.deviceId, Colors.blueGrey.shade800, Icons.perm_device_information, isSmallText: true),
        ],
      ),
    );
  }

  Widget _buildKpiTile(String title, String val, Color color, IconData icon, {bool isSmallText = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              val,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSmallText ? 11 : 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionToolbar(BuildContext context, OfflineSyncProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F6B3C),
              foregroundColor: Colors.white,
            ),
            icon: provider.isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 16),
            label: Text(provider.isSyncing ? 'Syncing...' : 'Sync Now (ابھی سنک کریں)'),
            onPressed: provider.isSyncing
                ? null
                : () async {
                    final res = await provider.triggerSync();
                    if (res != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sync Completed: ${res.successCount} synced, ${res.conflictCount} conflicts, ${res.failureCount} failed',
                          ),
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_task, size: 16),
            label: const Text('Queue Demo Record'),
            onPressed: () => _enqueueDemoRecord(context, provider),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.grey),
            label: const Text('Clear History', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onPressed: () => provider.clearHistory(),
          ),
        ],
      ),
    );
  }

  void _enqueueDemoRecord(BuildContext context, OfflineSyncProvider provider) async {
    await provider.enqueueMutation(
      entityType: SyncEntityType.commodityRates,
      operation: SyncOperation.create,
      payload: {
        'commodity_name': 'گندم (Wheat)',
        'variety': 'Faisalabad 2008',
        'min_rate_per_40kg': 3900.0,
        'max_rate_per_40kg': 4100.0,
        'market_trend': 'bullish',
        'rate_date': DateTime.now().toIso8601String().substring(0, 10),
        'notes': 'Queued offline from mobile terminal',
      },
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo rate record enqueued locally in offline storage!')),
      );
    }
  }

  Widget _buildPendingQueueTab(OfflineSyncProvider provider) {
    if (provider.pendingQueue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_done_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Queue is Empty', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('All records have been synchronized to Supabase Cloud.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.pendingQueue.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final mutation = provider.pendingQueue[index];
        final timeStr = DateFormat('hh:mm:ss a').format(mutation.clientTimestamp);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: mutation.status == SyncMutationStatus.conflict
                  ? Colors.red.shade300
                  : (mutation.status == SyncMutationStatus.failed ? Colors.orange.shade300 : Colors.grey.shade300),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: mutation.status == SyncMutationStatus.conflict
                  ? Colors.red.shade100
                  : Colors.amber.shade100,
              child: Icon(
                mutation.status == SyncMutationStatus.conflict ? Icons.warning_amber : Icons.hourglass_top,
                color: mutation.status == SyncMutationStatus.conflict ? Colors.red : Colors.amber.shade900,
                size: 20,
              ),
            ),
            title: Text(
              '${mutation.entityType.labelEn} (${mutation.operation.value.toUpperCase()})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Key: ${mutation.idempotencyKey} • Queued: $timeStr', style: const TextStyle(fontSize: 11)),
                if (mutation.errorMessage != null)
                  Text(
                    'Error: ${mutation.errorMessage}',
                    style: const TextStyle(color: Colors.red, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Chip(
              label: Text(mutation.status.labelEn, style: const TextStyle(fontSize: 10)),
              backgroundColor: mutation.status == SyncMutationStatus.conflict ? Colors.red.shade50 : Colors.amber.shade50,
            ),
          ),
        );
      },
    );
  }

  Widget _buildConflictsTab(OfflineSyncProvider provider) {
    if (provider.activeConflicts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, size: 48, color: Colors.green.shade400),
            const SizedBox(height: 12),
            const Text('No Conflicts Detected', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Local offline mutations match server states seamlessly.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.activeConflicts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final conflict = provider.activeConflicts[index];

        return Card(
          elevation: 2,
          color: Colors.red.shade50.withAlpha(120),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.red.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${conflict.entityType.labelEn} • Conflict in ${conflict.entityType.labelUr}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.merge_type, size: 14),
                      label: const Text('Resolve Conflict', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ResolveConflictDialog(mutation: conflict, provider: provider),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Local Key: ${conflict.idempotencyKey} • ${conflict.errorMessage ?? "Modified on cloud during offline session"}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogTab(OfflineSyncProvider provider) {
    if (provider.syncedHistory.isEmpty && provider.auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No Sync Audit Records Yet', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.syncedHistory.isNotEmpty) ...[
          const Text('Locally Resolved & Synced Mutations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...provider.syncedHistory.take(20).map((m) {
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.cloud_done, color: Colors.green, size: 18),
                title: Text('${m.entityType.labelEn} (${m.operation.value.toUpperCase()})', style: const TextStyle(fontSize: 12)),
                subtitle: Text('Key: ${m.idempotencyKey} • ${DateFormat('dd MMM hh:mm a').format(m.clientTimestamp)}', style: const TextStyle(fontSize: 10)),
                trailing: const Chip(
                  label: Text('Synced', style: TextStyle(fontSize: 9, color: Colors.green)),
                  backgroundColor: Color(0xFFE8F5E9),
                  padding: EdgeInsets.zero,
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (provider.auditLogs.isNotEmpty) ...[
          const Text('Cloud Sync Sessions Audit Trail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...provider.auditLogs.map((log) {
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.assessment_outlined, color: Colors.blueGrey, size: 20),
                title: Text('Session: ${log.syncSessionId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                subtitle: Text('Device: ${log.deviceId} • Mutations: ${log.mutationCount} • Conflicts: ${log.conflictsCount}', style: const TextStyle(fontSize: 10)),
                trailing: Chip(
                  label: Text(log.status.toUpperCase(), style: const TextStyle(fontSize: 9)),
                  backgroundColor: log.status == 'completed' ? Colors.green.shade50 : Colors.amber.shade50,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
