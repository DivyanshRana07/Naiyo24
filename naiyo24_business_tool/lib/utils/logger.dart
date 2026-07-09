import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:naiyo24_business_tool/utils/constants.dart';

/// Application logger for debugging and monitoring
/// 
/// Usage:
/// ```dart
/// AppLogger.debug('User logged in', data: {'email': email});
/// AppLogger.error('Failed to save', error: e, stackTrace: st);
/// ```
class AppLogger {
  AppLogger._();

  static const String _name = 'Naiyo24';
  
  /// Log debug messages (development only)
  static void debug(
    String message, {
    Map<String, dynamic>? data,
    String? tag,
  }) {
    if (!FeatureFlags.enableDebugMode) return;
    
    _log(
      message,
      level: _LogLevel.debug,
      data: data,
      tag: tag,
    );
  }

  /// Log info messages
  static void info(
    String message, {
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      message,
      level: _LogLevel.info,
      data: data,
      tag: tag,
    );
  }

  /// Log warning messages
  static void warning(
    String message, {
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      message,
      level: _LogLevel.warning,
      data: data,
      tag: tag,
    );
  }

  /// Log error messages
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      message,
      level: _LogLevel.error,
      error: error,
      stackTrace: stackTrace,
      data: data,
      tag: tag,
    );
  }

  /// Log network requests
  static void network(
    String method,
    String url, {
    int? statusCode,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    Duration? duration,
  }) {
    if (!FeatureFlags.enableDebugMode) return;

    final message = '[$method] $url ${statusCode ?? ''}';
    final data = <String, dynamic>{
      if (requestData != null) 'request': requestData,
      if (responseData != null) 'response': responseData,
      if (duration != null) 'duration': '${duration.inMilliseconds}ms',
    };

    _log(
      message,
      level: _LogLevel.info,
      data: data,
      tag: 'Network',
    );
  }

  /// Log navigation events
  static void navigation(String route, {Map<String, dynamic>? params}) {
    if (!FeatureFlags.enableDebugMode) return;

    _log(
      'Navigating to: $route',
      level: _LogLevel.debug,
      data: params,
      tag: 'Navigation',
    );
  }

  /// Log state changes
  static void state(String notifier, String action, {dynamic oldValue, dynamic newValue}) {
    if (!FeatureFlags.enableDebugMode) return;

    _log(
      '$notifier: $action',
      level: _LogLevel.debug,
      data: {
        if (oldValue != null) 'old': oldValue.toString(),
        if (newValue != null) 'new': newValue.toString(),
      },
      tag: 'State',
    );
  }

  static void _log(
    String message, {
    required _LogLevel level,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    if (kReleaseMode && level == _LogLevel.debug) return;

    final timestamp = DateTime.now();
    final prefix = tag != null ? '[$tag] ' : '';
    final emoji = level.emoji;
    final logMessage = '$emoji $prefix$message';

    // Use dart:developer for better DevTools integration
    developer.log(
      logMessage,
      time: timestamp,
      name: _name,
      level: level.value,
      error: error,
      stackTrace: stackTrace,
    );

    // Print data if available
    if (data != null && data.isNotEmpty) {
      developer.log(
        '  Data: $data',
        time: timestamp,
        name: _name,
        level: level.value,
      );
    }

    // Print stack trace for errors
    if (stackTrace != null && level == _LogLevel.error) {
      developer.log(
        '  StackTrace:\n$stackTrace',
        time: timestamp,
        name: _name,
        level: level.value,
      );
    }
  }
}

enum _LogLevel {
  debug(0, '🔍'),
  info(800, 'ℹ️'),
  warning(900, '⚠️'),
  error(1000, '❌');

  const _LogLevel(this.value, this.emoji);

  final int value;
  final String emoji;
}
