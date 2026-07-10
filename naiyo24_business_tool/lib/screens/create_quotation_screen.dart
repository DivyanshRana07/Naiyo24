import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart' as export_helper;
import 'package:naiyo24_business_tool/utils/document_calculator.dart';
import 'package:naiyo24_business_tool/widgets/common/document_settings_dialogs.dart';

import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/models/quotation_model.dart';
import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/quotation_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/confirm_discard_dialog.dart';
import 'package:naiyo24_business_tool/widgets/common/dashboard_app_bar.dart';
import 'package:naiyo24_business_tool/widgets/common/side_navigation.dart';
import 'package:naiyo24_business_tool/widgets/invoice/create_invoice_widgets.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';
import 'package:naiyo24_business_tool/models/line_item_model.dart';
import 'package:naiyo24_business_tool/widgets/invoice/send_options_dialog.dart';
import 'package:naiyo24_business_tool/widgets/quotation/create_quotation_widgets.dart';
import 'package:naiyo24_business_tool/utils/constants.dart';
import 'package:naiyo24_business_tool/utils/extensions.dart';

class CreateQuotationScreen extends ConsumerStatefulWidget {
  const CreateQuotationScreen({super.key});

  @override
  ConsumerState<CreateQuotationScreen> createState() =>
      _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends ConsumerState<CreateQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form state
  CustomerModel? _selectedCustomer;
  DateTime _quotationDate = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  final List<InvoiceLineItem> _lineItems = [];
  String _paymentTerms = AppConfig.defaultPaymentTerms;
  String _currency = AppConfig.defaultCurrency;
  
  // Text controllers
  final _referenceController = TextEditingController();
  final _termsController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isSaving = false;
  bool _isSavingAndSending = false;
  bool _hasChanges = false;

  String? _subtitle;
  bool _isEditingSubtitle = false;
  String? _logoBase64;
  late TextEditingController _subtitleCtrl;

  Map<String, dynamic> _invoiceSettings = {
    'gst': {
      'enabled': true,
      'defaultRate': 12.0,
      'isInclusive': false,
      'gstin': '',
    },
    'format': {
      'currency': 'INR',
      'currencySymbol': '₹',
      'decimals': 2,
      'indianFormat': true,
    },
    'columns': {
      'hsn': true,
      'discount': true,
      'gst': true,
      'unit': true,
      'category': true,
    }
  };

  @override
  void initState() {
    super.initState();
    _subtitleCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  double get _subTotal => DocumentCalculator.getSubTotal(_lineItems, _invoiceSettings);
  double get _totalDiscount => DocumentCalculator.getTotalDiscount(_lineItems);
  double get _totalGst => DocumentCalculator.getTotalGst(_lineItems, _invoiceSettings);
  double get _grandTotal => DocumentCalculator.getGrandTotal(_lineItems, _invoiceSettings);

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userEmail = authState.userEmail ?? '';
    
    final isMedium = MediaQuery.of(context).size.width >= 768;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await ConfirmDiscardDialog.show(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: DashboardAppBar(email: userEmail, showBackButton: true),
        drawer: !isMedium
            ? Drawer(
                child: SideNavigation(
                  email: userEmail,
                  onLogout: () =>
                      ref.read(authNotifierProvider.notifier).logout(),
                  currentRoute: AppRoutes.quotations,
                ),
              )
            : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMedium)
              SideNavigation(
                email: userEmail,
                onLogout: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                currentRoute: AppRoutes.quotations,
              ),
            Expanded(
              child: Form(
                key: _formKey,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepperHeader(),
              const SizedBox(height: AppSpacing.xl),
              _quotationTitleBlock(),
              const SizedBox(height: AppSpacing.md),
              _businessLogoBlock(),
              const SizedBox(height: AppSpacing.lg),
              QuotationCustomerFormSection(
                selectedCustomer: _selectedCustomer,
                onSelected: (customer) {
                  setState(() => _selectedCustomer = customer);
                  _markChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              QuotationMetaRow(
                quotationDate: _quotationDate,
                validUntil: _validUntil,
                referenceController: _referenceController,
                onQuotationDatePicked: (date) {
                  setState(() => _quotationDate = date);
                  _markChanged();
                },
                onValidUntilPicked: (date) {
                  setState(() => _validUntil = date);
                  _markChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              QuotationRightPaneControls(
                paymentTerms: _paymentTerms,
                currency: _currency,
                validUntil: _validUntil,
                onPaymentTermsChanged: (v) {
                  setState(() => _paymentTerms = v!);
                  _markChanged();
                },
                onCurrencyChanged: (v) {
                  setState(() => _currency = v!);
                  _markChanged();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DocumentSettingsButtons(
                onConfigureGst: () => showGstConfigDialog(
                  context: context,
                  settings: _invoiceSettings,
                  onSaved: (updated) => setState(() => _invoiceSettings = updated),
                ),
                onConfigureFormat: () => showFormatConfigDialog(
                  context: context,
                  settings: _invoiceSettings,
                  onSaved: (updated) => setState(() => _invoiceSettings = updated),
                ),
                onConfigureColumns: () => showColumnsConfigDialog(
                  context: context,
                  settings: _invoiceSettings,
                  onSaved: (updated) => setState(() => _invoiceSettings = updated),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LineItemsFormSection(
                lineItems: _lineItems,
                onItemAdded: (item) {
                  final gstSettings = _invoiceSettings['gst'] as Map<String, dynamic>?;
                  final defaultGstRate = gstSettings?['defaultRate'] as double? ?? 12.0;
                  final updatedItem = item.copyWith(
                    gstPercent: (item.gstPercent == 0.0 || item.gstPercent == 12.0) ? defaultGstRate : item.gstPercent,
                  );
                  setState(() => _lineItems.add(updatedItem));
                  _markChanged();
                },
                onItemChanged: (updated) {
                  final index = _lineItems.indexWhere((item) => item.id == updated.id);
                  if (index != -1) {
                    setState(() => _lineItems[index] = updated);
                    _markChanged();
                  }
                },
                onItemDeleted: (item) {
                  setState(() => _lineItems.remove(item));
                  _markChanged();
                },
                onClearAll: () {
                  setState(() => _lineItems.clear());
                  _markChanged();
                },
                settings: _invoiceSettings,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextInputSection(
                title: 'Terms & Conditions',
                icon: Icons.gavel_rounded,
                controller: _termsController,
                hintText: 'Enter terms and conditions...',
              ),
              const SizedBox(height: AppSpacing.lg),
              TextInputSection(
                title: 'Notes',
                icon: Icons.notes_rounded,
                controller: _notesController,
                hintText: 'Add any notes for this quotation...',
              ),
              const SizedBox(height: AppSpacing.xl),
              QuotationSummaryCard(
                subTotal: _subTotal,
                totalDiscount: _totalDiscount,
                taxableAmount: _subTotal,
                totalGst: _totalGst,
                grandTotal: _grandTotal,
                onAddTax: () {
                  context.showInfoSnackBar('Add Tax coming soon');
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              FormActionButtons(
                isSaving: _isSaving,
                isSavingAndSending: _isSavingAndSending,
                onSave: () => _saveQuotation(showSendDialog: false),
                onSaveAndSend: () => _saveQuotation(showSendDialog: true),
                onCancel: () => Navigator.maybePop(context),
                saveLabel: 'Save Quotation',
                buttonHeight: 52,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepperHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create New Quotation', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text(
              'Add Quotation Details',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Divider(color: AppColors.border, thickness: 1)),
          ],
        ),
      ],
    );
  }

  Widget _quotationTitleBlock() {
    return Center(
      child: Column(
        children: [
          Text(
            'Quotation',
            style: AppTextStyles.displayMedium
                .copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_isEditingSubtitle)
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: _subtitleCtrl,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'e.g. Price Quotation, Estimate',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: Colors.green, size: 18),
                    onPressed: () {
                      setState(() {
                        _subtitle = _subtitleCtrl.text.trim();
                        _isEditingSubtitle = false;
                      });
                    },
                  ),
                ),
                onFieldSubmitted: (v) {
                  setState(() {
                    _subtitle = v.trim();
                    _isEditingSubtitle = false;
                  });
                },
              ),
            )
          else
            InkWell(
              onTap: () {
                setState(() {
                  _subtitleCtrl.text = _subtitle ?? '';
                  _isEditingSubtitle = true;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: _subtitle == null || _subtitle!.isEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Add Subtitle',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      )
                    : Text(
                        _subtitle!,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickLogo() async {
    final base64 = await export_helper.pickLogoImage();
    if (base64 != null) {
      setState(() {
        _logoBase64 = base64;
      });
    }
  }

  Widget _businessLogoBlock() {
    final hasLogo = _logoBase64 != null && _logoBase64!.isNotEmpty;
    Uint8List? logoBytes;
    if (hasLogo) {
      try {
        final commaIdx = _logoBase64!.indexOf(',');
        final pureBase64 = commaIdx != -1
            ? _logoBase64!.substring(commaIdx + 1)
            : _logoBase64!;
        logoBytes = base64Decode(pureBase64);
      } catch (e) {
        logoBytes = null;
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: _pickLogo,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
          child: Column(
            children: [
              if (hasLogo && logoBytes != null) ...[
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: Image.memory(
                        logoBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete, size: 14, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _logoBase64 = null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Change Business Logo',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ] else ...[
                Icon(Icons.image_outlined, size: 40, color: AppColors.textHint),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Add Business Logo',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Resolution up to 1080×1080px.\nPNG or JPEG file.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _saveQuotation({bool showSendDialog = false}) async {
    if (!_formKey.currentState!.validate()) {
      context.showErrorSnackBar('Please fix the form errors');
      return;
    }

    if (_selectedCustomer == null) {
      context.showErrorSnackBar(ErrorMessages.selectCustomer);
      return;
    }

    if (_lineItems.isEmpty) {
      context.showErrorSnackBar(ErrorMessages.addLineItems);
      return;
    }

    if (showSendDialog) {
      _showSendOptionsDialog();
    } else {
      await _saveQuotationInternal(showSendDialog: false);
    }
  }

  void _showSendOptionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SendOptionsDialog(
        title: 'Quotation',
        whatsappText: '',
        pdfContent: '',
        filenamePrefix: 'quotation',
        onClose: () {
          context.go(AppRoutes.quotations);
        },
        onSave: () => _saveQuotationInternal(showSendDialog: true),
        whatsappTextBuilder: (saved) {
          final q = saved as QuotationModel;
          final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
          return [
            '*Naiyo24 Quotation*',
            'Quotation No: ${q.quotationNo}',
            'Client: ${q.customerName}',
            'Amount: ${formatCurrency.format(_grandTotal)}',
          ].join('\n');
        },
        pdfContentBuilder: (saved) {
          final q = saved as QuotationModel;
          final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
          final formatDate = DateFormat('dd MMM yyyy');
          return [
            'Naiyo24 Business Tool - Quotation',
            '========================================',
            'Quotation No: ${q.quotationNo}',
            'Client: ${q.customerName}',
            'Date: ${formatDate.format(q.quotationDate)}',
            'Amount: ${formatCurrency.format(_grandTotal)}',
          ].join('\n');
        },
      ),
    );
  }

  Future<QuotationModel?> _saveQuotationInternal({required bool showSendDialog}) async {
    if (showSendDialog) {
      setState(() => _isSavingAndSending = true);
    } else {
      setState(() => _isSaving = true);
    }

    try {
      final quotation = QuotationModel(
        id: const Uuid().v4(),
        quotationNo: 'QT-${DateTime.now().millisecondsSinceEpoch}',
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        customerMobile: _selectedCustomer!.mobile,
        customerAddress: _selectedCustomer!.address ?? '',
        customerGst: _selectedCustomer!.gstNumber,
        quotationDate: _quotationDate,
        validUntil: _validUntil,
        lineItems: _lineItems,
        paymentTerms: _paymentTerms,
        currency: _currency,
        status: QuotationStatus.draft,
        terms: _termsController.text.isNotEmpty ? _termsController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
        subtitle: _subtitle,
        logo: _logoBase64,
        settings: _invoiceSettings,
      );

      await Future.delayed(const Duration(milliseconds: 400));

      // Convert quotation model to backend format
      final quotationData = {
        'customer_id': quotation.customerId,
        'customer_name': quotation.customerName,
        'customer_mobile': quotation.customerMobile,
        'customer_address': quotation.customerAddress,
        'customer_gst': quotation.customerGst,
        'quotation_date': quotation.quotationDate.toIso8601String().split('T')[0],
        'valid_until': quotation.validUntil.toIso8601String().split('T')[0],
        'payment_terms': quotation.paymentTerms,
        'currency': 'INR', // Send just the currency code, not the full name
        'status': 'Draft', // Backend expects 'Draft' not 'draft'
        'subtitle': quotation.subtitle,
        'logo': quotation.logo,
        'settings': quotation.settings,
        'items': quotation.lineItems.map((item) => {
          'name': item.name,
          'price': item.rate,
          'quantity': item.qty,
          'discount_percent': item.discountPercent,
          'gst_percent': item.gstPercent,
        }).toList(),
      };

      try {
        await ref.read(quotationNotifierProvider.notifier).addQuotation(quotationData);
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Failed to save quotation: $e');
        }
        return null;
      }

      if (!mounted) return null;

      context.showSuccessSnackBar(SuccessMessages.quotationCreated);

      if (!showSendDialog) {
        context.go(AppRoutes.quotations);
      }
      return quotation;
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(ErrorMessages.dataSaveError);
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSavingAndSending = false;
        });
      }
    }
  }
}
