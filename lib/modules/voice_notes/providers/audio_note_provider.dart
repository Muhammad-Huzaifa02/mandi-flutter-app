import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:mandi/core/utils/voice_dictation_parser.dart';
import 'package:mandi/data/models/audio_voice_note_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Central provider managing Munshi voice recordings, audio memos, and dictation.
class AudioNoteProvider extends ChangeNotifier {
  String? _currentShopId;

  List<AudioVoiceNote> _notes = [];
  bool _isLoading = false;
  StreamSubscription? _notesSub;

  AudioNoteStatus? _statusFilter;
  AudioEntityType? _entityFilter;
  String _searchQuery = '';

  // Recording Simulation State
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<AudioVoiceNote> get notes => _notes;
  bool get isLoading => _isLoading;
  AudioNoteStatus? get statusFilter => _statusFilter;
  AudioEntityType? get entityFilter => _entityFilter;
  String get searchQuery => _searchQuery;
  bool get isRecording => _isRecording;
  int get recordingSeconds => _recordingSeconds;

  String get recordingDurationFormatted {
    final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  List<AudioVoiceNote> get filteredNotes {
    return _notes.where((n) {
      if (_statusFilter != null && n.status != _statusFilter) {
        return false;
      }
      if (_entityFilter != null && n.entityType != _entityFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchTitle = n.title.toLowerCase().contains(q);
        final matchText = n.transcriptionText.toLowerCase().contains(q);
        final matchParty = n.partyName.toLowerCase().contains(q);
        final matchNotes = n.notes.toLowerCase().contains(q);
        if (!matchTitle && !matchText && !matchParty && !matchNotes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get pendingCount =>
      _notes.where((n) => n.status == AudioNoteStatus.pending).length;

  int get processedCount =>
      _notes.where((n) => n.status == AudioNoteStatus.processed).length;

  // ── Shop Life-cycle ──────────────────────────────────────────────────────

  void updateShop(String? shopId) {
    if (_currentShopId != shopId) {
      _currentShopId = shopId;
      _cancelSubscription();
      if (shopId != null && shopId.isNotEmpty) {
        _subscribeToNotes(shopId);
        loadNotes();
      } else {
        _notes = [];
        notifyListeners();
      }
    }
  }

  void _subscribeToNotes(String shopId) {
    _notesSub = SupabaseService.audioVoiceNotesStream(shopId).listen(
      (rows) {
        _notes = rows
            .map((r) => AudioVoiceNote.fromMap(r['id']?.toString() ?? '', r))
            .toList();
        notifyListeners();
      },
      onError: (err) => debugPrint('[AudioNoteProvider] Stream error: $err'),
    );
  }

  void _cancelSubscription() {
    _notesSub?.cancel();
    _notesSub = null;
  }

  @override
  void dispose() {
    _cancelSubscription();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // ── CRUD Operations ──────────────────────────────────────────────────────

  Future<void> loadNotes() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.getAudioVoiceNotes(shopId);
      _notes = rows
          .map((r) => AudioVoiceNote.fromMap(r['id']?.toString() ?? '', r))
          .toList();
    } catch (e) {
      debugPrint('[AudioNoteProvider] Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startRecording() {
    _isRecording = true;
    _recordingSeconds = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordingSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<AudioVoiceNote?> stopAndSaveRecording({
    required String title,
    String transcriptionText = '',
    String detectedPartyType = 'none',
    String? partyId,
    String partyName = '',
    AudioEntityType entityType = AudioEntityType.general,
    String? entityId,
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return null;

    _isRecording = false;
    _recordingTimer?.cancel();
    final duration = _recordingSeconds;
    _recordingSeconds = 0;

    // Run smart parser on transcription
    final parsed = VoiceDictationParser.parse(transcriptionText);
    final resolvedParty = partyName.isNotEmpty ? partyName : parsed.detectedPartyName;
    final resolvedAmount = parsed.parsedAmountPkr;
    final resolvedMaunds = parsed.parsedMaunds;

    // Generate mock storage path & audio URL
    final randomId = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$shopId/audio_$randomId.m4a';
    final audioUrl = 'https://supabase.local/storage/v1/object/public/documents/$storagePath';

    try {
      final data = {
        'shop_id': shopId,
        'title': title.isNotEmpty ? title : 'صوتی نوٹ ($resolvedParty)',
        'audio_url': audioUrl,
        'storage_path': storagePath,
        'duration_seconds': duration > 0 ? duration : 18,
        'file_size_bytes': (duration > 0 ? duration : 18) * 16000,
        'mime_type': 'audio/m4a',
        'transcription_text': transcriptionText,
        'detected_party_type': detectedPartyType,
        'party_id': partyId,
        'party_name': resolvedParty,
        'entity_type': entityType.toDbString(),
        'entity_id': entityId,
        'parsed_amount_pkr': resolvedAmount,
        'parsed_maunds': resolvedMaunds,
        'status': AudioNoteStatus.pending.toDbString(),
        'notes': notes,
      };

      final newId = await SupabaseService.createAudioVoiceNote(data);
      final createdNote = AudioVoiceNote.fromMap(newId, data);
      await loadNotes();
      return createdNote;
    } catch (e) {
      debugPrint('[AudioNoteProvider] Error saving voice note: $e');
      return null;
    }
  }

  Future<bool> markAsProcessed(String noteId, {String? notes}) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    try {
      await SupabaseService.updateAudioVoiceNoteStatus(
        noteId: noteId,
        shopId: shopId,
        status: AudioNoteStatus.processed.toDbString(),
        notes: notes,
      );
      await loadNotes();
      return true;
    } catch (e) {
      debugPrint('[AudioNoteProvider] Error marking note as processed: $e');
      return false;
    }
  }

  Future<bool> markAsArchived(String noteId) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    try {
      await SupabaseService.updateAudioVoiceNoteStatus(
        noteId: noteId,
        shopId: shopId,
        status: AudioNoteStatus.archived.toDbString(),
      );
      await loadNotes();
      return true;
    } catch (e) {
      debugPrint('[AudioNoteProvider] Error archiving note: $e');
      return false;
    }
  }

  Future<bool> deleteNote(String noteId) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    try {
      await SupabaseService.deleteAudioVoiceNote(noteId, shopId);
      await loadNotes();
      return true;
    } catch (e) {
      debugPrint('[AudioNoteProvider] Error deleting note: $e');
      return false;
    }
  }

  // ── Filters ──────────────────────────────────────────────────────────────

  void setStatusFilter(AudioNoteStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setEntityFilter(AudioEntityType? entity) {
    _entityFilter = entity;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void resetFilters() {
    _statusFilter = null;
    _entityFilter = null;
    _searchQuery = '';
    notifyListeners();
  }
}
