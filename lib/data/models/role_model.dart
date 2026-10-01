/// A named set of permission strings, scoped to one shop.
///
/// Five default roles are seeded for every new shop (see
/// [Role.defaultRolesFor]) but owners can edit their permissions or add
/// custom roles.
class Role {
  final String id;
  final String shopId;
  final String name;
  final bool isDefault;
  final List<String> permissions;

  const Role({
    required this.id,
    required this.shopId,
    required this.name,
    this.isDefault = false,
    this.permissions = const [],
  });

  bool has(String permission) => permissions.contains(permission);

  factory Role.fromMap(String id, Map<String, dynamic> d) => Role(
        id: id,
        shopId: d['shop_id'] as String? ?? '',
        name: d['name'] as String? ?? '',
        isDefault: d['is_default'] as bool? ?? false,
        permissions: (d['permissions'] as List?)?.cast<String>() ?? const [],
      );

  /// NOTE: intentionally camelCase, NOT the Postgres column names — this
  /// feeds the `p_default_roles` jsonb argument of the create_shop_with_owner
  /// RPC (see supabase/schema.sql), which expects the same camelCase shape
  /// Shop.toMap() uses for `p_shop`. Postgres rows themselves come back
  /// snake_case, which is what fromMap() above parses.
  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'name': name,
        'isDefault': isDefault,
        'permissions': permissions,
      };

  Role copyWith({String? name, List<String>? permissions}) => Role(
        id: id,
        shopId: shopId,
        name: name ?? this.name,
        isDefault: isDefault,
        permissions: permissions ?? this.permissions,
      );

  /// All permission strings recognized by the app. Kept in one place so
  /// screens and the role editor stay in sync with what's actually checked.
  static const List<String> allPermissions = [
    'view_dashboard',
    'manage_products',
    'manage_inventory',
    'manage_customers',
    'manage_suppliers',
    'create_sale',
    'create_purchase',
    'create_invoice',
    'edit_invoice',
    'delete_invoice',
    'void_invoice',
    'create_receipt',
    'manage_expenses',
    'view_ledger',
    'view_analytics',
    'view_reports',
    'export_data',
    'manage_employees',
    'manage_roles',
    'manage_settings',
    'send_reminders',
  ];

  static String permissionDisplayName(String permission) {
    switch (permission) {
      case 'view_dashboard':
        return 'View Dashboard';
      case 'manage_products':
        return 'Manage Products';
      case 'manage_inventory':
        return 'Manage Inventory';
      case 'manage_customers':
        return 'Manage Customers';
      case 'manage_suppliers':
        return 'Manage Suppliers';
      case 'create_sale':
        return 'Create Sales';
      case 'create_purchase':
        return 'Create Purchases';
      case 'create_invoice':
        return 'Create Invoices';
      case 'edit_invoice':
        return 'Edit Invoices';
      case 'delete_invoice':
        return 'Delete Invoices';
      case 'void_invoice':
        return 'Void Invoices';
      case 'create_receipt':
        return 'Create Payment Receipts';
      case 'manage_expenses':
        return 'Manage Expenses';
      case 'view_ledger':
        return 'View Ledgers';
      case 'view_analytics':
        return 'View Analytics';
      case 'view_reports':
        return 'View Reports';
      case 'export_data':
        return 'Export Data';
      case 'manage_employees':
        return 'Manage Employees';
      case 'manage_roles':
        return 'Manage Roles & Permissions';
      case 'manage_settings':
        return 'Manage Shop Settings';
      case 'send_reminders':
        return 'Send Payment Reminders';
      default:
        return permission;
    }
  }

  /// Seed data for a brand-new shop's five default roles. Callers pass the
  /// real shopId once the shop document has been created.
  static List<Role> defaultRolesFor(String shopId) => [
        Role(
          id: 'owner',
          shopId: shopId,
          name: 'Owner',
          isDefault: true,
          permissions: allPermissions,
        ),
        Role(
          id: 'manager',
          shopId: shopId,
          name: 'Manager',
          isDefault: true,
          permissions: const [
            'view_dashboard', 'manage_products', 'manage_inventory',
            'manage_customers', 'manage_suppliers', 'create_sale',
            'create_purchase', 'create_invoice', 'edit_invoice',
            'view_ledger', 'view_analytics', 'view_reports', 'export_data',
            'send_reminders',
          ],
        ),
        Role(
          id: 'accountant',
          shopId: shopId,
          name: 'Accountant',
          isDefault: true,
          permissions: const [
            'view_dashboard', 'manage_customers', 'manage_suppliers',
            'create_invoice', 'create_receipt', 'manage_expenses',
            'view_ledger', 'view_reports', 'export_data',
          ],
        ),
        Role(
          id: 'sales_staff',
          shopId: shopId,
          name: 'Sales Staff',
          isDefault: true,
          permissions: const [
            'view_dashboard', 'manage_customers', 'create_sale',
            'create_invoice',
          ],
        ),
        Role(
          id: 'inventory_staff',
          shopId: shopId,
          name: 'Inventory Staff',
          isDefault: true,
          permissions: const [
            'view_dashboard', 'manage_products', 'manage_inventory',
          ],
        ),
        // Not "staff" roles in the traditional sense — customers and
        // suppliers get their own dedicated dashboards regardless of this
        // role's permission list. The row exists so shop_memberships has
        // something to reference, and so an owner can later grant a
        // specific customer/supplier an extra permission (e.g. view_ledger)
        // via shop_memberships.custom_permissions without changing the
        // shared default for everyone else in that role.
        Role(
          id: 'customer',
          shopId: shopId,
          name: 'Customer',
          isDefault: true,
          permissions: const [],
        ),
        Role(
          id: 'supplier',
          shopId: shopId,
          name: 'Supplier',
          isDefault: true,
          permissions: const [],
        ),
      ];

  /// Shape expected by SupabaseService.createShopWithOwner's `defaultRoles`
  /// param — each map keeps 'id' alongside the role's field map so the
  /// batch write can use it as the doc id and then drop it from the data.
  static List<Map<String, dynamic>> defaultRoleSeedMaps(String shopId) =>
      defaultRolesFor(shopId).map((r) => {'id': r.id, ...r.toMap()}).toList();
}
