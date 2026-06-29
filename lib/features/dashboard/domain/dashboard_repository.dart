import 'dashboard_models.dart';

abstract class DashboardRepository {
  Future<DashboardSnapshot> getDashboardSnapshot({
    required DashboardFilters filters,
    required DashboardPeriod period,
  });

  Future<DriverAvailability> updateAvailability(
    DriverAvailability availability,
  );

  Future<void> acceptRide(String rideId);
}
