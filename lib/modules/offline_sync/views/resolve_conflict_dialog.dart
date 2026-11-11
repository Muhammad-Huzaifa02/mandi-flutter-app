import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/offline_sync_model.dart';
import '../providers/offline_sync_provider.dart';

class ResolveConflictDialog extends StatelessWidget {
  final SyncMutation mutation;
  final OfflineSyncProvider provider;

  const ResolveConflictDialog({
    super.key,
    required this.mutation,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final clientData = mutation.payload;
    final serverData = mutation.conflictServerPayload ?? {};
    final clientTimeStr = DateFormat('dd MMM, hh:mm:ss a').format(mutation.clientTimestamp);
    final serverTimeStr = serverData['updated_at'] != null
        ? DateFormat('dd MMM, hh:mm:ss a').format(DateTime.tryParse(serverData['updated_at'].toString()) ?? DateTime.now())
        : 'Unknown';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.merge_type_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resolve Data Conflict (ڈیٹا ٹکراؤ حل کریں)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${mutation.entityType.labelEn} • Key: ${mutation.idempotencyKey}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Explanation Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade900, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This record was edited on this device while offline, but someone else modified it on the cloud in the meantime. Choose which version to keep.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Side-by-Side Comparison
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Side
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withAlpha(120),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.phone_android, size: 16, color: Colors.blue),
                                SizedBox(width: 6),
                                Text(
                                  'Your Device (Local)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                ),
                              ],
                            ),
                            Text('Edited: $clientTimeStr', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            const Divider(height: 14),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  const JsonEncoder.withIndent('  ').convert(clientData),
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Keep Local Version', style: TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  await provider.resolveConflict(
                                    mutationId: mutation.id,
                                    strategy: ConflictStrategy.clientWins,
                                  );
                                  if (context.mounted) Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Server Side
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50.withAlpha(120),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.cloud_done, size: 16, color: Colors.green),
                                SizedBox(width: 6),
                                Text(
                                  'Cloud Server (Remote)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                ),
                              ],
                            ),
                            Text('Updated: $serverTimeStr', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            const Divider(height: 14),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  const JsonEncoder.withIndent('  ').convert(serverData),
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.cloud_download, size: 16),
                                label: const Text('Accept Cloud Version', style: TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  await provider.resolveConflict(
                                    mutationId: mutation.id,
                                    strategy: ConflictStrategy.serverWins,
                                  );
                                  if (context.mounted) Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
