/// Smart parser extracting Mandi amounts, maunds/bags, and party mentions
/// from verbal voice transcriptions (*منشی صوتی ڈکٹیشن پارسر*).
class VoiceDictationParserResult {
  final String rawText;
  final double parsedAmountPkr;
  final double parsedMaunds;
  final int parsedBags;
  final String detectedPartyName;
  final String detectedCommodity;
  final String suspectedAction; // 'payment_recovery', 'consignment_sale', 'general_memo'

  const VoiceDictationParserResult({
    required this.rawText,
    this.parsedAmountPkr = 0.0,
    this.parsedMaunds = 0.0,
    this.parsedBags = 0,
    this.detectedPartyName = '',
    this.detectedCommodity = '',
    this.suspectedAction = 'general_memo',
  });
}

class VoiceDictationParser {
  /// Parses spoken Urdu and English voice text into structured Mandi accounting fields.
  static VoiceDictationParserResult parse(String text) {
    if (text.trim().isEmpty) {
      return VoiceDictationParserResult(rawText: text);
    }

    final lower = text.toLowerCase();
    double amount = 0.0;
    double maunds = 0.0;
    int bags = 0;
    String party = '';
    String commodity = '';
    String action = 'general_memo';

    // 1. Detect Action Intent
    if (lower.contains('وصول') ||
        lower.contains('وصولی') ||
        lower.contains('جمع') ||
        lower.contains('received') ||
        lower.contains('payment')) {
      action = 'payment_recovery';
    } else if (lower.contains('بولی') ||
        lower.contains('نیلام') ||
        lower.contains('ڈھیری') ||
        lower.contains('آمد') ||
        lower.contains('auction') ||
        lower.contains('lot')) {
      action = 'consignment_sale';
    }

    // 2. Extract Numbers with RegEx
    // Match amounts like: "25000 روپے", "50,000", "Rs 15000", "20 ہزار"
    final thousandMatch = RegExp(r'(\d+)\s*(ہزار|hazar|thousand)').firstMatch(lower);
    if (thousandMatch != null) {
      final base = double.tryParse(thousandMatch.group(1) ?? '0') ?? 0.0;
      amount = base * 1000.0;
    }

    final lakhMatch = RegExp(r'(\d+)\s*(لاکھ|lakh)').firstMatch(lower);
    if (lakhMatch != null) {
      final base = double.tryParse(lakhMatch.group(1) ?? '0') ?? 0.0;
      amount = base * 100000.0;
    }

    if (amount == 0.0) {
      final rupeeMatch = RegExp(r'(rs\.?|روپے)?\s*(\d+[\d,]*)\s*(روپے|rupees|rs)?', caseSensitive: false)
          .allMatches(text);
      for (final m in rupeeMatch) {
        final rawNum = m.group(2)?.replaceAll(',', '') ?? '';
        final val = double.tryParse(rawNum) ?? 0.0;
        if (val >= 1000) {
          amount = val;
          break;
        }
      }
    }

    // Match Maunds like: "50 من", "120 maunds", "40 mann"
    final maundMatch = RegExp(r'(\d+[\d\.]*)\s*(من|maunds?|manns?|mann)', caseSensitive: false)
        .firstMatch(text);
    if (maundMatch != null) {
      maunds = double.tryParse(maundMatch.group(1) ?? '0') ?? 0.0;
    }

    // Match Bags like: "20 بوری", "100 bags", "50 تھیلے", "30 پیٹی"
    final bagMatch = RegExp(r'(\d+)\s*(بوری|بوریاں|bags?|تھیلا|تھیلے|پیٹی|crates?)', caseSensitive: false)
        .firstMatch(text);
    if (bagMatch != null) {
      bags = int.tryParse(bagMatch.group(1) ?? '0') ?? 0;
    }

    // 3. Detect Commodity
    if (lower.contains('گندم') || lower.contains('wheat')) {
      commodity = 'Wheat (گندم)';
    } else if (lower.contains('چاول') || lower.contains('rice') || lower.contains('دھان')) {
      commodity = 'Rice / Paddy (دھان)';
    } else if (lower.contains('مکئی') || lower.contains('maize') || lower.contains('corn')) {
      commodity = 'Maize (مکئی)';
    } else if (lower.contains('کپاس') || lower.contains('cotton') || lower.contains('پھٹی')) {
      commodity = 'Cotton (پھٹی)';
    } else if (lower.contains('کنو') || lower.contains('kinnu') || lower.contains('مالٹا')) {
      commodity = 'Kinnu (کنو)';
    } else if (lower.contains('آلو') || lower.contains('potato')) {
      commodity = 'Potato (آلو)';
    } else if (lower.contains('پیاز') || lower.contains('onion')) {
      commodity = 'Onion (پیاز)';
    }

    // 4. Detect Party Honorifics & Name clues
    final partyMatch = RegExp(
      r'(چوہدری|ملک|حاجی|میاں|سیٹھ|رانا|شیخ|سردار|خان|ڈاکٹر|صاحب)\s+([A-Za-z\u0600-\u06FF]+)',
      caseSensitive: false,
    ).firstMatch(text);

    if (partyMatch != null) {
      party = '${partyMatch.group(1)} ${partyMatch.group(2)}';
    }

    return VoiceDictationParserResult(
      rawText: text,
      parsedAmountPkr: amount,
      parsedMaunds: maunds,
      parsedBags: bags,
      detectedPartyName: party,
      detectedCommodity: commodity,
      suspectedAction: action,
    );
  }
}
