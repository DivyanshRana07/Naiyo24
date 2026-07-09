import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/app_colors.dart';

abstract final class AppGradients {
  static LinearGradient navbar = LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient heroBanner = LinearGradient(
    colors: [AppColors.primary, AppColors.gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient primaryButton = LinearGradient(
    colors: [AppColors.primaryMid, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumButton = LinearGradient(
    colors: [Color(0xFF374151), Color(0xFF111827)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient cardShimmer = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primaryLightest],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient revenueCard = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryMid],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient sidebarIndicator = LinearGradient(
    colors: [AppColors.primary, AppColors.gradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  AppGradients._();
}
