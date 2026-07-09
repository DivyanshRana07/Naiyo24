import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/models/item_model.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/widgets/item/item_form.dart';

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key, this.existing});

  final ItemModel? existing;

  @override
  Widget build(BuildContext context) {
    final isEditing = existing != null;

    return ScreenShell(
      currentRoute: AppRoutes.items,
      title: isEditing ? 'Edit Item' : 'Add New Item',
      icon: Icons.inventory_2_rounded,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.items);
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
              child: ItemForm(existing: existing),
            ),
          ),
        ),
      ),
    );
  }
}
