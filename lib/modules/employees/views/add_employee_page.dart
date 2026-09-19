import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/employees/providers/employee_provider.dart';
import 'package:mandi/data/services/employee_functions_service.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _cnic = TextEditingController();
  final _salary = TextEditingController();
  String? _roleId;
  DateTime _joiningDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _cnic.dispose();
    _salary.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roleId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please choose a role.')));
      return;
    }

    final shopId = context.read<ShopContextProvider>().currentShopId!;
    setState(() => _saving = true);

    try {
      // Invitation-based: this never returns a password. The Edge Function
      // sends an activation email, and the person sets their own password
      // when they accept — the shop never sees or shares a plain-text
      // credential.
      await AccountInviteService.inviteStaff(
        shopId: shopId,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        cnic: _cnic.text.trim().isEmpty ? null : _cnic.text.trim(),
        roleId: _roleId!,
        joiningDate: _joiningDate,
        salary: _salary.text.trim().isEmpty
            ? null
            : double.tryParse(_salary.text.trim()),
      );

      if (!mounted) return;
      await _showInvitedDialog(_name.text.trim(), _email.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showInvitedDialog(String name, String email) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Invitation sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$name will get an email at $email to activate the account '
              'and set their own password.',
              style: MText.bodyMd,
            ),
            const SizedBox(height: MSpacing.md),
            Text(
              'This shop never sees or shares their password — they choose '
              'it themselves during activation.',
              style: MText.labelSm.copyWith(color: MColors.textSecondary),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<EmployeeProvider>().roles
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: const Text('Add Staff')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: MColors.primary.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(MSpacing.sm),
                  child: Text(
                    'This account is assigned to your current shop '
                    'automatically — there is no Shop ID to enter.',
                    style: MText.labelSm.copyWith(color: MColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email (used to sign in)'),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'A valid email is required'
                    : null,
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _cnic,
                decoration:
                    const InputDecoration(labelText: 'CNIC (optional)'),
              ),
              const SizedBox(height: MSpacing.md),
              DropdownButtonFormField<String>(
                value: _roleId,
                decoration: const InputDecoration(labelText: 'Role'),
                items: roles
                    .map((r) =>
                        DropdownMenuItem(value: r.id, child: Text(r.name)))
                    .toList(),
                onChanged: (v) => setState(() => _roleId = v),
              ),
              const SizedBox(height: MSpacing.md),
              TextFormField(
                controller: _salary,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Salary (optional)'),
              ),
              const SizedBox(height: MSpacing.md),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _joiningDate,
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _joiningDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Joining date'),
                  child: Text(
                      '${_joiningDate.year}-${_joiningDate.month.toString().padLeft(2, '0')}-${_joiningDate.day.toString().padLeft(2, '0')}'),
                ),
              ),
              const SizedBox(height: MSpacing.xl),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create & Invite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
