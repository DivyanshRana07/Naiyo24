import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/widgets/customer/customer_form.dart';

class AddClientScreen extends StatelessWidget {
  const AddClientScreen({super.key, this.existing});

  final CustomerModel? existing;

  @override
  Widget build(BuildContext context) {
    final isEditing = existing != null;

    return ScreenShell(
      currentRoute: AppRoutes.clients,
      title: isEditing ? 'Edit Client' : 'Add New Client',
      icon: Icons.person_add_rounded,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.clients);
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
              child: CustomerForm(existing: existing),
            ),
          ),
        ),
      ),
    );
  }
}
