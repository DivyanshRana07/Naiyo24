import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/notifiers/customer_notifier.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';

class CustomerForm extends ConsumerStatefulWidget {
  const CustomerForm({
    super.key,
    this.existing,
    this.onSaved,
    this.onCancel,
  });

  final CustomerModel? existing;
  final void Function(CustomerModel)? onSaved;
  final VoidCallback? onCancel;

  @override
  ConsumerState<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<CustomerForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _gstCtrl;
  late TextEditingController _creditLimitCtrl;
  late TextEditingController _openingBalanceCtrl;

  CustomerStatus _status = CustomerStatus.active;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _mobileCtrl = TextEditingController(text: e?.mobile ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _gstCtrl = TextEditingController(text: e?.gstNumber ?? '');
    _creditLimitCtrl =
        TextEditingController(text: e?.creditLimit.toString() ?? '0');
    _openingBalanceCtrl =
        TextEditingController(text: e?.openingBalance.toString() ?? '0');
    _status = e?.status ?? CustomerStatus.active;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    _creditLimitCtrl.dispose();
    _openingBalanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Customer Name
          LabeledField(
            label: 'Customer Name *',
            child: TextFormField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(hintText: 'e.g. Rahul Medical Store'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Code + Mobile
          FormPairRow(
            left: LabeledField(
              label: 'Customer Code *',
              child: TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(hintText: 'e.g. C001'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            right: LabeledField(
              label: 'Mobile *',
              child: TextFormField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '10-digit number'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Email
          LabeledField(
            label: 'Email (optional)',
            child: TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(hintText: 'customer@example.com'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Address
          LabeledField(
            label: 'Address (optional)',
            child: TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(hintText: 'Street, City, State - PIN'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // GST
          LabeledField(
            label: 'GST Number (optional)',
            child: TextFormField(
              controller: _gstCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  hintText: '15-digit GSTIN e.g. 29ABCDE1234F1Z5'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Credit Limit + Opening Balance
          FormPairRow(
            left: LabeledField(
              label: 'Credit Limit (₹)',
              child: TextFormField(
                controller: _creditLimitCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(hintText: '0'),
              ),
            ),
            right: LabeledField(
              label: 'Opening Balance (₹)',
              child: TextFormField(
                controller: _openingBalanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(hintText: '0'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Status
          LabeledField(
            label: 'Status',
            child: DropdownButtonFormField<CustomerStatus>(
              initialValue: _status,
              isExpanded: true,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(
                    value: CustomerStatus.active, child: Text('Active')),
                DropdownMenuItem(
                    value: CustomerStatus.inactive, child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel ?? () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                  ),
                  onPressed: _save,
                  child: Text(
                    _isEditing ? 'Save Changes' : 'Save Customer',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(customerNotifierProvider.notifier);
    final customer = CustomerModel(
      id: widget.existing?.id ?? 'c-${DateTime.now().millisecondsSinceEpoch}',
      code: _codeCtrl.text.trim().toUpperCase(),
      name: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      gstNumber: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
      creditLimit: double.tryParse(_creditLimitCtrl.text) ?? 0,
      openingBalance: double.tryParse(_openingBalanceCtrl.text) ?? 0,
      status: _status,
    );

    if (_isEditing) {
      notifier.updateCustomer(customer);
    } else {
      notifier.addCustomer(customer);
    }

    if (widget.onSaved != null) {
      widget.onSaved!(customer);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? '${customer.name} updated successfully.'
              : '${customer.name} added to directory.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
