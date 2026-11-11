import 'dart:convert';

/// Entity types supported by the offline mutation synchronization engine
enum SyncEntityType {
  commodityRates,
  inventoryLabels,
  weighbridgeTickets,
  staffAttendance,
  salesInvoices,
  consignmentLots,
  farmerAdvances,
  expenses,
  custom;

  String get value {
    switch (this) {
      case SyncEntityType.commodityRates:
        return 'commodity_rates';
      case SyncEntityType.inventoryLabels:
        return 'inventory_labels';
      case SyncEntityType.weighbridgeTickets:
        return 'weighbridge_tickets';
      case SyncEntityType.staffAttendance:
        return 'staff_attendance';
      case SyncEntityType.salesInvoices:
        return 'sales_invoices';
      case SyncEntityType.consignmentLots:
        return 'consignment_lots';
      case SyncEntityType.farmerAdvances:
        return 'farmer_advances';
      case SyncEntityType.expenses:
        return 'expenses';
      case SyncEntityType.custom:
        return 'custom';
    }
  }

  String get labelEn {
    switch (this) {
      case SyncEntityType.commodityRates:
        return 'Mandi Commodity Rates';
      case SyncEntityType.inventoryLabels:
        return 'Inventory Labels / Pallets';
      case SyncEntityType.weighbridgeTickets:
        return 'Weighbridge Kanda Tickets';
      case SyncEntityType.staffAttendance:
        return 'Staff Daily Attendance';
      case SyncEntityType.salesInvoices:
        return 'Sales Invoices';
      case SyncEntityType.consignmentLots:
        return 'Consignment Lots / Boli';
      case SyncEntityType.farmerAdvances:
        return 'Farmer Crop Advances';
      case SyncEntityType.expenses:
        return 'Mandi Daily Expenses';
      case SyncEntityType.custom:
        return 'General Entity';
    }
  }

  String get labelUr {
    switch (this) {
      case SyncEntityType.commodityRates:
        return 'منڈی ریٹ لسٹ';
      case SyncEntityType.inventoryLabels:
        return 'بارکوڈ و اسٹاک لیبل';
      case SyncEntityType.weighbridgeTickets:
        return 'دھرم کنڈا پرچی';
      case SyncEntityType.staffAttendance:
        return 'ملازمین حاضری رجسٹر';
      case SyncEntityType.salesInvoices:
        return 'سیلز انوائس';
      case SyncEntityType.consignmentLots:
        return 'لاٹ و بولی ریکارڈ';
      case SyncEntityType.farmerAdvances:
        return 'زمیندار پیشگی کھاتہ';
      case SyncEntityType.expenses:
        return 'روزانہ منڈی اخراجات';
      case SyncEntityType.custom:
        return 'عمومی ریکارڈ';
    }
  }

  static SyncEntityType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'commodity_rates':
      case 'commodityrates':
        return SyncEntityType.commodityRates;
      case 'inventory_labels':
      case 'inventorylabels':
        return SyncEntityType.inventoryLabels;
      case 'weighbridge_tickets':
      case 'weighbridgetickets':
        return SyncEntityType.weighbridgeTickets;
      case 'staff_attendance':
      case 'staffattendance':
        return SyncEntityType.staffAttendance;
      case 'sales_invoices':
      case 'salesinvoices':
        return SyncEntityType.salesInvoices;
      case 'consignment_lots':
      case 'consignmentlots':
        return SyncEntityType.consignmentLots;
      case 'farmer_advances':
      case 'farmeradvances':
        return SyncEntityType.farmerAdvances;
      case 'expenses':
        return SyncEntityType.expenses;
      default:
        return SyncEntityType.custom;
    }
  }
}

/// Operation type for offline queued mutation
enum SyncOperation {
  create,
  update,
  delete;

  String get value => name;

  static SyncOperation fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'update':
        return SyncOperation.update;
      case 'delete':
        return SyncOperation.delete;
      case 'create':
      default:
        return SyncOperation.create;
    }
  }
}

/// Lifecycle state of a mutation inside the sync queue
enum SyncMutationStatus {
  pending,
  syncing,
  synced,
  conflict,
  failed;

  String get value => name;

  String get labelEn {
    switch (this) {
      case SyncMutationStatus.pending:
        return 'Pending Queue';
      case SyncMutationStatus.syncing:
        return 'Syncing...';
      case SyncMutationStatus.synced:
        return 'Synced to Cloud';
      case SyncMutationStatus.conflict:
        return 'Conflict Detected';
      case SyncMutationStatus.failed:
        return 'Sync Failed';
    }
  }

  String get labelUr {
    switch (this) {
      case SyncMutationStatus.pending:
        return 'قطار میں انتظار';
      case SyncMutationStatus.syncing:
        return 'سنک جاری ہے...';
      case SyncMutationStatus.synced:
        return 'کلاؤڈ پر محفوظ';
      case SyncMutationStatus.conflict:
        return 'ڈیٹا ٹکراؤ (تنازع)';
      case SyncMutationStatus.failed:
        return 'سنک ناکام';
    }
  }

  static SyncMutationStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'syncing':
        return SyncMutationStatus.syncing;
      case 'synced':
        return SyncMutationStatus.synced;
      case 'conflict':
        return SyncMutationStatus.conflict;
      case 'failed':
        return SyncMutationStatus.failed;
      case 'pending':
      default:
        return SyncMutationStatus.pending;
    }
  }
}

/// Conflict resolution strategy chosen by Munshi or automated rule
enum ConflictStrategy {
  clientWins, // Local offline edits overwrite cloud
  serverWins, // Cloud latest changes overwrite local
  manualMerge; // Custom merged JSON payload

  String get value => name;

  String get labelEn {
    switch (this) {
      case ConflictStrategy.clientWins:
        return 'Client Local State Wins';
      case ConflictStrategy.serverWins:
        return 'Cloud Server State Wins';
      case ConflictStrategy.manualMerge:
        return 'Manual Side-by-Side Merge';
    }
  }

  String get labelUr {
    switch (this) {
      case ConflictStrategy.clientWins:
        return 'مقامی آف لائن ڈیٹا بحال رکھیں';
      case ConflictStrategy.serverWins:
        return 'کلاؤڈ سرور ڈیٹا قبول کریں';
      case ConflictStrategy.manualMerge:
        return 'باہمی موازنہ اور انتخاب';
    }
  }
}

/// Represents an offline mutation queued locally
class SyncMutation {
  final String id;
  final String shopId;
  final SyncEntityType entityType;
  final SyncOperation operation;
  final String? entityId;
  final Map<String, dynamic> payload;
  final String idempotencyKey;
  final DateTime clientTimestamp;
  final DateTime? serverTimestamp;
  final int retryCount;
  final SyncMutationStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? conflictServerPayload;

  const SyncMutation({
    required this.id,
    required this.shopId,
    required this.entityType,
    required this.operation,
    this.entityId,
    required this.payload,
    required this.idempotencyKey,
    required this.clientTimestamp,
    this.serverTimestamp,
    this.retryCount = 0,
    this.status = SyncMutationStatus.pending,
    this.errorMessage,
    this.conflictServerPayload,
  });

  SyncMutation copyWith({
    String? id,
    String? shopId,
    SyncEntityType? entityType,
    SyncOperation? operation,
    String? entityId,
    Map<String, dynamic>? payload,
    String? idempotencyKey,
    DateTime? clientTimestamp,
    DateTime? serverTimestamp,
    int? retryCount,
    SyncMutationStatus? status,
    String? errorMessage,
    Map<String, dynamic>? conflictServerPayload,
  }) {
    return SyncMutation(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      entityType: entityType ?? this.entityType,
      operation: operation ?? this.operation,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      clientTimestamp: clientTimestamp ?? this.clientTimestamp,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      conflictServerPayload: conflictServerPayload ?? this.conflictServerPayload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'entity_type': entityType.value,
      'operation': operation.value,
      'entity_id': entityId,
      'payload': jsonEncode(payload),
      'idempotency_key': idempotencyKey,
      'client_timestamp': clientTimestamp.toIso8601String(),
      'server_timestamp': serverTimestamp?.toIso8601String(),
      'retry_count': retryCount,
      'status': status.value,
      'error_message': errorMessage,
      'conflict_server_payload':
          conflictServerPayload != null ? jsonEncode(conflictServerPayload) : null,
    };
  }

  factory SyncMutation.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedPayload = {};
    if (map['payload'] is String) {
      try {
        parsedPayload = jsonDecode(map['payload'] as String) as Map<String, dynamic>;
      } catch (_) {}
    } else if (map['payload'] is Map) {
      parsedPayload = Map<String, dynamic>.from(map['payload'] as Map);
    }

    Map<String, dynamic>? parsedConflict;
    if (map['conflict_server_payload'] is String) {
      try {
        parsedConflict =
            jsonDecode(map['conflict_server_payload'] as String) as Map<String, dynamic>;
      } catch (_) {}
    } else if (map['conflict_server_payload'] is Map) {
      parsedConflict =
          Map<String, dynamic>.from(map['conflict_server_payload'] as Map);
    }

    return SyncMutation(
      id: map['id']?.toString() ?? '',
      shopId: map['shop_id']?.toString() ?? '',
      entityType: SyncEntityType.fromString(map['entity_type']?.toString() ?? ''),
      operation: SyncOperation.fromString(map['operation']?.toString() ?? ''),
      entityId: map['entity_id']?.toString(),
      payload: parsedPayload,
      idempotencyKey: map['idempotency_key']?.toString() ?? '',
      clientTimestamp: DateTime.tryParse(map['client_timestamp']?.toString() ?? '') ??
          DateTime.now(),
      serverTimestamp: map['server_timestamp'] != null
          ? DateTime.tryParse(map['server_timestamp'].toString())
          : null,
      retryCount: (map['retry_count'] as num?)?.toInt() ?? 0,
      status: SyncMutationStatus.fromString(map['status']?.toString() ?? ''),
      errorMessage: map['error_message']?.toString(),
      conflictServerPayload: parsedConflict,
    );
  }
}

/// Record of an audit log for an offline sync session sent to Supabase
class SyncAuditLog {
  final String id;
  final String shopId;
  final String deviceId;
  final String syncSessionId;
  final int mutationCount;
  final int conflictsCount;
  final String status;
  final String clientPlatform;
  final Map<String, dynamic> details;
  final DateTime startedAt;
  final DateTime? completedAt;

  const SyncAuditLog({
    required this.id,
    required this.shopId,
    required this.deviceId,
    required this.syncSessionId,
    this.mutationCount = 0,
    this.conflictsCount = 0,
    this.status = 'completed',
    this.clientPlatform = 'android',
    this.details = const {},
    required this.startedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'device_id': deviceId,
      'sync_session_id': syncSessionId,
      'mutation_count': mutationCount,
      'conflicts_count': conflictsCount,
      'status': status,
      'client_platform': clientPlatform,
      'details': details,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory SyncAuditLog.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedDetails = {};
    if (map['details'] is Map) {
      parsedDetails = Map<String, dynamic>.from(map['details'] as Map);
    } else if (map['details'] is String) {
      try {
        parsedDetails = jsonDecode(map['details'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return SyncAuditLog(
      id: map['id']?.toString() ?? '',
      shopId: map['shop_id']?.toString() ?? '',
      deviceId: map['device_id']?.toString() ?? '',
      syncSessionId: map['sync_session_id']?.toString() ?? '',
      mutationCount: (map['mutation_count'] as num?)?.toInt() ?? 0,
      conflictsCount: (map['conflicts_count'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'completed',
      clientPlatform: map['client_platform']?.toString() ?? 'android',
      details: parsedDetails,
      startedAt: DateTime.tryParse(map['started_at']?.toString() ?? '') ?? DateTime.now(),
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'].toString())
          : null,
    );
  }
}
