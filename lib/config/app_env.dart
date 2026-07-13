import 'dart:io';

import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, prod }

class AppEnv {
  AppEnv._();

  static const String _envValue = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static AppEnvironment get environment {
    switch (_envValue.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      default:
        return AppEnvironment.dev;
    }
  }

  static bool get isProd => environment == AppEnvironment.prod;

  static String get apiBaseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      return _normalizeBaseUrl(override);
    }

    if (isProd) {
      return _normalizeBaseUrl(
        'https://tmjapp-api-53m7i55c3q-rj.a.run.app/api/',
      );
    }

    if (kIsWeb) {
      return _normalizeBaseUrl('http://localhost:3000/api/');
    }

    if (Platform.isAndroid) {
      return _normalizeBaseUrl('http://10.0.2.2:3000/api/');
    }

    return _normalizeBaseUrl('http://localhost:3000/api/');
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value : '$value/';
  }
}
