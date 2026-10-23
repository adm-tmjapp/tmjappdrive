import 'dart:convert';

import '../../../api/base_api.dart';

class DriverSafetyApi {
  DriverSafetyApi({BaseApi? baseApi}) : _baseApi = baseApi ?? BaseApi();

  final BaseApi _baseApi;

  Future<String> reportIncident({
    required String rideId,
    required String description,
  }) async {
    final uri = Uri.parse(
      '${_baseApi.baseUrl}v2/driver/rides/$rideId/support/tickets',
    );
    final response = await _baseApi.client.post(
      uri,
      headers: await _baseApi.getHeaders(),
      body: jsonEncode({
        'issueCode': 'SECURITY_INCIDENT',
        'subject': 'Incidente de segurança',
        'description': description,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const DriverSafetyException(
        'Não foi possível registrar o incidente.',
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is Map && payload['ticketId'] != null) {
      return payload['ticketId'].toString();
    }
    return 'registrado';
  }
}

class DriverSafetyException implements Exception {
  const DriverSafetyException(this.message);
  final String message;
  @override
  String toString() => message;
}
