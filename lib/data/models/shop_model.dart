/// A single shop/tenant on the Mandi platform.
///
/// Every shop-scoped row elsewhere in the app (products, customers,
/// invoices, ...) carries this shop's [id] as its `shop_id` column. Never
/// hardcode a shop id — always resolve the current shop through
/// ShopContextProvider. Maps to the `shops` Postgres table — see
/// supabase/schema.sql.
class Shop {
  final String id;
  final String name;
  final String? logoUrl;
  final String ownerUid;
  final List<String> businessTypes;

  final String phone;
  final String whatsapp;
  final String email;
  final String address;
  final String city;
  final String district;
  final String province;

  final String ntn; // National Tax Number (optional)
  final String strn; // Sales Tax Registration Number (optional)

  final String defaultWeightUnit; // e.g. "40kg", "50kg", "kg", "mann"
  final double defaultCommissionPercent;
  final String invoicePrefix;
  final int invoiceNextNumber;
  final String receiptPrefix;
  final int receiptNextNumber;

  final String currency; // "PKR"
  final ShopStatus status;
  final bool setupComplete;
  final DateTime? createdAt;

  const Shop({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.ownerUid,
    this.businessTypes = const [],
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.district = '',
    this.province = '',
    this.ntn = '',
    this.strn = '',
    this.defaultWeightUnit = '40kg',
    this.defaultCommissionPercent = 0,
    this.invoicePrefix = 'INV',
    this.invoiceNextNumber = 1,
    this.receiptPrefix = 'RCPT',
    this.receiptNextNumber = 1,
    this.currency = 'PKR',
    this.status = ShopStatus.active,
    this.setupComplete = false,
    this.createdAt,
  });

  /// Parses a row as returned by Postgres/PostgREST (snake_case columns).
  factory Shop.fromMap(String id, Map<String, dynamic> d) => Shop(
        id: id,
        name: d['name'] as String? ?? '',
        logoUrl: d['logo_url'] as String?,
        ownerUid: d['owner_id'] as String? ?? '',
        businessTypes:
            (d['business_types'] as List?)?.cast<String>() ?? const [],
        phone: d['phone'] as String? ?? '',
        whatsapp: d['whatsapp'] as String? ?? '',
        email: d['email'] as String? ?? '',
        address: d['address'] as String? ?? '',
        city: d['city'] as String? ?? '',
        district: d['district'] as String? ?? '',
        province: d['province'] as String? ?? '',
        ntn: d['ntn'] as String? ?? '',
        strn: d['strn'] as String? ?? '',
        defaultWeightUnit: d['default_weight_unit'] as String? ?? '40kg',
        defaultCommissionPercent:
            (d['default_commission_percent'] as num?)?.toDouble() ?? 0,
        invoicePrefix: d['invoice_prefix'] as String? ?? 'INV',
        invoiceNextNumber: (d['invoice_next_number'] as num?)?.toInt() ?? 1,
        receiptPrefix: d['receipt_prefix'] as String? ?? 'RCPT',
        receiptNextNumber: (d['receipt_next_number'] as num?)?.toInt() ?? 1,
        currency: d['currency'] as String? ?? 'PKR',
        status: ShopStatusX.fromString(d['status'] as String?),
        setupComplete: d['setup_complete'] as bool? ?? false,
        createdAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'] as String)
            : null,
      );

  /// NOTE: intentionally camelCase — this feeds the `p_shop` jsonb argument
  /// of the create_shop_with_owner RPC (see supabase/schema.sql and
  /// ShopSetupWizard), which reads these exact camelCase keys and maps them
  /// to the real snake_case columns itself. Rows read back from Postgres go
  /// through fromMap() above instead, which does expect snake_case.
  Map<String, dynamic> toMap() => {
        'name': name,
        'logoUrl': logoUrl,
        'businessTypes': businessTypes,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'address': address,
        'city': city,
        'district': district,
        'province': province,
        'ntn': ntn,
        'strn': strn,
        'defaultWeightUnit': defaultWeightUnit,
        'defaultCommissionPercent': defaultCommissionPercent,
        'invoicePrefix': invoicePrefix,
        'invoiceNextNumber': invoiceNextNumber,
        'receiptPrefix': receiptPrefix,
        'receiptNextNumber': receiptNextNumber,
        'currency': currency,
        'status': status.name,
        'setupComplete': setupComplete,
      };

  Shop copyWith({
    String? name,
    String? logoUrl,
    List<String>? businessTypes,
    String? phone,
    String? whatsapp,
    String? email,
    String? address,
    String? city,
    String? district,
    String? province,
    String? ntn,
    String? strn,
    String? defaultWeightUnit,
    double? defaultCommissionPercent,
    String? invoicePrefix,
    int? invoiceNextNumber,
    String? receiptPrefix,
    int? receiptNextNumber,
    ShopStatus? status,
    bool? setupComplete,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      ownerUid: ownerUid,
      businessTypes: businessTypes ?? this.businessTypes,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      province: province ?? this.province,
      ntn: ntn ?? this.ntn,
      strn: strn ?? this.strn,
      defaultWeightUnit: defaultWeightUnit ?? this.defaultWeightUnit,
      defaultCommissionPercent:
          defaultCommissionPercent ?? this.defaultCommissionPercent,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      invoiceNextNumber: invoiceNextNumber ?? this.invoiceNextNumber,
      receiptPrefix: receiptPrefix ?? this.receiptPrefix,
      receiptNextNumber: receiptNextNumber ?? this.receiptNextNumber,
      status: status ?? this.status,
      setupComplete: setupComplete ?? this.setupComplete,
      createdAt: createdAt,
    );
  }
}

enum ShopStatus { active, suspended }

extension ShopStatusX on ShopStatus {
  static ShopStatus fromString(String? s) => ShopStatus.values
      .firstWhere((e) => e.name == s, orElse: () => ShopStatus.active);
}
