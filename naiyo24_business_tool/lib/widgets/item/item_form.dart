import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/item_model.dart';
import 'package:naiyo24_business_tool/notifiers/item_notifier.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/dropdown_field.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';

class ItemForm extends ConsumerStatefulWidget {
  const ItemForm({
    super.key,
    this.existing,
    this.onSaved,
    this.onCancel,
  });

  final ItemModel? existing;
  final void Function(ItemModel)? onSaved;
  final VoidCallback? onCancel;

  @override
  ConsumerState<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends ConsumerState<ItemForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _purchasePriceCtrl;
  late TextEditingController _sellingPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _gstCtrl;

  String _category = 'Medicine';
  String _unit = 'Strip';
  ItemStatus _status = ItemStatus.active;

  bool get _isEditing => widget.existing != null;

  static const List<String> _categories = [
    'Medicine',
    'Grocery',
    'Electronics',
    'Clothing',
    'Food & Beverage',
    'Cosmetics',
    'Stationery',
    'Other',
  ];

  static const List<String> _units = [
    'Strip',
    'Capsule',
    'Tablet',
    'Bottle',
    'Kg',
    'Gram',
    'Litre',
    'Ml',
    'Piece',
    'Box',
    'Packet',
    'Other',
  ];

  static const List<double> _gstRates = [0, 5, 12, 18, 28];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _purchasePriceCtrl =
        TextEditingController(text: e?.purchasePrice.toString() ?? '');
    _sellingPriceCtrl =
        TextEditingController(text: e?.sellingPrice.toString() ?? '');
    _stockCtrl = TextEditingController(text: e?.stockQty.toString() ?? '');
    _gstCtrl =
        TextEditingController(text: e?.gstPercent.toStringAsFixed(0) ?? '12');
    _category = e?.category ?? 'Medicine';
    _unit = e?.unit ?? 'Strip';
    _status = e?.status ?? ItemStatus.active;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _stockCtrl.dispose();
    _gstCtrl.dispose();
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
          // Item Name
          LabeledField(
            label: 'Item Name *',
            child: TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'e.g. Paracetamol 650mg'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Item Code
          LabeledField(
            label: 'Item Code / SKU *',
            child: TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(hintText: 'e.g. P001'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Category + Unit
          FormPairRow(
            left: LabeledField(
              label: 'Category *',
              child: DropdownField<String>(
                value: _category,
                items: DropdownField.stringItems(_categories),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ),
            right: LabeledField(
              label: 'Unit *',
              child: DropdownField<String>(
                value: _unit,
                items: DropdownField.stringItems(_units),
                onChanged: (v) => setState(() => _unit = v!),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Purchase Price + Selling Price
          FormPairRow(
            left: LabeledField(
              label: 'Purchase Price (₹) *',
              child: TextFormField(
                controller: _purchasePriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(hintText: '0.00'),
                validator: _validatePrice,
              ),
            ),
            right: LabeledField(
              label: 'Selling Price (₹) *',
              child: TextFormField(
                controller: _sellingPriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(hintText: '0.00'),
                validator: _validatePrice,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Opening Stock + GST
          FormPairRow(
            left: LabeledField(
              label: 'Opening Stock',
              child: TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '0'),
              ),
            ),
            right: LabeledField(
              label: 'GST % *',
              child: DropdownField<double>(
                value: double.tryParse(_gstCtrl.text) ?? 12,
                items: _gstRates
                    .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text('${g.toStringAsFixed(0)}%')))
                    .toList(),
                onChanged: (v) => _gstCtrl.text = v!.toStringAsFixed(0),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Status
          LabeledField(
            label: 'Status',
            child: DropdownField<ItemStatus>(
              value: _status,
              items: const [
                DropdownMenuItem(
                    value: ItemStatus.active, child: Text('Active')),
                DropdownMenuItem(
                    value: ItemStatus.inactive, child: Text('Inactive')),
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
                    _isEditing ? 'Save Changes' : 'Save Item',
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
    final notifier = ref.read(itemNotifierProvider.notifier);
    final item = ItemModel(
      id: widget.existing?.id ?? 'p-${DateTime.now().millisecondsSinceEpoch}',
      code: _codeCtrl.text.trim().toUpperCase(),
      name: _nameCtrl.text.trim(),
      category: _category,
      unit: _unit,
      purchasePrice: double.tryParse(_purchasePriceCtrl.text) ?? 0,
      sellingPrice: double.tryParse(_sellingPriceCtrl.text) ?? 0,
      stockQty: int.tryParse(_stockCtrl.text) ?? 0,
      gstPercent: double.tryParse(_gstCtrl.text) ?? 0,
      status: _status,
    );

    if (_isEditing) {
      notifier.updateItem(item);
    } else {
      notifier.addItem(item);
    }

    if (widget.onSaved != null) {
      widget.onSaved!(item);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? '${item.name} updated successfully.'
              : '${item.name} added to inventory.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String? _validatePrice(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (double.tryParse(v) == null) return 'Enter a valid number';
    return null;
  }
}
