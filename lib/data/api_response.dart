import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:http_status_code/http_status_code.dart';

import 'api_excepton.dart';

class ApiResponseModel<T> {
  Response? _response;
  ApiException? _exception;
  T result;

  Response? get response => _response;

  String? get exceptionMessage => _exception?.message;
  String? get exceptionStackTrace => _exception?.stackTrace;

  String? get errorCode => _response!.statusCode.toString();
  String? get message => _response!.reasonPhrase;

  bool get ok => _response != null && _response!.statusCode == 200;
  bool get badRequest =>
      _response != null &&
      _response!.statusCode >= 400 &&
      _response!.statusCode < 500;
  bool get serverError => _response != null && _response!.statusCode >= 500;
  bool get hasException => _exception != null;

  ApiResponseModel(Response response, this.result) : _response = response {
    int statusCode = response.statusCode;
    String message = getStatusMessage(statusCode);

    if (kDebugMode) {
      print("$statusCode $message ${response.request!.url}");
    }
  }

  ApiResponseModel.fromException(
    Object message,
    StackTrace stackTrace,
    this.result,
  ) : _exception = ApiException(message.toString(), stackTrace.toString()) {
    if (kDebugMode) {
      print(exceptionMessage);
    }
    if (kDebugMode) {
      print(exceptionStackTrace);
    }
  }
}
