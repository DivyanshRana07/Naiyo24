import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/services/dashboard_services.dart';
import 'package:naiyo24_business_tool/models/dashboard_stats_model.dart';
import 'package:naiyo24_business_tool/providers/api_providers.dart';

class DashboardState {
  const DashboardState({
    required this.stats,
    required this.isLoading,
    this.error,
  });

  final DashboardStatsModel stats;
  final bool isLoading;
  final String? error;

  DashboardState copyWith({
    DashboardStatsModel? stats,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._service)
      : super(DashboardState(
          stats: DashboardStatsModel.empty(),
          isLoading: false,
        ));

  final DashboardService _service;

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final stats = await _service.getDashboardStats();
      state = state.copyWith(
        stats: stats,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadStats();
  }
}

final dashboardNotifierProvider =
    StateNotifierProvider.autoDispose<DashboardNotifier, DashboardState>((ref) {
  final service = ref.watch(dashboardApiServiceProvider);
  final notifier = DashboardNotifier(service);
  notifier.loadStats(); // Auto-load on init
  return notifier;
});
