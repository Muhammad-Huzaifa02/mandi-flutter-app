import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:mandi/core/utils/sms_gateway_service.dart';
import 'package:mandi/data/models/sms_gateway_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Central state management and event-driven dispatcher for Mandi automated SMS.
class SmsProvider extends ChangeNotifier {
  String? _currentShopId;
  StreamSubscription<List<Map<String, dynamic>>>? _logsSub;

  SmsGatewaySettings _settings = const SmsGatewaySettings(shopId: '');
  List<SmsLog> _logs = [];

  bool _isLoadingSettings = false;
  bool _isSavingSettings = false;
  bool _isSending = false;

  String _searchQuery = '';
  String? _statusFilter; // null = all, 'sent', 'delivered', 'failed', 'pending'
  SmsEventType? _eventFilter;

  // Optional injected HTTP client for unit tests
  http.Client? httpClient;

  SmsProvider({http.Client? client}) : httpClient = client;

  // ── Getters ──────────────────────────────────────────────────────────────

  SmsGatewaySettings get settings => _settings;
  List<SmsLog> get allLogs => _logs;
  bool get isLoadingSettings => _isLoadingSettings;
  bool get isSavingSettings => _isSavingSettings;
  bool get isSending => _isSending;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  SmsEventType? get eventFilter => _eventFilter;

  SmsSummary get summary => SmsSummary.fromLogs(_logs);

  List<SmsLog> get filteredLogs {
    return _logs.where((log) {
      if (_statusFilter != null && _statusFilter!.isNotEmpty) {
        if (log.status.toDbString() != _statusFilter) {
          return false;
        }
      }

      if (_eventFilter != null) {
        if (log.eventType != _eventFilter) {
          return false;
        }
      }

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchPhone = log.recipientPhone.toLowerCase().contains(query);
        final matchName = log.recipientName.toLowerCase().contains(query);
        final matchBody = log.messageBody.toLowerCase().contains(query);
        final matchId = log.externalMessageId.toLowerCase().contains(query);
        if (!matchPhone && !matchName && !matchBody && !matchId) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ── Shop Life-Cycle Binding ──────────────────────────────────────────────

  void updateShop(String? shopId) {
    if (_currentShopId == shopId) return;
    _currentShopId = shopId;
    _logsSub?.cancel();
    _logs = [];

    if (shopId != null && shopId.isNotEmpty) {
      _settings = SmsGatewaySettings.defaultSettings(shopId);
      loadSettings();
      _subscribeLogs(shopId);
    } else {
      _settings = const SmsGatewaySettings(shopId: '');
      notifyListeners();
    }
  }

  void _subscribeLogs(String shopId) {
    _logsSub?.cancel();
    _logsSub = SupabaseService.smsLogsStream(shopId).listen((rows) {
      _logs = rows.map((r) => SmsLog.fromMap(r['id']?.toString() ?? '', r)).toList();
      notifyListeners();
    }, onError: (err) {
      debugPrint('[SmsProvider] Stream error: $err');
    });
  }

  // ── Settings CRUD ────────────────────────────────────────────────────────

  Future<void> loadSettings() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return;

    _isLoadingSettings = true;
    notifyListeners();

    try {
      final map = await SupabaseService.getSmsSettings(shopId);
      if (map != null) {
        _settings = SmsGatewaySettings.fromMap(map['id']?.toString() ?? '', map);
      } else {
        _settings = SmsGatewaySettings.defaultSettings(shopId);
      }
    } catch (e) {
      debugPrint('[SmsProvider] Error loading SMS settings: $e');
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings(SmsGatewaySettings newSettings) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    _isSavingSettings = true;
    notifyListeners();

    try {
      final data = newSettings.toMap();
      await SupabaseService.upsertSmsSettings(data);
      _settings = newSettings;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[SmsProvider] Error saving SMS settings: $e');
      return false;
    } finally {
      _isSavingSettings = false;
      notifyListeners();
    }
  }

  // ── Dispatch Methods ─────────────────────────────────────────────────────

  /// Sends an SMS message to a recipient, automatically logging to Supabase.
  Future<SmsDispatchResult> sendSms({
    required String recipientPhone,
    String recipientName = '',
    required String message,
    SmsEventType eventType = SmsEventType.manualTest,
    double estimatedCostPkr = 0.0,
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) {
      return const SmsDispatchResult(
        success: false,
        errorMessage: 'No active Mandi shop selected.',
      );
    }

    _isSending = true;
    notifyListeners();

    final partsInfo = SmsGatewayService.calculateParts(message);

    // 1. Initial pending audit log
    String? logId;
    try {
      logId = await SupabaseService.createSmsLog({
        'shop_id': shopId,
        'recipient_phone': recipientPhone,
        'recipient_name': recipientName,
        'message_body': message,
        'event_type': eventType.toDbString(),
        'provider': _settings.provider.toDbString(),
        'status': SmsDeliveryStatus.pending.toDbString(),
        'parts_count': partsInfo.partsCount,
        'cost_pkr': estimatedCostPkr,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SmsProvider] Failed to create pending SMS log: $e');
    }

    // 2. Dispatch to telecom gateway
    final result = await SmsGatewayService.dispatchSms(
      settings: _settings,
      toPhone: recipientPhone,
      message: message,
      client: httpClient,
    );

    // 3. Update audit log with outcome
    if (logId != null) {
      try {
        await SupabaseService.updateSmsLogStatus(
          logId: logId,
          shopId: shopId,
          status: result.success
              ? SmsDeliveryStatus.sent.toDbString()
              : SmsDeliveryStatus.failed.toDbString(),
          errorMessage: result.errorMessage,
          externalMessageId: result.messageId,
        );
      } catch (e) {
        debugPrint('[SmsProvider] Failed to update SMS log status: $e');
      }
    }

    _isSending = false;
    notifyListeners();
    return result;
  }

  /// Re-attempts sending a previously failed SMS message.
  Future<SmsDispatchResult> retrySms(SmsLog log) async {
    return sendSms(
      recipientPhone: log.recipientPhone,
      recipientName: log.recipientName,
      message: log.messageBody,
      eventType: log.eventType,
      estimatedCostPkr: log.costPkr,
    );
  }

  /// Sends a live test SMS verification message.
  Future<SmsDispatchResult> sendTestSms({
    required String recipientPhone,
    required String shopName,
  }) async {
    final timeStr = DateTime.now().toString().split('.').first;
    final message = 'Mandi ERP SMS Gateway Test: Connection Verified!\n'
        'Shop: $shopName\n'
        'Time: $timeStr\n'
        'Automated Mandi Billing System';

    return sendSms(
      recipientPhone: recipientPhone,
      recipientName: 'Test Recipient',
      message: message,
      eventType: SmsEventType.manualTest,
    );
  }

  // ── Filters & Search ─────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setEventFilter(SmsEventType? eventType) {
    _eventFilter = eventType;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _eventFilter = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _logsSub?.cancel();
    super.dispose();
  }
}
