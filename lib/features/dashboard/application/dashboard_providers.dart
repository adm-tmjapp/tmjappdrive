import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_api.dart';
import '../data/dashboard_realtime_api.dart';
import '../data/dashboard_repository_impl.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_controller.dart';
import 'dashboard_realtime_service.dart';
import 'dashboard_state.dart';

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi();
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final api = ref.watch(dashboardApiProvider);
  return DashboardRepositoryImpl(api: api);
});

final dashboardRealtimeApiProvider = Provider<DashboardRealtimeApi>((ref) {
  return DashboardRealtimeApi();
});

final dashboardRealtimeServiceProvider = Provider<DashboardRealtimeService>((
  ref,
) {
  final api = ref.watch(dashboardRealtimeApiProvider);
  return DashboardRealtimeService(api: api);
});

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
      final repository = ref.watch(dashboardRepositoryProvider);
      final realtimeService = ref.watch(dashboardRealtimeServiceProvider);
      return DashboardController(repository, realtimeService);
    });
