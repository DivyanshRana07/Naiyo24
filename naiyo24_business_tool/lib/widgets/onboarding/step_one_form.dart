import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/models/business_profile_model.dart';
import 'package:naiyo24_business_tool/notifiers/business_profile_notifier.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/custom_text_field.dart';
import 'package:naiyo24_business_tool/widgets/common/custom_button.dart';
import 'package:naiyo24_business_tool/widgets/common/dropdown_field.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';

class StepOneForm extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const StepOneForm({super.key, required this.onContinue});

  @override
  ConsumerState<StepOneForm> createState() => _StepOneFormState();
}

class _StepOneFormState extends ConsumerState<StepOneForm> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();

  bool _showBrandName = false;
  bool _hasGst = true;
  String? _selectedTeamSize;
  String? _selectedUseCase;
  String? _selectedBusinessType;
  String _selectedCountry = 'India';
  String _selectedCurrency = 'Indian Rupee (INR, ₹)';
  String _selectedPhoneCode = '+91';

  static const List<String> _teamSizes = [
    'Just me',
    '2-10',
    '11-50',
    '51-200',
    '200+'
  ];

  static const List<Map<String, String>> _countries = [
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
  ];

  static const List<String> _currencies = [
    'Indian Rupee (INR, ₹)',
    'US Dollar (USD, \$)',
    'Euro (EUR, €)',
    'British Pound (GBP, £)'
  ];

  static const List<Map<String, String>> _phoneCodes = [
    {'label': '🇮🇳 +91', 'value': '+91'},
    {'label': '🇺🇸 +1', 'value': '+1'},
    {'label': '🇬🇧 +44', 'value': '+44'},
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _brandNameController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      final profile = BusinessProfileModel(
        businessName: _businessNameController.text.trim(),
        brandName: _showBrandName ? _brandNameController.text.trim() : '',
        website: _websiteController.text.trim(),
        phone: '$_selectedPhoneCode ${_phoneController.text.trim()}',
        country: _selectedCountry,
        currency: _selectedCurrency,
        gstNumber: _hasGst ? _gstController.text.trim() : '',
      );
      ref.read(businessProfileNotifierProvider.notifier).saveProfile(profile);
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBusinessNameSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildTeamSizeAndWebsite(),
          const SizedBox(height: AppSpacing.lg),
          _buildPhoneSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildCountryAndCurrency(),
          const SizedBox(height: AppSpacing.lg),
          _buildGstSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildUseCaseDropdown(),
          const SizedBox(height: AppSpacing.lg),
          _buildBusinessTypeDropdown(),
          const SizedBox(height: AppSpacing.xxl),
          CustomButton(
            label: 'Continue \u2192',
            onPressed: _handleContinue,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormFieldLabel(
          text: '1. Business Name*',
          subtitle: 'Official Name used across Accounting documents and reports.',
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomTextField(
          controller: _businessNameController,
          hintText: 'If you\'re a freelancer, add your personal name',
          validator: (v) =>
              v == null || v.isEmpty ? 'Business name is required' : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!_showBrandName)
          GestureDetector(
            onTap: () => setState(() => _showBrandName = true),
            child: Row(
              children: [
                Icon(Icons.add_box_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Add Brand or Display name',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          )
        else ...[
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            controller: _brandNameController,
            hintText: 'Brand or Display name',
          ),
        ],
      ],
    );
  }

  Widget _buildTeamSizeAndWebsite() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('2. Team Size*'),
              const SizedBox(height: AppSpacing.sm),
              DropdownField<String>(
                value: _selectedTeamSize,
                hint: 'Select Team Size',
                items: DropdownField.stringItems(_teamSizes),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => setState(() => _selectedTeamSize = v),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('3. Website'),
              const SizedBox(height: AppSpacing.sm),
              CustomTextField(
                controller: _websiteController,
                hintText: 'Your Work Website',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormFieldLabel(
          text: '4. Phone Number*',
          subtitle: 'Contact phone number associated with your business',
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: DropdownField<String>(
                value: _selectedPhoneCode,
                items: _phoneCodes
                    .map((c) => DropdownMenuItem(
                        value: c['value'], child: Text(c['label']!)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPhoneCode = v ?? '+91'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CustomTextField(
                controller: _phoneController,
                hintText: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountryAndCurrency() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('5. Country*'),
              const SizedBox(height: AppSpacing.sm),
              DropdownField<String>(
                value: _selectedCountry,
                items: _countries
                    .map((c) => DropdownMenuItem(
                        value: c['name'], child: Text(c['name']!)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCountry = v ?? 'India'),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('6. Currency*'),
              const SizedBox(height: AppSpacing.sm),
              DropdownField<String>(
                value: _selectedCurrency,
                items: DropdownField.stringItems(_currencies),
                onChanged: (v) =>
                    setState(() => _selectedCurrency = v ?? 'Indian Rupee (INR, ₹)'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGstSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FormFieldLabel(
                text: _hasGst ? '7. Have GST Number?*' : '7. Have GST Number?',
                subtitle: 'Add your GSTIN to unlock smart AI and GST workflows.',
              ),
            ),
            Switch(
              value: _hasGst,
              onChanged: (v) => setState(() => _hasGst = v),
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
        if (_hasGst) ...[
          const SizedBox(height: AppSpacing.sm),
          CustomTextField(
            controller: _gstController,
            hintText: 'Enter Your GST Number',
            validator: (v) =>
                v == null || v.isEmpty ? 'GST number is required' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildUseCaseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('8. What do you want to use Naiyo Business Tool for?'),
        const SizedBox(height: AppSpacing.sm),
        DropdownField<String>(
          value: _selectedUseCase,
          hint: 'Select...',
          items: DropdownField.categorizedItems({
            'ACCOUNTING': [
              'End-to-end accounting',
              'Accounting services',
              'GST Compliance',
              'E-invoices & E-way Bills',
              'Only Invoicing & Billing',
              'Automate Invoicing (APIs/Shopify)',
            ],
            'INVENTORY MANAGEMENT': [
              'Manage stock',
              'Manage stock locations/warehouses',
              'Batch-wise tracking with expiry',
            ],
            'SALES CRM': [
              'End-to-end Sales Management',
              'Lead Generation Forms',
              'Automate Lead Capture (IndiaMART, Meta, etc.)',
            ],
          }),
          onChanged: (v) => setState(() => _selectedUseCase = v),
        ),
      ],
    );
  }

  Widget _buildBusinessTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('9. What best describes your business?'),
        const SizedBox(height: AppSpacing.sm),
        DropdownField<String>(
          value: _selectedBusinessType,
          hint: 'Select...',
          items: DropdownField.stringItems([
            'Manufacturer',
            'Trading',
            'Retail',
            'Online',
            'Professional Services',
            'Contractor',
            'Software',
            'Something else',
          ]),
          onChanged: (v) => setState(() => _selectedBusinessType = v),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
    );
  }
}
