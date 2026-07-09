import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/vendor_model.dart';
import 'package:naiyo24_business_tool/notifiers/vendor_notifier.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/custom_text_field.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';

class VendorForm extends ConsumerStatefulWidget {
  const VendorForm({
    super.key,
    this.existingVendor,
    this.onSaved,
    this.onCancel,
  });

  final VendorModel? existingVendor;
  final void Function(VendorModel)? onSaved;
  final VoidCallback? onCancel;

  @override
  ConsumerState<VendorForm> createState() => _VendorFormState();
}

class _VendorFormState extends ConsumerState<VendorForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool get _isEditing => widget.existingVendor != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existingVendor;
    _nameController = TextEditingController(text: v?.name ?? '');
    _contactPersonController =
        TextEditingController(text: v?.contactPerson ?? '');
    _emailController = TextEditingController(text: v?.email ?? '');
    _phoneController = TextEditingController(text: v?.phone ?? '');
    _addressController = TextEditingController(text: v?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
          // Vendor Name
          LabeledField(
            label: 'Vendor / Company Name *',
            child: CustomTextField(
              controller: _nameController,
              hintText: 'Enter vendor name',
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Contact Person
          LabeledField(
            label: 'Contact Person',
            child: CustomTextField(
              controller: _contactPersonController,
              hintText: 'Enter contact person name',
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Email + Phone
          FormPairRow(
            left: LabeledField(
              label: 'Email Address',
              child: CustomTextField(
                controller: _emailController,
                hintText: 'Enter email',
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            right: LabeledField(
              label: 'Phone Number',
              child: CustomTextField(
                controller: _phoneController,
                hintText: 'Enter phone',
                keyboardType: TextInputType.phone,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Address
          LabeledField(
            label: 'Billing Address',
            child: CustomTextField(
              controller: _addressController,
              hintText: 'Enter complete billing address',
              maxLines: 3,
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
                    _isEditing ? 'Save Changes' : 'Save Vendor',
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_isEditing) {
        final vendor = VendorModel(
          id: widget.existingVendor!.id,
          name: _nameController.text.trim(),
          contactPerson: _contactPersonController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );
        await ref.read(vendorNotifierProvider.notifier).updateVendor(vendor);
        
        if (widget.onSaved != null) {
          widget.onSaved!(vendor);
        }
      } else {
        await ref.read(vendorNotifierProvider.notifier).addVendor(
          name: _nameController.text.trim(),
          contactPerson: _contactPersonController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Vendor updated successfully'
                  : 'Vendor added successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
