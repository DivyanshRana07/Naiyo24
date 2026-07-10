import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/notifiers/theme_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_router.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    AppColors.isDarkMode = (themeMode == ThemeMode.dark);

    return MaterialApp.router(
      title: 'Business Tool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
