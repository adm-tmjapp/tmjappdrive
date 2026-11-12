import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Centraliza Crashlytics, Analytics e contexto operacional sem enviar dados
/// sensíveis. Falhas de observabilidade nunca interrompem o fluxo do app.
class AppObservability {
  AppObservability._();

  static FirebaseCrashlytics? _crashlytics;
  static FirebaseAnalytics? _analytics;
  static bool _ready = false;
  static String _appVersion = 'unknown';
  static final NavigatorObserver navigatorObserver =
      _ObservabilityNavigatorObserver();

  static Future<void> initialize({required bool firebaseReady}) async {
    try {
      final package = await PackageInfo.fromPlatform();
      _appVersion = '${package.version}+${package.buildNumber}';
    } catch (_) {}

    if (!firebaseReady) return;

    try {
      _crashlytics = FirebaseCrashlytics.instance;
      _analytics = FirebaseAnalytics.instance;
      await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);
      await _crashlytics!.setCustomKey('app_version', _appVersion);
      await _crashlytics!.setCustomKey(
        'environment',
        kReleaseMode ? 'production' : 'debug',
      );
      _ready = true;
    } catch (_) {}
  }

  static void setUserContext({String? userId, String? role}) {
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;

    try {
      if (userId != null && userId.trim().isNotEmpty) {
        final normalized = userId.trim();
        final anonymousId =
            normalized.length > 8
                ? 'user-${normalized.substring(normalized.length - 8)}'
                : 'user-$normalized';
        unawaited(crashlytics.setUserIdentifier(anonymousId));
      }
      if (role != null && role.trim().isNotEmpty) {
        unawaited(crashlytics.setCustomKey('user_role', role.trim()));
      }
    } catch (_) {}
  }

  static void setContext(Map<String, Object?> values) {
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;

    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) continue;
      unawaited(crashlytics.setCustomKey(entry.key, _safeValue(value)));
    }
  }

  static void breadcrumb(String message, {Map<String, Object?>? context}) {
    final safeMessage = _sanitize(message);
    debugPrint('[Observability] $safeMessage');
    final crashlytics = _crashlytics;
    if (crashlytics != null) {
      unawaited(crashlytics.log(safeMessage));
    }
    if (context != null) setContext(context);
  }

  static Future<void> event(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    breadcrumb('event=$name', context: parameters);
    final analytics = _analytics;
    if (!_ready || analytics == null) return;

    try {
      final safeParameters = <String, Object>{};
      for (final entry in parameters.entries) {
        final value = _safeAnalyticsValue(entry.value);
        if (value != null) safeParameters[entry.key] = value;
      }
      await analytics.logEvent(name: name, parameters: safeParameters);
    } catch (_) {}
  }

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    breadcrumb(
      'error=${error.runtimeType}${reason == null ? '' : ' reason=$reason'}',
      context: context,
    );
    final crashlytics = _crashlytics;
    if (!_ready || crashlytics == null) return;

    try {
      await crashlytics.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: reason,
        information:
            context.entries
                .where((entry) => entry.value != null)
                .map(
                  (entry) => DiagnosticsProperty<Object>(
                    entry.key,
                    _safeValue(entry.value!),
                  ),
                )
                .toList(),
      );
    } catch (_) {}
  }

  static Future<void> recordHttpFailure({
    required String method,
    required Uri uri,
    required int statusCode,
    String? code,
    String? requestId,
  }) async {
    final path = '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
    await event(
      'api_request_failed',
      parameters: <String, Object?>{
        'method': method,
        'path': path,
        'status_code': statusCode,
        if (code != null && code.isNotEmpty) 'error_code': code,
        if (requestId != null && requestId.isNotEmpty) 'request_id': requestId,
      },
    );
    if (statusCode >= 500) {
      await recordError(
        StateError('HTTP $statusCode $method $path'),
        StackTrace.current,
        reason: 'api_server_error',
        context: <String, Object?>{
          'http_method': method,
          'http_path': path,
          'http_status': statusCode,
          if (code != null) 'api_error_code': code,
          if (requestId != null && requestId.isNotEmpty)
            'request_id': requestId,
        },
      );
    }
  }

  static String _sanitize(String value) {
    return value
        .replaceAll(
          RegExp(r'Bearer\s+[^\s]+', caseSensitive: false),
          'Bearer [REDACTED]',
        )
        .replaceAll(
          RegExp(
            r'([?&](?:token|password|cpf|email)=[^&]+)',
            caseSensitive: false,
          ),
          r'\1=[REDACTED]',
        );
  }

  static String _safeValue(Object value) {
    final text = value.toString();
    return text.length > 120 ? '${text.substring(0, 120)}…' : text;
  }

  static Object? _safeAnalyticsValue(Object? value) {
    if (value is String || value is int || value is double) return value;
    if (value is bool) return value ? 1 : 0;
    return value == null ? null : _safeValue(value);
  }
}

class _ObservabilityNavigatorObserver extends NavigatorObserver {
  void _track(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.trim().isEmpty) return;
    AppObservability.breadcrumb('screen=$name');
    AppObservability.setContext(<String, Object?>{'current_screen': name});
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(previousRoute);
    super.didPop(route, previousRoute);
  }
}
