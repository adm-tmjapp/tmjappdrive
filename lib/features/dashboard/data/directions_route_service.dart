import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Builds the same road-following route used by the passenger app.
class DirectionsRouteService {
  DirectionsRouteService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    // Keep this aligned with the Android Maps key in AndroidManifest.xml.
    defaultValue: 'AIzaSyBggG1v_Lbevj0NiZERxC6sYjsvfrrCvMI',
  );

  Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'key': _apiKey,
      'language': 'pt-br',
      'mode': 'driving',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) return const [];

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['status'] != 'OK') {
      return const [];
    }
    final routes = body['routes'];
    if (routes is! List || routes.isEmpty) return const [];
    final route = routes.first;
    if (route is! Map<String, dynamic>) return const [];
    final overview = route['overview_polyline'];
    if (overview is! Map<String, dynamic>) return const [];
    final encoded = overview['points'];
    if (encoded is! String || encoded.isEmpty) return const [];
    return _decodePolyline(encoded);
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      final lat = _decodeValue(encoded, index);
      latitude += lat.value;
      index = lat.nextIndex;
      final lng = _decodeValue(encoded, index);
      longitude += lng.value;
      index = lng.nextIndex;
      points.add(LatLng(latitude / 1e5, longitude / 1e5));
    }

    return points;
  }

  ({int value, int nextIndex}) _decodeValue(String encoded, int index) {
    var result = 0;
    var shift = 0;
    var byte = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && index < encoded.length);

    final value = (result & 1) == 1 ? ~(result >> 1) : result >> 1;
    return (value: value, nextIndex: index);
  }
}
