import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:naiyo24_business_tool/utils/constants.dart';

/// Extensions for common operations following Flutter best practices

// ============================================================================
// DateTime Extensions
// ============================================================================

extension DateTimeExtensions on DateTime {
  /// Format date for display (e.g., "01 Jan 2024")
  String toDisplayString() {
    return DateFormat(DateFormats.display).format(this);
  }

  /// Format date short (e.g., "01/01/2024")
  String toDisplayShortString() {
    return DateFormat(DateFormats.displayShort).format(this);
  }

  /// Format for API (e.g., "2024-01-01")
  String toApiString() {
    return DateFormat(DateFormats.api).format(this);
  }

  /// Format date and time (e.g., "01 Jan 2024, 02:30 PM")
  String toDateTimeString() {
    return DateFormat(DateFormats.dateTime).format(this);
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get relative time string (e.g., "2 hours ago", "in 3 days")
  String toRelativeString() {
    final now = DateTime.now();
    final difference = this.difference(now);

    if (isToday) {
      if (difference.inHours.abs() < 1) {
        final minutes = difference.inMinutes.abs();
        if (minutes == 0) return 'Just now';
        return difference.isNegative
            ? '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago'
            : 'in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
      }
      final hours = difference.inHours.abs();
      return difference.isNegative
          ? '$hours ${hours == 1 ? 'hour' : 'hours'} ago'
          : 'in $hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';

    final days = difference.inDays.abs();
    if (days < 7) {
      return difference.isNegative
          ? '$days ${days == 1 ? 'day' : 'days'} ago'
          : 'in $days ${days == 1 ? 'day' : 'days'}';
    }

    return toDisplayString();
  }

  /// Start of day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// End of day (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }
}

// ============================================================================
// Number Extensions
// ============================================================================

extension DoubleExtensions on double {
  /// Format as currency (e.g., "₹1,234.56")
  String toCurrency() {
    return NumberFormat.currency(
      locale: CurrencyFormats.locale,
      symbol: CurrencyFormats.symbol,
      decimalDigits: CurrencyFormats.decimalDigits,
    ).format(this);
  }

  /// Format as compact currency (e.g., "₹1.2K", "₹5.6M")
  String toCompactCurrency() {
    return NumberFormat.compactCurrency(
      locale: CurrencyFormats.locale,
      symbol: CurrencyFormats.symbol,
    ).format(this);
  }

  /// Format as percentage (e.g., "12.5%")
  String toPercentage({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Format with thousand separators (e.g., "1,234.56")
  String toFormattedString({int decimals = 2}) {
    return NumberFormat('#,##0.${'0' * decimals}', CurrencyFormats.locale)
        .format(this);
  }
}

extension IntExtensions on int {
  /// Format as currency
  String toCurrency() => toDouble().toCurrency();

  /// Format as compact currency
  String toCompactCurrency() => toDouble().toCompactCurrency();

  /// Format with thousand separators
  String toFormattedString() {
    return NumberFormat('#,##0', CurrencyFormats.locale).format(this);
  }
}

// ============================================================================
// String Extensions
// ============================================================================

extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize())
        .join(' ');
  }

  /// Remove all whitespace
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  /// Check if string contains only digits
  bool get isNumeric {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Check if string contains only alphabets
  bool get isAlpha {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  /// Check if string is alphanumeric
  bool get isAlphanumeric {
    return ValidationPatterns.alphanumeric.hasMatch(this);
  }

  /// Parse to double safely
  double? toDoubleOrNull() {
    return double.tryParse(this);
  }

  /// Parse to int safely
  int? toIntOrNull() {
    return int.tryParse(this);
  }

  /// Get initials (e.g., "John Doe" -> "JD")
  String getInitials({int maxLength = 2}) {
    final words = trim().split(RegExp(r'\s+'));
    final initials = words
        .where((word) => word.isNotEmpty)
        .take(maxLength)
        .map((word) => word[0].toUpperCase())
        .join();
    return initials;
  }
}

// ============================================================================
// BuildContext Extensions
// ============================================================================

extension BuildContextExtensions on BuildContext {
  /// Get MediaQuery data
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  Size get screenSize => mediaQuery.size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Check if mobile
  bool get isMobile => screenWidth < 600;

  /// Check if tablet
  bool get isTablet => screenWidth >= 600 && screenWidth < 1100;

  /// Check if desktop
  bool get isDesktop => screenWidth >= 1100;

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Show snackbar with success message
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show snackbar with error message
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show snackbar with info message
  void showInfoSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Navigate and remove all previous routes
  void navigateAndRemoveUntil(String route) {
    Navigator.of(this).pushNamedAndRemoveUntil(
      route,
      (route) => false,
    );
  }
}

// ============================================================================
// List Extensions
// ============================================================================

extension ListExtensions<T> on List<T> {
  /// Get element at index or null if out of bounds
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if list is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Split list into chunks
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

// ============================================================================
// Color Extensions
// ============================================================================

extension ColorExtensions on Color {
  /// Get contrasting color (black or white)
  Color get contrastColor {
    final luminance = computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Lighten color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Darken color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Convert to hex string
  String toHex() {
    return '#${toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

// ============================================================================
// Future Extensions
// ============================================================================

extension FutureExtensions<T> on Future<T> {
  /// Add timeout with default value
  Future<T> withTimeout(
    Duration duration, {
    required T defaultValue,
  }) {
    return timeout(duration, onTimeout: () => defaultValue);
  }

  /// Handle errors gracefully
  Future<T?> handleError([void Function(Object)? onError]) {
    return then<T?>((value) => value).catchError((error) {
      onError?.call(error);
      return null as T?;
    });
  }
}
