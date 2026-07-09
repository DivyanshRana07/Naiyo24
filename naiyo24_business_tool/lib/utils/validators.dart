import 'package:naiyo24_business_tool/utils/constants.dart';

/// Form validation utilities
/// 
/// Provides reusable validators for common form fields following
/// Flutter best practices with proper null safety.
class Validators {
  Validators._();

  /// Validates required fields
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : ErrorMessages.fieldRequired;
    }
    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.emailRequired;
    }
    
    if (!ValidationPatterns.email.hasMatch(value.trim())) {
      return ErrorMessages.invalidEmail;
    }
    
    return null;
  }

  /// Validates password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return ErrorMessages.passwordRequired;
    }
    
    if (value.length < AppConfig.minPasswordLength) {
      return ErrorMessages.passwordTooShort;
    }
    
    return null;
  }

  /// Validates mobile number (Indian format)
  static String? mobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (!ValidationPatterns.mobile.hasMatch(cleaned)) {
      return ErrorMessages.invalidMobile;
    }
    
    return null;
  }

  /// Validates GST number
  static String? gst(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // GST is optional
    }
    
    if (!ValidationPatterns.gst.hasMatch(value.trim().toUpperCase())) {
      return ErrorMessages.invalidGST;
    }
    
    return null;
  }

  /// Validates numeric input
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Allow empty for optional fields
    }
    
    if (double.tryParse(value.trim()) == null) {
      return fieldName != null
          ? '$fieldName must be a valid number'
          : ErrorMessages.invalidNumber;
    }
    
    return null;
  }

  /// Validates positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    final numberError = number(value, fieldName: fieldName);
    if (numberError != null) return numberError;
    
    if (value != null && value.trim().isNotEmpty) {
      final num = double.parse(value.trim());
      if (num <= 0) {
        return fieldName != null
            ? '$fieldName must be greater than 0'
            : 'Must be greater than 0';
      }
    }
    
    return null;
  }

  /// Validates non-negative number
  static String? nonNegativeNumber(String? value, {String? fieldName}) {
    final numberError = number(value, fieldName: fieldName);
    if (numberError != null) return numberError;
    
    if (value != null && value.trim().isNotEmpty) {
      final num = double.parse(value.trim());
      if (num < 0) {
        return fieldName != null
            ? '$fieldName cannot be negative'
            : 'Cannot be negative';
      }
    }
    
    return null;
  }

  /// Validates minimum length
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Allow empty, use required() for mandatory fields
    }
    
    if (value.length < min) {
      return fieldName != null
          ? '$fieldName must be at least $min characters'
          : 'Must be at least $min characters';
    }
    
    return null;
  }

  /// Validates maximum length
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (value.length > max) {
      return fieldName != null
          ? '$fieldName cannot exceed $max characters'
          : 'Cannot exceed $max characters';
    }
    
    return null;
  }

  /// Validates PIN code (Indian)
  static String? pinCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    
    if (!ValidationPatterns.pinCode.hasMatch(value.trim())) {
      return 'Please enter a valid 6-digit PIN code';
    }
    
    return null;
  }

  /// Validates percentage (0-100)
  static String? percentage(String? value, {String? fieldName}) {
    final numberError = nonNegativeNumber(value, fieldName: fieldName);
    if (numberError != null) return numberError;
    
    if (value != null && value.trim().isNotEmpty) {
      final num = double.parse(value.trim());
      if (num > 100) {
        return fieldName != null
            ? '$fieldName cannot exceed 100%'
            : 'Cannot exceed 100%';
      }
    }
    
    return null;
  }

  /// Combines multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Validates if value matches another value (e.g., confirm password)
  static String? match(String? value, String? matchValue, {String? fieldName}) {
    if (value != matchValue) {
      return fieldName != null
          ? '$fieldName does not match'
          : 'Values do not match';
    }
    return null;
  }

  /// Validates URL format
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    
    try {
      final uri = Uri.parse(value.trim());
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'Please enter a valid URL';
      }
    } catch (_) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  /// Validates date is not in the past
  static String? futureDate(DateTime? value, {String? fieldName}) {
    if (value == null) return null;
    
    if (value.isBefore(DateTime.now())) {
      return fieldName != null
          ? '$fieldName must be in the future'
          : 'Date must be in the future';
    }
    
    return null;
  }

  /// Validates date is not in the future
  static String? pastDate(DateTime? value, {String? fieldName}) {
    if (value == null) return null;
    
    if (value.isAfter(DateTime.now())) {
      return fieldName != null
          ? '$fieldName must be in the past'
          : 'Date must be in the past';
    }
    
    return null;
  }
}

/// Extension on String for easy validation
extension StringValidation on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
  
  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => !isNullOrEmpty;
  
  /// Check if string is a valid email
  bool get isValidEmail => 
      this != null && ValidationPatterns.email.hasMatch(this!.trim());
  
  /// Check if string is a valid mobile
  bool get isValidMobile => 
      this != null && ValidationPatterns.mobile.hasMatch(this!.replaceAll(RegExp(r'[^\d]'), ''));
  
  /// Check if string is a valid GST
  bool get isValidGST => 
      this != null && ValidationPatterns.gst.hasMatch(this!.trim().toUpperCase());
}
