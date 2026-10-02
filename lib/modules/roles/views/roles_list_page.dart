import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/role_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/roles/views/edit_role_page.dart';

class RolesListPage extends StatelessWidget {
  const RolesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shopId = context.watch<ShopContextProvider>().currentShopId;
    final canManage = context.watch<ShopContextProvider>().hasPermission('manage_roles');

    if (shopId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Roles & Permissions')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.rolesStream(shopId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data ?? [];
          final roles = rows
              .map((r) => Role.fromMap(r['id'] as String, r))
              .toList();

          if (roles.isEmpty) {
            return const Center(child: Text('No roles found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(MSpacing.md),
            itemCount: roles.length,
            separatorBuilder: (_, __) => const SizedBox(height: MSpacing.sm),
            itemBuilder: (context, i) {
              final r = roles[i];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: MRadius.md,
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: MColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.admin_panel_settings_outlined,
                        color: MColors.primary),
                  ),
                  title: Text(r.name, style: MText.titleLg),
                  subtitle: Text(
                    '${r.permissions.length} permissions granted',
                    style: MText.bodySm.copyWith(color: MColors.textSecondary),
                  ),
                  trailing: canManage
                      ? IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditRolePage(role: r),
                            ),
                          ),
                        )
                      : null,
                  onTap: canManage
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditRolePage(role: r),
                            ),
                          )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
