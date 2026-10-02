import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class AuditLogListPage extends StatefulWidget {
  const AuditLogListPage({super.key});

  @override
  State<AuditLogListPage> createState() => _AuditLogListPageState();
}

class _AuditLogListPageState extends State<AuditLogListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopId = context.watch<ShopContextProvider>().currentShopId;

    if (shopId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs & Activity Trail')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.auditLogsStream(shopId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLogs = snapshot.data ?? [];
          final query = _searchCtrl.text.toLowerCase().trim();

          final logs = allLogs.where((log) {
            if (query.isEmpty) return true;
            final actor = (log['actor_name'] as String? ?? '').toLowerCase();
            final action = (log['action'] as String? ?? '').toLowerCase();
            final summary = (log['summary'] as String? ?? '').toLowerCase();
            return actor.contains(query) ||
                action.contains(query) ||
                summary.contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(MSpacing.md),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search activity by staff or action...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: logs.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'No audit log activity recorded yet.'
                              : 'No activity matches your search.',
                          style: MText.bodyMd
                              .copyWith(color: MColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(MSpacing.md),
                        itemCount: logs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: MSpacing.sm),
                        itemBuilder: (context, i) {
                          final log = logs[i];
                          final actor =
                              log['actor_name'] as String? ?? 'System';
                          final action = log['action'] as String? ?? 'event';
                          final summary = log['summary'] as String? ?? '';
                          final createdAt = log['created_at'] != null
                              ? DateTime.tryParse(log['created_at'].toString())
                              : null;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: MRadius.md,
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    MColors.primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.history_outlined,
                                    color: MColors.primary),
                              ),
                              title: Text(
                                summary.isNotEmpty
                                    ? summary
                                    : '$actor performed $action',
                                style: MText.titleLg.copyWith(fontSize: 15),
                              ),
                              subtitle: Text(
                                createdAt != null
                                    ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                                    : 'Recent',
                                style: MText.bodySm
                                    .copyWith(color: MColors.textSecondary),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
