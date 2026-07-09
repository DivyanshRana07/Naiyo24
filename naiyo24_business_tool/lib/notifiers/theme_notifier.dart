import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/providers/shared_prefs_provider.dart';
import 'package:naiyo24_business_tool/theme/app_colors.dart';

class ThemeNotifier extends AutoDisposeNotifier<ThemeMode> {
  static const _storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final savedValue = prefs.getString(_storageKey);
    if (savedValue == 'dark') {
      AppColors.isDarkMode = true;
      return ThemeMode.dark;
    } else if (savedValue == 'light') {
      AppColors.isDarkMode = false;
      return ThemeMode.light;
    }
    // Fallback to system theme (default light for this app)
    AppColors.isDarkMode = false;
    return ThemeMode.light;
  }

  void toggleTheme() {
    final prefs = ref.read(sharedPrefsProvider);
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      AppColors.isDarkMode = false;
      prefs.setString(_storageKey, 'light');
    } else {
      state = ThemeMode.dark;
      AppColors.isDarkMode = true;
      prefs.setString(_storageKey, 'dark');
    }
  }

  void setLightMode() {
    if (state != ThemeMode.light) {
      state = ThemeMode.light;
      AppColors.isDarkMode = false;
      ref.read(sharedPrefsProvider).setString(_storageKey, 'light');
    }
  }

  void setDarkMode() {
    if (state != ThemeMode.dark) {
      state = ThemeMode.dark;
      AppColors.isDarkMode = true;
      ref.read(sharedPrefsProvider).setString(_storageKey, 'dark');
    }
  }
}

final themeNotifierProvider = AutoDisposeNotifierProvider<ThemeNotifier, ThemeMode>(
  () => ThemeNotifier(),
);
