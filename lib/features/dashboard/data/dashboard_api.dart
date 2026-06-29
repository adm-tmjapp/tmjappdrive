import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../../../api/base_api.dart';
import '../domain/dashboard_models.dart';

class DashboardApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const DashboardApiException(this.message, {this.code, this.statusCode});

  @override
  String toString() => message;
}

class DashboardApi {
  DashboardApi({BaseApi? baseApi}) : _baseApi = baseApi ?? BaseApi();

  final BaseApi _baseApi;

  Future<Map<String, dynamic>> getDashboard({
    required DashboardFilters filters,
    required DashboardPeriod period,
  }) async {
    final query = <String, String>{
      if (filters.highPriorityOnly) 'highPriority': 'true',
      if (filters.passengerOnly) 'category': 'passenger',
      'period': _periodParam(period),
    };

    final uri = Uri(
      path: 'v2/driver/dashboard',
      queryParameters: query.isEmpty ? null : query,
    );
    final headers = await _baseApi.getHeaders();

    _logRequest(method: 'GET', uri: uri, headers: headers);

    final response = await _baseApi.get(uri, headers: headers);

    _logResponse(method: 'GET', uri: uri, response: response);

    return _parsePayload(
      response,
      fallbackError: 'Falha ao carregar dashboard.',
    );
  }

  String _periodParam(DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.weekly:
        return 'week';
      case DashboardPeriod.biweekly:
        return 'biweekly';
      case DashboardPeriod.monthly:
        return 'month';
    }
  }

  Future<DriverAvailability> updateAvailability({
    required DriverAvailability availability,
  }) async {
    final uri = Uri.parse('${_baseApi.baseUrl}v2/driver/availability');
    final headers = await _baseApi.getHeaders();
    final body = jsonEncode(<String, String>{
      'availability':
          availability == DriverAvailability.online ? 'ONLINE' : 'OFFLINE',
    });

    _logRequest(method: 'PATCH', uri: uri, headers: headers, body: body);

    final response = await _baseApi.client.patch(
      uri,
      headers: headers,
      body: body,
    );

    _logResponse(method: 'PATCH', uri: uri, response: response);

    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao atualizar disponibilidade.',
    );

    return _mapAvailability(payload['availability']);
  }

  Future<void> acceptRide(String rideId) async {
    await _postRideAction(
      rideId: rideId,
      action: 'accept',
      fallbackError: 'Nao foi possivel aceitar a corrida.',
    );
  }

  Future<void> markRideArrived(String rideId) async {
    await _postRideAction(
      rideId: rideId,
      action: 'arrive',
      fallbackError: 'Nao foi possivel marcar chegada ao embarque.',
    );
  }

  Future<void> startRide(String rideId) async {
    await _postRideAction(
      rideId: rideId,
      action: 'start',
      fallbackError: 'Nao foi possivel iniciar a corrida.',
    );
  }

  Future<void> completeRide(String rideId) async {
    await _postRideAction(
      rideId: rideId,
      action: 'complete',
      fallbackError: 'Nao foi possivel concluir a corrida.',
    );
  }

  Future<void> _postRideAction({
    required String rideId,
    required String action,
    required String fallbackError,
  }) async {
    final uri = Uri.parse('${_baseApi.baseUrl}v2/driver/rides/$rideId/$action');
    final headers = await _baseApi.getHeaders();

    _logRequest(method: 'POST', uri: uri, headers: headers);

    final response = await _baseApi.client.post(uri, headers: headers);

    _logResponse(method: 'POST', uri: uri, response: response);

    _parsePayload(response, fallbackError: fallbackError);
  }

  Map<String, dynamic> _parsePayload(
    Response response, {
    required String fallbackError,
  }) {
    final body = _decodeBody(response.body);
    final status = response.statusCode;

    if (status == 200 || status == 201) {
      final payload = body['data'];
      if (payload is Map<String, dynamic>) {
        return payload;
      }
      return body;
    }

    throw DashboardApiException(
      _errorMessage(body, fallbackError),
      code: body['code']?.toString(),
      statusCode: status,
    );
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  DriverAvailability _mapAvailability(dynamic raw) {
    if (raw is String && raw.toUpperCase() == 'OFFLINE') {
      return DriverAvailability.offline;
    }
    return DriverAvailability.online;
  }

  String _errorMessage(Map<String, dynamic> body, String fallbackError) {
    final message = body['message']?.toString();
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    return fallbackError;
  }

  void _logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    debugPrint('[DashboardApi][$method] baseUrl=${_baseApi.baseUrl}');
    debugPrint('[DashboardApi][$method] url=${_resolveUrl(uri)}');
    debugPrint(
      '[DashboardApi][$method] hasToken=${headers.containsKey("Authorization")}',
    );
    debugPrint('[DashboardApi][$method] headers=$headers');
    if (body != null) {
      debugPrint('[DashboardApi][$method] body=$body');
    }
  }

  void _logResponse({
    required String method,
    required Uri uri,
    required Response response,
  }) {
    debugPrint(
      '[DashboardApi][$method] response url=${_resolveUrl(uri)} status=${response.statusCode}',
    );
    debugPrint('[DashboardApi][$method] response body=${response.body}');
  }

  String _resolveUrl(Uri uri) {
    final raw = uri.toString();
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return '${_baseApi.baseUrl}$raw';
  }
}
