import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/dashboard_api.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_realtime_service.dart';
import 'dashboard_state.dart';
import '../../../utils/strings.dart';

class DashboardController extends StateNotifier<DashboardState> {
  static const String serviceUnavailableMessage = 'Servico indisponivel';

  DashboardController(this._repository, this._realtimeService)
    : super(DashboardState.initial()) {
    _loadDriverSession();
    unawaited(_initializeRealtime());
    load();
  }

  final DashboardRepository _repository;
  final DashboardRealtimeService _realtimeService;

  Future<void> _loadDriverSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(Strings.prefDriverName);
      final profileImage = prefs.getString(Strings.prefDriverProfileImage);

      state = state.copyWith(
        driverName: (name == null || name.trim().isEmpty) ? 'Motorista' : name,
        driverProfileImage:
            (profileImage == null || profileImage.trim().isEmpty)
                ? null
                : profileImage,
      );
    } catch (_) {}
  }

  Future<void> refreshDriverSession() async {
    await _loadDriverSession();
  }

  Future<void> _initializeRealtime() async {
    await _realtimeService.initialize(onNewRideRequest: _handleNewRideRequest);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final snapshot = await _repository.getDashboardSnapshot(
        filters: state.filters,
        period: state.filters.period,
      );

      state = state.copyWith(
        isLoading: false,
        availability: snapshot.availability,
        snapshot: snapshot,
        lastUpdatedAt: DateTime.now(),
        clearError: true,
      );
      await _realtimeService.updateOperationalState(
        isOnline: snapshot.availability == DriverAvailability.online,
      );
    } catch (_) {
      await _realtimeService.updateOperationalState(isOnline: false);
      state = state.copyWith(
        isLoading: false,
        availability: DriverAvailability.offline,
        error: serviceUnavailableMessage,
      );
    }
  }

  Future<void> toggleAvailability() async {
    final current = state.availability;
    final next =
        current == DriverAvailability.online
            ? DriverAvailability.offline
            : DriverAvailability.online;

    state = state.copyWith(availability: next, clearError: true);
    try {
      final updated = await _repository.updateAvailability(next);
      state = state.copyWith(availability: updated);
      await _realtimeService.updateOperationalState(
        isOnline: updated == DriverAvailability.online,
      );
      await load();
    } catch (_) {
      await _realtimeService.updateOperationalState(isOnline: false);
      state = state.copyWith(
        availability: DriverAvailability.offline,
        error: serviceUnavailableMessage,
      );
    }
  }

  Future<void> setHighPriorityOnly(bool enabled) async {
    state = state.copyWith(
      filters: state.filters.copyWith(highPriorityOnly: enabled),
    );
    await load();
  }

  Future<void> setPassengerOnly(bool enabled) async {
    state = state.copyWith(
      filters: state.filters.copyWith(passengerOnly: enabled),
    );
    await load();
  }

  Future<void> setPeriod(DashboardPeriod period) async {
    if (state.filters.period == period) return;
    state = state.copyWith(filters: state.filters.copyWith(period: period));
    await load();
  }

  Future<void> acceptRide(String rideId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.acceptRide(rideId);
      state = state.copyWith(clearLiveRideRequest: true);
      await load();
    } on DashboardApiException catch (error) {
      if (error.code == 'RIDE_NOT_AVAILABLE' || error.statusCode == 409) {
        state = state.copyWith(
          isLoading: false,
          clearLiveRideRequest: true,
          error: error.message,
        );
        await load();
        return;
      }

      state = state.copyWith(
        isLoading: false,
        availability: DriverAvailability.offline,
        error: error.message,
        clearLiveRideRequest: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        availability: DriverAvailability.offline,
        error: serviceUnavailableMessage,
        clearLiveRideRequest: true,
      );
    }
  }

  void rejectRide(String rideId) {
    final snapshot = state.snapshot;
    if (snapshot == null) {
      if (state.liveRideRequest != null &&
          state.liveRideRequest!.id == rideId) {
        state = state.copyWith(clearLiveRideRequest: true, clearError: true);
      }
      return;
    }

    final nextRides = snapshot.rides
        .where((ride) => ride.id != rideId)
        .toList(growable: false);

    state = state.copyWith(
      snapshot: snapshot.copyWith(rides: nextRides),
      clearError: true,
      clearLiveRideRequest:
          state.liveRideRequest != null && state.liveRideRequest!.id == rideId,
    );
  }

  void _handleNewRideRequest(RideCardItem ride) {
    state = state.copyWith(liveRideRequest: ride, clearError: true);
  }

  @override
  void dispose() {
    unawaited(_realtimeService.dispose());
    super.dispose();
  }
}
