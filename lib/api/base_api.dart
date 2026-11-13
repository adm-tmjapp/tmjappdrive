import 'dart:convert';

import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_env.dart';
import '../observability/app_observability.dart';
import '../utils/strings.dart';

class BaseApi extends BaseClient {
  final String baseUrl = AppEnv.apiBaseUrl;
  Client client = Client();
  SharedPreferences? _prefs;
  String? _token;

  BaseApi() {
    initData();
  }

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) {
    return super.get(Uri.parse(baseUrl + url.toString()), headers: headers);
  }

  @override
  Future<Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.post(
      Uri.parse(baseUrl + url.toString()),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
      encoding: encoding,
    );
  }

  @override
  Future<Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.put(
      Uri.parse(baseUrl + url.toString()),
      headers: headers,
      body: jsonEncode(body),
      encoding: encoding,
    );
  }

  @override
  Future<Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.patch(
      Uri.parse(baseUrl + url.toString()),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
      encoding: encoding,
    );
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    await initData();
    request.headers.addAll({
      if (_token != null) 'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    });

    final startedAt = DateTime.now();
    final method = request.method;
    final uri = request.url;
    AppObservability.breadcrumb(
      'HTTP $method ${uri.path}',
      context: <String, Object?>{'http_method': method, 'http_path': uri.path},
    );

    try {
      final response = await client.send(request);
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      final requestId = response.headers['x-request-id'];
      AppObservability.breadcrumb(
        'HTTP $method ${uri.path} status=${response.statusCode} durationMs=$durationMs',
        context: <String, Object?>{
          'http_method': method,
          'http_path': uri.path,
          'http_status': response.statusCode,
          'http_duration_ms': durationMs,
          if (requestId != null) 'request_id': requestId,
        },
      );
      if (response.statusCode >= 400) {
        await AppObservability.recordHttpFailure(
          method: method,
          uri: uri,
          statusCode: response.statusCode,
          requestId: requestId,
        );
      }
      return response;
    } catch (error, stackTrace) {
      await AppObservability.recordError(
        error,
        stackTrace,
        reason: 'api_network_error',
        context: <String, Object?>{
          'http_method': method,
          'http_path': uri.path,
          'http_duration_ms':
              DateTime.now().difference(startedAt).inMilliseconds,
        },
      );
      rethrow;
    }
  }

  Future<void> initData() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs != null) {
      _token = _prefs?.getString(Strings.prefToken);
    }
  }

  Future<Map<String, String>> getHeaders() async {
    await initData();
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return Map<String, String>.from(headers);
  }
}
