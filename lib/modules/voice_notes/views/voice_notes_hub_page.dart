import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/audio_voice_note_model.dart';
import 'package:mandi/modules/voice_notes/providers/audio_note_provider.dart';
import 'package:mandi/modules/voice_notes/views/record_voice_note_dialog.dart';

/// Central Hub for Munshi Audio Voice Notes & Dictation (*منشی صوتی نوٹس اور یاد دہانیاں*).
class VoiceNotesHubPage extends StatefulWidget {
  const VoiceNotesHubPage({super.key});

  @override
  State<VoiceNotesHubPage> createState() => _VoiceNotesHubPageState();
}

class _VoiceNotesHubPageState extends State<VoiceNotesHubPage> {
  final _searchCtrl = TextEditingController();
  final _currencyFmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioNoteProvider>().loadNotes();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openRecordDialog() {
    showDialog(
      context: context,
      builder: (_) => const RecordVoiceNoteDialog(),
    );
  }

  Future<void> _confirmDelete(AudioVoiceNote note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('صوتی نوٹ حذف کریں؟'),
        content: Text('کیا آپ واقعی "${note.title}" کو حذف کرنا چاہتے ہیں؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('واپس'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف کریں'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await context.read<AudioNoteProvider>().deleteNote(note.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AudioNoteProvider>();
    final notes = prov.filteredNotes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Munshi Voice Notes'),
            Text(
              'منشی صوتی نوٹس اور آواز سے کھاتہ اندراج',
              style: TextStyle(fontSize: 11, color: MColors.gold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ریفریش (Refresh)',
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.loadNotes(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        onPressed: _openRecordDialog,
        icon: const Icon(Icons.mic),
        label: const Text('نیا صوتی نوٹ (Record Audio)'),
      ),
      body: Column(
        children: [
          // KPI Metric Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('کل صوتی نوٹس', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${prov.notes.length}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('زیرِ التواء (Pending)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${prov.pendingCount}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('کھاتہ میں درج (Linked)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${prov.processedCount}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'تلاش کریں (پارٹی، جنس، رقم، یا صوتی متن)...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                prov.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) => prov.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('تمام'),
                  selected: prov.statusFilter == null,
                  onSelected: (_) => prov.setStatusFilter(null),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('زیرِ التواء'),
                  selected: prov.statusFilter == AudioNoteStatus.pending,
                  onSelected: (_) => prov.setStatusFilter(AudioNoteStatus.pending),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('درج شدہ'),
                  selected: prov.statusFilter == AudioNoteStatus.processed,
                  onSelected: (_) => prov.setStatusFilter(AudioNoteStatus.processed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List of Notes
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic_none, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('کوئی صوتی یادداشت نہیں ملی',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text('نیا صوتی نوٹ ریکارڈ کرنے کے لیے نیچے بٹن دبائیں',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: notes.length,
                        itemBuilder: (context, idx) {
                          final n = notes[idx];
                          return _buildVoiceCard(context, n, prov);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCard(BuildContext context, AudioVoiceNote n, AudioNoteProvider prov) {
    Color statusColor;
    switch (n.status) {
      case AudioNoteStatus.pending:
        statusColor = Colors.amber.shade800;
        break;
      case AudioNoteStatus.processed:
        statusColor = Colors.green.shade700;
        break;
      case AudioNoteStatus.archived:
        statusColor = Colors.grey.shade600;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  radius: 18,
                  child: const Icon(Icons.mic, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${DateFormat('dd MMM yyyy, hh:mm a').format(n.createdAt)} • ${n.durationFormatted} (${n.fileSizeFormatted})',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    n.status.labelUrdu,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Spoken Transcription
            if (n.transcriptionText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  '🗣️ "${n.transcriptionText}"',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),

            const SizedBox(height: 10),

            // Extracted Mandi Badges
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (n.partyName.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.person, size: 14),
                    label: Text(n.partyName),
                    backgroundColor: Colors.blue.shade50,
                  ),
                if (n.parsedAmountPkr > 0)
                  Chip(
                    avatar: const Icon(Icons.monetization_on, size: 14),
                    label: Text('Rs. ${_currencyFmt.format(n.parsedAmountPkr)}'),
                    backgroundColor: Colors.green.shade50,
                  ),
                if (n.parsedMaunds > 0)
                  Chip(
                    avatar: const Icon(Icons.scale, size: 14),
                    label: Text('${n.parsedMaunds} من'),
                    backgroundColor: Colors.amber.shade50,
                  ),
                Chip(
                  avatar: const Icon(Icons.link, size: 14),
                  label: Text(n.entityType.labelUrdu),
                  backgroundColor: Colors.purple.shade50,
                ),
              ],
            ),

            const Divider(height: 18),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'حذف کریں (Delete)',
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  onPressed: () => _confirmDelete(n),
                ),
                if (n.status == AudioNoteStatus.pending) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                    onPressed: () => prov.markAsArchived(n.id),
                    icon: const Icon(Icons.archive_outlined, size: 16),
                    label: const Text('آرکائیو (Archive)'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () => prov.markAsProcessed(n.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('کھاتہ میں تصدیق (Link & Done)'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
