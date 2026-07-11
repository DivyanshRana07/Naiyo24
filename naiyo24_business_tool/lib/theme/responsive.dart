import 'package:flutter/material.dart';

/// Responsive utility class that scales UI elements based on screen size.
/// Keeps laptop/desktop view unchanged while making mobile view more compact.
class Responsive {
  final BuildContext context;
  late final double _width;
  late final double _height;
  late final bool _isMobile;
  late final bool _isTablet;
  late final bool _isDesktop;

  Responsive(this.context) {
    _width = MediaQuery.of(context).size.width;
    _height = MediaQuery.of(context).size.height;
    _isMobile = _width < 600;
    _isTablet = _width >= 600 && _width < 900;
    _isDesktop = _width >= 900;
  }

  /// Screen width
  double get width => _width;

  /// Screen height
  double get height => _height;

  /// Is mobile screen (< 600px)
  bool get isMobile => _isMobile;

  /// Is tablet screen (600px - 900px)
  bool get isTablet => _isTablet;

  /// Is desktop screen (>= 900px)
  bool get isDesktop => _isDesktop;

  /// Scale factor for mobile (0.75 = 25% smaller than desktop)
  double get scaleFactor {
    if (_isDesktop) return 1.0; // No scaling on desktop
    if (_isTablet) return 0.9; // 10% smaller on tablet
    return 0.75; // 25% smaller on mobile
  }

  /// Responsive spacing - scales down on mobile
  double spacing(double desktopValue) {
    return desktopValue * scaleFactor;
  }

  /// Responsive font size - scales down on mobile
  double fontSize(double desktopSize) {
    return desktopSize * scaleFactor;
  }

  /// Responsive icon size - scales down on mobile
  double iconSize(double desktopSize) {
    return desktopSize * scaleFactor;
  }

  /// Responsive padding - scales down on mobile
  EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(all * scaleFactor);
    }
    return EdgeInsets.only(
      left: (left ?? horizontal ?? 0) * scaleFactor,
      top: (top ?? vertical ?? 0) * scaleFactor,
      right: (right ?? horizontal ?? 0) * scaleFactor,
      bottom: (bottom ?? vertical ?? 0) * scaleFactor,
    );
  }

  /// Responsive border radius - scales down on mobile
  double borderRadius(double desktopRadius) {
    return desktopRadius * scaleFactor;
  }

  /// Get responsive value based on screen size
  T value<T>({
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (_isDesktop) return desktop;
    if (_isTablet) return tablet ?? desktop;
    return mobile;
  }
}

/// Extension method for easier access to responsive utilities
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}

/// Responsive spacing constants that scale based on screen size
class ResponsiveSpacing {
  final BuildContext context;
  late final Responsive _responsive;

  ResponsiveSpacing(this.context) {
    _responsive = Responsive(context);
  }

  double get xxs => _responsive.spacing(2.0);
  double get xs => _responsive.spacing(4.0);
  double get sm => _responsive.spacing(8.0);
  double get md => _responsive.spacing(16.0);
  double get lg => _responsive.spacing(24.0);
  double get xl => _responsive.spacing(32.0);
  double get xxl => _responsive.spacing(48.0);
  double get xxxl => _responsive.spacing(64.0);
}

/// Responsive text styles that scale based on screen size
class ResponsiveTextStyles {
  final BuildContext context;
  final TextStyle baseStyle;
  late final Responsive _responsive;

  ResponsiveTextStyles(this.context, this.baseStyle) {
    _responsive = Responsive(context);
  }

  TextStyle get style {
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * _responsive.scaleFactor,
    );
  }
}
