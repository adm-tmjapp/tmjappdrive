import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/dashboard_realtime_api.dart';
import '../domain/dashboard_models.dart';
import '../../../services/ride_alert_notification_service.dart';

typedef NewRideRequestCallback = void Function(RideCardItem ride);

class DashboardRealtimeService {
  DashboardRealtimeService({required DashboardRealtimeApi api}) : _api = api;

  final DashboardRealtimeApi _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Timer? _locationTimer;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  bool _initialized = false;
  bool _isOnline = false;
  bool _isSendingLocation = false;
  DateTime? _lastRideAlertAt;
  final Set<String> _alertedRideIds = <String>{};
  NewRideRequestCallback? _onNewRideRequest;

  Future<void> initialize({
    required NewRideRequestCallback onNewRideRequest,
  }) async {
    _onNewRideRequest = onNewRideRequest;
    if (_initialized) return;
    _initialized = true;

    try {
      final permission = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        '[DashboardRealtimeService] notification permission=${permission.authorizationStatus}',
      );
      await _registerCurrentToken();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
        _registerRefreshedToken,
      );
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
        _handleRemoteMessage,
      );
      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleRemoteMessage,
      );

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessage(initialMessage);
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[DashboardRealtimeService] initialization failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> updateOperationalState({required bool isOnline}) async {
    _isOnline = isOnline;
    if (!isOnline) {
      await _stopLocationTracking();
      return;
    }

    await _startLocationTracking();
  }

  Future<void> dispose() async {
    await _stopLocationTracking();
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
  }

  Future<void> _registerCurrentToken() async {
    final token = await _messaging.getToken();
    debugPrint(
      '[DashboardRealtimeService] current FCM token length=${token?.length ?? 0}',
    );
    if (token == null || token.trim().isEmpty) {
      debugPrint('[DashboardRealtimeService] current FCM token is empty');
      return;
    }
    await _registerRefreshedToken(token);
  }

  Future<void> _registerRefreshedToken(String token) async {
    try {
      debugPrint(
        '[DashboardRealtimeService] registering FCM token platform=$_platformLabel length=${token.length}',
      );
      await _api.registerDeviceToken(
        provider: 'fcm',
        token: token,
        platform: _platformLabel,
      );
      debugPrint('[DashboardRealtimeService] FCM token registered');
    } catch (error, stackTrace) {
      debugPrint(
        '[DashboardRealtimeService] register token failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> _startLocationTracking() async {
    if (_locationTimer != null) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      await _captureAndSendCurrentPosition();
      _locationTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _captureAndSendCurrentPosition(),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[DashboardRealtimeService] start tracking failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> _stopLocationTracking() async {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _captureAndSendCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    await _sendLocation(position);
  }

  Future<void> _sendLocation(Position position) async {
    if (!_isOnline || _isSendingLocation) return;
    final lat = _finiteValue(position.latitude);
    final lng = _finiteValue(position.longitude);
    if (lat == null || lng == null) return;

    _isSendingLocation = true;
    try {
      await _api.updateDriverLocation(
        lat: lat,
        lng: lng,
        heading: _nonNegativeFiniteValue(position.heading),
        speed: _nonNegativeFiniteValue(position.speed),
        accuracy: _positiveFiniteValue(position.accuracy),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[DashboardRealtimeService] send location failed: $error\n$stackTrace',
      );
    } finally {
      _isSendingLocation = false;
    }
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final data = message.data;
    if (data['type'] != 'NEW_RIDE_REQUEST') return;
    debugPrint('[DashboardRealtimeService] NEW_RIDE_REQUEST data=$data');
    final pickup = _mapValue(data['pickup']);
    final dropoff = _mapValue(data['dropoff']);

    final ride = RideCardItem(
      id: _stringValue(data['rideId']),
      status: 'pending',
      type: 'Corrida próxima',
      route: '${_stringValue(data['pickupAddress'])} -> Aguardando destino',
      details:
          '${_distanceValue(data['distanceKm'])} km • ${_intValue(data['etaMin'])} min • Pagamento via app',
      price: _currencyValue(data['price']),
      isHighPriority: false,
      isPassenger: true,
      pickupAddress: _stringValue(data['pickupAddress']),
      pickupLat: _nullableDoubleValue(data['pickupLat'] ?? pickup['lat']),
      pickupLng: _nullableDoubleValue(data['pickupLng'] ?? pickup['lng']),
      dropoffAddress: 'Aguardando destino',
      dropoffLat: _nullableDoubleValue(data['dropoffLat'] ?? dropoff['lat']),
      dropoffLng: _nullableDoubleValue(data['dropoffLng'] ?? dropoff['lng']),
      distanceKm: _doubleValue(data['distanceKm']),
      etaMin: _intValue(data['etaMin']),
      paymentMethodLabel: 'Pagamento via app',
      passengerName:
          _stringValue(data['passengerName']).isNotEmpty
              ? _stringValue(data['passengerName'])
              : 'Passageiro',
      passengerPhotoUrl: _nullableStringValue(data['passengerPhotoUrl']),
      passengerPhone: _stringValue(data['passengerPhone']),
      passengerRating: _nullableDoubleValue(data['passengerRating']),
      dispatchTimeoutMs: _nullableIntValue(data['dispatchTimeoutMs']),
      startedAt: _nullableDateTimeValue(data['startedAt']),
      expiresAt: _nullableDateTimeValue(data['expiresAt']),
    );

    unawaited(_playNewRideAlert(ride));
    _onNewRideRequest?.call(ride);
  }

  Future<void> _playNewRideAlert(RideCardItem ride) async {
    if (ride.id.trim().isNotEmpty && _alertedRideIds.contains(ride.id)) {
      return;
    }

    final now = DateTime.now();
    if (_lastRideAlertAt != null &&
        now.difference(_lastRideAlertAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastRideAlertAt = now;
    if (ride.id.trim().isNotEmpty) {
      _alertedRideIds.add(ride.id);
      if (_alertedRideIds.length > 100) {
        _alertedRideIds.remove(_alertedRideIds.first);
      }
    }

    try {
      await RideAlertNotificationService.showNewRide(ride);
    } catch (error, stackTrace) {
      debugPrint(
        '[DashboardRealtimeService] ride alert sound failed: $error\n$stackTrace',
      );
    }
  }

  String get _platformLabel {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
      default:
        return 'android';
    }
  }

  String _stringValue(dynamic value) => value?.toString() ?? '';

  double _doubleValue(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  double? _nullableDoubleValue(dynamic value) =>
      double.tryParse(value?.toString() ?? '');

  int _intValue(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  int? _nullableIntValue(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  DateTime? _nullableDateTimeValue(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String? _nullableStringValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return text;
  }

  String _distanceValue(dynamic value) {
    final distance = _doubleValue(value);
    return distance.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _currencyValue(dynamic value) {
    final amount = _doubleValue(value);
    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  double? _finiteValue(double value) {
    if (!value.isFinite) return null;
    return value;
  }

  double? _nonNegativeFiniteValue(double value) {
    if (!value.isFinite || value < 0) return null;
    return value;
  }

  double? _positiveFiniteValue(double value) {
    if (!value.isFinite || value <= 0) return null;
    return value;
  }
}
