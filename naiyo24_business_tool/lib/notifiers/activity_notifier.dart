import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/services/activity_services.dart';
import 'package:naiyo24_business_tool/models/activity_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

/// Activity state fetched from backend API
class ActivityNotifier extends AutoDisposeAsyncNotifier<List<ActivityModel>> {
  @override
  Future<List<ActivityModel>> build() async {
    return await loadActivities();
  }

  Future<List<ActivityModel>> loadActivities() async {
    try {
      return await ActivityService.getActivities(limit: 50);
    } catch (e) {
      AppLogger.error('Failed to load activities', error: e);
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await loadActivities();
    });
  }
}

final activityNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ActivityNotifier, List<ActivityModel>>(
  () => ActivityNotifier(),
);
