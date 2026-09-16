import 'package:flutter/foundation.dart';
import '../domain/dashboard_models.dart';

@immutable
class DashboardState {
  final bool isLoading;
  final String? error;
  final DriverAvailability availability;
  final DashboardFilters filters;
  final String driverName;
  final String? driverProfileImage;
  final DashboardSnapshot? snapshot;
  final RideCardItem? liveRideRequest;
  final DateTime? lastUpdatedAt;

  const DashboardState({
    required this.isLoading,
    required this.availability,
    required this.filters,
    required this.driverName,
    this.driverProfileImage,
    this.snapshot,
    this.liveRideRequest,
    this.lastUpdatedAt,
    this.error,
  });

  factory DashboardState.initial() {
    return const DashboardState(
      isLoading: true,
      availability: DriverAvailability.offline,
      filters: DashboardFilters(),
      driverName: 'Motorista',
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    DriverAvailability? availability,
    DashboardFilters? filters,
    String? driverName,
    String? driverProfileImage,
    bool clearDriverProfileImage = false,
    DashboardSnapshot? snapshot,
    RideCardItem? liveRideRequest,
    bool clearLiveRideRequest = false,
    DateTime? lastUpdatedAt,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      availability: availability ?? this.availability,
      filters: filters ?? this.filters,
      driverName: driverName ?? this.driverName,
      driverProfileImage:
          clearDriverProfileImage
              ? null
              : (driverProfileImage ?? this.driverProfileImage),
      snapshot: snapshot ?? this.snapshot,
      liveRideRequest:
          clearLiveRideRequest
              ? null
              : (liveRideRequest ?? this.liveRideRequest),
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
