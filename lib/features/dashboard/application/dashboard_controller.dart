import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/dashboard_api.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_realtime_service.dart';
import 'dashboard_state.dart';
import '../../../utils/strings.dart';
import '../../../observability/app_observability.dart';

class DashboardController extends StateNotifier<DashboardState> {
  static const String serviceUnavailableMessage = 'Serviço indisponível';
  static const String sessionExpiredMessage =
      'Sua sessão expirou. Entre novamente para continuar.';
  static const String driverNotFoundMessage =
      'Seu cadastro de motorista não está disponível. Entre novamente ou procure o suporte.';
  static const String driverNotActiveMessage =
      'Seu cadastro ainda não está ativo ou aprovado para ficar online.';

  DashboardController(this._repository, this._realtimeService)
    : super(DashboardState.initial()) {
    _loadDriverSession();
    unawaited(_initializeRealtime());
    load();
  }

  final DashboardRepository _repository;
  final DashboardRealtimeService _realtimeService;
  Future<void>? _loadInFlight;

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

  /// Consolida recargas disparadas pelo timer, retorno ao app e ações do
  /// usuário. Sem isso, respostas fora de ordem podem sobrescrever o estado
  /// e tentar atualizar a interface durante a troca de Activity.
  Future<void> load() {
    final inFlight = _loadInFlight;
    if (inFlight != null) return inFlight;

    final request = _loadDashboard();
    _loadInFlight = request;
    return request.whenComplete(() {
      if (identical(_loadInFlight, request)) {
        _loadInFlight = null;
      }
    });
  }

  Future<void> _loadDashboard() async {
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
      await AppObservability.event(
        'dashboard_load_success',
        parameters: {'period': state.filters.period.name},
      );
      await _realtimeService.updateOperationalState(
        isOnline: snapshot.availability == DriverAvailability.online,
      );
    } on DashboardApiException catch (error) {
      await AppObservability.event(
        'dashboard_load_failed',
        parameters: {
          'status_code': error.statusCode ?? 0,
          if (error.code != null) 'error_code': error.code!,
        },
      );
      await _realtimeService.updateOperationalState(isOnline: false);
      if (error.statusCode == 401 ||
          error.statusCode == 403 ||
          error.code == 'DRIVER_NOT_FOUND') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(Strings.prefToken);
        state = state.copyWith(
          isLoading: false,
          availability: DriverAvailability.offline,
          error:
              error.code == 'DRIVER_NOT_FOUND'
                  ? driverNotFoundMessage
                  : sessionExpiredMessage,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        availability: DriverAvailability.offline,
        error: serviceUnavailableMessage,
      );
    } catch (_) {
      await AppObservability.event(
        'dashboard_load_failed',
        parameters: {'reason': 'unexpected_error'},
      );
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
    if (next == DriverAvailability.online) {
      final requirementsError =
          await _realtimeService.checkOnlineRequirements();
      if (requirementsError != null) {
        await AppObservability.event(
          'driver_online_blocked_by_permission',
          parameters: {'reason': requirementsError},
        );
        state = state.copyWith(availability: current, error: requirementsError);
        return;
      }
    }
    try {
      final updated = await _repository.updateAvailability(next);
      state = state.copyWith(availability: updated);
      await AppObservability.event(
        updated == DriverAvailability.online
            ? 'driver_online_success'
            : 'driver_offline_success',
      );
      await _realtimeService.updateOperationalState(
        isOnline: updated == DriverAvailability.online,
      );
      await load();
    } on DashboardApiException catch (error) {
      await AppObservability.event(
        'driver_online_failed',
        parameters: {
          'status_code': error.statusCode ?? 0,
          if (error.code != null) 'error_code': error.code!,
        },
      );
      await _realtimeService.updateOperationalState(isOnline: false);
      state = state.copyWith(
        availability: current,
        error:
            error.code == 'DRIVER_NOT_ACTIVE'
                ? (error.message.trim().isEmpty
                    ? driverNotActiveMessage
                    : error.message)
                : (error.statusCode != null && error.statusCode! >= 500
                    ? serviceUnavailableMessage
                    : error.message),
      );
    } catch (_) {
      await AppObservability.event(
        'driver_online_failed',
        parameters: {'reason': 'unexpected_error'},
      );
      await _realtimeService.updateOperationalState(isOnline: false);
      state = state.copyWith(
        availability: current,
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
      await AppObservability.event(
        'ride_accept_success',
        parameters: {'ride_id_present': true},
      );
      state = state.copyWith(clearLiveRideRequest: true);
      await load();
    } on DashboardApiException catch (error) {
      await AppObservability.event(
        'ride_accept_failed',
        parameters: {
          'status_code': error.statusCode ?? 0,
          if (error.code != null) 'error_code': error.code!,
        },
      );
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
      await AppObservability.event(
        'ride_accept_failed',
        parameters: {'reason': 'unexpected_error'},
      );
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
