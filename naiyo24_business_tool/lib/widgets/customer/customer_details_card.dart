import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

class CustomerDetailsCard extends StatelessWidget {
  const CustomerDetailsCard({super.key, required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              customer.name[0].toUpperCase(),
              style:
                  AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 18),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w400)),
                const SizedBox(height: 2),
                if (customer.mobile.isNotEmpty)
                  _detail(Icons.phone_rounded, customer.mobile),
                if (customer.address != null)
                  _detail(Icons.location_on_rounded, customer.address!),
                if (customer.gstNumber != null)
                  _detail(Icons.business_rounded, customer.gstNumber!),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _chip('Credit Limit',
                  '₹${customer.creditLimit.toStringAsFixed(0)}'),
              const SizedBox(height: 4),
              _chip('Opening Bal.',
                  '₹${customer.openingBalance.toStringAsFixed(0)}',
                  color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(text,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _chip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary, fontSize: 10)),
          Text(value,
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: color ?? AppColors.primary)),
        ],
      ),
    );
  }
}
