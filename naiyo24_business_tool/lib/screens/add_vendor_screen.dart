import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/models/vendor_model.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/widgets/vendor/vendor_form.dart';

class AddVendorScreen extends StatelessWidget {
  const AddVendorScreen({super.key, this.existing});

  final VendorModel? existing;

  @override
  Widget build(BuildContext context) {
    final isEditing = existing != null;

    return ScreenShell(
      currentRoute: AppRoutes.vendors,
      title: isEditing ? 'Edit Vendor' : 'Add New Vendor',
      icon: Icons.store_rounded,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.maybePop(context);
        } else {
          context.go(AppRoutes.vendors);
        }
      },
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: VendorForm(existingVendor: existing),
            ),
          ),
        ),
      ),
    );
  }
}
