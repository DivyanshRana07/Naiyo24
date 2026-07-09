import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/auth_state.dart';
import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';

export 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';

// Manual provider
final authProvider = Provider<AuthState>((ref) {
  return ref.watch(authNotifierProvider);
});
