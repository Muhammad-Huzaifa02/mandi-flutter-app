// Dialog to Callout Queued Vehicle to Unloading Platform
// (*پھڑ پر ان لوڈنگ کے لیے بلائیں*).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/locale_provider.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/gate_pass_model.dart';
import 'package:mandi/modules/gate_pass/providers/gate_pass_provider.dart';

class CalloutPlatformDialog extends StatefulWidget {
  final GatePassModel gatePass;

  const CalloutPlatformDialog({super.key, required this.gatePass});

  @override
  State<CalloutPlatformDialog> createState() => _CalloutPlatformDialogState();
}

class _CalloutPlatformDialogState extends State<CalloutPlatformDialog> {
  String? _selectedPlatform;
  bool _isCalling = false;

  List<String> _platforms(bool isUrdu) => isUrdu
      ? const [
          'پھڑ نمبر 1',
          'پھڑ نمبر 2',
          'پھڑ نمبر 3',
          'پھڑ نمبر 4',
          'شیڈ نمبر A',
          'شیڈ نمبر B',
        ]
      : const [
          'Platform 1',
          'Platform 2',
          'Platform 3',
          'Platform 4',
          'Shed A',
          'Shed B',
        ];

  Future<void> _submit() async {
    setState(() => _isCalling = true);
    final provider = context.read<GatePassProvider>();
    final platformName = _selectedPlatform ?? _platforms(AppStrings.isUrdu(context)).first;
    final success = await provider.calloutForUnloading(
      passId: widget.gatePass.id,
      platformName: platformName,
    );

    setState(() => _isCalling = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Callout Issued: ${widget.gatePass.tokenNumber} -> $platformName',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error calling out platform'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = context.watch<LocaleProvider>().isUrdu;
    final platformList = _platforms(isUrdu);
    _selectedPlatform ??= platformList[0];

    return GlassDialog(
      maxWidth: 500,
      title: Row(
        children: [
          const Icon(Icons.campaign, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${AppStrings.tr(context, 'callout_dialog_title')} (${widget.gatePass.tokenNumber})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle: ${widget.gatePass.vehicleNumber}\nDriver: ${widget.gatePass.driverName}\nFarmer: ${widget.gatePass.farmerName} (${widget.gatePass.commodityName})',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.tr(context, 'select_unloading_platform'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedPlatform,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.storefront),
            ),
            items: platformList.map((p) {
              return DropdownMenuItem<String>(
                value: p,
                child: Text(p, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedPlatform = val);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isCalling ? null : () => Navigator.pop(context),
          child: Text(AppStrings.tr(context, 'cancel')),
        ),
        ElevatedButton.icon(
          onPressed: _isCalling ? null : _submit,
          icon: _isCalling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.volume_up, color: Colors.white),
          label: Text(AppStrings.tr(context, 'callout_btn'), style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[900]),
        ),
      ],
    );
  }
}
