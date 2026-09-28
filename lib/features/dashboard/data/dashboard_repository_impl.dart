import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_api.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required DashboardApi api}) : _api = api;

  final DashboardApi _api;

  @override
  Future<DashboardSnapshot> getDashboardSnapshot({
    required DashboardFilters filters,
    required DashboardPeriod period,
  }) async {
    final payload = await _api.getDashboard(filters: filters, period: period);

    final summaryMap = _mapFrom(payload['summary']);
    final ridesRaw = payload['pendingRides'];
    final pendingList = ridesRaw is List ? ridesRaw : const [];

    final currentRideRaw = payload['currentRide'];
    final List<dynamic> allRidesList = [];
    if (currentRideRaw != null) {
      allRidesList.add(currentRideRaw);
    }
    allRidesList.addAll(pendingList);

    return DashboardSnapshot(
      availability: _mapAvailability(payload['availability']),
      summary: DashboardSummary(
        todayRides: _asInt(summaryMap['todayRides']),
        todayEarnings: _currency(_asNum(summaryMap['todayEarnings'])),
        progressPercent: _asInt(summaryMap['progressPercent']),
      ),
      rides: allRidesList.map(_toRide).toList(growable: false),
    );
  }

  @override
  Future<DriverAvailability> updateAvailability(
    DriverAvailability availability,
  ) async {
    return _api.updateAvailability(availability: availability);
  }

  @override
  Future<void> acceptRide(String rideId) {
    return _api.acceptRide(rideId);
  }

  RideCardItem _toRide(dynamic item) {
    final map = _mapFrom(item);
    final category = _asString(map['category']).toLowerCase();
    final distance = _asNum(map['distanceKm']);
    final eta = _asInt(map['etaMin']);

    final pickup = _mapFrom(map['pickup'] ?? map['origin']);
    final dropoff = _mapFrom(map['dropoff'] ?? map['destination']);
    final passenger =
        map['passenger'] != null
            ? _mapFrom(map['passenger'])
            : <String, dynamic>{};

    final routeLabel =
        _asString(map['routeLabel']).isNotEmpty
            ? _asString(map['routeLabel'])
            : '${_asString(pickup['address'])} -> ${_asString(dropoff['address'])}';

    return RideCardItem(
      id: _asString(map['id']),
      status:
          _asString(map['status']).isNotEmpty
              ? _asString(map['status'])
              : 'pending',
      type:
          _asString(map['typeLabel']).isNotEmpty
              ? _asString(map['typeLabel'])
              : (category == 'delivery'
                  ? 'Entrega'
                  : (category == 'passenger' ? 'Passageiro' : 'Corrida')),
      route: routeLabel,
      details:
          '${_distance(distance)} km • $eta min • ${_paymentMethod(_asString(map['paymentMethod']))}',
      price: _currency(_asNum(map['price'])),
      isHighPriority: _asBool(map['highPriority']),
      isPassenger: category == 'passenger',
      pickupAddress: _asString(pickup['address']),
      pickupLat: _coordinate(pickup, map, 'pickupLat', latitude: true),
      pickupLng: _coordinate(pickup, map, 'pickupLng', latitude: false),
      dropoffAddress: _asString(dropoff['address']),
      dropoffLat: _coordinate(dropoff, map, 'dropoffLat', latitude: true),
      dropoffLng: _coordinate(dropoff, map, 'dropoffLng', latitude: false),
      distanceKm: distance.toDouble(),
      etaMin: eta,
      paymentMethodLabel: _paymentMethod(_asString(map['paymentMethod'])),
      passengerName:
          _asString(passenger['name']).isNotEmpty
              ? _asString(passenger['name'])
              : 'Passageiro',
      passengerPhotoUrl: _nullableString(
        passenger['photoUrl'] ??
            passenger['avatarUrl'] ??
            passenger['imageUrl'],
      ),
      passengerPhone: _asString(passenger['phone']),
      passengerRating: _asNullableDouble(passenger['rating']),
      dispatchTimeoutMs: _asNullableInt(map['dispatchTimeoutMs']),
      startedAt: _asDateTimeOrNull(map['startedAt']),
      expiresAt: _asDateTimeOrNull(map['expiresAt']),
      arrivedAt: _asDateTimeOrNull(map['arrivedAt']),
      pickedUpAt: _asDateTimeOrNull(map['pickedUpAt']),
      completedAt: _asDateTimeOrNull(map['completedAt']),
    );
  }

  DriverAvailability _mapAvailability(dynamic raw) {
    final normalized = _asString(raw).toUpperCase();
    if (normalized == 'OFFLINE') {
      return DriverAvailability.offline;
    }
    return DriverAvailability.online;
  }

  String _paymentMethod(String value) {
    final normalized = value.toUpperCase();
    if (normalized == 'CASH') return 'Dinheiro';
    if (normalized == 'CARD') return 'Cartao';
    return 'Pagamento via app';
  }

  String _distance(num value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _currency(num value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $fixed';
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  double? _coordinate(
    Map<String, dynamic> point,
    Map<String, dynamic> ride,
    String topLevelKey, {
    required bool latitude,
  }) {
    final key = latitude ? 'lat' : 'lng';
    final longKey = latitude ? 'latitude' : 'longitude';
    final shortLongKey = latitude ? 'y' : 'lon';
    final location = _mapFrom(point['location']);
    final coordinates = point['coordinates'];
    final coordinateMap = _mapFrom(coordinates);
    final alternateTopLevelKey = topLevelKey
        .replaceFirst('Lat', 'Latitude')
        .replaceFirst('Lng', 'Longitude');
    final routeTopLevelPrefix =
        topLevelKey.startsWith('pickup') ? 'origin' : 'destination';
    final routeTopLevelKey = '$routeTopLevelPrefix${latitude ? 'Lat' : 'Lng'}';
    final routeTopLevelLongKey =
        '$routeTopLevelPrefix${latitude ? 'Latitude' : 'Longitude'}';
    final raw =
        point[key] ??
        point[longKey] ??
        point[shortLongKey] ??
        location[key] ??
        location[longKey] ??
        coordinateMap[key] ??
        coordinateMap[longKey] ??
        ride[topLevelKey] ??
        ride[alternateTopLevelKey] ??
        ride[routeTopLevelKey] ??
        ride[routeTopLevelLongKey] ??
        (coordinates is List && coordinates.length > (latitude ? 1 : 0)
            ? coordinates[latitude ? 1 : 0]
            : null);
    return _asNullableDouble(raw);
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(_asString(value)) ?? 0;
  }

  int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(_asString(value));
  }

  double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(_asString(value).replaceAll(',', '.'));
  }

  num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(_asString(value).replaceAll(',', '.')) ?? 0;
  }

  DateTime? _asDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(_asString(value));
  }

  String? _nullableString(dynamic value) {
    final text = _asString(value).trim();
    if (text.isEmpty) return null;
    return text;
  }
}
