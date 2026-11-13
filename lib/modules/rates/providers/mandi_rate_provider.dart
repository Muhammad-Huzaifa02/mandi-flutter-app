import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:mandi/data/models/mandi_rate_model.dart';
import 'package:mandi/data/services/supabase_service.dart';

/// Central provider managing Daily Mandi Commodity Rates, Price Trend calculations,
/// and Broadcast dispatch to farmers and buyers via WhatsApp and SMS.
class MandiRateProvider extends ChangeNotifier {
  String? _currentShopId;

  List<MandiCommodityRate> _rates = [];
  bool _isLoading = false;
  StreamSubscription? _ratesSub;

  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  MarketTrend? _trendFilter;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<MandiCommodityRate> get rates => _rates;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  String get searchQuery => _searchQuery;
  MarketTrend? get trendFilter => _trendFilter;

  List<MandiCommodityRate> get filteredRates {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _rates.where((r) {
      final rDateStr = DateFormat('yyyy-MM-dd').format(r.rateDate);
      if (rDateStr != dateStr) {
        return false;
      }
      if (_trendFilter != null && r.marketTrend != _trendFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchCommodity = r.commodityName.toLowerCase().contains(q);
        final matchVariety = r.variety.toLowerCase().contains(q);
        if (!matchCommodity && !matchVariety) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ── Shop Life-cycle ──────────────────────────────────────────────────────

  void updateShop(String? shopId) {
    if (_currentShopId != shopId) {
      _currentShopId = shopId;
      _cancelSubscription();
      if (shopId != null && shopId.isNotEmpty) {
        _subscribeToRates(shopId);
        loadRates();
      } else {
        _rates = [];
        notifyListeners();
      }
    }
  }

  void _subscribeToRates(String shopId) {
    _ratesSub = SupabaseService.mandiRatesStream(shopId).listen(
      (rows) {
        _rates = rows
            .map((r) => MandiCommodityRate.fromMap(r['id']?.toString() ?? '', r))
            .toList();
        notifyListeners();
      },
      onError: (err) => debugPrint('[MandiRateProvider] Stream error: $err'),
    );
  }

  void _cancelSubscription() {
    _ratesSub?.cancel();
    _ratesSub = null;
  }

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }

  // ── CRUD Operations ──────────────────────────────────────────────────────

  Future<void> loadRates() async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.getMandiRates(shopId);
      _rates = rows
          .map((r) => MandiCommodityRate.fromMap(r['id']?.toString() ?? '', r))
          .toList();
    } catch (e) {
      debugPrint('[MandiRateProvider] Error loading rates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordCommodityRate({
    required String commodityName,
    String variety = '',
    required DateTime rateDate,
    required double minRatePerMaund,
    required double maxRatePerMaund,
    required double modalRatePerMaund,
    double previousModalRate = 0.0,
    double arrivalsMaunds = 0.0,
    String qualityGrade = 'Grade A',
    String notes = '',
  }) async {
    final shopId = _currentShopId;
    if (shopId == null || shopId.isEmpty) return false;

    // Automatically compute trend metrics
    final trendMap = MandiCommodityRate.computeTrendMetrics(modalRatePerMaund, previousModalRate);
    final changePkr = trendMap['changePkr'] as double;
    final changePercent = trendMap['changePercent'] as double;
    final trend = trendMap['trend'] as MarketTrend;

    try {
      final data = {
        'shop_id': shopId,
        'commodity_name': commodityName,
        'variety': variety,
        'rate_date': DateFormat('yyyy-MM-dd').format(rateDate),
        'min_rate_per_maund': minRatePerMaund,
        'max_rate_per_maund': maxRatePerMaund,
        'modal_rate_per_maund': modalRatePerMaund,
        'previous_modal_rate': previousModalRate,
        'price_change_pkr': changePkr,
        'price_change_percent': changePercent,
        'market_trend': trend.toDbString(),
        'arrivals_maunds': arrivalsMaunds,
        'quality_grade': qualityGrade,
        'notes': notes,
      };

      await SupabaseService.createMandiRate(data);
      await loadRates();
      return true;
    } catch (e) {
      debugPrint('[MandiRateProvider] Error recording commodity rate: $e');
      return false;
    }
  }

  /// Generates formatted text message for WhatsApp and SMS broadcast.
  String generateBroadcastMessage({
    required String shopName,
    required String city,
    required DateTime date,
    bool isUrdu = false,
  }) {
    final dateStr = DateFormat('dd MMMM yyyy').format(date);
    final buffer = StringBuffer();

    if (isUrdu) {
      buffer.writeln('🌾 *${shopName.toUpperCase()} — روزانہ منڈی ریٹ بورڈ*');
      if (city.isNotEmpty) buffer.writeln('📍 غلہ و سبزی منڈی: $city');
      buffer.writeln('📅 تاریخ: $dateStr');
      buffer.writeln('────────────────────────');

      final dayRates = filteredRates;
      if (dayRates.isEmpty) {
        buffer.writeln('آج کے ریٹس ابھی ریکارڈ نہیں کیے گئے۔');
      } else {
        for (final r in dayRates) {
          final symbol = r.marketTrend == MarketTrend.bullish
              ? '▲ تیزی'
              : r.marketTrend == MarketTrend.bearish
                  ? '▼ مندی'
                  : '▬ مستحکم';
          buffer.writeln('• *${r.commodityName}* ${r.variety.isNotEmpty ? "(${r.variety})" : ""}');
          buffer.writeln('  ریٹ فی من (40 کلو): Rs. ${r.modalRatePerMaund.toStringAsFixed(0)} ($symbol)');
          buffer.writeln('  رینج: ${r.minRatePerMaund.toStringAsFixed(0)} - ${r.maxRatePerMaund.toStringAsFixed(0)}');
          if (r.arrivalsMaunds > 0) {
            buffer.writeln('  آمد: ${r.arrivalsMaunds.toStringAsFixed(0)} من');
          }
          buffer.writeln('');
        }
      }

      buffer.writeln('────────────────────────');
      buffer.writeln('📞 برائے رابطہ و مال ترسیل: منڈی دفتر');
      buffer.writeln('منڈی کمیشن شاپ سافٹ ویئر کے ذریعے جاری کردہ');
    } else {
      buffer.writeln('🌾 *${shopName.toUpperCase()} — Daily Mandi Rate Board*');
      if (city.isNotEmpty) buffer.writeln('📍 Grain Market: $city');
      buffer.writeln('📅 Date: $dateStr');
      buffer.writeln('────────────────────────');

      final dayRates = filteredRates;
      if (dayRates.isEmpty) {
        buffer.writeln('Rates have not been recorded yet for today.');
      } else {
        for (final r in dayRates) {
          final symbol = r.marketTrend == MarketTrend.bullish
              ? '▲ Bullish'
              : r.marketTrend == MarketTrend.bearish
                  ? '▼ Bearish'
                  : '▬ Stable';
          buffer.writeln('• *${r.commodityName}* ${r.variety.isNotEmpty ? "(${r.variety})" : ""}');
          buffer.writeln('  Rate per Maund (40 KG): Rs. ${r.modalRatePerMaund.toStringAsFixed(0)} ($symbol)');
          buffer.writeln('  Range: ${r.minRatePerMaund.toStringAsFixed(0)} - ${r.maxRatePerMaund.toStringAsFixed(0)}');
          if (r.arrivalsMaunds > 0) {
            buffer.writeln('  Arrivals: ${r.arrivalsMaunds.toStringAsFixed(0)} Maunds');
          }
          buffer.writeln('');
        }
      }

      buffer.writeln('────────────────────────');
      buffer.writeln('📞 Contact & Consignments: Mandi Office');
      buffer.writeln('Issued via Mandi Commission Shop Software');
    }

    return buffer.toString();
  }

  // ── Filters ──────────────────────────────────────────────────────────────

  void setSelectedDate(DateTime d) {
    _selectedDate = d;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setTrendFilter(MarketTrend? t) {
    _trendFilter = t;
    notifyListeners();
  }

  void resetFilters() {
    _selectedDate = DateTime.now();
    _searchQuery = '';
    _trendFilter = null;
    notifyListeners();
  }
}
