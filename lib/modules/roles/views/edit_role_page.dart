import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/role_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';

class EditRolePage extends StatefulWidget {
  final Role role;

  const EditRolePage({super.key, required this.role});

  @override
  State<EditRolePage> createState() => _EditRolePageState();
}

class _EditRolePageState extends State<EditRolePage> {
  late Set<String> _selectedPermissions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedPermissions = Set.from(widget.role.permissions);
  }

  Future<void> _save() async {
    final shopId = context.read<ShopContextProvider>().currentShopId!;
    setState(() => _saving = true);

    try {
      final roleData = {
        'name': widget.role.name,
        'is_default': widget.role.isDefault,
        'permissions': _selectedPermissions.toList(),
      };

      await SupabaseService.saveRole(shopId, widget.role.id, roleData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role permissions updated.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: MColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${role.name} Role'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(MSpacing.md),
            color: MColors.primary.withOpacity(0.08),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: MColors.primary),
                const SizedBox(width: MSpacing.md),
                Expanded(
                  child: Text(
                    'Select permissions granted to the ${role.name} role.',
                    style: MText.bodySm,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: Role.allPermissions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final perm = Role.allPermissions[i];
                final isGranted = _selectedPermissions.contains(perm);
                final displayName = Role.permissionDisplayName(perm);

                return CheckboxListTile(
                  title: Text(displayName, style: MText.titleLg.copyWith(fontSize: 15)),
                  subtitle: Text(perm, style: MText.bodySm.copyWith(color: MColors.textSecondary)),
                  value: isGranted,
                  activeColor: MColors.primary,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedPermissions.add(perm);
                      } else {
                        _selectedPermissions.remove(perm);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Role Permissions'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
