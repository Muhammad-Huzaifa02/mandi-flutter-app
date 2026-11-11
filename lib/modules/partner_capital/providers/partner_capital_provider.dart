// Provider for Multi-Partner Mandi Shop Profit Sharing & Drawings
// (*شراکت داری اور منافع تقسیم کھاتہ*).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mandi/data/models/partner_capital_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

class PartnerCapitalProvider extends ChangeNotifier {
  String? _shopId;
  List<ShopPartnerModel> _partners = [];
  List<PartnerTransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _partnersSub;
  StreamSubscription? _transactionsSub;

  String? get shopId => _shopId;
  List<ShopPartnerModel> get partners => List.unmodifiable(_partners);
  List<PartnerTransactionModel> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalShopCapital =>
      _partners.fold(0.0, (sum, p) => sum + p.currentCapital);

  double get totalShopDrawings =>
      _partners.fold(0.0, (sum, p) => sum + p.totalDrawings);

  double get totalProfitRatio =>
      _partners.fold(0.0, (sum, p) => sum + p.profitSharingRatio);

  bool get isRatioConfigValid => (totalProfitRatio - 100.0).abs() < 0.01;

  void updateShop(String? shopId) {
    if (_shopId != shopId) {
      _shopId = shopId;
      _partnersSub?.cancel();
      _transactionsSub?.cancel();
      _partners = [];
      _transactions = [];
      if (_shopId != null && _shopId!.isNotEmpty) {
        _subscribeToData();
      } else {
        notifyListeners();
      }
    }
  }

  void _subscribeToData() {
    if (_shopId == null) return;
    _isLoading = true;
    notifyListeners();

    _partnersSub = SupabaseService.shopPartnersStream(_shopId!).listen(
      (rows) {
        _partners = rows.map((r) => ShopPartnerModel.fromJson(r)).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _transactionsSub = SupabaseService.partnerTransactionsStream(_shopId!).listen(
      (rows) {
        _transactions = rows.map((r) => PartnerTransactionModel.fromJson(r)).toList();
        notifyListeners();
      },
    );
  }

  Future<bool> addPartner({
    required String name,
    String? cnic,
    String? phone,
    required double profitSharingRatio,
    required double openingCapital,
    String? notes,
  }) async {
    if (_shopId == null) return false;

    final now = DateTime.now();
    final data = <String, dynamic>{
      'shop_id': _shopId,
      'name': name.trim(),
      'cnic': cnic?.trim(),
      'phone': phone?.trim(),
      'profit_sharing_ratio': profitSharingRatio,
      'opening_capital': openingCapital,
      'current_capital': openingCapital,
      'total_drawings': 0.0,
      'is_active': true,
      'notes': notes?.trim(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    try {
      await SupabaseService.createShopPartner(data);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordDrawing({
    required String partnerId,
    required double amount,
    String paymentMethod = 'cash',
    String? reference,
    String? description,
    required DateTime transactionDate,
  }) async {
    if (_shopId == null) return false;

    try {
      final partner = _partners.firstWhere((p) => p.id == partnerId);
      final newCapital = partner.currentCapital - amount;
      final newDrawings = partner.totalDrawings + amount;

      final txnData = <String, dynamic>{
        'shop_id': _shopId,
        'partner_id': partnerId,
        'type': PartnerTransactionType.drawing.toDbString(),
        'amount': amount,
        'payment_method': paymentMethod,
        'reference': reference?.trim(),
        'description': description?.trim() ?? 'Monthly Personal Drawing / ذاتی خرچ',
        'transaction_date': transactionDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.createPartnerTransaction(
        txnData,
        partnerNewCapital: newCapital,
        partnerNewDrawings: newDrawings,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordCapitalInjection({
    required String partnerId,
    required double amount,
    String paymentMethod = 'bank_transfer',
    String? reference,
    String? description,
    required DateTime transactionDate,
  }) async {
    if (_shopId == null) return false;

    try {
      final partner = _partners.firstWhere((p) => p.id == partnerId);
      final newCapital = partner.currentCapital + amount;

      final txnData = <String, dynamic>{
        'shop_id': _shopId,
        'partner_id': partnerId,
        'type': PartnerTransactionType.capitalInjection.toDbString(),
        'amount': amount,
        'payment_method': paymentMethod,
        'reference': reference?.trim(),
        'description': description?.trim() ?? 'Capital Injection / تازہ سرمایہ',
        'transaction_date': transactionDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.createPartnerTransaction(
        txnData,
        partnerNewCapital: newCapital,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> distributeNetProfit({
    required double totalNetProfit,
    String? periodDescription,
    required DateTime distributionDate,
  }) async {
    if (_shopId == null || totalNetProfit <= 0 || _partners.isEmpty) return false;

    try {
      for (final partner in _partners.where((p) => p.isActive)) {
        final sharePercent = partner.profitSharingRatio / 100.0;
        final allocatedProfit = totalNetProfit * sharePercent;
        final newCapital = partner.currentCapital + allocatedProfit;

        final txnData = <String, dynamic>{
          'shop_id': _shopId,
          'partner_id': partner.id,
          'type': PartnerTransactionType.profitDistribution.toDbString(),
          'amount': allocatedProfit,
          'payment_method': 'cash',
          'description': periodDescription ??
              'Net Commission Profit Distribution (${partner.profitRatioFormatted})',
          'transaction_date': distributionDate.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        };

        await SupabaseService.createPartnerTransaction(
          txnData,
          partnerNewCapital: newCapital,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _partnersSub?.cancel();
    _transactionsSub?.cancel();
    super.dispose();
  }
}
