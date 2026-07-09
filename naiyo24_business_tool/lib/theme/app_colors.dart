import 'package:flutter/material.dart';

abstract final class AppColors {
  static bool isDarkMode = false;

  static Color get primary => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);

  static Color get primaryDark => isDarkMode ? const Color(0xFFE5E7EB) : const Color(0xFF282B2E);

  static Color get primaryMid => isDarkMode ? const Color(0xFF8E8E8E) : const Color(0xFF2D3033);

  static Color get primaryLight => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFF3F4F6);

  static Color get primaryLightest => isDarkMode ? const Color(0xFF1E2022) : const Color(0xFFF9FAFB);

  static Color get gradientStart => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFFFFFFF);

  static Color get gradientEnd => isDarkMode ? const Color(0xFF1E2022) : const Color(0xFFFFFFFF);

  static Color get background => isDarkMode ? const Color(0xFF1E2022) : const Color(0xFFFFFFFF);

  static Color get surface => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFFFFFFF);

  static Color get cardBg => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFFFFFFF);

  static Color get surfaceVariant => isDarkMode ? const Color(0xFF1E2022) : const Color(0xFFF9FAFB);

  static Color get surfaceHover => isDarkMode ? const Color(0xFF383C40) : const Color(0xFFF3F4F6);

  static Color get sidebarBg => isDarkMode ? const Color(0xFF1E2022) : const Color(0xFFFFFFFF);

  static Color get sidebarSelected => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFF3F4F6);

  static Color get sidebarIndicator => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);

  static Color get textPrimary => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);

  static Color get textSecondary => isDarkMode ? const Color(0xFF8E8E8E) : const Color(0xFF777777);

  static Color get textHint => isDarkMode ? const Color(0xFF777777) : const Color(0xFF8E8E8E);

  static Color get textOnPrimary => isDarkMode ? const Color(0xFF1E2022) : const Color(0xFFFFFFFF);

  static Color get textOnDark => const Color(0xFFFFFFFF);

  static Color get border => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFE5E7EB);

  static Color get borderFocus => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);

  static Color get divider => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFE5E7EB);

  static Color get error => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);
  static Color get errorLight => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFF3F4F6);

  static Color get success => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);
  static Color get successLight => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFF3F4F6);

  static Color get warning => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);
  static Color get warningLight => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFF3F4F6);

  static Color get info => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);
  static Color get infoLight => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFF3F4F6);

  static Color get accentRevenue => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);
  static Color get accentRevenueBg => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFF3F4F6);

  static Color get accentInvoice => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);
  static Color get accentInvoiceBg => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFF3F4F6);

  static Color get accentClient => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);
  static Color get accentClientBg => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFF3F4F6);

  static Color get accentOverdue => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);
  static Color get accentOverdueBg => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFF3F4F6);

  static Color get notificationBadge => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);

  static Color get googleButtonBg => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFFFFFFF);
  static Color get googleButtonBorder => isDarkMode ? const Color(0xFF2D3033) : const Color(0xFFE5E7EB);
  static Color get googleButtonText => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);

  static Color get chatBubble => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E2022);

  static const Color transparent = Colors.transparent;

  AppColors._();
}
