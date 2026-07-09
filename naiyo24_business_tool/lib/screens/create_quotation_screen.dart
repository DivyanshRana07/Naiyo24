import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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

  @override
  void dispose() {
    _referenceController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  double get _subTotal {
    return _lineItems.fold(0.0, (sum, item) {
      final itemTotal = item.qty * item.rate;
      final discount = itemTotal * (item.discountPercent / 100);
      return sum + (itemTotal - discount);
    });
  }

  double get _totalDiscount {
    return _lineItems.fold(0.0, (sum, item) {
      final itemTotal = item.qty * item.rate;
      return sum + (itemTotal * item.discountPercent / 100);
    });
  }

  double get _totalGst {
    return _lineItems.fold(0.0, (sum, item) {
      final itemTotal = item.qty * item.rate;
      final discount = itemTotal * (item.discountPercent / 100);
      final taxableAmount = itemTotal - discount;
      return sum + (taxableAmount * item.gstPercent / 100);
    });
  }

  double get _grandTotal => _subTotal + _totalGst;

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
              _configButtons(),
              const SizedBox(height: AppSpacing.md),
              LineItemsFormSection(
                lineItems: _lineItems,
                onItemAdded: (item) {
                  setState(() => _lineItems.add(item));
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
                onCancel: () => context.pop(),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Add Subtitle',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _businessLogoBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
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
      ),
    );
  }

  Widget _configButtons() {
    return Column(
      children: [
        _configBtn(Icons.percent_rounded, 'Configure GST'),
        const SizedBox(height: AppSpacing.sm),
        _configBtn(
            Icons.format_list_numbered_rounded, 'Number and Currency Format'),
        const SizedBox(height: AppSpacing.sm),
        _configBtn(Icons.table_chart_outlined, 'Edit Columns/Formulas'),
      ],
    );
  }

  Widget _configBtn(IconData icon, String label) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
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
