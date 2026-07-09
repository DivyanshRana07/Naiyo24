import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/line_item_model.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/models/item_model.dart';
import 'package:naiyo24_business_tool/models/service_model.dart';
import 'package:naiyo24_business_tool/notifiers/customer_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/item_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/service_notifier.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

class CustomerAutocomplete extends ConsumerWidget {
  const CustomerAutocomplete({
    super.key,
    required this.onSelected,
    this.selectedCustomer,
  });

  final void Function(CustomerModel) onSelected;
  final CustomerModel? selectedCustomer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCustomers = ref.watch(customerNotifierProvider);

    return Autocomplete<CustomerModel>(
      initialValue: selectedCustomer != null
          ? TextEditingValue(text: selectedCustomer!.name)
          : TextEditingValue.empty,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (TextEditingValue val) {
        if (val.text.isEmpty) return allCustomers;
        return ref.read(customerNotifierProvider.notifier).search(val.text);
      },
      optionsViewBuilder: (context, onSelected, options) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final boxWidth = isMobile ? screenWidth - 48 : 400.0;
        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: boxWidth,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              color: AppColors.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (ctx, i) {
                    final c = options.elementAt(i);
                    return InkWell(
                      onTap: () => onSelected(c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                c.name[0].toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w400),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                              fontWeight: FontWeight.w400)),
                                  Text(c.mobile,
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(c.code,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search customer by name or mobile...',
            prefixIcon: Icon(Icons.person_search_rounded,
                color: AppColors.textSecondary, size: 20),
            suffixIcon:
                Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ),
          validator: (_) =>
              selectedCustomer == null ? 'Please select a customer' : null,
        );
      },
      onSelected: (c) {
        Future.delayed(Duration.zero, () => onSelected(c));
      },
    );
  }
}

class _ItemResult {
  const _ItemResult.item(this.item) : service = null;
  const _ItemResult.service(this.service) : item = null;

  final ItemModel? item;
  final ServiceModel? service;

  String get name => item?.name ?? service!.name;
  String get code => item?.code ?? service!.code;
  double get price => item?.sellingPrice ?? service!.sellingPrice;
  double get gst => item?.gstPercent ?? service!.gstPercent;
  LineItemType get type =>
      item != null ? LineItemType.item : LineItemType.service;
  String get id => item?.id ?? service!.id;
  String get typeLabel => item != null ? 'Item' : 'Service';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ItemResult &&
          other.item?.id == item?.id &&
          other.service?.id == service?.id);

  @override
  int get hashCode => (item?.id ?? service!.id).hashCode;
}

class ItemSearchAutocomplete extends ConsumerStatefulWidget {
  const ItemSearchAutocomplete({
    super.key,
    required this.onSelected,
  });

  final void Function(InvoiceLineItem) onSelected;

  @override
  ConsumerState<ItemSearchAutocomplete> createState() =>
      _ItemSearchAutocompleteState();
}

class _ItemSearchAutocompleteState
    extends ConsumerState<ItemSearchAutocomplete> {
  TextEditingController? _fieldController;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(itemNotifierProvider);
    ref.watch(serviceNotifierProvider);

    return Autocomplete<_ItemResult>(
      displayStringForOption: (r) => r.name,
      optionsBuilder: (val) {
        final q = val.text;
        if (q.isEmpty) return const [];
        final items = ref
            .read(itemNotifierProvider.notifier)
            .search(q)
            .map((p) => _ItemResult.item(p));
        final services = ref
            .read(serviceNotifierProvider.notifier)
            .search(q)
            .map((s) => _ItemResult.service(s));
        return [...items, ...services];
      },
      optionsViewBuilder: (context, onSelected, options) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final boxWidth = isMobile ? screenWidth - 48 : 480.0;
        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: boxWidth,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              color: AppColors.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (ctx, i) {
                    final r = options.elementAt(i);
                    final isItem = r.type == LineItemType.item;
                    return InkWell(
                      onTap: () => onSelected(r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isItem
                                    ? AppColors.primary
                                        .withValues(alpha: 0.08)
                                    : const Color(0xFF0284C7)
                                        .withValues(alpha: 0.08),
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.xs),
                              ),
                              child: Text(
                                r.typeLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: isItem
                                      ? AppColors.primary
                                      : const Color(0xFF0284C7),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                              fontWeight: FontWeight.w400)),
                                  Text(r.code,
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(
                              '₹${r.price.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _fieldController = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onFieldSubmitted: (String value) => onFieldSubmitted(),
          decoration: InputDecoration(
            hintText: 'Search item or service by name / code...',
            prefixIcon: Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        );
      },
      onSelected: (r) {
        final item = InvoiceLineItem(
          id: '${r.id}-${DateTime.now().millisecondsSinceEpoch}',
          itemType: r.type,
          itemId: r.id,
          code: r.code,
          name: r.name,
          qty: 1,
          rate: r.price,
          gstPercent: r.gst,
        );
        Future.delayed(Duration.zero, () {
          widget.onSelected(item);
          _fieldController?.clear();
        });
      },
    );
  }
}

class ItemDropdownSelector extends ConsumerStatefulWidget {
  const ItemDropdownSelector({super.key, required this.onSelected});

  final void Function(InvoiceLineItem) onSelected;

  @override
  ConsumerState<ItemDropdownSelector> createState() => _ItemDropdownSelectorState();
}

class _ItemDropdownSelectorState extends ConsumerState<ItemDropdownSelector> {
  TextEditingController? _fieldController;

  @override
  Widget build(BuildContext context) {
    final activeItems = ref.watch(itemNotifierProvider)
        .where((i) => i.status == ItemStatus.active)
        .toList();

    return Autocomplete<ItemModel>(
      displayStringForOption: (item) => item.name,
      optionsBuilder: (TextEditingValue val) {
        if (val.text.isEmpty) return activeItems;
        return ref.read(itemNotifierProvider.notifier).search(val.text)
            .where((i) => i.status == ItemStatus.active)
            .toList();
      },
      optionsViewBuilder: (context, onSelected, options) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final boxWidth = isMobile ? screenWidth - 48 : 350.0;
        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: boxWidth,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              color: AppColors.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (ctx, i) {
                    final item = options.elementAt(i);
                    return InkWell(
                      onTap: () => onSelected(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                item.name[0].toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w400),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                              fontWeight: FontWeight.w400)),
                                  Text(item.code,
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item.sellingPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _fieldController = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Select Item to Add...',
            prefixIcon: Icon(Icons.inventory_2_rounded,
                color: AppColors.textSecondary, size: 20),
            suffixIcon:
                Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ),
        );
      },
      onSelected: (item) {
        final lineItem = InvoiceLineItem(
          id: '${item.id}-${DateTime.now().millisecondsSinceEpoch}',
          itemType: LineItemType.item,
          itemId: item.id,
          code: item.code,
          name: item.name,
          qty: 1,
          rate: item.sellingPrice,
          gstPercent: item.gstPercent,
        );
        Future.delayed(Duration.zero, () {
          widget.onSelected(lineItem);
          _fieldController?.clear();
        });
      },
    );
  }
}

class ServiceDropdownSelector extends ConsumerStatefulWidget {
  const ServiceDropdownSelector({super.key, required this.onSelected});

  final void Function(InvoiceLineItem) onSelected;

  @override
  ConsumerState<ServiceDropdownSelector> createState() => _ServiceDropdownSelectorState();
}

class _ServiceDropdownSelectorState extends ConsumerState<ServiceDropdownSelector> {
  TextEditingController? _fieldController;

  @override
  Widget build(BuildContext context) {
    final activeServices = ref.watch(serviceNotifierProvider)
        .where((s) => s.status == ServiceStatus.active)
        .toList();

    return Autocomplete<ServiceModel>(
      displayStringForOption: (service) => service.name,
      optionsBuilder: (TextEditingValue val) {
        if (val.text.isEmpty) return activeServices;
        return ref.read(serviceNotifierProvider.notifier).search(val.text)
            .where((s) => s.status == ServiceStatus.active)
            .toList();
      },
      optionsViewBuilder: (context, onSelected, options) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final boxWidth = isMobile ? screenWidth - 48 : 350.0;
        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: boxWidth,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              color: AppColors.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (ctx, i) {
                    final service = options.elementAt(i);
                    return InkWell(
                      onTap: () => onSelected(service),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  const Color(0xFF0284C7).withValues(alpha: 0.1),
                              child: Text(
                                service.name[0].toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFF0284C7),
                                    fontWeight: FontWeight.w400),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service.name,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                              fontWeight: FontWeight.w400)),
                                  Text(service.code,
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(
                              '₹${service.sellingPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _fieldController = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Select Service to Add...',
            prefixIcon: Icon(Icons.miscellaneous_services_rounded,
                color: AppColors.textSecondary, size: 20),
            suffixIcon:
                Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ),
        );
      },
      onSelected: (service) {
        final lineItem = InvoiceLineItem(
          id: '${service.id}-${DateTime.now().millisecondsSinceEpoch}',
          itemType: LineItemType.service,
          itemId: service.id,
          code: service.code,
          name: service.name,
          qty: 1,
          rate: service.sellingPrice,
          gstPercent: service.gstPercent,
        );
        Future.delayed(Duration.zero, () {
          widget.onSelected(lineItem);
          _fieldController?.clear();
        });
      },
    );
  }
}
