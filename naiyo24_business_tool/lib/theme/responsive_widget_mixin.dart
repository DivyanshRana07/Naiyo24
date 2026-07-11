import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/responsive.dart';

/// Mixin to add responsive helper methods to StatelessWidget and StatefulWidget
mixin ResponsiveWidgetMixin {
  /// Get responsive instance from context
  Responsive responsive(BuildContext context) => Responsive(context);

  /// Responsive spacing
  double rSpacing(BuildContext context, double value) => 
      responsive(context).spacing(value);

  /// Responsive font size
  double rFontSize(BuildContext context, double value) => 
      responsive(context).fontSize(value);

  /// Responsive icon size
  double rIconSize(BuildContext context, double value) => 
      responsive(context).iconSize(value);

  /// Responsive border radius
  double rBorderRadius(BuildContext context, double value) => 
      responsive(context).borderRadius(value);

  /// Responsive padding
  EdgeInsets rPadding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return responsive(context).padding(
      all: all,
      horizontal: horizontal,
      vertical: vertical,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  /// Check if mobile
  bool isMobile(BuildContext context) => responsive(context).isMobile;

  /// Check if tablet
  bool isTablet(BuildContext context) => responsive(context).isTablet;

  /// Check if desktop
  bool isDesktop(BuildContext context) => responsive(context).isDesktop;
}
