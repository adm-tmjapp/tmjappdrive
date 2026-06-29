import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import '../../../api/base_api.dart';
import '../domain/ride_history_models.dart';

class RideHistoryApiException implements Exception {
  const RideHistoryApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RideHistoryApi {
  RideHistoryApi({BaseApi? baseApi}) : _baseApi = baseApi ?? BaseApi();

  final BaseApi _baseApi;

  Future<RideHistorySummary> fetchSummary({
    required RideHistoryRange range,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _baseApi.get(
      Uri(
        path: 'v2/driver/rides/history/summary',
        queryParameters: _query(
          range: range,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
      headers: await _baseApi.getHeaders(),
    );

    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao carregar resumo do historico.',
    );

    return RideHistorySummary(
      totalBilled: _asDouble(payload['totalBilled']),
      totalRides: _asInt(payload['totalRides']),
      billedGrowthLabel: _growth(payload['billedGrowthPercent']),
      ridesGrowthLabel: _growth(payload['ridesGrowthPercent']),
    );
  }

  Future<List<RideHistoryItem>> fetchHistory({
    required RideHistoryRange range,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _baseApi.get(
      Uri(
        path: 'v2/driver/rides/history',
        queryParameters: _query(
          range: range,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
      headers: await _baseApi.getHeaders(),
    );

    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao carregar historico.',
    );

    final itemsRaw = payload['data'];
    final items =
        itemsRaw is List
            ? itemsRaw
            : (payload['items'] is List ? payload['items'] as List : const []);

    return items.map(_mapRide).toList(growable: false);
  }

  Future<RideHistoryDetail> getHistoryDetail(String rideId) async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/rides/$rideId/history-detail'),
      headers: await _baseApi.getHeaders(),
    );
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao carregar detalhes da corrida.',
    );
    final ride = _asMap(payload['ride'].isNotEmpty ? payload['ride'] : payload);

    return RideHistoryDetail(
      id: _asString(ride['id']).isEmpty ? rideId : _asString(ride['id']),
      status: _asString(ride['status']),
      startedAt: _asDateTimeOrNull(ride['startedAt']),
      endedAt: _asDateTimeOrNull(ride['endedAt']),
      durationMinutes: _asInt(ride['durationMinutes']),
      distanceKm: _asDouble(ride['distanceKm']),
      originAddress: _nullableString(ride['originAddress']),
      destinationAddress: _nullableString(ride['destinationAddress']),
      originLat: _asDoubleOrNull(ride['originLat']),
      originLng: _asDoubleOrNull(ride['originLng']),
      destinationLat: _asDoubleOrNull(ride['destinationLat']),
      destinationLng: _asDoubleOrNull(ride['destinationLng']),
      grossAmount: _asDouble(ride['grossAmount']),
      appFee: _asDouble(ride['appFee']),
      netAmount: _asDouble(ride['netAmount']),
      paymentMethodLabel: _asString(ride['paymentMethodLabel']),
      polyline: _nullableString(ride['polyline']),
    );
  }

  Future<List<RideSupportOption>> getSupportOptions(String rideId) async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/rides/$rideId/support/options'),
      headers: await _baseApi.getHeaders(),
    );
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao carregar opções de suporte.',
    );
    final items =
        payload['options'] is List ? payload['options'] as List : const [];
    return items
        .map((item) {
          final map = _asMap(item);
          return RideSupportOption(
            code: _issueCodeFromApi(_asString(map['code'])),
            label: _asString(map['label']),
            enabled: map['enabled'] == true,
          );
        })
        .toList(growable: false);
  }

  Future<RideSupportTicketResult> createSupportTicket({
    required String rideId,
    required RideSupportIssueCode issueCode,
    required String subject,
    String? description,
    List<String> attachments = const <String>[],
  }) async {
    final response = await _baseApi.client.post(
      Uri.parse('${_baseApi.baseUrl}v2/driver/rides/$rideId/support/tickets'),
      headers: await _baseApi.getHeaders(),
      body: jsonEncode(<String, dynamic>{
        'issueCode': _issueCodeToApi(issueCode),
        'subject': subject.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (attachments.isNotEmpty) 'attachments': attachments,
      }),
    );
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao abrir ticket de suporte.',
    );
    return RideSupportTicketResult(
      ticketId: _asString(payload['ticketId']),
      status: _asString(payload['status']),
      createdAt: _asDateTimeOrNull(payload['createdAt']) ?? DateTime.now(),
      message: _nullableString(payload['message']),
    );
  }

  Future<RideSupportTicketResult> createPaymentIssue({
    required String rideId,
    required double expectedAmount,
    required double receivedAmount,
    String? description,
    List<String> attachments = const <String>[],
  }) async {
    final response = await _baseApi.client.post(
      Uri.parse(
        '${_baseApi.baseUrl}v2/driver/rides/$rideId/support/payment-issue',
      ),
      headers: await _baseApi.getHeaders(),
      body: jsonEncode(<String, dynamic>{
        'expectedAmount': expectedAmount,
        'receivedAmount': receivedAmount,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (attachments.isNotEmpty) 'attachments': attachments,
      }),
    );
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao registrar problema com valor.',
    );
    return RideSupportTicketResult(
      ticketId: _asString(payload['ticketId']),
      status: _asString(payload['status']),
      createdAt: _asDateTimeOrNull(payload['createdAt']) ?? DateTime.now(),
      message: _nullableString(payload['message']),
    );
  }

  Future<RideSupportTicketResult> createForgottenObject({
    required String rideId,
    required String description,
    List<String> attachments = const <String>[],
  }) async {
    final response = await _baseApi.client.post(
      Uri.parse(
        '${_baseApi.baseUrl}v2/driver/rides/$rideId/support/forgotten-object',
      ),
      headers: await _baseApi.getHeaders(),
      body: jsonEncode(<String, dynamic>{
        'description': description.trim(),
        if (attachments.isNotEmpty) 'attachments': attachments,
      }),
    );
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao registrar objeto esquecido.',
    );
    return RideSupportTicketResult(
      ticketId: _asString(payload['ticketId']),
      status: _asString(payload['status']),
      createdAt: _asDateTimeOrNull(payload['createdAt']) ?? DateTime.now(),
      message: _nullableString(payload['message']),
    );
  }

  Future<RidePassengerAbsentResult> createPassengerAbsent({
    required String rideId,
    required bool waitedMoreThan5Minutes,
    required bool calledPassenger,
    required bool messagedPassenger,
    required bool atBoardingPoint,
    required double driverLat,
    required double driverLng,
    String? gpsEvidenceId,
  }) async {
    final response = await _baseApi.client.post(
      Uri.parse(
        '${_baseApi.baseUrl}v2/driver/rides/$rideId/support/passenger-absent',
      ),
      headers: await _baseApi.getHeaders(),
      body: jsonEncode(<String, dynamic>{
        'waitedMoreThan5Minutes': waitedMoreThan5Minutes,
        'calledPassenger': calledPassenger,
        'messagedPassenger': messagedPassenger,
        'atBoardingPoint': atBoardingPoint,
        'driverLat': driverLat,
        'driverLng': driverLng,
        if (gpsEvidenceId != null && gpsEvidenceId.trim().isNotEmpty)
          'gpsEvidenceId': gpsEvidenceId.trim(),
      }),
    );
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao registrar passageiro ausente.',
    );
    return RidePassengerAbsentResult(
      requestId: _asString(payload['requestId']),
      status: _asString(payload['status']),
      createdAt: _asDateTimeOrNull(payload['createdAt']) ?? DateTime.now(),
      penaltyWaiverRequested: payload['penaltyWaiverRequested'] == true,
    );
  }

  Future<RideSupportUploadAsset> uploadAttachment(File file) async {
    final request = MultipartRequest(
      'POST',
      Uri.parse('${_baseApi.baseUrl}v2/uploads'),
    );
    request.files.add(await MultipartFile.fromPath('file', file.path));
    request.fields['context'] = 'ride_support';

    final headers = await _baseApi.getHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    final streamed = await _baseApi.client.send(request);
    final response = await Response.fromStream(streamed);
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao enviar anexo.',
    );
    return RideSupportUploadAsset(
      fileId: _asString(payload['fileId']),
      url: _asString(payload['url']),
      mimeType: _asString(payload['mimeType']),
      size: _asInt(payload['size']),
    );
  }

  Future<RideSupportContact> getSupportContact() async {
    final response = await _baseApi.get(
      Uri(path: 'v2/support/contact'),
      headers: await _baseApi.getHeaders(),
    );
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao carregar contato do suporte.',
    );
    return RideSupportContact(
      channel: _asString(payload['channel']),
      phone: _nullableString(payload['phone']),
      whatsApp: _nullableString(payload['whatsApp']),
      chatUrl: _nullableString(payload['chatUrl']),
      availability: _asString(payload['availability']),
    );
  }

  Map<String, String> _query({
    required RideHistoryRange range,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return <String, String>{
      'period': _rangeParam(range),
      if (range == RideHistoryRange.custom && startDate != null)
        'startDate': _formatDate(startDate),
      if (range == RideHistoryRange.custom && endDate != null)
        'endDate': _formatDate(endDate),
    };
  }

  String _rangeParam(RideHistoryRange range) {
    switch (range) {
      case RideHistoryRange.week:
        return 'week';
      case RideHistoryRange.month:
        return 'month';
      case RideHistoryRange.custom:
        return 'custom';
    }
  }

  RideHistoryItem _mapRide(dynamic raw) {
    final map = _asMap(raw);
    return RideHistoryItem(
      id: _asString(map['id']),
      startedAt: _asDateTime(map['startedAt']),
      endedAt: _asDateTime(map['endedAt']),
      distanceKm: _asDouble(map['distanceKm']),
      origin: _asString(map['originAddress']),
      destination: _asString(map['destinationAddress']),
      netAmount: _asDouble(map['netAmount']),
      grossAmount: _asDouble(map['grossAmount']),
      appFee: _asDouble(map['appFee']),
      paymentMethod: _paymentLabel(map['paymentMethodLabel']),
      statusLabel: _statusLabel(map['status']),
    );
  }

  RideSupportIssueCode _issueCodeFromApi(String raw) {
    switch (raw.toUpperCase()) {
      case 'FORGOTTEN_OBJECT':
        return RideSupportIssueCode.forgottenObject;
      case 'PAYMENT_ISSUE':
        return RideSupportIssueCode.paymentIssue;
      case 'SECURITY_INCIDENT':
        return RideSupportIssueCode.securityIncident;
      case 'PASSENGER_ABSENT':
        return RideSupportIssueCode.passengerAbsent;
      default:
        return RideSupportIssueCode.other;
    }
  }

  String _issueCodeToApi(RideSupportIssueCode code) {
    switch (code) {
      case RideSupportIssueCode.forgottenObject:
        return 'FORGOTTEN_OBJECT';
      case RideSupportIssueCode.paymentIssue:
        return 'PAYMENT_ISSUE';
      case RideSupportIssueCode.securityIncident:
        return 'SECURITY_INCIDENT';
      case RideSupportIssueCode.passengerAbsent:
        return 'PASSENGER_ABSENT';
      case RideSupportIssueCode.other:
        return 'OTHER';
    }
  }

  Map<String, dynamic> _parsePayload(
    Response response, {
    required String fallbackError,
  }) {
    final body = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is List) return <String, dynamic>{'data': data};
      return body;
    }

    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      throw RideHistoryApiException(message);
    }
    throw RideHistoryApiException(fallbackError);
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  DateTime _asDateTime(dynamic value) {
    final parsed = DateTime.tryParse(_asString(value));
    return parsed ?? DateTime.now();
  }

  DateTime? _asDateTimeOrNull(dynamic value) {
    final text = _asString(value);
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(_asString(value)) ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_asString(value).replaceAll(',', '.')) ?? 0;
  }

  double? _asDoubleOrNull(dynamic value) {
    final text = _asString(value);
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String? _nullableString(dynamic value) {
    final text = _asString(value).trim();
    return text.isEmpty ? null : text;
  }

  String _growth(dynamic value) {
    final number = _asDouble(value);
    final prefix = number > 0 ? '+' : '';
    if (number == number.roundToDouble()) {
      return '$prefix${number.toInt()}%';
    }
    return '$prefix${number.toStringAsFixed(1)}%';
  }

  String _paymentLabel(dynamic value) {
    final text = _asString(value).trim();
    final normalized = text.toUpperCase();

    if (normalized.isEmpty) return 'Método de pagamento não informado';
    if (normalized == 'CASH' || normalized.contains('DINHEIRO')) {
      return 'Dinheiro';
    }
    if (normalized.contains('CART') ||
        normalized.contains('CRÉDITO') ||
        normalized.contains('CREDITO') ||
        normalized.contains('CARD')) {
      return 'Pago via Cartão de Crédito no App';
    }
    return text;
  }

  String _statusLabel(dynamic value) {
    final text = _asString(value).toUpperCase();
    if (text == 'FINISHED' || text == 'FINALIZED') {
      return 'FINALIZADA';
    }
    return text.isEmpty ? 'FINALIZADA' : text;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
