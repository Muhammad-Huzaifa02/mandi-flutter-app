import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/data/models/offline_sync_model.dart';
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
    final isUrdu = AppStrings.isUrdu(context);

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
                        Text(
                          AppStrings.val(
                            context,
                            en: 'Resolve Data Conflict',
                            ur: 'ڈیٹا ٹکراؤ حل کریں',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${isUrdu ? mutation.entityType.labelUr : mutation.entityType.labelEn} • Key: ${mutation.idempotencyKey}',
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
                    Expanded(
                      child: Text(
                        AppStrings.val(
                          context,
                          en: 'This record was edited on this device while offline, but someone else modified it on the cloud in the meantime. Choose which version to keep.',
                          ur: 'یہ ریکارڈ آف لائن حالت میں اس ڈیوائس پر تبدیل کیا گیا تھا، جبکہ اس دوران کلاؤڈ پر بھی ترمیم ہو گئی۔ منتخب کریں کہ کون سا ورژن رکھنا ہے۔',
                        ),
                        style: const TextStyle(fontSize: 12),
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
                            Row(
                              children: [
                                const Icon(Icons.phone_android, size: 16, color: Colors.blue),
                                const SizedBox(width: 6),
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Your Device (Local)',
                                    ur: 'یہ ڈیوائس (مقامی)',
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                ),
                              ],
                            ),
                            Text('${AppStrings.val(context, en: "Edited:", ur: "تبدیلی:")} $clientTimeStr', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
                                label: Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Keep Local Version',
                                    ur: 'مقامی ورژن رکھیں',
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
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
                            Row(
                              children: [
                                const Icon(Icons.cloud_done, size: 16, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Cloud Server (Remote)',
                                    ur: 'کلاؤڈ سرور',
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                ),
                              ],
                            ),
                            Text('${AppStrings.val(context, en: "Updated:", ur: "اپ ڈیٹ:")} $serverTimeStr', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
                                label: Text(
                                  AppStrings.val(
                                    context,
                                    en: 'Accept Cloud Version',
                                    ur: 'کلاؤڈ ورژن قبول کریں',
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
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
