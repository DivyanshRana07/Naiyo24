import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/auth_state.dart';
import 'package:naiyo24_business_tool/providers/shared_prefs_provider.dart';
import 'package:naiyo24_business_tool/utils/constants.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

class AuthNotifier extends AutoDisposeNotifier<AuthState> {
  @override
  AuthState build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final isLoggedIn = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
    final hasCompletedOnboarding =
        prefs.getBool(StorageKeys.hasCompletedOnboarding) ?? false;
    final userEmail = prefs.getString(StorageKeys.userEmail);
    
    AppLogger.debug('Auth state initialized', data: {
      'isLoggedIn': isLoggedIn,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'userEmail': userEmail,
    });
    
    return AuthState(
      isLoggedIn: isLoggedIn,
      hasCompletedOnboarding: hasCompletedOnboarding,
      userEmail: userEmail,
    );
  }

  bool login(String email, String password) {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    
    if (cleanEmail == DemoCredentials.email && cleanPassword == DemoCredentials.password) {
      state = state.copyWith(isLoggedIn: true, userEmail: cleanEmail);

      final prefs = ref.read(sharedPrefsProvider);
      prefs.setBool(StorageKeys.isLoggedIn, true);
      prefs.setString(StorageKeys.userEmail, cleanEmail);

      AppLogger.info('User logged in successfully', data: {'email': cleanEmail});
      return true;
    }
    
    AppLogger.warning('Login failed', data: {'email': cleanEmail});
    return false;
  }

  void forceLogin(String email) {
    final cleanEmail = email.trim();
    state = state.copyWith(isLoggedIn: true, userEmail: cleanEmail);

    final prefs = ref.read(sharedPrefsProvider);
    prefs.setBool(StorageKeys.isLoggedIn, true);
    prefs.setString(StorageKeys.userEmail, cleanEmail);
    
    AppLogger.info('User force logged in', data: {'email': cleanEmail});
  }

  void completeOnboarding() {
    state = state.copyWith(hasCompletedOnboarding: true);
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setBool(StorageKeys.hasCompletedOnboarding, true);
    
    AppLogger.info('Onboarding completed');
  }

  void logout() {
    final userEmail = state.userEmail;
    state = const AuthState();
    
    final prefs = ref.read(sharedPrefsProvider);
    prefs.remove(StorageKeys.isLoggedIn);
    prefs.remove(StorageKeys.userEmail);
    
    AppLogger.info('User logged out', data: {'email': userEmail});
  }

  bool get isLoggedIn => state.isLoggedIn;
}

// Manual provider
final authNotifierProvider = AutoDisposeNotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);
