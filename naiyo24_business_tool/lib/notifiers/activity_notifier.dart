import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/services/activity_services.dart';
import 'package:naiyo24_business_tool/models/activity_model.dart';
import 'package:naiyo24_business_tool/providers/api_providers.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

/// Activity state fetched from backend API
class ActivityNotifier extends AutoDisposeAsyncNotifier<List<ActivityModel>> {
  late final ActivityService _service;

  @override
  Future<List<ActivityModel>> build() async {
    _service = ref.watch(activityApiServiceProvider);
    return await loadActivities();
  }

  Future<List<ActivityModel>> loadActivities() async {
    try {
      return await _service.getActivities(limit: 50);
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

  Future<void> deleteActivity(int activityId) async {
    try {
      await _service.deleteActivity(activityId);
      // Refresh activities after deletion
      await refresh();
    } catch (e) {
      AppLogger.error('Failed to delete activity', error: e);
      rethrow;
    }
  }
}

final activityNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ActivityNotifier, List<ActivityModel>>(
  () => ActivityNotifier(),
);
