import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/data/models/product_model.dart';
import 'package:mandi/data/models/role_model.dart';
import 'package:mandi/data/models/shop_member_model.dart';
import 'package:mandi/data/models/shop_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/providers/shop_context_provider.dart';

const _businessTypeOptions = [
  'Commission Shop',
  'Rice Dealer',
  'Wheat Dealer',
  'Grain Trader',
  'Agricultural Products',
  'Wholesale Business',
  'Mandi Shop',
  'Other',
];

const _pakistaniProvinces = [
  'Punjab', 'Sindh', 'Khyber Pakhtunkhwa', 'Balochistan',
  'Gilgit-Baltistan', 'Azad Kashmir', 'Islamabad Capital Territory',
];

class ShopSetupWizard extends StatefulWidget {
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String? ownerCnic;

  const ShopSetupWizard({
    super.key,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    this.ownerCnic,
  });

  @override
  State<ShopSetupWizard> createState() => _ShopSetupWizardState();
}

class _ShopSetupWizardState extends State<ShopSetupWizard> {
  final _pageController = PageController();
  int _step = 0;
  static const _totalSteps = 4;
  bool _submitting = false;
  String? _error;

  // Step 1 — shop info
  final _shopNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  String _province = _pakistaniProvinces.first;
  final _whatsappCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final Set<String> _businessTypes = {};

  // Step 2 — products
  final Set<String> _selectedProducts = {'Rice', 'Wheat'};
  final _customProductCtrl = TextEditingController();

  // Step 3 — units
  final Set<String> _selectedUnits = {'40 KG'};
  final _customUnitCtrl = TextEditingController();

  // Step 4 — invoice settings
  final _invoicePrefixCtrl = TextEditingController(text: 'INV');
  final _commissionCtrl = TextEditingController(text: '2');
  String _defaultUnit = '40 KG';

  @override
  void dispose() {
    _pageController.dispose();
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _whatsappCtrl.dispose();
    _contactCtrl.dispose();
    _customProductCtrl.dispose();
    _customUnitCtrl.dispose();
    _invoicePrefixCtrl.dispose();
    _commissionCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _shopNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your shop name');
      return;
    }
    setState(() => _error = null);
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step--);
    _pageController.previousPage(
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _finish() async {
    final shopCtx = context.read<ShopContextProvider>();

    // Read the session directly from Supabase rather than trusting a
    // possibly-stale AuthProvider snapshot, and try one silent refresh
    // before concluding there's genuinely no session.
    var uid = Supabase.instance.client.auth.currentSession?.user.id;
    if (uid == null) {
      try {
        final refreshed = await Supabase.instance.client.auth.refreshSession();
        uid = refreshed.session?.user.id;
      } catch (_) {
        // fall through — still null, handled below
      }
    }
    if (uid == null) {
      setState(() => _error = 'session_expired');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final shopData = {
        'name': _shopNameCtrl.text.trim(),
        'businessTypes': _businessTypes.toList(),
        'phone': _contactCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'email': widget.ownerEmail,
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'province': _province,
        'defaultWeightUnit': _defaultUnit,
        'defaultCommissionPercent':
            double.tryParse(_commissionCtrl.text.trim()) ?? 0,
        'invoicePrefix': _invoicePrefixCtrl.text.trim().isEmpty
            ? 'INV'
            : _invoicePrefixCtrl.text.trim(),
        'invoiceNextNumber': 1,
        'receiptPrefix': 'RCPT',
        'receiptNextNumber': 1,
        'currency': 'PKR',
        'status': 'active',
        'setupComplete': true,
      };

      final defaultRoles = Role.defaultRoleSeedMaps('pending'); // shopId patched server-side by create_shop_with_owner

      final shopId = await SupabaseService.createShopWithOwner(
        shopData: shopData,
        ownerName: widget.ownerName,
        ownerPhone: widget.ownerPhone,
        ownerEmail: widget.ownerEmail,
        defaultRoles: defaultRoles,
      );

      // Seed the chosen default products so the shop isn't empty on day one.
      for (final name in _selectedProducts) {
        await SupabaseService.addProduct({
          'shop_id': shopId,
          'name': name,
          'category': name,
          'unit': _defaultUnit,
          'weight_per_unit_kg':
              double.tryParse(_defaultUnit.replaceAll(RegExp(r'[^0-9]'), '')) ?? 40,
          'purchase_price': 0,
          'selling_price': 0,
          'min_stock_level': 0,
          'current_stock': 0,
          'is_active': true,
        });
      }

      if (!mounted) return;

      final shopRow = await SupabaseService.getShop(shopId);
      final shopModel = shopRow != null ? Shop.fromMap(shopId, shopRow) : null;

      // Fetch the real membership row create_shop_with_owner just inserted,
      // rather than fabricating one client-side — picks up its real id and
      // 'active' status straight from Postgres.
      final memberRows = await SupabaseService.shopMembersForUser(uid);
      final ownerRow = memberRows.firstWhere((r) => r['shop_id'] == shopId);
      var ownerMember = ShopMember.fromMap(ownerRow['id'] as String, ownerRow);
      final ownerRole = Role.defaultRolesFor(shopId).first;

      if (widget.ownerCnic != null && widget.ownerCnic!.isNotEmpty) {
        await SupabaseService.updateShopMember(
          membershipId: ownerMember.id,
          shopId: shopId,
          data: {'cnic': widget.ownerCnic},
          actorUid: uid,
          actorName: widget.ownerName,
        );
        ownerMember = ownerMember.copyWith(cnic: widget.ownerCnic);
      }

      if (shopModel != null) {
        shopCtx.adoptNewShop(
          shopModel,
          ownerMember,
          ownerRole,
        );
      } else {
        await shopCtx.loadForUser(uid);
      }

      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e, stack) {
      debugPrint('Shop setup error: $e\n$stack');
      final msg = e is PostgrestException ? e.message : e.toString();
      setState(() => _error = 'Could not create shop: $msg');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Shop'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: _back),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: MSpacing.lg, vertical: MSpacing.sm),
              child: Row(
                children: List.generate(_totalSteps, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 4,
                      decoration: BoxDecoration(
                        color: active ? MColors.primary : Colors.grey.shade300,
                        borderRadius: MRadius.full,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _shopInfoStep(),
                  _productsStep(),
                  _unitsStep(),
                  _invoiceSettingsStep(),
                ],
              ),
            ),
            if (_error == 'session_expired') ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: MSpacing.lg),
                child: Text(
                  'Your session expired before this could be saved.',
                  style: TextStyle(color: MColors.danger),
                ),
              ),
              const SizedBox(height: MSpacing.sm),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Log In Again'),
              ),
            ] else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MSpacing.lg),
                child: Text(_error!, style: const TextStyle(color: MColors.danger)),
              ),
            Padding(
              padding: const EdgeInsets.all(MSpacing.lg),
              child: ElevatedButton(
                onPressed: _submitting ? null : _next,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_step == _totalSteps - 1
                        ? 'Finish & Open Dashboard'
                        : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepScaffold({required String title, required String subtitle, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: MText.titleLg),
          const SizedBox(height: MSpacing.xs),
          Text(subtitle, style: MText.bodyMd.copyWith(color: MColors.textSecondary)),
          const SizedBox(height: MSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _chipSet(List<String> options, Set<String> selected) {
    return Wrap(
      spacing: MSpacing.sm,
      runSpacing: MSpacing.sm,
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return FilterChip(
          label: Text(o),
          selected: isSelected,
          onSelected: (v) => setState(() => v ? selected.add(o) : selected.remove(o)),
          selectedColor: MColors.primary.withValues(alpha: 0.15),
          checkmarkColor: MColors.primary,
        );
      }).toList(),
    );
  }

  Widget _shopInfoStep() => _stepScaffold(
        title: 'Shop Information',
        subtitle: 'Tell us about your business',
        children: [
          TextFormField(
            controller: _shopNameCtrl,
            decoration: const InputDecoration(labelText: 'Shop Name'),
          ),
          const SizedBox(height: MSpacing.md),
          const Text('Business Type', style: MText.labelMd),
          const SizedBox(height: MSpacing.sm),
          _chipSet(_businessTypeOptions, _businessTypes),
          const SizedBox(height: MSpacing.md),
          TextFormField(
            controller: _addressCtrl,
            decoration: const InputDecoration(labelText: 'Shop Address'),
          ),
          const SizedBox(height: MSpacing.md),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: MSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: _districtCtrl,
                decoration: const InputDecoration(labelText: 'District'),
              ),
            ),
          ]),
          const SizedBox(height: MSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _province,
            decoration: const InputDecoration(labelText: 'Province'),
            items: _pakistaniProvinces
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _province = v ?? _province),
          ),
          const SizedBox(height: MSpacing.md),
          TextFormField(
            controller: _whatsappCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'WhatsApp Number'),
          ),
          const SizedBox(height: MSpacing.md),
          TextFormField(
            controller: _contactCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact Number'),
          ),
        ],
      );

  Widget _productsStep() => _stepScaffold(
        title: 'Your Products',
        subtitle: 'Pick what you deal in — add custom ones too',
        children: [
          _chipSet(Product.defaultSuggestions, _selectedProducts),
          const SizedBox(height: MSpacing.md),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _customProductCtrl,
                decoration: const InputDecoration(labelText: 'Add a custom product'),
              ),
            ),
            const SizedBox(width: MSpacing.sm),
            IconButton.filled(
              onPressed: () {
                final v = _customProductCtrl.text.trim();
                if (v.isNotEmpty) {
                  setState(() {
                    _selectedProducts.add(v);
                    _customProductCtrl.clear();
                  });
                }
              },
              icon: const Icon(Icons.add),
            ),
          ]),
        ],
      );

  Widget _unitsStep() => _stepScaffold(
        title: 'Weight & Quantity Units',
        subtitle: 'Choose the units you buy and sell in',
        children: [
          _chipSet(Product.defaultUnits, _selectedUnits),
          const SizedBox(height: MSpacing.md),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _customUnitCtrl,
                decoration: const InputDecoration(labelText: 'Add a custom unit'),
              ),
            ),
            const SizedBox(width: MSpacing.sm),
            IconButton.filled(
              onPressed: () {
                final v = _customUnitCtrl.text.trim();
                if (v.isNotEmpty) {
                  setState(() {
                    _selectedUnits.add(v);
                    _customUnitCtrl.clear();
                  });
                }
              },
              icon: const Icon(Icons.add),
            ),
          ]),
        ],
      );

  Widget _invoiceSettingsStep() => _stepScaffold(
        title: 'Invoice Settings',
        subtitle: 'You can change these anytime from Settings',
        children: [
          TextFormField(
            controller: _invoicePrefixCtrl,
            decoration: const InputDecoration(labelText: 'Invoice Number Prefix'),
          ),
          const SizedBox(height: MSpacing.md),
          TextFormField(
            controller: _commissionCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Default Commission %'),
          ),
          const SizedBox(height: MSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _selectedUnits.contains(_defaultUnit)
                ? _defaultUnit
                : _selectedUnits.first,
            decoration: const InputDecoration(labelText: 'Default Pricing Unit'),
            items: _selectedUnits
                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                .toList(),
            onChanged: (v) => setState(() => _defaultUnit = v ?? _defaultUnit),
          ),
        ],
      );
}
