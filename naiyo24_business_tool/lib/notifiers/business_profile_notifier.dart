import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/business_profile_model.dart';
import 'package:naiyo24_business_tool/providers/shared_prefs_provider.dart';

const _kBusinessProfileKey = 'business_profile_data';

class BusinessProfileNotifier extends AutoDisposeNotifier<BusinessProfileModel> {
  @override
  BusinessProfileModel build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final raw = prefs.getString(_kBusinessProfileKey);
    if (raw == null) return const BusinessProfileModel();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return BusinessProfileModel.fromJson(json);
    } catch (_) {
      return const BusinessProfileModel();
    }
  }

  void saveProfile(BusinessProfileModel profile) {
    state = profile;
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString(_kBusinessProfileKey, jsonEncode(profile.toJson()));
  }
}

// Manual provider
final businessProfileNotifierProvider = AutoDisposeNotifierProvider<BusinessProfileNotifier, BusinessProfileModel>(
  () => BusinessProfileNotifier(),
);
