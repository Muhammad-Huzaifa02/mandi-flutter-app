import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:mandi/data/models/weighbridge_ticket_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Provider managing real-time Mandi Weighbridge tickets and scale operations.
class WeighbridgeProvider extends ChangeNotifier {
  String? _shopId;

  List<WeighbridgeTicket> _tickets = [];
  WeighbridgeSummary _summary = const WeighbridgeSummary();
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // 'all', 'awaitingTare', 'completed'
  String _searchQuery = '';

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  WeighbridgeProvider({String? shopId}) : _shopId = shopId {
    if (_shopId != null && _shopId!.isNotEmpty) {
      _initStream();
    } else {
      _isLoading = false;
    }
  }

  String? get shopId => _shopId;

  void updateShop(String? newShopId) {
    if (newShopId == _shopId) return;
    _shopId = newShopId;
    _subscription?.cancel();
    _tickets = [];
    _summary = const WeighbridgeSummary();
    if (_shopId != null && _shopId!.isNotEmpty) {
      _initStream();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<WeighbridgeTicket> get tickets => _tickets;
  WeighbridgeSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;
  String get searchQuery => _searchQuery;

  List<WeighbridgeTicket> get filteredTickets {
    return _tickets.where((t) {
      // Filter by status
      if (_filter == 'awaitingTare' && !t.isAwaitingTare) return false;
      if (_filter == 'completed' && t.status != WeighbridgeStatus.completed) return false;

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesNum = t.ticketNumber.toLowerCase().contains(q);
        final matchesVehicle = t.vehicleNumber.toLowerCase().contains(q);
        final matchesParty = t.partyName.toLowerCase().contains(q);
        final matchesCommodity = t.commodityName.toLowerCase().contains(q);
        final matchesDriver = t.driverName.toLowerCase().contains(q);
        if (!matchesNum && !matchesVehicle && !matchesParty && !matchesCommodity && !matchesDriver) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void setFilter(String newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q.trim();
    notifyListeners();
  }

  void _initStream() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription =
        SupabaseService.weighbridgeTicketsStream(shopId!).listen(
      (data) {
        _tickets = data
            .map((map) => WeighbridgeTicket.fromMap(map['id'] as String, map))
            .toList();
        _summary = WeighbridgeSummary.fromTickets(_tickets);
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        _error = err.toString();
        notifyListeners();
      },
    );
  }

  /// Generates the next sequential ticket number for the shop: e.g. WB-2411-001
  String generateNextTicketNumber() {
    final now = DateTime.now();
    final prefix = 'WB-${DateFormat('yyMM').format(now)}';
    final existingCount = _tickets.length;
    final seq = (existingCount + 1).toString().padLeft(3, '0');
    return '$prefix-$seq';
  }

  /// Create a new 1st Weight (Gross) Weighbridge Ticket.
  Future<String> createGrossTicket({
    required String vehicleNumber,
    VehicleType vehicleType = VehicleType.trolley,
    String driverName = '',
    String driverPhone = '',
    String partyName = '',
    WeighbridgePartyType partyType = WeighbridgePartyType.farmer,
    String? partyId,
    String commodityName = '',
    required double grossWeightKg,
    int bagCount = 0,
    double kandaFee = 0.0,
    WeighbridgeFeePaidBy feePaidBy = WeighbridgeFeePaidBy.farmer,
    String operatorName = '',
    String? consignmentLotId,
    String notes = '',
  }) async {
    if (shopId == null) throw Exception('No active shop context');

    final ticketNumber = generateNextTicketNumber();
    final now = DateTime.now();

    final ticket = WeighbridgeTicket(
      id: '',
      shopId: shopId!,
      ticketNumber: ticketNumber,
      vehicleNumber: vehicleNumber.trim().toUpperCase(),
      vehicleType: vehicleType,
      driverName: driverName.trim(),
      driverPhone: driverPhone.trim(),
      partyName: partyName.trim(),
      partyType: partyType,
      partyId: partyId,
      commodityName: commodityName.trim(),
      grossWeightKg: grossWeightKg,
      tareWeightKg: 0.0,
      netWeightKg: 0.0,
      deductionKg: 0.0,
      finalWeightKg: 0.0,
      bagCount: bagCount,
      kandaFee: kandaFee,
      feePaidBy: feePaidBy,
      status: WeighbridgeStatus.grossRecorded,
      grossWeighedAt: now,
      operatorName: operatorName.trim(),
      consignmentLotId: consignmentLotId,
      notes: notes.trim(),
    );

    return await SupabaseService.createWeighbridgeTicket(ticket.toMap());
  }

  /// Record 2nd Weight (Tare) when vehicle returns empty, computing Net and Final weight.
  Future<void> recordTareWeight({
    required String ticketId,
    required double grossWeightKg,
    required double tareWeightKg,
    double deductionKg = 0.0,
    String deductionReason = '',
  }) async {
    if (shopId == null) throw Exception('No active shop context');
    if (tareWeightKg >= grossWeightKg) {
      throw Exception('Tare weight cannot be greater than or equal to Gross weight');
    }

    final netWeightKg = grossWeightKg - tareWeightKg;
    final finalWeightKg = (netWeightKg - deductionKg).clamp(0.0, double.infinity);

    await SupabaseService.recordTareWeight(
      id: ticketId,
      shopId: shopId!,
      tareWeightKg: tareWeightKg,
      deductionKg: deductionKg,
      deductionReason: deductionReason.trim(),
      finalWeightKg: finalWeightKg,
      netWeightKg: netWeightKg,
    );
  }

  /// Cancel a ticket
  Future<void> cancelTicket(String ticketId) async {
    if (shopId == null) throw Exception('No active shop context');
    await SupabaseService.cancelWeighbridgeTicket(
      id: ticketId,
      shopId: shopId!,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
