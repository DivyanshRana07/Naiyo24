import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:naiyo24_business_tool/widgets/common/confirm_discard_dialog.dart';

import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/models/line_item_model.dart';
import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/invoice_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart' as export_helper;
import 'package:naiyo24_business_tool/utils/document_calculator.dart';
import 'package:naiyo24_business_tool/widgets/common/document_settings_dialogs.dart';
import 'package:naiyo24_business_tool/widgets/common/dashboard_app_bar.dart';
import 'package:naiyo24_business_tool/widgets/common/side_navigation.dart';
import 'package:naiyo24_business_tool/widgets/invoice/invoice_line_item_row.dart';
import 'package:naiyo24_business_tool/widgets/invoice/send_options_dialog.dart';
import 'package:naiyo24_business_tool/widgets/invoice/create_invoice_widgets.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  CustomerModel? _selectedCustomer;
  List<InvoiceLineItem> _lineItems = [];
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));
  String _paymentMethod = 'Cash';
  double _paidAmount = 0;
  String _invoiceType = 'regular'; // regular or proforma
  bool _isSaving = false;
  bool _isSavingAndSending = false;
  late TextEditingController _invoiceNoCtrl;
  
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
    final invoices = ref.read(invoiceNotifierProvider);
    final nextNum = invoices.length + 1;
    _invoiceNoCtrl = TextEditingController(
      text: 'INV-${nextNum.toString().padLeft(5, '0')}',
    );
    _subtitleCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _invoiceNoCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  double get _subTotal => DocumentCalculator.getSubTotal(_lineItems, _invoiceSettings);
  double get _totalDiscount => DocumentCalculator.getTotalDiscount(_lineItems);
  double get _totalGst => DocumentCalculator.getTotalGst(_lineItems, _invoiceSettings);
  double get _grandTotal => DocumentCalculator.getGrandTotal(_lineItems, _invoiceSettings);

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isMedium = MediaQuery.of(context).size.width >= 900;
    final hasChanges = _selectedCustomer != null || _lineItems.isNotEmpty;

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await ConfirmDiscardDialog.show(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar:
            DashboardAppBar(email: authState.userEmail, showBackButton: true),
        drawer: !isMedium
            ? Drawer(
                child: SideNavigation(
                  email: authState.userEmail,
                  onLogout: () =>
                      ref.read(authNotifierProvider.notifier).logout(),
                  currentRoute: AppRoutes.invoices,
                ),
              )
            : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMedium)
              SideNavigation(
                email: authState.userEmail,
                onLogout: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                currentRoute: AppRoutes.invoices,
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

  // ── Single-column centered layout (Refrens-style) ───────────────────────────

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
              _invoiceTitleBlock(),
              const SizedBox(height: AppSpacing.md),
              _businessLogoBlock(),
              const SizedBox(height: AppSpacing.lg),
              CustomerFormSection(
                selectedCustomer: _selectedCustomer,
                onSelected: (c) => setState(() => _selectedCustomer = c),
              ),
              const SizedBox(height: AppSpacing.md),
              InvoiceMetaRow(
                invoiceDate: _invoiceDate,
                dueDate: _dueDate,
                onInvoiceDatePicked: (d) => setState(() => _invoiceDate = d),
                onDueDatePicked: (d) => setState(() => _dueDate = d),
                invoiceNoController: _invoiceNoCtrl,
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
                  setState(() => _lineItems = [..._lineItems, updatedItem]);
                },
                onItemChanged: (updated) {
                  setState(() {
                    _lineItems = [
                      for (final li in _lineItems)
                        li.id == updated.id ? updated : li,
                    ];
                  });
                },
                onItemDeleted: (deleted) {
                  setState(() {
                    _lineItems =
                        _lineItems.where((li) => li.id != deleted.id).toList();
                  });
                },
                onClearAll: () => setState(() => _lineItems = []),
                settings: _invoiceSettings,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInvoiceTypeToggle(),
              const SizedBox(height: AppSpacing.lg),
              InvoiceTotalsCard(
                subTotal: _subTotal,
                totalDiscount: _totalDiscount,
                totalGst: _totalGst,
                roundOff: 0,
                grandTotal: _grandTotal,
                paidAmount: _paidAmount,
                paymentMethod: _paymentMethod,
                onPaidAmountChanged: (v) => setState(() => _paidAmount = v),
                onPaymentMethodChanged: (v) =>
                    setState(() => _paymentMethod = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormActionButtons(
                isSaving: _isSaving,
                isSavingAndSending: _isSavingAndSending,
                onSave: _saveInvoice,
                onSaveAndSend: _saveAndSendInvoice,
                onCancel: () => Navigator.maybePop(context),
                saveLabel: 'Save Invoice',
                buttonHeight: 52,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ── New visual elements (Refrens-style) ─────────────────────────────────────

  Widget _stepperHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create New Invoice', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text(
              'Add Invoice Details',
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

  Widget _invoiceTitleBlock() {
    return Center(
      child: Column(
        children: [
          Text(
            'Invoice',
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
                  hintText: 'e.g. Tax Invoice, Proforma',
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



  // ── Existing toggle (unchanged) ──────────────────────────────────────────────

  Widget _buildInvoiceTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Invoice Type:', style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'regular',
                  label: Text('Regular Invoice'),
                  icon: Icon(Icons.receipt_long, size: 18),
                ),
                ButtonSegment(
                  value: 'proforma',
                  label: Text('Proforma Invoice'),
                  icon: Icon(Icons.receipt_outlined, size: 18),
                ),
              ],
              selected: {_invoiceType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _invoiceType = newSelection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Save logic (unchanged) ───────────────────────────────────────────────────

  Future<void> _saveInvoice() async {
    await _saveInvoiceInternal(navigate: true);
  }

  Future<InvoiceModel?> _saveInvoiceInternal({
    required bool navigate,
    bool isSend = false,
  }) async {
    if (!_formKey.currentState!.validate()) return null;
    if (_selectedCustomer == null) {
      _showError('Please select a customer.');
      return null;
    }
    if (_lineItems.isEmpty) {
      _showError('Add at least one item or service.');
      return null;
    }

    if (isSend) {
      setState(() => _isSavingAndSending = true);
    } else {
      setState(() => _isSaving = true);
    }
    await Future.delayed(const Duration(milliseconds: 400));

    final invoice = InvoiceModel(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNo: _invoiceNoCtrl.text.trim(),
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      customerMobile: _selectedCustomer!.mobile,
      customerAddress: _selectedCustomer!.address,
      customerGst: _selectedCustomer!.gstNumber,
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      lineItems: _lineItems,
      paymentMethod: _paymentMethod,
      paidAmount: _paidAmount,
      invoiceType: _invoiceType,
      subtitle: _subtitle,
      logo: _logoBase64,
      settings: _invoiceSettings,
    );

    try {
      final saved =
          await ref.read(invoiceNotifierProvider.notifier).saveInvoice(invoice);

      if (!mounted) return null;
      if (isSend) {
        setState(() => _isSavingAndSending = false);
      } else {
        setState(() => _isSaving = false);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${saved.invoiceNo} created for ${saved.customerName}!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (navigate) {
        context.go(AppRoutes.invoices);
      }
      return saved;
    } catch (e) {
      if (!mounted) return null;
      setState(() {
        _isSaving = false;
        _isSavingAndSending = false;
      });
      String errorMsg = e.toString();
      if (errorMsg.contains('UNIQUE constraint failed') || errorMsg.contains('already exists')) {
        errorMsg = 'Invoice number already exists. Please enter a unique number.';
      } else if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      _showError(errorMsg);
      return null;
    }
  }

  Future<void> _saveAndSendInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      _showError('Please select a customer.');
      return;
    }
    if (_lineItems.isEmpty) {
      _showError('Add at least one item or service.');
      return;
    }
    _showSendOptionsDialog(context);
  }

  void _showSendOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SendOptionsDialog(
        title: 'Invoice',
        whatsappText: '',
        pdfContent: '',
        filenamePrefix: 'invoice',
        onClose: () {
          context.go(AppRoutes.invoices);
        },
        onSave: () => _saveInvoiceInternal(navigate: false, isSend: true),
        whatsappTextBuilder: (saved) {
          final inv = saved as InvoiceModel;
          final formatCurrency =
              NumberFormat.currency(locale: 'en_IN', symbol: '₹');
          return [
            '*Naiyo24 Invoice*',
            'Invoice No: ${inv.invoiceNo}',
            'Client: ${inv.customerName}',
            'Amount: ${formatCurrency.format(inv.grandTotal)}',
          ].join('\n');
        },
        pdfContentBuilder: (saved) {
          final inv = saved as InvoiceModel;
          final formatCurrency =
              NumberFormat.currency(locale: 'en_IN', symbol: '₹');
          return [
            'Naiyo24 Business Tool - Invoice',
            '========================================',
            'Invoice No: ${inv.invoiceNo}',
            'Client: ${inv.customerName}',
            'Amount: ${formatCurrency.format(inv.grandTotal)}',
          ].join('\n');
        },
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
