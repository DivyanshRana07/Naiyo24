import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/models/line_item_model.dart';
import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/invoice_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
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

  double get _subTotal => _lineItems.fold(0, (s, i) => s + (i.rate * i.qty));
  double get _totalDiscount =>
      _lineItems.fold(0, (s, i) => s + i.discountAmount);
  double get _totalGst => _lineItems.fold(0, (s, i) => s + i.gstAmount);
  double get _grandTotal => _subTotal - _totalDiscount + _totalGst;

  Future<bool> _onWillPop() async {
    if (_selectedCustomer == null && _lineItems.isEmpty) {
      return true;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?', style: AppTextStyles.h2),
        content: Text(
            'You have unsaved changes. Are you sure you want to discard them?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Discard',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isMedium = MediaQuery.of(context).size.width >= 900;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
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
              ),
              const SizedBox(height: AppSpacing.md),
              _configButtons(),
              const SizedBox(height: AppSpacing.md),
              LineItemsFormSection(
                lineItems: _lineItems,
                onItemAdded: (item) =>
                    setState(() => _lineItems = [..._lineItems, item]),
                onItemChanged: (updated) {
                  setState(() {
                    _lineItems = [
                      for (final li in _lineItems)
                        li.id == updated.id ? updated : li,
                    ];
                  });
                },
                onItemDeleted: (item) {
                  setState(() {
                    _lineItems =
                        _lineItems.where((li) => li.id != item.id).toList();
                  });
                },
                onClearAll: () => setState(() => _lineItems = []),
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
                onCancel: () => context.pop(),
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
      invoiceNo: '',
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
    );

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
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
