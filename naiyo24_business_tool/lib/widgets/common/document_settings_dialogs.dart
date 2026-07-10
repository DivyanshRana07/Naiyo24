import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

class DocumentSettingsButtons extends StatelessWidget {
  const DocumentSettingsButtons({
    super.key,
    required this.onConfigureGst,
    required this.onConfigureFormat,
    required this.onConfigureColumns,
  });

  final VoidCallback onConfigureGst;
  final VoidCallback onConfigureFormat;
  final VoidCallback onConfigureColumns;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _configBtn(Icons.percent_rounded, 'Configure GST', onConfigureGst),
        const SizedBox(height: AppSpacing.sm),
        _configBtn(
            Icons.format_list_numbered_rounded,
            'Number and Currency Format',
            onConfigureFormat),
        const SizedBox(height: AppSpacing.sm),
        _configBtn(Icons.table_chart_outlined, 'Edit Columns/Formulas', onConfigureColumns),
      ],
    );
  }

  Widget _configBtn(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 48),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
        ),
        icon: Icon(icon, size: 18, color: AppColors.primary),
        label: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

/// Wraps a [SwitchListTile] in its own Material so ink effects don't clash
/// with the AlertDialog's decorated background.
Widget _switchTile({
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return Material(
    color: Colors.transparent,
    child: SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    ),
  );
}

/// An input decoration consistent with the dark dialog background.
InputDecoration _inputDec(String label) => InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.input),
        borderSide: BorderSide(color: AppColors.borderFocus.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.input),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );

// ── GST Config Dialog ──────────────────────────────────────────────────────────

void showGstConfigDialog({
  required BuildContext context,
  required Map<String, dynamic> settings,
  required ValueChanged<Map<String, dynamic>> onSaved,
}) {
  final gstSettings = settings['gst'] as Map<String, dynamic>;
  bool enabled = gstSettings['enabled'] ?? true;
  double defaultRate = gstSettings['defaultRate'] ?? 12.0;
  bool isInclusive = gstSettings['isInclusive'] ?? false;
  final gstinController = TextEditingController(text: gstSettings['gstin'] ?? '');

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Configure GST', style: AppTextStyles.h2),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _switchTile(
                label: 'Enable GST Tax',
                value: enabled,
                onChanged: (val) => setDialogState(() => enabled = val),
              ),
              if (enabled) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<double>(
                  initialValue: defaultRate,
                  decoration: _inputDec('Default GST Rate'),
                  dropdownColor: AppColors.cardBg,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  items: [
                    DropdownMenuItem(
                        value: 0.0,
                        child: Text('0%', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                    DropdownMenuItem(
                        value: 5.0,
                        child: Text('5%', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                    DropdownMenuItem(
                        value: 12.0,
                        child: Text('12%', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                    DropdownMenuItem(
                        value: 18.0,
                        child: Text('18%', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                    DropdownMenuItem(
                        value: 28.0,
                        child: Text('28%', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                  ],
                  onChanged: (val) => setDialogState(() => defaultRate = val!),
                ),
                const SizedBox(height: 12),
                _switchTile(
                  label: 'Prices are Inclusive of GST',
                  value: isInclusive,
                  onChanged: (val) => setDialogState(() => isInclusive = val),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: gstinController,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: _inputDec('Your Business GSTIN')
                      .copyWith(hintText: 'e.g. 22AAAAA1111A1Z1'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              onSaved({
                ...settings,
                'gst': {
                  'enabled': enabled,
                  'defaultRate': defaultRate,
                  'isInclusive': isInclusive,
                  'gstin': gstinController.text.trim(),
                }
              });
              Navigator.pop(dialogCtx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

// ── Format Config Dialog ───────────────────────────────────────────────────────

void showFormatConfigDialog({
  required BuildContext context,
  required Map<String, dynamic> settings,
  required ValueChanged<Map<String, dynamic>> onSaved,
}) {
  final formatSettings = settings['format'] as Map<String, dynamic>;
  String currency = formatSettings['currency'] ?? 'INR';
  int decimals = formatSettings['decimals'] ?? 2;
  bool indianFormat = formatSettings['indianFormat'] ?? true;

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Number & Currency Format', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: currency,
              decoration: _inputDec('Currency'),
              dropdownColor: AppColors.cardBg,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              items: [
                DropdownMenuItem(
                    value: 'INR',
                    child: Text('Indian Rupee (INR, ₹)',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                DropdownMenuItem(
                    value: 'USD',
                    child: Text('US Dollar (USD, \$)',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                DropdownMenuItem(
                    value: 'EUR',
                    child: Text('Euro (EUR, €)',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                DropdownMenuItem(
                    value: 'GBP',
                    child: Text('British Pound (GBP, £)',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
              ],
              onChanged: (val) => setDialogState(() => currency = val!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: decimals,
              decoration: _inputDec('Decimal Places'),
              dropdownColor: AppColors.cardBg,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              items: [
                DropdownMenuItem(
                    value: 2,
                    child: Text('2 Decimals',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                DropdownMenuItem(
                    value: 3,
                    child: Text('3 Decimals',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                DropdownMenuItem(
                    value: 4,
                    child: Text('4 Decimals',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
              ],
              onChanged: (val) => setDialogState(() => decimals = val!),
            ),
            const SizedBox(height: 12),
            _switchTile(
              label: 'Use Indian Format (Lakhs)',
              value: indianFormat,
              onChanged: (val) => setDialogState(() => indianFormat = val),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              String symbol = '₹';
              if (currency == 'USD') symbol = '\$';
              if (currency == 'EUR') symbol = '€';
              if (currency == 'GBP') symbol = '£';
              onSaved({
                ...settings,
                'format': {
                  'currency': currency,
                  'currencySymbol': symbol,
                  'decimals': decimals,
                  'indianFormat': indianFormat,
                }
              });
              Navigator.pop(dialogCtx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

// ── Columns Config Dialog ──────────────────────────────────────────────────────

void showColumnsConfigDialog({
  required BuildContext context,
  required Map<String, dynamic> settings,
  required ValueChanged<Map<String, dynamic>> onSaved,
}) {
  final columnsSettings = settings['columns'] as Map<String, dynamic>;
  bool showHsn = columnsSettings['hsn'] ?? true;
  bool showDiscount = columnsSettings['discount'] ?? true;
  bool showGst = columnsSettings['gst'] ?? true;
  bool showUnit = columnsSettings['unit'] ?? true;
  bool showCategory = columnsSettings['category'] ?? true;

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Edit Columns / Formulas', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _switchTile(
              label: 'Show HSN/SAC Code Column',
              value: showHsn,
              onChanged: (val) => setDialogState(() => showHsn = val),
            ),
            _switchTile(
              label: 'Show Discount Column',
              value: showDiscount,
              onChanged: (val) => setDialogState(() => showDiscount = val),
            ),
            _switchTile(
              label: 'Show GST Rate & Tax Columns',
              value: showGst,
              onChanged: (val) => setDialogState(() => showGst = val),
            ),
            _switchTile(
              label: 'Show Unit Column',
              value: showUnit,
              onChanged: (val) => setDialogState(() => showUnit = val),
            ),
            _switchTile(
              label: 'Show Category Column',
              value: showCategory,
              onChanged: (val) => setDialogState(() => showCategory = val),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              onSaved({
                ...settings,
                'columns': {
                  'hsn': showHsn,
                  'discount': showDiscount,
                  'gst': showGst,
                  'unit': showUnit,
                  'category': showCategory,
                }
              });
              Navigator.pop(dialogCtx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
