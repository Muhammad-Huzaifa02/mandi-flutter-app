import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/utils/offline_sync_pdf_generator.dart';
import 'package:mandi/data/models/offline_sync_model.dart';
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
    final isUrdu = AppStrings.isUrdu(context);

    if (activeShop == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.val(context, en: 'Offline Sync Engine', ur: 'آف لائن سنک سسٹم'))),
        body: Center(child: Text(AppStrings.val(context, en: 'Please select an active shop', ur: 'براہ کرم فعال دکان منتخب کریں'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.val(
            context,
            en: 'Offline Sync Engine',
            ur: 'آف لائن سنک اور مقامی ڈیٹا بیس',
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          // Simulated Offline Mode Toggle
          Row(
            children: [
              Text(
                syncProvider.simulatedOffline
                    ? AppStrings.val(context, en: 'Sim Offline', ur: 'فرضی آف لائن')
                    : AppStrings.val(context, en: 'Live Net', ur: 'آن لائن نیٹ'),
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
            tooltip: AppStrings.val(
              context,
              en: 'Print Sync Audit Report',
              ur: 'سنک رپورٹ پرنٹ کریں',
            ),
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
                  Text(AppStrings.val(context, en: 'Pending', ur: 'زیر التواء')),
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
                  Text(AppStrings.val(context, en: 'Conflicts', ur: 'ٹکراؤ')),
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
            Tab(
              text: AppStrings.val(context, en: 'Audit Log', ur: 'آڈٹ لاگ'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusBar(syncProvider, isUrdu),
          _buildKpiBanner(syncProvider),
          _buildActionToolbar(context, syncProvider),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingQueueTab(syncProvider, isUrdu),
                _buildConflictsTab(syncProvider, isUrdu),
                _buildAuditLogTab(syncProvider, isUrdu),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(OfflineSyncProvider provider, bool isUrdu) {
    Color bg;
    IconData icon;
    String statusText;

    if (provider.isSyncing) {
      bg = Colors.amber.shade700;
      icon = Icons.sync;
      statusText = AppStrings.val(
        context,
        en: 'Syncing offline records to cloud...',
        ur: 'آف لائن ڈیٹا کلاؤڈ پر منتقل ہو رہا ہے...',
      );
    } else if (provider.isOnline) {
      bg = Colors.green.shade700;
      icon = Icons.cloud_done;
      statusText = AppStrings.val(
        context,
        en: 'Connected to Supabase Cloud • Live Sync Active',
        ur: 'کلاؤڈ سے منسلک ہے • لائیو سنک فعال ہے',
      );
    } else {
      bg = Colors.red.shade700;
      icon = Icons.cloud_off;
      statusText = AppStrings.val(
        context,
        en: 'Operating in Offline Mode • Changes queued locally',
        ur: 'آف لائن موڈ میں فعال • تبدیلیاں مقامی طور پر محفوظ ہیں',
      );
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
              '${AppStrings.val(context, en: "Last:", ur: "آخری:")} ${DateFormat('hh:mm a').format(provider.lastSyncTime!)}',
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
          _buildKpiTile(
            AppStrings.val(context, en: 'Pending Queue', ur: 'زیر التواء قطار'),
            '${provider.pendingCount}',
            Colors.amber.shade900,
            Icons.queue,
          ),
          const SizedBox(width: 8),
          _buildKpiTile(
            AppStrings.val(context, en: 'Conflicts', ur: 'ڈیٹا ٹکراؤ'),
            '${provider.conflictsCount}',
            Colors.red.shade800,
            Icons.merge_type,
          ),
          const SizedBox(width: 8),
          _buildKpiTile(
            AppStrings.val(context, en: 'Synced History', ur: 'کامیاب سنک'),
            '${provider.historyCount}',
            Colors.green.shade800,
            Icons.done_all,
          ),
          const SizedBox(width: 8),
          _buildKpiTile(
            AppStrings.val(context, en: 'Device ID', ur: 'ڈیوائس آئی ڈی'),
            provider.deviceId,
            Colors.blueGrey.shade800,
            Icons.perm_device_information,
            isSmallText: true,
          ),
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
            label: Text(
              provider.isSyncing
                  ? AppStrings.val(context, en: 'Syncing...', ur: 'منتقلی جاری...')
                  : AppStrings.val(context, en: 'Sync Now', ur: 'ابھی سنک کریں'),
            ),
            onPressed: provider.isSyncing
                ? null
                : () async {
                    final res = await provider.triggerSync();
                    if (res != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${AppStrings.val(context, en: "Sync Completed:", ur: "سنک مکمل:")} ${res.successCount} synced, ${res.conflictCount} conflicts, ${res.failureCount} failed',
                          ),
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_task, size: 16),
            label: Text(AppStrings.val(context, en: 'Queue Demo Record', ur: 'ڈیمو ڈیٹا شامل کریں')),
            onPressed: () => _enqueueDemoRecord(context, provider),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.grey),
            label: Text(
              AppStrings.val(context, en: 'Clear History', ur: 'ہسٹری صاف کریں'),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onPressed: () => provider.clearHistory(),
          ),
        ],
      ),
    );
  }

  void _enqueueDemoRecord(BuildContext context, OfflineSyncProvider provider) async {
    final isUrdu = AppStrings.isUrdu(context);
    await provider.enqueueMutation(
      entityType: SyncEntityType.commodityRates,
      operation: SyncOperation.create,
      payload: {
        'commodity_name': isUrdu ? 'گندم' : 'Wheat',
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
        SnackBar(
          content: Text(isUrdu
              ? 'ڈیمو ریٹ ریکارڈ آف لائن محفوظ کر لیا گیا!'
              : 'Demo rate record enqueued locally in offline storage!'),
        ),
      );
    }
  }

  Widget _buildPendingQueueTab(OfflineSyncProvider provider, bool isUrdu) {
    if (provider.pendingQueue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_done_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              AppStrings.val(context, en: 'Queue is Empty', ur: 'قطار خالی ہے'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.val(
                context,
                en: 'All records have been synchronized to Supabase Cloud.',
                ur: 'تمام ریکارڈز کلاؤڈ پر کامیابی سے سنک ہو چکے ہیں۔',
              ),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
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
              '${isUrdu ? mutation.entityType.labelUr : mutation.entityType.labelEn} (${mutation.operation.value.toUpperCase()})',
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
              label: Text(
                isUrdu ? mutation.status.labelUr : mutation.status.labelEn,
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: mutation.status == SyncMutationStatus.conflict ? Colors.red.shade50 : Colors.amber.shade50,
            ),
          ),
        );
      },
    );
  }

  Widget _buildConflictsTab(OfflineSyncProvider provider, bool isUrdu) {
    if (provider.activeConflicts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, size: 48, color: Colors.green.shade400),
            const SizedBox(height: 12),
            Text(
              AppStrings.val(context, en: 'No Conflicts Detected', ur: 'کوئی ٹکراؤ نہیں ہے'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.val(
                context,
                en: 'Local offline mutations match server states seamlessly.',
                ur: 'مقامی آف لائن ڈیٹا کلاؤڈ ڈیٹا سے مکمل مطابقت رکھتا ہے۔',
              ),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
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
                        '${isUrdu ? conflict.entityType.labelUr : conflict.entityType.labelEn} • ${AppStrings.val(context, en: "Data Conflict", ur: "ڈیٹا ٹکراؤ")}',
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
                      label: Text(
                        AppStrings.val(context, en: 'Resolve Conflict', ur: 'ٹکراؤ حل کریں'),
                        style: const TextStyle(fontSize: 11),
                      ),
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
                  'Local Key: ${conflict.idempotencyKey} • ${conflict.errorMessage ?? (isUrdu ? "آف لائن سیشن کے دوران کلاؤڈ پر ترمیم ہوئی" : "Modified on cloud during offline session")}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogTab(OfflineSyncProvider provider, bool isUrdu) {
    if (provider.syncedHistory.isEmpty && provider.auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              AppStrings.val(context, en: 'No Sync Audit Records Yet', ur: 'کوئی آڈٹ ریکارڈ موجود نہیں ہے'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.syncedHistory.isNotEmpty) ...[
          Text(
            AppStrings.val(
              context,
              en: 'Locally Resolved & Synced Mutations',
              ur: 'کامیابی سے حل اور سنک شدہ تبدیلیاں',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
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
                title: Text(
                  '${isUrdu ? m.entityType.labelUr : m.entityType.labelEn} (${m.operation.value.toUpperCase()})',
                  style: const TextStyle(fontSize: 12),
                ),
                subtitle: Text('Key: ${m.idempotencyKey} • ${DateFormat('dd MMM hh:mm a').format(m.clientTimestamp)}', style: const TextStyle(fontSize: 10)),
                trailing: Chip(
                  label: Text(
                    AppStrings.val(context, en: 'Synced', ur: 'سنک شدہ'),
                    style: const TextStyle(fontSize: 9, color: Colors.green),
                  ),
                  backgroundColor: const Color(0xFFE8F5E9),
                  padding: EdgeInsets.zero,
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (provider.auditLogs.isNotEmpty) ...[
          Text(
            AppStrings.val(
              context,
              en: 'Cloud Sync Sessions Audit Trail',
              ur: 'کلاؤڈ سنک سیشنز کی تفصیل',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
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
