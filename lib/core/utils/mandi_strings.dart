/// Dictionary helper for English and Urdu (اردو) Mandi trading terms.
class MandiStrings {
  static const Map<String, Map<String, String>> _localizedStrings = {
    'products': {'en': 'Products', 'ur': 'اجناس / پروڈکٹس'},
    'invoices': {'en': 'Invoices', 'ur': 'بل / انوائس'},
    'customers': {'en': 'Customers', 'ur': 'گاہک'},
    'suppliers': {'en': 'Suppliers', 'ur': 'بیوپاری / سپلائرز'},
    'expenses': {'en': 'Expenses', 'ur': 'اخراجات'},
    'payments': {'en': 'Payments', 'ur': 'ادائیگی / وصولی'},
    'reports': {'en': 'Reports', 'ur': 'رپورٹس'},
    'wheat': {'en': 'Wheat', 'ur': 'گندم'},
    'rice': {'en': 'Rice', 'ur': 'چاول'},
    'maize': {'en': 'Maize', 'ur': 'مکئی'},
    'cotton': {'en': 'Cotton', 'ur': 'کپاس'},
    'labor': {'en': 'Labor (Mazdoori)', 'ur': 'مزدوری'},
    'transport': {'en': 'Transport & Freight', 'ur': 'کرایہ / ٹرانسپورٹ'},
    'rent': {'en': 'Shop Rent', 'ur': 'دکان کا کرایہ'},
    'electricity': {'en': 'Electricity & Bills', 'ur': 'بجلی کا بل'},
    'tea_food': {'en': 'Tea & Refreshments', 'ur': 'چائے اور کھانا'},
    'mann': {'en': 'Mann (40 KG)', 'ur': 'من (40 کلو)'},
    'received': {'en': 'Received', 'ur': 'وصول شدہ'},
    'pending': {'en': 'Pending', 'ur': 'بقایا'},
    'grand_total': {'en': 'Grand Total', 'ur': 'کل رقم'},
    'commission': {'en': 'Commission', 'ur': 'کمیشن'},
  };

  /// Returns translated string for key based on current language code ('en' or 'ur').
  static String tr(String key, {bool isUrdu = false}) {
    final lang = isUrdu ? 'ur' : 'en';
    return _localizedStrings[key]?[lang] ?? key;
  }
}
