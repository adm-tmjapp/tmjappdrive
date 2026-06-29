import 'dart:convert';

import 'package:http/http.dart';

import '../../../api/base_api.dart';
import '../domain/wallet_models.dart';

class WalletApiException implements Exception {
  final String message;

  const WalletApiException(this.message);

  @override
  String toString() => message;
}

class WalletApi {
  WalletApi({BaseApi? baseApi}) : _baseApi = baseApi ?? BaseApi();

  final BaseApi _baseApi;

  Future<Map<String, dynamic>> getSummary(WalletPeriod period) async {
    final response = await _baseApi.get(
      Uri(
        path: 'v2/driver/wallet/summary',
        queryParameters: <String, String>{'period': _periodToApi(period)},
      ),
      headers: await _baseApi.getHeaders(),
    );
    return _parsePayload(
      response,
      fallbackError: 'Falha ao carregar resumo da carteira.',
    );
  }

  Future<Map<String, dynamic>> getActivities({int limit = 20}) async {
    final response = await _baseApi.get(
      Uri(
        path: 'v2/driver/wallet/activities',
        queryParameters: <String, String>{'limit': '$limit', 'offset': '0'},
      ),
      headers: await _baseApi.getHeaders(),
    );
    return _parsePayload(
      response,
      fallbackError: 'Falha ao carregar atividades da carteira.',
    );
  }

  Future<Map<String, dynamic>> createPixTransfer({
    required String cpf,
    required double amount,
    required String idempotencyKey,
  }) async {
    final headers = await _baseApi.getHeaders();
    headers['Idempotency-Key'] = idempotencyKey;

    final response = await _baseApi.client.post(
      Uri.parse('${_baseApi.baseUrl}v2/driver/wallet/transfers/pix'),
      headers: headers,
      body: jsonEncode(<String, dynamic>{'cpf': cpf, 'amount': amount}),
    );

    return _parsePayload(
      response,
      fallbackError: 'Nao foi possivel concluir a transferencia PIX.',
    );
  }

  Future<Map<String, dynamic>> getTransfer(String transferId) async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/wallet/transfers/$transferId'),
      headers: await _baseApi.getHeaders(),
    );
    return _parsePayload(
      response,
      fallbackError: 'Falha ao carregar detalhes da transferencia.',
    );
  }

  String _periodToApi(WalletPeriod period) {
    switch (period) {
      case WalletPeriod.today:
        return 'today';
      case WalletPeriod.week:
        return 'week';
      case WalletPeriod.month:
        return 'month';
    }
  }

  Map<String, dynamic> _parsePayload(
    Response response, {
    required String fallbackError,
  }) {
    final body = _decodeBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final payload = body['data'];
      if (payload is Map<String, dynamic>) return payload;
      return body;
    }

    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      throw WalletApiException(message);
    }
    throw WalletApiException(fallbackError);
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }
}
