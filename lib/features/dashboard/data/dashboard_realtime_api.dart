import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../api/base_api.dart';

class DashboardRealtimeApi {
  DashboardRealtimeApi({BaseApi? baseApi}) : _baseApi = baseApi ?? BaseApi();

  final BaseApi _baseApi;

  Future<void> updateDriverLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    double? accuracy,
  }) async {
    final uri = Uri.parse('${_baseApi.baseUrl}v2/driver/location');
    final headers = await _baseApi.getHeaders();
    final body = jsonEncode(<String, dynamic>{
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (accuracy != null) 'accuracy': accuracy,
    });

    debugPrint('[DashboardRealtimeApi][POST] url=$uri');
    debugPrint('[DashboardRealtimeApi][POST] location body=$body');

    final response = await _baseApi.client.post(
      uri,
      headers: headers,
      body: body,
    );

    debugPrint(
      '[DashboardRealtimeApi][POST] location status=${response.statusCode} body=${response.body}',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    if (response.statusCode == 429) {
      return;
    }

    throw DashboardRealtimeApiException(
      'Falha ao atualizar localizacao do motorista.',
    );
  }

  Future<void> registerDeviceToken({
    required String provider,
    required String token,
    required String platform,
  }) async {
    final uri = Uri.parse('${_baseApi.baseUrl}v2/driver/device-token');
    final headers = await _baseApi.getHeaders();
    final body = jsonEncode(<String, dynamic>{
      'provider': provider,
      'token': token,
      'platform': platform,
    });

    debugPrint('[DashboardRealtimeApi][POST] url=$uri');
    debugPrint(
      '[DashboardRealtimeApi][POST] device token body={"provider":"$provider","tokenLength":${token.length},"platform":"$platform"}',
    );

    final response = await _baseApi.client.post(
      uri,
      headers: headers,
      body: body,
    );

    debugPrint(
      '[DashboardRealtimeApi][POST] device token status=${response.statusCode} body=${response.body}',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    throw DashboardRealtimeApiException(
      'Falha ao registrar token do dispositivo.',
    );
  }
}

class DashboardRealtimeApiException implements Exception {
  const DashboardRealtimeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
