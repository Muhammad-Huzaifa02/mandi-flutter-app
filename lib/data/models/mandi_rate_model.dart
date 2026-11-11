// Domain models for Mandi Price Intelligence & Daily Rate Board Broadcast
// (*منڈی روزانہ ریٹ لسٹ اور مارکیٹ انڈیکس*).

import 'package:intl/intl.dart';

enum MarketTrend {
  bullish,
  bearish,
  stable;

  String toDbString() {
    switch (this) {
      case MarketTrend.bullish:
        return 'bullish';
      case MarketTrend.bearish:
        return 'bearish';
      case MarketTrend.stable:
        return 'stable';
    }
  }

  String get labelUrdu {
    switch (this) {
      case MarketTrend.bullish:
        return 'تیزی (Bullish ▲)';
      case MarketTrend.bearish:
        return 'مندی (Bearish ▼)';
      case MarketTrend.stable:
        return 'مستحکم (Stable ▬)';
    }
  }

  String get labelEnglish {
    switch (this) {
      case MarketTrend.bullish:
        return 'Bullish ▲';
      case MarketTrend.bearish:
        return 'Bearish ▼';
      case MarketTrend.stable:
        return 'Stable ▬';
    }
  }

  static MarketTrend fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'bullish':
        return MarketTrend.bullish;
      case 'bearish':
        return MarketTrend.bearish;
      case 'stable':
      default:
        return MarketTrend.stable;
    }
  }
}

class MandiCommodityRate {
  final String id;
  final String shopId;
  final String commodityName;
  final String variety;
  final DateTime rateDate;
  final double minRatePerMaund;
  final double maxRatePerMaund;
  final double modalRatePerMaund;
  final double previousModalRate;
  final double priceChangePkr;
  final double priceChangePercent;
  final MarketTrend marketTrend;
  final double arrivalsMaunds;
  final String qualityGrade;
  final String notes;
  final DateTime? broadcastSentAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MandiCommodityRate({
    this.id = '',
    required this.shopId,
    required this.commodityName,
    this.variety = '',
    required this.rateDate,
    required this.minRatePerMaund,
    required this.maxRatePerMaund,
    required this.modalRatePerMaund,
    this.previousModalRate = 0.0,
    this.priceChangePkr = 0.0,
    this.priceChangePercent = 0.0,
    this.marketTrend = MarketTrend.stable,
    this.arrivalsMaunds = 0.0,
    this.qualityGrade = 'Grade A',
    this.notes = '',
    this.broadcastSentAt,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  /// Computed price per 1 KG based on modal rate per Maund (40 KG).
  double get pricePerKgPkr => modalRatePerMaund > 0 ? (modalRatePerMaund / 40.0) : 0.0;

  /// Helper to calculate change and percentage based on previous rate.
  static Map<String, dynamic> computeTrendMetrics(double currentModal, double previousModal) {
    if (previousModal <= 0) {
      return {
        'changePkr': 0.0,
        'changePercent': 0.0,
        'trend': MarketTrend.stable,
      };
    }
    final change = currentModal - previousModal;
    final percent = (change / previousModal) * 100.0;
    final trend = change > 0
        ? MarketTrend.bullish
        : change < 0
            ? MarketTrend.bearish
            : MarketTrend.stable;

    return {
      'changePkr': change,
      'changePercent': percent,
      'trend': trend,
    };
  }

  factory MandiCommodityRate.fromMap(String id, Map<String, dynamic> map) {
    return MandiCommodityRate(
      id: id,
      shopId: map['shop_id']?.toString() ?? '',
      commodityName: map['commodity_name']?.toString() ?? '',
      variety: map['variety']?.toString() ?? '',
      rateDate: map['rate_date'] != null
          ? DateTime.tryParse(map['rate_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      minRatePerMaund: (map['min_rate_per_maund'] as num?)?.toDouble() ?? 0.0,
      maxRatePerMaund: (map['max_rate_per_maund'] as num?)?.toDouble() ?? 0.0,
      modalRatePerMaund: (map['modal_rate_per_maund'] as num?)?.toDouble() ?? 0.0,
      previousModalRate: (map['previous_modal_rate'] as num?)?.toDouble() ?? 0.0,
      priceChangePkr: (map['price_change_pkr'] as num?)?.toDouble() ?? 0.0,
      priceChangePercent: (map['price_change_percent'] as num?)?.toDouble() ?? 0.0,
      marketTrend: MarketTrend.fromString(map['market_trend']?.toString() ?? 'stable'),
      arrivalsMaunds: (map['arrivals_maunds'] as num?)?.toDouble() ?? 0.0,
      qualityGrade: map['quality_grade']?.toString() ?? 'Grade A',
      notes: map['notes']?.toString() ?? '',
      broadcastSentAt: map['broadcast_sent_at'] != null
          ? DateTime.tryParse(map['broadcast_sent_at'].toString())
          : null,
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
      'commodity_name': commodityName,
      'variety': variety,
      'rate_date': DateFormat('yyyy-MM-dd').format(rateDate),
      'min_rate_per_maund': minRatePerMaund,
      'max_rate_per_maund': maxRatePerMaund,
      'modal_rate_per_maund': modalRatePerMaund,
      'previous_modal_rate': previousModalRate,
      'price_change_pkr': priceChangePkr,
      'price_change_percent': priceChangePercent,
      'market_trend': marketTrend.toDbString(),
      'arrivals_maunds': arrivalsMaunds,
      'quality_grade': qualityGrade,
      'notes': notes,
      'broadcast_sent_at': broadcastSentAt?.toIso8601String(),
    };
  }

  MandiCommodityRate copyWith({
    String? id,
    String? shopId,
    String? commodityName,
    String? variety,
    DateTime? rateDate,
    double? minRatePerMaund,
    double? maxRatePerMaund,
    double? modalRatePerMaund,
    double? previousModalRate,
    double? priceChangePkr,
    double? priceChangePercent,
    MarketTrend? marketTrend,
    double? arrivalsMaunds,
    String? qualityGrade,
    String? notes,
    DateTime? broadcastSentAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MandiCommodityRate(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      commodityName: commodityName ?? this.commodityName,
      variety: variety ?? this.variety,
      rateDate: rateDate ?? this.rateDate,
      minRatePerMaund: minRatePerMaund ?? this.minRatePerMaund,
      maxRatePerMaund: maxRatePerMaund ?? this.maxRatePerMaund,
      modalRatePerMaund: modalRatePerMaund ?? this.modalRatePerMaund,
      previousModalRate: previousModalRate ?? this.previousModalRate,
      priceChangePkr: priceChangePkr ?? this.priceChangePkr,
      priceChangePercent: priceChangePercent ?? this.priceChangePercent,
      marketTrend: marketTrend ?? this.marketTrend,
      arrivalsMaunds: arrivalsMaunds ?? this.arrivalsMaunds,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      notes: notes ?? this.notes,
      broadcastSentAt: broadcastSentAt ?? this.broadcastSentAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
