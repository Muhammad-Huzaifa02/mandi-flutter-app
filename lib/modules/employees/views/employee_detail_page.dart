import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/shop_member_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/auth_provider.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/employees/providers/employee_provider.dart';

class EmployeeDetailPage extends StatefulWidget {
  final ShopMember member;
  const EmployeeDetailPage({super.key, required this.member});

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _salary;
  String? _roleId;
  bool _saving = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.member.name);
    _phone = TextEditingController(text: widget.member.phone);
    _salary = TextEditingController(
        text: widget.member.salary?.toStringAsFixed(0) ?? '');
    _roleId = widget.member.roleId;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _salary.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final shopCtx = context.read<ShopContextProvider>();
    setState(() => _saving = true);
    try {
      await SupabaseService.updateShopMember(
        membershipId: widget.member.id,
        shopId: widget.member.shopId,
        data: {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'role_id': _roleId,
          'salary':
              _salary.text.trim().isEmpty ? null : double.tryParse(_salary.text.trim()),
        },
        actorUid: shopCtx.currentMember!.uid,
        actorName: shopCtx.currentMember!.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleActive(bool makeActive) async {
    final shopCtx = context.read<ShopContextProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(makeActive ? 'Reactivate staff member?' : 'Deactivate staff member?'),
        content: Text(makeActive
            ? '${widget.member.name} will be able to access this shop\'s data again.'
            : '${widget.member.name} will immediately lose access to this shop\'s data until reactivated.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(makeActive ? 'Reactivate' : 'Deactivate')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      // No Edge Function needed here: every Row Level Security policy in
      // supabase/schema.sql already requires status = 'active' before
      // granting shop data access, so flipping this one column is enough
      // to fully cut the person off immediately.
      await SupabaseService.toggleMemberStatus(
        membershipId: widget.member.id,
        shopId: widget.member.shopId,
        makeActive: makeActive,
        memberName: widget.member.name,
        actorUid: shopCtx.currentMember!.uid,
        actorName: shopCtx.currentMember!.name,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    setState(() => _busy = true);
    try {
      // Supabase's own recovery email — no service role needed, and no
      // password (temporary or otherwise) ever passes through this shop.
      await context.read<AuthProvider>().sendPasswordResetEmail(widget.member.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Password reset link sent to ${widget.member.email}.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final canManage = shopCtx.hasPermission('manage_employees');
    final isOwnerRow = widget.member.roleId == 'owner';
    final isSelf = widget.member.uid == shopCtx.currentMember?.uid;
    final roles = context.watch<EmployeeProvider>().roles;

    return Scaffold(
      appBar: AppBar(title: Text(widget.member.name)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(MSpacing.md),
          children: [
            if (widget.member.isInvited)
              Card(
                color: MColors.warning.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(MSpacing.sm),
                  child: Text(
                    'Invitation sent — waiting for ${widget.member.name} to activate their account.',
                    style: MText.labelSm.copyWith(color: MColors.warning),
                  ),
                ),
              ),
            const SizedBox(height: MSpacing.md),
            TextFormField(
              controller: _name,
              enabled: canManage,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: MSpacing.md),
            TextFormField(
              controller: _phone,
              enabled: canManage,
              decoration: const InputDecoration(labelText: 'Mobile number'),
            ),
            const SizedBox(height: MSpacing.md),
            Text('Email: ${widget.member.email}',
                style: MText.bodyMd.copyWith(color: MColors.textSecondary)),
            const SizedBox(height: MSpacing.md),
            DropdownButtonFormField<String>(
              value: _roleId,
              decoration: const InputDecoration(labelText: 'Role'),
              // Owner role can't be reassigned to someone else here — a
              // shop needs exactly the owner it was created with.
              items: roles
                  .where((r) => !isOwnerRow || r.id == 'owner')
                  .map((r) =>
                      DropdownMenuItem(value: r.id, child: Text(r.name)))
                  .toList(),
              onChanged: (canManage && !isOwnerRow)
                  ? (v) => setState(() => _roleId = v)
                  : null,
            ),
            const SizedBox(height: MSpacing.md),
            TextFormField(
              controller: _salary,
              enabled: canManage,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Salary (optional)'),
            ),
            if (canManage) ...[
              const SizedBox(height: MSpacing.lg),
              FilledButton(
                onPressed: _saving ? null : _saveChanges,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
              const SizedBox(height: MSpacing.md),
              OutlinedButton.icon(
                onPressed: _busy ? null : _sendPasswordReset,
                icon: const Icon(Icons.lock_reset),
                label: const Text('Send Password Reset Link'),
              ),
              if (!isOwnerRow && !isSelf) ...[
                const SizedBox(height: MSpacing.md),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.member.isActive
                        ? MColors.danger
                        : MColors.success,
                  ),
                  onPressed:
                      _busy ? null : () => _toggleActive(!widget.member.isActive),
                  icon: Icon(widget.member.isActive
                      ? Icons.block
                      : Icons.check_circle_outline),
                  label: Text(widget.member.isActive
                      ? 'Deactivate Staff'
                      : 'Reactivate Staff'),
                ),
              ],
            ],
            const SizedBox(height: MSpacing.xl),
            Text('Recent Activity', style: MText.titleLg),
            const SizedBox(height: MSpacing.sm),
            _ActivityLog(shopId: widget.member.shopId, uid: widget.member.uid),
          ],
        ),
      ),
    );
  }
}

class _ActivityLog extends StatelessWidget {
  final String shopId;
  final String uid;
  const _ActivityLog({required this.shopId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.auditLogsForActorStream(shopId, uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: MSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return Text('No activity recorded yet.',
              style: MText.bodyMd.copyWith(color: MColors.textSecondary));
        }
        return Column(
          children: rows.take(20).map((data) {
            final ts = data['created_at'] != null
                ? DateTime.tryParse(data['created_at'] as String)
                : null;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: MColors.textSecondary),
              title: Text(data['summary'] as String? ?? ''),
              subtitle: ts != null
                  ? Text('${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}')
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}
