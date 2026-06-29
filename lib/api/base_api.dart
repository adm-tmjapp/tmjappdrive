import 'dart:convert';

import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_env.dart';
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
    // TODO: implement post
    return super.post(
      Uri.parse(baseUrl + url.toString()),
      headers: headers,
      body: jsonEncode(body),
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
    // TODO: implement put
    return super.put(
      Uri.parse(baseUrl + url.toString()),
      headers: headers,
      body: jsonEncode(body),
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
    return client.send(request);
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
