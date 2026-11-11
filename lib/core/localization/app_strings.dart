import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/theme/locale_provider.dart';

/// Centralized localization dictionary for pure English and pure Urdu.
/// When the user chooses English, the entire app renders in pure English.
/// When the user chooses Urdu, the entire app renders in pure Urdu.
class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    // Top Bar & Common
    'app_title': {'en': 'Mandi', 'ur': 'غلہ منڈی'},
    'switch_shop': {'en': 'Switch Shop', 'ur': 'دکان تبدیل کریں'},
    'switch_mandi_shop': {'en': 'Switch Mandi Shop', 'ur': 'منڈی دکان تبدیل کریں'},
    'no_other_shops': {'en': 'No other shops available for this account.', 'ur': 'اس اکاؤنٹ کے لیے کوئی دوسری دکان دستیاب نہیں ہے۔'},
    'manage': {'en': 'Manage', 'ur': 'انتظام و کھاتہ جات'},
    'welcome': {'en': 'Welcome', 'ur': 'خوش آمدید'},
    'role': {'en': 'Role', 'ur': 'عہدہ'},
    'cancel': {'en': 'Cancel', 'ur': 'منسوخ'},
    'save_changes': {'en': 'Save Changes', 'ur': 'تبدیلیاں محفوظ کریں'},
    'logout': {'en': 'Logout', 'ur': 'لاگ آؤٹ'},
    'required': {'en': 'Required', 'ur': 'لازمی فیلڈ'},
    'reset': {'en': 'Reset', 'ur': 'ری سیٹ'},

    // Manage Hub Modules
    'employees': {'en': 'Employees', 'ur': 'ملازمین'},
    'customers': {'en': 'Customers', 'ur': 'گاہک (خریدار)'},
    'suppliers': {'en': 'Suppliers', 'ur': 'سپلائرز (زمیندار)'},
    'purchases': {'en': 'Purchases', 'ur': 'خریداری'},
    'consignments': {'en': 'Consignments', 'ur': 'امانت و آڑھت'},
    'products': {'en': 'Products', 'ur': 'اجناس و اشیاء'},
    'invoices': {'en': 'Invoices', 'ur': 'بل و انوائس'},
    'expenses': {'en': 'Expenses', 'ur': 'اخراجات'},
    'payments': {'en': 'Payments', 'ur': 'ادائیگیاں'},
    'recovery': {'en': 'Payment Recovery', 'ur': 'وصولی یاددہانی'},
    'reports': {'en': 'Reports', 'ur': 'رپورٹس'},
    'roznamcha': {'en': 'Daily Roznamcha', 'ur': 'روزنامچہ کھاتہ'},
    'bank_and_cheques': {'en': 'Bank & Cheques', 'ur': 'بینک و چیکس'},
    'godown_and_bardana': {'en': 'Godown & Bardana', 'ur': 'گودام و باردانہ'},
    'weighbridge': {'en': 'Weighbridge (Kanda)', 'ur': 'دھرم کنڈا'},
    'farmer_advances': {'en': 'Farmer Advances', 'ur': 'زمیندار پیشگی کھاتہ'},
    'border_trade': {'en': 'Border Trade', 'ur': 'سرحدی تجارتی مال'},
    'sms_gateway': {'en': 'SMS Gateway', 'ur': 'ایس ایم ایس گیٹ وے'},
    'multi_shop': {'en': 'Multi-Shop Hub', 'ur': 'مشترکہ دکان کھاتہ'},
    'voice_notes': {'en': 'Voice Notes', 'ur': 'صوتی نوٹس'},
    'loyalty_and_rebates': {'en': 'Loyalty & Rebates', 'ur': 'رعایت و بونس'},
    'rate_board': {'en': 'Mandi Rate Board', 'ur': 'ریٹ لسٹ بورڈ'},
    'staff_payroll': {'en': 'Staff Payroll', 'ur': 'تنخواہ و حاضری'},
    'fleet_and_bilty': {'en': 'Fleet & Logistics', 'ur': 'ٹرانسپورٹ و بلٹی'},
    'quality_lab': {'en': 'Quality Lab', 'ur': 'کوالٹی ٹیسٹنگ لیب'},
    'barcode_and_qr': {'en': 'Barcode & QR Labels', 'ur': 'بارکوڈ و کیو آر'},
    'offline_sync': {'en': 'Offline Sync', 'ur': 'آف لائن ڈیٹا سنک'},
    'rate_broadcast': {'en': 'Rate Broadcast', 'ur': 'ریٹ براڈکاسٹ'},
    'live_auction': {'en': 'Live Auction Floor', 'ur': 'لائیو نیلامی بولی'},
    'gate_pass': {'en': 'Gate Pass & Tokens', 'ur': 'گیٹ پاس و ٹوکن'},
    'farmer_passbook': {'en': 'Farmer Passbook', 'ur': 'زمیندار پاس بک'},
    'shop_partners': {'en': 'Shop Partners', 'ur': 'شراکت داری کھاتہ'},
    'warehouse_2d_grid': {'en': 'Warehouse 2D Grid', 'ur': 'گودام تصویری نقشہ'},
    'roles': {'en': 'Roles & Permissions', 'ur': 'اختیارات و رولز'},
    'audit_logs': {'en': 'Audit Logs', 'ur': 'سسٹم لاگز'},
    'settings': {'en': 'Shop Settings', 'ur': 'ترتیبات'},

    // Live Auction Screen
    'auction_terminal_title': {'en': 'Live Auction Terminal', 'ur': 'لائیو نیلامی بولی اسکرین'},
    'new_heap': {'en': 'New Heap (Boli)', 'ur': 'نئی ڈھیری شروع کریں'},
    'maunds': {'en': 'Maunds', 'ur': 'من'},
    'bags': {'en': 'Bags', 'ur': 'بوریاں'},
    'per_maund': {'en': 'per Maund', 'ur': 'فی من'},
    'current_highest_bid': {'en': 'CURRENT HIGHEST BID', 'ur': 'موجودہ بلند ترین بولی'},
    'auction_sold': {'en': 'SOLD! AUCTION CLOSED', 'ur': 'بولی مکمل ہو گئی'},
    'hammer_gavel_callout': {'en': 'Going Once, Going Twice, SOLD!', 'ur': 'ایک، دو، تین — ہو گیا!'},
    'quick_increment': {'en': 'Quick Bid Increments', 'ur': 'فوری بولی اضافہ'},
    'registered_buyers': {'en': 'Registered Buyers (Paddles)', 'ur': 'رجسٹرڈ خریدار (پیڈل نمبر)'},
    'live_bid_log': {'en': 'Live Bid Log', 'ur': 'بولی کی تاریخ'},
    'print_thermal_slip': {'en': 'Print Boli Slip', 'ur': 'بولی پرچی پرنٹ'},

    // Gate Pass & Token Screen
    'gate_pass_title': {'en': 'Gate Pass & Unloading Queue', 'ur': 'گیٹ پاس و ٹوکن لائن'},
    'unloading_board_tab': {'en': 'Unloading Board', 'ur': 'پھڑ ان لوڈنگ بورڈ'},
    'inward_tokens_tab': {'en': 'Inward Tokens', 'ur': 'انٹری ٹوکنز'},
    'gate_out_tab': {'en': 'Gate-Out Pass', 'ur': 'گیٹ آؤٹ کلیئرنس'},
    'issue_token_btn': {'en': 'Issue Token', 'ur': 'نیا ٹوکن جاری کریں'},
    'public_callout_title': {'en': 'PUBLIC CALLOUT / UNLOADING', 'ur': 'اعلان برائے ان لوڈنگ'},
    'currently_unloading': {'en': 'Currently Unloading at Platforms', 'ur': 'پھڑ پر زیر ان لوڈنگ گاڑیاں'},
    'waiting_queue': {'en': 'Vehicles in Waiting Queue', 'ur': 'انتظار گاہ میں موجود گاڑیاں'},
    'tare_weighment_btn': {'en': 'Record Tare', 'ur': 'خالی وزن کنڈا'},

    // Farmer Passbook
    'farmer_passbook_title': {'en': 'Farmer Digital Passbook', 'ur': 'زمیندار ڈیجیٹل پاس بک'},
    'select_farmer': {'en': 'Select Farmer', 'ur': 'زمیندار منتخب کریں'},
    'current_khata_balance': {'en': 'CURRENT KHATA BALANCE', 'ur': 'موجودہ کھاتہ بیلنس'},
    'payable_to_farmer': {'en': 'Payable to Farmer', 'ur': 'واجب الادا رقم'},
    'advance_receivable': {'en': 'Advance Receivable', 'ur': 'پیشگی واجب الوصول'},
    'audio_summary_btn': {'en': 'Listen to Audio Summary', 'ur': 'کھاتے کا صوتی خلاصہ سنیں'},
    'print_qr_card': {'en': 'Print QR ID Card', 'ur': 'شناختی کارڈ پرنٹ'},
    'print_passbook_slip': {'en': 'Print Passbook Slip', 'ur': 'پاس بک پرچی پرنٹ'},

    // Partner Capital
    'partner_capital_title': {'en': 'Shop Partner Profit & Capital', 'ur': 'شراکت داری و منافع کھاتہ'},
    'total_partners': {'en': 'Total Partners', 'ur': 'کل حصہ دار'},
    'total_firm_capital': {'en': 'Total Firm Capital', 'ur': 'کل فرم سرمایہ'},
    'total_drawings': {'en': 'Total Drawings', 'ur': 'کل ذاتی خرچ'},
    'add_partner_btn': {'en': 'Add Partner', 'ur': 'نیا حصہ دار'},
    'record_drawing_btn': {'en': 'Record Drawing', 'ur': 'ذاتی خرچ اندراج'},
    'inject_capital_btn': {'en': 'Inject Capital', 'ur': 'سرمایہ اضافہ'},
    'distribute_profit_btn': {'en': 'Distribute Profit', 'ur': 'منافع تقسیم'},

    // Warehouse 2D Grid
    'warehouse_grid_title': {'en': 'Warehouse Floor Grid', 'ur': 'گودام تصویری نقشہ'},
    'select_chamber': {'en': 'Chamber / Section', 'ur': 'سیکشن / چیمبر'},
    'total_capacity': {'en': 'Total Capacity', 'ur': 'کل گنجائش'},
    'stored_stock': {'en': 'Stored Stock', 'ur': 'موجودہ مال'},
    'active_bays': {'en': 'Active Bays', 'ur': 'زیر استعمال خانے'},
    'store_crop_btn': {'en': 'Store Crop', 'ur': 'مال رکھیں'},
    'relocate_stock_btn': {'en': 'Relocate Stock', 'ur': 'مال منتقل کریں'},
    'clear_bay_btn': {'en': 'Clear Bay', 'ur': 'خانہ خالی کریں'},
  };

  /// Returns localized string by key based on [LocaleProvider.isUrdu].
  static String tr(BuildContext context, String key, {String? fallback}) {
    final isUrdu = context.watch<LocaleProvider>().isUrdu;
    final langCode = isUrdu ? 'ur' : 'en';
    final entry = _localizedValues[key];
    if (entry != null && entry.containsKey(langCode)) {
      return entry[langCode]!;
    }
    return fallback ?? key;
  }

  /// Convenience method accepting a boolean [isUrdu].
  static String of(bool isUrdu, String key, {String? fallback}) {
    final langCode = isUrdu ? 'ur' : 'en';
    final entry = _localizedValues[key];
    if (entry != null && entry.containsKey(langCode)) {
      return entry[langCode]!;
    }
    return fallback ?? key;
  }
}
