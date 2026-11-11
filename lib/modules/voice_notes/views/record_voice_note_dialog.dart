import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/voice_dictation_parser.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/audio_voice_note_model.dart';
import 'package:mandi/modules/voice_notes/providers/audio_note_provider.dart';

/// Modal dialog to record a verbal voice memo, parse keywords, and attach to Mandi entities.
class RecordVoiceNoteDialog extends StatefulWidget {
  final AudioEntityType initialEntityType;
  final String? initialEntityId;
  final String? initialPartyName;

  const RecordVoiceNoteDialog({
    super.key,
    this.initialEntityType = AudioEntityType.general,
    this.initialEntityId,
    this.initialPartyName,
  });

  @override
  State<RecordVoiceNoteDialog> createState() => _RecordVoiceNoteDialogState();
}

class _RecordVoiceNoteDialogState extends State<RecordVoiceNoteDialog> {
  final _formKey = GlobalKey<FormState>();

  late AudioEntityType _entityType;
  final _titleCtrl = TextEditingController(text: 'صوتی یادداشت منڈی');
  final _transcriptionCtrl = TextEditingController(
      text: 'چوہدری اکرم، 150 من گندم، 45,000 روپے بقایا وصولی');
  final _partyNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  VoiceDictationParserResult? _parsedResult;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entityType = widget.initialEntityType;
    if (widget.initialPartyName != null && widget.initialPartyName!.isNotEmpty) {
      _partyNameCtrl.text = widget.initialPartyName!;
    }
    _runParser();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _transcriptionCtrl.dispose();
    _partyNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _runParser() {
    final res = VoiceDictationParser.parse(_transcriptionCtrl.text);
    setState(() {
      _parsedResult = res;
      if (_partyNameCtrl.text.isEmpty && res.detectedPartyName.isNotEmpty) {
        _partyNameCtrl.text = res.detectedPartyName;
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final prov = context.read<AudioNoteProvider>();

    final created = await prov.stopAndSaveRecording(
      title: _titleCtrl.text.trim(),
      transcriptionText: _transcriptionCtrl.text.trim(),
      detectedPartyType: _partyNameCtrl.text.isNotEmpty ? 'customer' : 'none',
      partyName: _partyNameCtrl.text.trim(),
      entityType: _entityType,
      entityId: widget.initialEntityId,
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (created != null) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('صوتی نوٹ کامیابی سے محفوظ کر لیا گیا ہے'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('صوتی نوٹ محفوظ کرنے میں خرابی پیش آگئی'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AudioNoteProvider>();
    final parsed = _parsedResult;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.mic, color: Colors.red, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'منشی صوتی ڈکٹیشن و نوٹ (Voice Note)',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'آواز ریکارڈ کریں یا بول کر کھاتہ و ڈھیری تفصیلات درج کریں',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
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
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Form Scrollable Body
                Expanded(
                  child: ListView(
                    children: [
                      // Simulated Microphone Live Recorder Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: prov.isRecording
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: prov.isRecording
                                ? Colors.red.shade300
                                : Colors.grey.shade300,
                            width: prov.isRecording ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (prov.isRecording) ...[
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ریکارڈنگ جاری ہے... (${prov.recordingDurationFormatted})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ] else ...[
                                  const Icon(Icons.mic_none, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'مائیکروفون تیار ہے (00:18 سیکنڈ آڈیو)',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: prov.isRecording
                                    ? Colors.red.shade700
                                    : MColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              onPressed: () {
                                if (prov.isRecording) {
                                  prov.stopAndSaveRecording(
                                    title: _titleCtrl.text,
                                    transcriptionText: _transcriptionCtrl.text,
                                    partyName: _partyNameCtrl.text,
                                    entityType: _entityType,
                                  );
                                } else {
                                  prov.startRecording();
                                }
                              },
                              icon: Icon(prov.isRecording ? Icons.stop : Icons.mic),
                              label: Text(
                                prov.isRecording
                                    ? 'ریکارڈنگ بند کریں (Stop)'
                                    : 'آواز ریکارڈ کریں (Record Live Audio)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Spoken Transcription Field
                      TextFormField(
                        controller: _transcriptionCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'صوتی متن یا تحریر (Spoken Dictation / Transcription)',
                          hintText: 'مثلاً: حاجی سلیم، 80 من چاول، 50,000 وصولی...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.record_voice_over_outlined),
                        ),
                        onChanged: (_) => _runParser(),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'لازمی درج کریں' : null,
                      ),
                      const SizedBox(height: 12),

                      // Smart Parser Preview Card
                      if (parsed != null)
                        GlassCard(
                          padding: const EdgeInsets.all(12),
                          borderColor: Colors.teal.withValues(alpha: 0.3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_awesome,
                                      color: Colors.teal, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'خودکار منڈی پارسر نتائج (Smart Parsed Fields)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (parsed.detectedPartyName.isNotEmpty)
                                    Chip(
                                      avatar: const Icon(Icons.person, size: 14),
                                      label: Text('گاہک/زمیندار: ${parsed.detectedPartyName}'),
                                      backgroundColor: Colors.teal.shade50,
                                    ),
                                  if (parsed.parsedAmountPkr > 0)
                                    Chip(
                                      avatar: const Icon(Icons.monetization_on, size: 14),
                                      label: Text('رقم: Rs. ${parsed.parsedAmountPkr.toStringAsFixed(0)}'),
                                      backgroundColor: Colors.green.shade50,
                                    ),
                                  if (parsed.parsedMaunds > 0)
                                    Chip(
                                      avatar: const Icon(Icons.scale, size: 14),
                                      label: Text('وزن: ${parsed.parsedMaunds} من'),
                                      backgroundColor: Colors.amber.shade50,
                                    ),
                                  if (parsed.detectedCommodity.isNotEmpty)
                                    Chip(
                                      avatar: const Icon(Icons.eco, size: 14),
                                      label: Text('مال: ${parsed.detectedCommodity}'),
                                      backgroundColor: Colors.blue.shade50,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Note Title & Entity Link
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _titleCtrl,
                              decoration: InputDecoration(
                                labelText: 'عنوان (Title)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<AudioEntityType>(
                              initialValue: _entityType,
                              decoration: InputDecoration(
                                labelText: 'کھاتہ کی قسم (Link)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: AudioEntityType.values.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(e.labelUrdu, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _entityType = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Party Name & Extra Notes
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _partyNameCtrl,
                              decoration: InputDecoration(
                                labelText: 'پارٹی / خریدار کا نام (Party Name)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _notesCtrl,
                              decoration: InputDecoration(
                                labelText: 'اضافی یادداشت (Notes)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('منسوخ (Cancel)'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'محفوظ ہو رہا ہے...' : 'نوٹ محفوظ کریں (Save Note)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
