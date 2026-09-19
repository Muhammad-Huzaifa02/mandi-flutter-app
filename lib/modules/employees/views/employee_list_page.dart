import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/shop_member_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/employees/providers/employee_provider.dart';
import 'package:mandi/modules/employees/views/add_employee_page.dart';
import 'package:mandi/modules/employees/views/employee_detail_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final canManage = shopCtx.hasPermission('manage_employees');
    final employeeCtx = context.watch<EmployeeProvider>();
    final results = employeeCtx.search(_query);

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEmployeePage()),
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Employee'),
            )
          : null,
      body: employeeCtx.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(MSpacing.md),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by name, phone or email',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: results.isEmpty
                      ? Center(
                          child: Text(
                            employeeCtx.employees.isEmpty
                                ? 'No employees yet.'
                                : 'No matches.',
                            style: MText.bodyMd
                                .copyWith(color: MColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: MSpacing.md),
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: MSpacing.sm),
                          itemBuilder: (_, i) =>
                              _EmployeeTile(member: results[i]),
                        ),
                ),
              ],
            ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final ShopMember member;
  const _EmployeeTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final employeeCtx = context.read<EmployeeProvider>();
    final active = member.isActive;

    return Card(
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EmployeeDetailPage(member: member)),
        ),
        leading: CircleAvatar(
          backgroundColor: MColors.primary.withOpacity(0.12),
          backgroundImage:
              member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
          child: member.photoUrl == null
              ? Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: MColors.primary, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(member.name, style: MText.bodyMd.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(employeeCtx.roleName(member.roleId)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (active ? MColors.success : MColors.danger).withOpacity(0.12),
            borderRadius: MRadius.full,
          ),
          child: Text(
            active ? 'Active' : 'Inactive',
            style: MText.labelSm.copyWith(
              color: active ? MColors.success : MColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}
