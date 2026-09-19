/// Links one Supabase Auth user to one shop, with a role.
///
/// A user can have more than one ShopMember row (one per shop they belong
/// to) — that's what makes the Shop Switcher possible. Always resolve
/// "what can this user do right now" through ShopContextProvider, which
/// picks the ShopMember matching the currently active shop.
///
/// Maps 1:1 to the `shop_memberships` Postgres table — see
/// supabase/schema.sql. `customPermissions`, when set, overrides the
/// role's permission list entirely for this one member, which is how two
/// Sales Staff can end up with different access without needing two roles.
class ShopMember {
  final String id; // shop_memberships.id (uuid)
  final String shopId;
  final String uid; // Supabase Auth user id
  final String roleId;
  final List<String>? customPermissions;
  final String name;
  final String phone;
  final String email;
  final String? cnic;
  final DateTime? joiningDate;
  final double? salary;
  final MemberStatus status;
  final String? photoUrl;
  final DateTime? createdAt;

  const ShopMember({
    required this.id,
    required this.shopId,
    required this.uid,
    required this.roleId,
    required this.name,
    this.customPermissions,
    this.phone = '',
    this.email = '',
    this.cnic,
    this.joiningDate,
    this.salary,
    this.status = MemberStatus.active,
    this.photoUrl,
    this.createdAt,
  });

  bool get isActive => status == MemberStatus.active;
  bool get isInvited => status == MemberStatus.invited;
  bool get isOwnerRole => roleId == 'owner';

  factory ShopMember.fromMap(String id, Map<String, dynamic> d) => ShopMember(
        id: id,
        shopId: d['shop_id'] as String? ?? '',
        uid: d['user_id'] as String? ?? '',
        roleId: d['role_id'] as String? ?? '',
        customPermissions:
            (d['custom_permissions'] as List?)?.cast<String>(),
        name: d['name'] as String? ?? '',
        phone: d['phone'] as String? ?? '',
        email: d['email'] as String? ?? '',
        cnic: d['cnic'] as String?,
        joiningDate: d['joining_date'] != null
            ? DateTime.tryParse(d['joining_date'] as String)
            : null,
        salary: (d['salary'] as num?)?.toDouble(),
        status: MemberStatusX.fromString(d['status'] as String?),
        photoUrl: d['photo_url'] as String?,
        createdAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'shop_id': shopId,
        'user_id': uid,
        'role_id': roleId,
        'custom_permissions': customPermissions,
        'name': name,
        'phone': phone,
        'email': email,
        'cnic': cnic,
        'joining_date': joiningDate?.toIso8601String(),
        'salary': salary,
        'status': status.name,
      };

  ShopMember copyWith({
    String? roleId,
    List<String>? customPermissions,
    String? name,
    String? phone,
    String? email,
    String? cnic,
    DateTime? joiningDate,
    double? salary,
    MemberStatus? status,
    String? photoUrl,
  }) {
    return ShopMember(
      id: id,
      shopId: shopId,
      uid: uid,
      roleId: roleId ?? this.roleId,
      customPermissions: customPermissions ?? this.customPermissions,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      cnic: cnic ?? this.cnic,
      joiningDate: joiningDate ?? this.joiningDate,
      salary: salary ?? this.salary,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}

enum MemberStatus { invited, active, inactive }

extension MemberStatusX on MemberStatus {
  static MemberStatus fromString(String? s) => MemberStatus.values
      .firstWhere((e) => e.name == s, orElse: () => MemberStatus.active);
}
