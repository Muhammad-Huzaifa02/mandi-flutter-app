import 'dart:async';
import 'package:flutter/material.dart';

import 'package:mandi/data/models/bank_account_model.dart';
import 'package:mandi/data/models/cheque_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Provider managing Bank Accounts, Cheques, and Post-Dated Cheque (PDC) clearance
/// for the currently active shop context.
class BankProvider extends ChangeNotifier {
  StreamSubscription? _bankSub;
  StreamSubscription? _chequeSub;
  String? _shopId;

  List<BankAccount> _bankAccounts = [];
  List<Cheque> _cheques = [];
  bool _isLoading = true;

  List<BankAccount> get bankAccounts => List.unmodifiable(_bankAccounts);
  List<Cheque> get cheques => List.unmodifiable(_cheques);
  bool get isLoading => _isLoading;

  /// Fast access to Cheque summary KPI metrics
  ChequeSummary get summary => ChequeSummary.fromCheques(_cheques);

  /// Total liquid balance across all active bank accounts (PKR)
  double get totalBankBalance => _bankAccounts
      .where((a) => a.isActive)
      .fold<double>(0.0, (sum, a) => sum + a.currentBalance);

  /// In-hand cheques awaiting deposit/clearance
  List<Cheque> get inHandCheques =>
      _cheques.where((c) => c.status == ChequeStatus.inHand).toList();

  /// Cheques due for bank deposit today
  List<Cheque> get dueTodayCheques =>
      _cheques.where((c) => c.status == ChequeStatus.inHand && c.isDueToday).toList();

  /// Cheques deposited and under bank clearing
  List<Cheque> get depositedCheques =>
      _cheques.where((c) => c.status == ChequeStatus.deposited).toList();

  /// Successfully cleared cheques
  List<Cheque> get clearedCheques =>
      _cheques.where((c) => c.status == ChequeStatus.cleared).toList();

  /// Bounced / dishonored cheques needing immediate attention
  List<Cheque> get bouncedCheques =>
      _cheques.where((c) => c.status == ChequeStatus.bounced).toList();

  /// Called automatically by ProxyProvider when active shop changes
  void updateShop(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _bankSub?.cancel();
    _chequeSub?.cancel();
    _bankAccounts = [];
    _cheques = [];

    if (shopId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _bankSub = SupabaseService.bankAccountsStream(shopId).listen((rows) {
      _bankAccounts = rows
          .map((r) => BankAccount.fromMap(r['id'] as String, r))
          .toList();
      _mapBankAccountNamesToCheques();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });

    _chequeSub = SupabaseService.chequesStream(shopId).listen((rows) {
      _cheques = rows
          .map((r) => Cheque.fromMap(r['id'] as String, r))
          .toList();
      _mapBankAccountNamesToCheques();
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  void _mapBankAccountNamesToCheques() {
    if (_bankAccounts.isEmpty || _cheques.isEmpty) return;
    final bankMap = {for (final b in _bankAccounts) b.id: b.displayName};
    _cheques = _cheques.map((c) {
      if (c.targetBankAccountId != null &&
          bankMap.containsKey(c.targetBankAccountId)) {
        return c.copyWith(
          targetBankAccountName: bankMap[c.targetBankAccountId],
        );
      }
      return c;
    }).toList();
  }

  List<Cheque> filterCheques({
    ChequeStatus? status,
    ChequeType? type,
    bool onlyDueToday = false,
    bool onlyOverdue = false,
    String query = '',
  }) {
    return _cheques.where((c) {
      if (status != null && c.status != status) return false;
      if (type != null && c.type != type) return false;
      if (onlyDueToday && !c.isDueToday) return false;
      if (onlyOverdue && !c.isOverdue) return false;
      if (query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        final matchesNum = c.chequeNumber.toLowerCase().contains(q);
        final matchesParty = c.partyName.toLowerCase().contains(q);
        final matchesBank = c.bankName.toLowerCase().contains(q);
        if (!matchesNum && !matchesParty && !matchesBank) return false;
      }
      return true;
    }).toList();
  }

  // ── Bank Account Actions ──────────────────────────────────────────────────

  Future<void> addBankAccount(BankAccount account) async {
    if (_shopId == null) return;
    await SupabaseService.addBankAccount(account.toMap());
  }

  Future<void> updateBankAccount(BankAccount account) async {
    if (_shopId == null) return;
    await SupabaseService.updateBankAccount(
      id: account.id,
      shopId: _shopId!,
      data: account.toMap(),
    );
  }

  Future<void> deleteBankAccount(String id) async {
    if (_shopId == null) return;
    await SupabaseService.deleteBankAccount(id: id, shopId: _shopId!);
  }

  // ── Cheque Actions ────────────────────────────────────────────────────────

  Future<void> addCheque(Cheque cheque) async {
    if (_shopId == null) return;
    await SupabaseService.addCheque(cheque.toMap());
  }

  Future<void> updateCheque(Cheque cheque) async {
    if (_shopId == null) return;
    await SupabaseService.updateCheque(
      id: cheque.id,
      shopId: _shopId!,
      data: cheque.toMap(),
    );
  }

  Future<void> markAsDeposited({
    required String chequeId,
    required String targetBankAccountId,
    DateTime? depositDate,
  }) async {
    if (_shopId == null) return;
    await SupabaseService.markChequeDeposited(
      id: chequeId,
      shopId: _shopId!,
      targetBankAccountId: targetBankAccountId,
      depositDate: depositDate,
    );
  }

  Future<void> markAsCleared({
    required String chequeId,
    DateTime? clearanceDate,
  }) async {
    if (_shopId == null) return;
    await SupabaseService.markChequeCleared(
      id: chequeId,
      shopId: _shopId!,
      clearanceDate: clearanceDate,
    );
  }

  Future<void> markAsBounced({
    required String chequeId,
    required String bounceReason,
  }) async {
    if (_shopId == null) return;
    await SupabaseService.markChequeBounced(
      id: chequeId,
      shopId: _shopId!,
      bounceReason: bounceReason,
    );
  }

  @override
  void dispose() {
    _bankSub?.cancel();
    _chequeSub?.cancel();
    super.dispose();
  }
}
