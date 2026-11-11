// Domain models for Munshi Offline Audio-Voice Notes and Khata Dictation
// (*منشی صوتی نوٹس اور آواز سے کھاتہ اندراج*).

enum AudioNoteStatus {
  pending,
  processed,
  archived;

  String toDbString() {
    switch (this) {
      case AudioNoteStatus.pending:
        return 'pending';
      case AudioNoteStatus.processed:
        return 'processed';
      case AudioNoteStatus.archived:
        return 'archived';
    }
  }

  String get labelUrdu {
    switch (this) {
      case AudioNoteStatus.pending:
        return 'زیرِ التواء (نیا)';
      case AudioNoteStatus.processed:
        return 'کھاتہ میں درج شدہ';
      case AudioNoteStatus.archived:
        return 'محفوظ شدہ (آرکائیو)';
    }
  }

  String get labelEnglish {
    switch (this) {
      case AudioNoteStatus.pending:
        return 'Pending';
      case AudioNoteStatus.processed:
        return 'Processed / Linked';
      case AudioNoteStatus.archived:
        return 'Archived';
    }
  }

  static AudioNoteStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'processed':
        return AudioNoteStatus.processed;
      case 'archived':
        return AudioNoteStatus.archived;
      case 'pending':
      default:
        return AudioNoteStatus.pending;
    }
  }
}

enum AudioEntityType {
  general,
  invoice,
  consignmentLot,
  weighbridge,
  khataPayment;

  String toDbString() {
    switch (this) {
      case AudioEntityType.general:
        return 'general';
      case AudioEntityType.invoice:
        return 'invoice';
      case AudioEntityType.consignmentLot:
        return 'consignment_lot';
      case AudioEntityType.weighbridge:
        return 'weighbridge';
      case AudioEntityType.khataPayment:
        return 'khata_payment';
    }
  }

  String get labelUrdu {
    switch (this) {
      case AudioEntityType.general:
        return 'عام یادداشت';
      case AudioEntityType.invoice:
        return 'سیلز بل / انوائس';
      case AudioEntityType.consignmentLot:
        return 'آمد و ڈھیری بولی';
      case AudioEntityType.weighbridge:
        return 'دھرم کنڈا پرچہ';
      case AudioEntityType.khataPayment:
        return 'کھاتہ وصولی / ادائیگی';
    }
  }

  String get labelEnglish {
    switch (this) {
      case AudioEntityType.general:
        return 'General Memo';
      case AudioEntityType.invoice:
        return 'Sales Invoice';
      case AudioEntityType.consignmentLot:
        return 'Consignment Lot';
      case AudioEntityType.weighbridge:
        return 'Weighbridge Ticket';
      case AudioEntityType.khataPayment:
        return 'Khata Payment';
    }
  }

  static AudioEntityType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'invoice':
        return AudioEntityType.invoice;
      case 'consignment_lot':
      case 'consignmentlot':
        return AudioEntityType.consignmentLot;
      case 'weighbridge':
        return AudioEntityType.weighbridge;
      case 'khata_payment':
      case 'khatapayment':
        return AudioEntityType.khataPayment;
      case 'general':
      default:
        return AudioEntityType.general;
    }
  }
}

class AudioVoiceNote {
  final String id;
  final String shopId;
  final String title;
  final String audioUrl;
  final String storagePath;
  final int durationSeconds;
  final int fileSizeBytes;
  final String mimeType;
  final String transcriptionText;
  final String detectedPartyType; // 'none', 'customer', 'supplier'
  final String? partyId;
  final String partyName;
  final AudioEntityType entityType;
  final String? entityId;
  final double parsedAmountPkr;
  final double parsedMaunds;
  final AudioNoteStatus status;
  final String notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AudioVoiceNote({
    this.id = '',
    required this.shopId,
    required this.title,
    this.audioUrl = '',
    this.storagePath = '',
    this.durationSeconds = 0,
    this.fileSizeBytes = 0,
    this.mimeType = 'audio/m4a',
    this.transcriptionText = '',
    this.detectedPartyType = 'none',
    this.partyId,
    this.partyName = '',
    this.entityType = AudioEntityType.general,
    this.entityId,
    this.parsedAmountPkr = 0.0,
    this.parsedMaunds = 0.0,
    this.status = AudioNoteStatus.pending,
    this.notes = '',
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  String get durationFormatted {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  factory AudioVoiceNote.fromMap(String id, Map<String, dynamic> map) {
    return AudioVoiceNote(
      id: id,
      shopId: map['shop_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'صوتی یادداشت',
      audioUrl: map['audio_url']?.toString() ?? '',
      storagePath: map['storage_path']?.toString() ?? '',
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt() ?? 0,
      mimeType: map['mime_type']?.toString() ?? 'audio/m4a',
      transcriptionText: map['transcription_text']?.toString() ?? '',
      detectedPartyType: map['detected_party_type']?.toString() ?? 'none',
      partyId: map['party_id']?.toString(),
      partyName: map['party_name']?.toString() ?? '',
      entityType: AudioEntityType.fromString(map['entity_type']?.toString() ?? 'general'),
      entityId: map['entity_id']?.toString(),
      parsedAmountPkr: (map['parsed_amount_pkr'] as num?)?.toDouble() ?? 0.0,
      parsedMaunds: (map['parsed_maunds'] as num?)?.toDouble() ?? 0.0,
      status: AudioNoteStatus.fromString(map['status']?.toString() ?? 'pending'),
      notes: map['notes']?.toString() ?? '',
      createdBy: map['created_by']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'title': title,
      'audio_url': audioUrl,
      'storage_path': storagePath,
      'duration_seconds': durationSeconds,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'transcription_text': transcriptionText,
      'detected_party_type': detectedPartyType,
      'party_id': partyId,
      'party_name': partyName,
      'entity_type': entityType.toDbString(),
      'entity_id': entityId,
      'parsed_amount_pkr': parsedAmountPkr,
      'parsed_maunds': parsedMaunds,
      'status': status.toDbString(),
      'notes': notes,
    };
  }

  AudioVoiceNote copyWith({
    String? id,
    String? shopId,
    String? title,
    String? audioUrl,
    String? storagePath,
    int? durationSeconds,
    int? fileSizeBytes,
    String? mimeType,
    String? transcriptionText,
    String? detectedPartyType,
    String? partyId,
    String? partyName,
    AudioEntityType? entityType,
    String? entityId,
    double? parsedAmountPkr,
    double? parsedMaunds,
    AudioNoteStatus? status,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AudioVoiceNote(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      title: title ?? this.title,
      audioUrl: audioUrl ?? this.audioUrl,
      storagePath: storagePath ?? this.storagePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      transcriptionText: transcriptionText ?? this.transcriptionText,
      detectedPartyType: detectedPartyType ?? this.detectedPartyType,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      parsedAmountPkr: parsedAmountPkr ?? this.parsedAmountPkr,
      parsedMaunds: parsedMaunds ?? this.parsedMaunds,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
