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
    'connected_commission_shop': {'en': 'Connected Commission Shop', 'ur': 'منسلک آڑھت / کمیشن شاپ'},
    'shop_details': {'en': 'Shop Details', 'ur': 'دکان تفصیلات'},
    'grain_market': {'en': 'Grain Market', 'ur': 'غلہ منڈی'},
    'contact_shop': {'en': 'Call Shop', 'ur': 'دکان پر کال کریں'},
    'whatsapp_shop': {'en': 'WhatsApp', 'ur': 'واٹس ایپ'},
    'shop_info': {'en': 'Shop Info', 'ur': 'دکان کی معلومات'},
    'shop_address': {'en': 'Mandi Address', 'ur': 'منڈی کا پتہ'},
    'shop_phone': {'en': 'Phone Number', 'ur': 'فون نمبر'},
    'commission_agent': {'en': 'Commission Agent / Arhti', 'ur': 'آڑھتی / کمیشن ایجنٹ'},
    'switch_active_shop': {'en': 'Switch Active Shop', 'ur': 'فعال دکان تبدیل کریں'},
    'commission_shop': {'en': 'Commission Shop', 'ur': 'کمیشن شاپ'},
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
    'customers': {'en': 'Customers', 'ur': 'گاہک'},
    'suppliers': {'en': 'Farmers', 'ur': 'زمیندار'},
    'farmers': {'en': 'Farmers', 'ur': 'زمیندار'},
    'add_farmer': {'en': 'Add Farmer', 'ur': 'نیا زمیندار درج کریں'},
    'farmer_details': {'en': 'Farmer Khata', 'ur': 'زمیندار کھاتہ'},
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
    'weighbridge': {'en': 'Weighbridge', 'ur': 'دھرم کنڈا'},
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

    // Dashboard & Common Terms
    'receivables': {'en': 'Receivables', 'ur': 'وصولی'},
    'payables': {'en': 'Payables', 'ur': 'ادائیگی'},
    'bills': {'en': 'Bills', 'ur': 'بلز'},
    'this_season': {'en': 'This Season', 'ur': 'موجودہ سیزن'},
    'my_balance': {'en': 'My Outstanding Balance', 'ur': 'میرا بقایا بیلنس'},
    'buyer_services': {'en': 'Buyer Services', 'ur': 'خریدار سہولیات'},
    'my_khata': {'en': 'My Khata', 'ur': 'میرا کھاتہ'},
    'farmer_services': {'en': 'Farmer & Crop Services', 'ur': 'زمیندار اور فصل سروسز'},
    'farmer_dashboard': {'en': 'Farmer Dashboard', 'ur': 'زمیندار ڈیش بورڈ'},
    'customer_dashboard': {'en': 'Customer Dashboard', 'ur': 'گاہک ڈیش بورڈ'},
    'customer': {'en': 'Customer', 'ur': 'گاہک'},
    'farmer': {'en': 'Farmer', 'ur': 'زمیندار'},
    'at_this_shop': {'en': 'at', 'ur': 'نزد'},
    'money_owed_to_me': {'en': 'Money Owed to Me', 'ur': 'دکان پر میری بقایا رقم'},
    'send_reminder': {'en': 'Send Payment Reminder to Shop Owner', 'ur': 'دکان مالک کو یاددہانی میسج بھیجیں'},
    'offer_crop': {'en': 'Offer Crop', 'ur': 'فصل پیش کریں'},
    'khata_ledger': {'en': 'Khata Ledger', 'ur': 'کھاتہ لیجر'},
    'payable_to_farmer_urdu': {'en': 'Payable to farmer', 'ur': 'واجب الادا رقم'},
    'advance_to_farmer_urdu': {'en': 'Advance paid to farmer', 'ur': 'پیشگی رقم'},
    'settled': {'en': 'Settled', 'ur': 'بے باق'},
    'no_pending_dues': {'en': 'No pending dues', 'ur': 'کوئی بقایا نہیں'},
    'account_ledger_history': {'en': 'Account Ledger History', 'ur': 'کھاتہ لیجر ہسٹری'},
    'transactions': {'en': 'Transactions', 'ur': 'ٹرانزیکشنز'},
    'pay_farmer': {'en': 'Pay Farmer', 'ur': 'ادائیگی کریں'},
    'record_receipt': {'en': 'Record Receipt', 'ur': 'وصولی درج کریں'},
    'whatsapp': {'en': 'WhatsApp', 'ur': 'واٹس ایپ'},
    'edit_profile': {'en': 'Edit Profile', 'ur': 'پروفائل تبدیل کریں'},
    'print_ledger_pdf': {'en': 'Print Ledger Statement PDF', 'ur': 'لیجر اسٹیٹمنٹ پرنٹ کریں'},
    'outstanding_khata_balance': {'en': 'Outstanding Khata Balance', 'ur': 'موجودہ بقایا کھاتہ بیلنس'},
    'outstanding_payable_balance': {'en': 'Outstanding Payable Balance', 'ur': 'واجب الادا بقایا رقم'},
    'customer_owes_you': {'en': 'Customer owes you', 'ur': 'گاہک کے ذمے بقایا'},
    'advance_received': {'en': 'Advance payment received', 'ur': 'پیشگی وصول شدہ'},
    'khata_settled': {'en': 'Khata Settled', 'ur': 'کھاتہ بے باق ہے'},
    'loyalty_points': {'en': 'Loyalty Points', 'ur': 'پوائنٹس'},
    'spent': {'en': 'spent', 'ur': 'خرچ'},

    // Live Auction Screen
    'auction_terminal_title': {'en': 'Live Auction Terminal', 'ur': 'لائیو نیلامی بولی اسکرین'},
    'new_heap': {'en': 'New Auction Lot', 'ur': 'نئی ڈھیری شروع کریں'},
    'maunds': {'en': 'Maunds', 'ur': 'من'},
    'bags': {'en': 'Bags', 'ur': 'بوریاں'},
    'per_maund': {'en': 'per Maund', 'ur': 'فی من'},
    'current_highest_bid': {'en': 'CURRENT HIGHEST BID', 'ur': 'موجودہ بلند ترین بولی'},
    'auction_sold': {'en': 'SOLD! AUCTION CLOSED', 'ur': 'بولی مکمل ہو گئی'},
    'hammer_gavel_callout': {'en': 'Going Once, Going Twice, SOLD!', 'ur': 'ایک، دو، تین — ہو گیا!'},
    'quick_increment': {'en': 'Quick Bid Increments', 'ur': 'فوری بولی اضافہ'},
    'registered_buyers': {'en': 'Registered Buyers', 'ur': 'رجسٹرڈ خریدار'},
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
    'edit_stock_btn': {'en': 'Edit Stock', 'ur': 'مال تبدیل کریں'},
    'relocate_stock_btn': {'en': 'Relocate Stock', 'ur': 'مال منتقل کریں'},
    'clear_bay_btn': {'en': 'Clear Bay', 'ur': 'خانہ خالی کریں'},
    'floor_plan': {'en': '2D Floor Plan', 'ur': 'گودام تصویری نقشہ'},

    // Language & Settings
    'app_language': {'en': 'App Language', 'ur': 'ایپ کی زبان'},
    'language_english': {'en': 'English', 'ur': 'انگریزی'},
    'language_urdu': {'en': 'Urdu', 'ur': 'اردو'},
    'print_test_receipt': {'en': 'Print Test Thermal Receipt', 'ur': 'ٹیسٹ تھرمل رسید پرنٹ کریں'},
    'test_print': {'en': 'TEST PRINT', 'ur': 'ٹیسٹ پرنٹ'},
    'payable_to_shop': {'en': 'Payable to shop', 'ur': 'واجب الادا رقم نزد دکان'},

    // Live Auction & Modals
    'new_auction_heap_title': {'en': 'New Auction Heap Details', 'ur': 'پھڑ ڈھیری تفصیل درج کریں'},
    'heap_lot_code': {'en': 'Heap / Lot Code', 'ur': 'ڈھیری / لاٹ کوڈ'},
    'commodity': {'en': 'Commodity', 'ur': 'جنس'},
    'farmer_name': {'en': "Farmer's Name", 'ur': 'زمیندار کا نام'},
    'weight_in_maunds': {'en': 'Weight in Maunds', 'ur': 'وزن (من)'},
    'estimated_bags': {'en': 'Estimated Bags', 'ur': 'متوقع بوریاں'},
    'base_price_per_maund': {'en': 'Base Price per Maund', 'ur': 'ابتدائی بولی فی من'},
    'start_boli': {'en': 'Start Boli', 'ur': 'شروع کریں'},

    // Gate Pass & Weighment
    'callout_btn': {'en': 'Callout', 'ur': 'کال آؤٹ'},
    'issue_first_token_btn': {'en': 'Issue First Token', 'ur': 'پہلا ٹوکن جاری کریں'},
    'clear_gate_out_btn': {'en': 'Clear Gate-Out', 'ur': 'گیٹ آؤٹ کلیئر کریں'},
    'reprint_pass_btn': {'en': 'Reprint Pass', 'ur': 'پاس دوبارہ پرنٹ کریں'},
    'callout_dialog_title': {'en': 'Callout for Unloading', 'ur': 'پھڑ پر کال آؤٹ و لائن نمبر'},
    'select_unloading_platform': {'en': 'Select Unloading Platform', 'ur': 'پھڑ کا انتخاب کریں'},
    'tare_weighment_title': {'en': 'Tare Weighment', 'ur': 'خالی گاڑی وزن و کنڈا اندراج'},
    'gross_weight': {'en': 'Gross Weight (KG)', 'ur': 'بھرا ہوا وزن (کلوگرام)'},
    'empty_tare_weight': {'en': 'Empty Tare Weight (KG)', 'ur': 'خالی گاڑی وزن (کلوگرام)'},
    'net_crop_weight': {'en': 'Net Crop Weight', 'ur': 'خالص فصل کا وزن'},
    'save_weighment': {'en': 'Save Weighment', 'ur': 'وزن محفوظ کریں'},
    'issue_token_title': {'en': 'Issue Gate Inward Token', 'ur': 'گیٹ پاس و ٹوکن اجراء'},
    'vehicle_number': {'en': 'Vehicle Number', 'ur': 'گاڑی نمبر'},
    'driver_name': {'en': 'Driver Name', 'ur': 'ڈرائیور کا نام'},
    'driver_phone': {'en': 'Driver Phone', 'ur': 'ڈرائیور کا فون'},
    'platform_number': {'en': 'Platform Number', 'ur': 'پھڑ نمبر'},
    'notes': {'en': 'Notes / Remarks', 'ur': 'تفصیل / ہدایات'},

    // Passbook & Partner Capital
    'total_delivered': {'en': 'Total Delivered', 'ur': 'کل مال'},
    'gross_auction': {'en': 'Gross Auction', 'ur': 'کل بولی'},
    'deductions': {'en': 'Deductions', 'ur': 'منہائی و کمیشن'},
    'cash_paid': {'en': 'Cash Paid', 'ur': 'ادا شدہ رقم'},
    'delivered_crop_lots': {'en': 'Delivered Crop Lots', 'ur': 'فصل ترسیل و نیلامی تفصیل'},
    'audio_summary_title': {'en': 'Khata Audio Summary', 'ur': 'کھاتے کا صوتی خلاصہ'},
    'audio_summary_subtitle': {'en': 'Listen to spoken khata balance', 'ur': 'زمیندار کو بول کر کھاتہ بیلنس سنائیں'},
    'play': {'en': 'Play', 'ur': 'سنیں'},
    'stop': {'en': 'Stop', 'ur': 'روکیں'},
    'close': {'en': 'Close', 'ur': 'بند کریں'},
    'partner_balances_header': {'en': 'Partner Capital Balances', 'ur': 'حصہ داران و سرمایہ بیلنس'},
    'recent_transactions_header': {'en': 'Recent Transactions', 'ur': 'حالیہ ٹرانزیکشنز و منافع تفصیل'},
    'current_capital': {'en': 'Current Capital', 'ur': 'موجودہ سرمایہ'},

    // Mandi Rates
    'all': {'en': 'All', 'ur': 'تمام'},
    'bullish': {'en': 'Bullish', 'ur': 'تیزی'},
    'bearish': {'en': 'Bearish', 'ur': 'مندی'},
    'record_rate_btn': {'en': 'Record Rate', 'ur': 'اندراج ریٹ'},
    'commodities': {'en': 'Commodities', 'ur': 'اجناس'},
    'total_arrivals': {'en': 'Total Arrivals', 'ur': 'کل آمد'},
    'broadcast_rate_board': {'en': 'Broadcast Rate Board', 'ur': 'براڈکاسٹ ریٹ لسٹ'},
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

  /// Returns true if Urdu is currently the selected app language.
  static bool isUrdu(BuildContext context) {
    return context.watch<LocaleProvider>().isUrdu;
  }

  /// Returns [en] if English is selected, or [ur] if Urdu is selected.
  static String val(BuildContext context, {required String en, required String ur}) {
    final isUrdu = context.watch<LocaleProvider>().isUrdu;
    return isUrdu ? ur : en;
  }

  /// Non-reactive variant using a boolean flag.
  static String valOf(bool isUrdu, {required String en, required String ur}) {
    return isUrdu ? ur : en;
  }
}
