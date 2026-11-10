import 'package:flutter/material.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';

/// Interactive Munshi Mobile & Desktop Thermal Print Preview Modal.
///
/// Simulates a physical thermal receipt with realistic paper texture,
/// jagged cut bottom border, 58mm/80mm roll width selector, copies counter,
/// and direct layout print trigger.
class ThermalPrintPreviewDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<String> previewLines;
  final Future<void> Function(double rollWidthMm, int copies) onPrint;
  final double initialRollWidth;

  const ThermalPrintPreviewDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.previewLines,
    required this.onPrint,
    this.initialRollWidth = 80.0,
  });

  /// Convenient helper to open the dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    required List<String> previewLines,
    required Future<void> Function(double rollWidthMm, int copies) onPrint,
    double initialRollWidth = 80.0,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ThermalPrintPreviewDialog(
        title: title,
        subtitle: subtitle,
        previewLines: previewLines,
        onPrint: onPrint,
        initialRollWidth: initialRollWidth,
      ),
    );
  }

  @override
  State<ThermalPrintPreviewDialog> createState() =>
      _ThermalPrintPreviewDialogState();
}

class _ThermalPrintPreviewDialogState extends State<ThermalPrintPreviewDialog> {
  late double _selectedWidth;
  int _copies = 1;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _selectedWidth = widget.initialRollWidth;
  }

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      await widget.onPrint(_selectedWidth, _copies);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print job sent to thermal printer successfully!'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printing failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        child: GlassCard(
          padding: const EdgeInsets.all(MSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.print_rounded,
                        color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: MText.titleMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: MText.bodySm.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: MSpacing.md),

              // Roll Width & Copies Controls
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<double>(
                      segments: const [
                        ButtonSegment(
                          value: 80.0,
                          label: Text('80mm'),
                          icon: Icon(Icons.receipt_long, size: 16),
                        ),
                        ButtonSegment(
                          value: 58.0,
                          label: Text('58mm'),
                          icon: Icon(Icons.bluetooth, size: 16),
                        ),
                      ],
                      selected: {_selectedWidth},
                      onSelectionChanged: (set) {
                        setState(() => _selectedWidth = set.first);
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: MSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 24, minHeight: 24),
                          onPressed: _copies > 1
                              ? () => setState(() => _copies--)
                              : null,
                        ),
                        Text('$_copies',
                            style: MText.bodySm
                                .copyWith(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 24, minHeight: 24),
                          onPressed: _copies < 5
                              ? () => setState(() => _copies++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: MSpacing.md),

              // Simulated Thermal Roll Paper Preview
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7), // Warm receipt paper color
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: CustomPaint(
                      painter: _SerratedBottomPainter(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: widget.previewLines.map((line) {
                                final isHeader = line.startsWith('***') ||
                                    line.contains('MANDI') ||
                                    line.contains('COMMISSION');
                                final isDivider = line.startsWith('---') ||
                                    line.startsWith('===');
                                final isBold = line.contains('TOTAL') ||
                                    line.contains('RECEIVED') ||
                                    line.contains('WINNER') ||
                                    line.contains('FINAL');

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0.8),
                                  child: Text(
                                    line,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: _selectedWidth == 58 ? 10.5 : 11.5,
                                      fontWeight: isBold || isHeader
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isDivider
                                          ? const Color(0xFF757575)
                                          : const Color(0xFF1E1E1E),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: MSpacing.md),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel / بند کریں'),
                    ),
                  ),
                  const SizedBox(width: MSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _handlePrint,
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.print_rounded, size: 20),
                      label: Text(
                        _isPrinting
                          ? 'Printing...'
                          : 'Print Slip (${_selectedWidth.toStringAsFixed(0)}mm)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for drawing a serrated / jagged receipt paper tear bottom
class _SerratedBottomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    const toothWidth = 8.0;
    const toothHeight = 4.0;
    final teethCount = (size.width / toothWidth).ceil();

    path.moveTo(0, size.height);
    for (int i = 0; i < teethCount; i++) {
      final x = i * toothWidth;
      path.lineTo(x + toothWidth / 2, size.height - toothHeight);
      path.lineTo(x + toothWidth, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
