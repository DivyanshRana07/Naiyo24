import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';
import 'package:naiyo24_business_tool/widgets/common/add_resource_button.dart';
import 'package:naiyo24_business_tool/widgets/customer/customer_details_card.dart';
import 'package:naiyo24_business_tool/widgets/invoice/invoice_autocomplete_fields.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

/// Reusable customer selection section with autocomplete and add new button
class CustomerSelectionSection extends StatelessWidget {
  const CustomerSelectionSection({
    super.key,
    required this.selectedCustomer,
    required this.onSelected,
    this.title = '1. Select Customer',
    this.showDetails = true,
  });

  final CustomerModel? selectedCustomer;
  final ValueChanged<CustomerModel?> onSelected;
  final String title;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionTitle(
          title: title,
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomerAutocomplete(
                selectedCustomer: selectedCustomer,
                onSelected: onSelected,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AddResourceButton.newClient(
              () => context.push(AppRoutes.newClient),
            ),
          ],
        ),
        if (showDetails && selectedCustomer != null) ...[
          const SizedBox(height: AppSpacing.md),
          CustomerDetailsCard(customer: selectedCustomer!),
        ],
      ],
    );
  }
}
