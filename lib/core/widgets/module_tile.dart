import 'package:flutter/material.dart';
import 'package:mandi/core/theme/app_theme.dart';

/// One tile in a dashboard's "Modules" / "Manage" grid.
///
/// Pass [onTap] for a module that has a real screen; leave it null for a
/// module that's designed-for but not built yet — it renders muted with a
/// lock icon and taps show a "coming soon" message instead of silently
/// doing nothing or, worse, navigating somewhere broken.
class ModuleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ModuleTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  bool get _locked => onTap == null;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ??
          () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label — coming soon')),
              ),
      borderRadius: MRadius.md,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: MSpacing.md),
        decoration: BoxDecoration(
          color: MColors.surface,
          borderRadius: MRadius.md,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: _locked ? MColors.textSecondary : MColors.primary),
            const SizedBox(height: MSpacing.xs),
            Text(
              label,
              style: MText.labelMd.copyWith(
                color: _locked ? MColors.textSecondary : null,
              ),
              textAlign: TextAlign.center,
            ),
            if (_locked) ...[
              const SizedBox(height: 2),
              const Icon(Icons.lock_outline, size: 12, color: MColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
