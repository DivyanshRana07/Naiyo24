import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/service_model.dart';
import 'package:naiyo24_business_tool/notifiers/service_notifier.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/app_form_dialog.dart';
import 'package:naiyo24_business_tool/widgets/common/dropdown_field.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';

class ServiceFormDialog extends ConsumerStatefulWidget {
  const ServiceFormDialog({super.key, this.existing});

  final ServiceModel? existing;

  @override
  ConsumerState<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends ConsumerState<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _priceCtrl;

  String _category = 'Delivery';
  double _gstPercent = 18;
  ServiceStatus _status = ServiceStatus.active;

  bool get _isEditing => widget.existing != null;

  static const List<String> _categories = [
    'Delivery',
    'Consulting',
    'Laboratory',
    'Installation',
    'Repair',
    'Subscription',
    'Maintenance',
    'Other',
  ];

  static const List<double> _gstRates = [0, 5, 12, 18, 28];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _priceCtrl = TextEditingController(text: e?.sellingPrice.toString() ?? '');
    _category = e?.category ?? 'Delivery';
    _gstPercent = e?.gstPercent ?? 18;
    _status = e?.status ?? ServiceStatus.active;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialog(
      formKey: _formKey,
      title: _isEditing ? 'Edit Service' : 'Add New Service',
      icon: Icons.miscellaneous_services_rounded,
      iconColor: const Color(0xFF0284C7),
      iconBgColor: const Color(0xFFE0F2FE),
      saveLabel: _isEditing ? 'Save Changes' : 'Save Service',
      saveColor: const Color(0xFF0284C7),
      maxWidth: 480,
      onSave: _save,
      children: [
        // Service Name
        LabeledField(
          label: 'Service Name *',
          child: TextFormField(
            controller: _nameCtrl,
            decoration:
                const InputDecoration(hintText: 'e.g. Home Delivery'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Service Code
        LabeledField(
          label: 'Service Code *',
          child: TextFormField(
            controller: _codeCtrl,
            decoration: const InputDecoration(hintText: 'e.g. S001'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Category
        LabeledField(
          label: 'Category *',
          child: DropdownField<String>(
            value: _category,
            items: DropdownField.stringItems(_categories),
            onChanged: (v) => setState(() => _category = v!),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Price + GST
        FormPairRow(
          left: LabeledField(
            label: 'Price (₹) *',
            child: TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
          ),
          right: LabeledField(
            label: 'GST %',
            child: DropdownField<double>(
              value: _gstPercent,
              items: _gstRates
                  .map((g) => DropdownMenuItem(
                      value: g,
                      child: Text('${g.toStringAsFixed(0)}%')))
                  .toList(),
              onChanged: (v) => setState(() => _gstPercent = v!),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Status
        LabeledField(
          label: 'Status',
          child: DropdownField<ServiceStatus>(
            value: _status,
            items: const [
              DropdownMenuItem(
                  value: ServiceStatus.active, child: Text('Active')),
              DropdownMenuItem(
                  value: ServiceStatus.inactive, child: Text('Inactive')),
            ],
            onChanged: (v) => setState(() => _status = v!),
          ),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(serviceNotifierProvider.notifier);
    final service = ServiceModel(
      id: widget.existing?.id ?? 's-${DateTime.now().millisecondsSinceEpoch}',
      code: _codeCtrl.text.trim().toUpperCase(),
      name: _nameCtrl.text.trim(),
      category: _category,
      sellingPrice: double.tryParse(_priceCtrl.text) ?? 0,
      gstPercent: _gstPercent,
      status: _status,
    );
    if (_isEditing) {
      notifier.updateService(service);
    } else {
      notifier.addService(service);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? '${service.name} updated successfully.'
              : '${service.name} added to catalog.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
