import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart' as export_helper;

import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/vendor_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/purchase_order_notifier.dart';
import 'package:naiyo24_business_tool/models/vendor_model.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/widgets/common/dashboard_app_bar.dart';
import 'package:naiyo24_business_tool/widgets/common/side_navigation.dart';
import 'package:naiyo24_business_tool/widgets/common/confirm_discard_dialog.dart';

class CreatePurchaseOrderScreen extends ConsumerStatefulWidget {
  const CreatePurchaseOrderScreen({super.key});

  @override
  ConsumerState<CreatePurchaseOrderScreen> createState() =>
      _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState
    extends ConsumerState<CreatePurchaseOrderScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _poNumberController;
  late final TextEditingController _dateController;
  late final TextEditingController _gstController;

  VendorModel? _selectedVendor;
  String? _receiptImageBase64;
  final List<Map<String, dynamic>> _items = [
    {
      'desc': TextEditingController(),
      'qty': TextEditingController(text: '1'),
      'price': TextEditingController(text: '0')
    },
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _poNumberController = TextEditingController(
        text:
            'EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    _dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    _gstController = TextEditingController(text: '0.00');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _poNumberController.dispose();
    _dateController.dispose();
    _gstController.dispose();
    for (final item in _items) {
      (item['desc'] as TextEditingController).dispose();
      (item['qty'] as TextEditingController).dispose();
      (item['price'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add({
        'desc': TextEditingController(),
        'qty': TextEditingController(text: '1'),
        'price': TextEditingController(text: '0'),
      });
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      ((_items[index]['desc']) as TextEditingController).dispose();
      ((_items[index]['qty']) as TextEditingController).dispose();
      ((_items[index]['price']) as TextEditingController).dispose();
      setState(() => _items.removeAt(index));
    }
  }

  double _itemTotal(Map<String, dynamic> item) {
    final qty =
        double.tryParse((item['qty'] as TextEditingController).text) ?? 0;
    final price =
        double.tryParse((item['price'] as TextEditingController).text) ?? 0;
    return qty * price;
  }

  double get _totalAmount =>
      _items.fold(0.0, (sum, item) => sum + _itemTotal(item));

  Future<void> _pickReceipt() async {
    final base64 = await export_helper.pickLogoImage();
    if (base64 != null) {
      setState(() {
        _receiptImageBase64 = base64;
      });
    }
  }

  void _logout(BuildContext context) {
    ref.read(authNotifierProvider.notifier).logout();
    context.go(AppRoutes.login);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _savePO() async {
    if (_selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please select a vendor', style: TextStyle(color: AppColors.textOnPrimary)),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter a title', style: TextStyle(color: AppColors.textOnPrimary)),
            backgroundColor: AppColors.error),
      );
      return;
    }

    for (final item in _items) {
      final desc = (item['desc'] as TextEditingController).text.trim();
      final qty =
          int.tryParse((item['qty'] as TextEditingController).text) ?? 0;
      final price =
          double.tryParse((item['price'] as TextEditingController).text) ?? 0.0;

      if (desc.isEmpty || qty <= 0 || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please fill all line items with valid values', style: TextStyle(color: AppColors.textOnPrimary)),
              backgroundColor: AppColors.error),
        );
        return;
      }
    }

    final gstVal = double.tryParse(_gstController.text) ?? 0.0;
    final poData = {
      'vendor_id': int.tryParse(_selectedVendor!.id) ?? 0,
      'po_number': _poNumberController.text.trim(),
      'po_date': _dateController.text.trim(),
      'status': 'unpayed',
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'total_amount': _totalAmount + gstVal,
      'gst_amount': gstVal,
      'receipt_image': _receiptImageBase64,
      'items': _items.map((item) {
        final desc = (item['desc'] as TextEditingController).text.trim();
        final qty = double.tryParse((item['qty'] as TextEditingController).text) ?? 0.0;
        final price = double.tryParse((item['price'] as TextEditingController).text) ?? 0.0;
        final lineTotal = qty * price;
        return {
          'name': desc,
          'quantity': qty,
          'price': price,
          'gst_rate': 0.0,
          'line_total': lineTotal,
        };
      }).toList(),
    };

    try {
      await ref.read(purchaseOrderNotifierProvider.notifier).addPurchaseOrder(poData);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense created successfully!', style: TextStyle(color: AppColors.textOnPrimary)),
          backgroundColor: AppColors.success,
        ),
      );
      if (!mounted) return;
      context.go(AppRoutes.purchaseOrders);
    } catch (error) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create expense: $error', style: TextStyle(color: AppColors.textOnPrimary)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  bool _hasChanges() {
    if (_selectedVendor != null ||
        _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _gstController.text != '0.00' ||
        _receiptImageBase64 != null) {
      return true;
    }
    if (_items.length > 1) {
      return true;
    }
    if (_items.isNotEmpty) {
      final firstItem = _items[0];
      final desc = (firstItem['desc'] as TextEditingController).text;
      final qty = (firstItem['qty'] as TextEditingController).text;
      final price = (firstItem['price'] as TextEditingController).text;
      if (desc.isNotEmpty || qty != '1' || (price.isNotEmpty && price != '0' && price != '0.0')) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final asyncVendors = ref.watch(vendorNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return PopScope(
      canPop: !_hasChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await ConfirmDiscardDialog.show(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: asyncVendors.when(
        loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: DashboardAppBar(
          email: authState.userEmail,
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: DashboardAppBar(
          email: authState.userEmail,
          showBackButton: true,
        ),
        body: Center(child: Text('Error loading vendors: $err')),
      ),
      data: (vendors) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: DashboardAppBar(
          email: authState.userEmail,
          showBackButton: true,
        ),
        drawer: !isDesktop
            ? Drawer(
                child: SideNavigation(
                  email: authState.userEmail,
                  onLogout: () => _logout(context),
                  currentRoute: AppRoutes.purchaseOrders,
                ),
              )
            : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop)
              SideNavigation(
                email: authState.userEmail,
                onLogout: () => _logout(context),
                currentRoute: AppRoutes.purchaseOrders,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Unified Document Card Container (Refrens Style)
                    Container(
                      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xxl),
                      decoration: BoxDecoration(
                        color: AppColors.surface, // Charcoal surface (#262626)
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Section: Title & Metadata on Left, Logo Box on Right
                          if (isMobile) ...[
                            _buildTopLeftSection(context),
                            const SizedBox(height: AppSpacing.lg),
                            Center(child: _buildReceiptBox()),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTopLeftSection(context),
                                ),
                                const SizedBox(width: AppSpacing.xxl),
                                _buildReceiptBox(),
                              ],
                            ),
                          
                          const SizedBox(height: AppSpacing.xxl),
                          Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: AppSpacing.xxl),

                          // Billed To / Billed By (Order By / Order To) Section
                          if (isMobile) ...[
                            _buildOrderByBox(authState.userEmail),
                            const SizedBox(height: AppSpacing.lg),
                            _buildOrderToBox(vendors),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildOrderByBox(authState.userEmail),
                                ),
                                const SizedBox(width: AppSpacing.xl),
                                Expanded(
                                  child: _buildOrderToBox(vendors),
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: AppSpacing.xxl),
                          Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: AppSpacing.xxl),

                          // Line Items & Totals Section
                          _buildLineItemsSection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    
                    // Form Actions Bar
                    _buildFormActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _header() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Icon(Icons.arrow_back_rounded,
                size: 20, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Icon(Icons.shopping_bag_rounded,
            color: AppColors.primary, size: 28),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Record Expense',
            style: AppTextStyles.h1,
          ),
        ),
      ],
    );
  }

  Widget _buildTopLeftSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large Title Field mimicking Refrens "Purchase" header
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _titleController,
                style: AppTextStyles.displayMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Expense Title',
                  hintStyle: AppTextStyles.displayMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        
        // Subtitle / Description mimicking "+ Add Subtitle"
        TextField(
          controller: _descriptionController,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          decoration: InputDecoration(
            hintText: '+ Add Description',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Metadata Fields: PO Number & Date Row
        Row(
          children: [
            Expanded(
              child: _buildMetadataField(
                label: 'Expense Reference # *',
                controller: _poNumberController,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildMetadataField(
                    label: 'Date *',
                    controller: _dateController,
                    suffixIcon: Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetadataField({
    required String label,
    required TextEditingController controller,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        TextField(
          controller: controller,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptBox() {
    final pureBase64 = _receiptImageBase64 != null && _receiptImageBase64!.contains(',')
        ? _receiptImageBase64!.split(',').last
        : _receiptImageBase64;
    final imageBytes = pureBase64 != null ? base64Decode(pureBase64) : null;
    return GestureDetector(
      onTap: _pickReceipt,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.md - 1),
          child: imageBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _receiptImageBase64 = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 32,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Attach Receipt',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildOrderByBox(String? email) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background, // Nested `#101010`
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order By (Your Details)',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.border,
                child: Text(
                  email?.isNotEmpty == true ? email![0].toUpperCase() : 'N',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Naiyo24 Business',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? 'admin@naiyo24.com',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sector 62, Noida, India',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderToBox(List<VendorModel> vendors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background, // Nested `#101010`
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Order To (Vendor Details)',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(AppRoutes.newVendor),
                child: Text(
                  '+ Add New Vendor',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              border: Border.all(color: AppColors.border),
              color: AppColors.surface, // Elevated surface
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<VendorModel>(
                isExpanded: true,
                dropdownColor: AppColors.surface,
                value: _selectedVendor,
                hint: Text(
                  'Select Vendor',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                items: vendors.map((v) {
                  return DropdownMenuItem<VendorModel>(
                    value: v,
                    child: Text(v.name, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedVendor = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Table Header styled with dark background
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background, // Nested `#101010`
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  'Description',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Qty',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Unit Price (₹)',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Total (₹)',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Table Rows
        ...List.generate(_items.length, (index) {
          final item = _items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildItemField(
                    controller: item['desc'] as TextEditingController,
                    hint: 'e.g., MacBook Pro 14"',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: _buildItemField(
                    controller: item['qty'] as TextEditingController,
                    hint: '1',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: _buildItemField(
                    controller: item['price'] as TextEditingController,
                    hint: '0.00',
                    isNumber: true,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '₹${_itemTotal(item).toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _items.length > 1 ? AppColors.error : AppColors.border,
                    ),
                    onPressed: () => _removeItem(index),
                  ),
                ),
              ],
            ),
          );
        }),
        
        const SizedBox(height: AppSpacing.sm),
        
        // Add Line Item Button mimicking Refrens "+ Add Line Item" text button
        TextButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Line Item'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        
        Divider(height: AppSpacing.xl, color: AppColors.border),
        
        // Totals aligned to the right
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              children: [
                _buildTotalRow('Subtotal', '₹${_totalAmount.toStringAsFixed(2)}'),
                const SizedBox(height: AppSpacing.sm),
                _buildGstInputRow(),
                Divider(color: AppColors.border),
                _buildTotalRow(
                  'Total Amount',
                  '₹${(_totalAmount + (double.tryParse(_gstController.text) ?? 0.0)).toStringAsFixed(2)}',
                  highlight: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      onChanged: (_) => setState(() {}),
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.background, // Nested `#101010`
      ),
    );
  }

  Widget _buildGstInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Associated GST (₹)',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _gstController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: highlight
                ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)
                : AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: highlight
                ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)
                : AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildFormActions() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface, // Charcoal `#262626`
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _savePO,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton(
                  onPressed: _savePO,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
    );
  }
}
