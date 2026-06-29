import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:tmjappdrive/data/onboardingStatus.dart';
import 'package:tmjappdrive/data/response_singup.dart';
import 'package:tmjappdrive/data/response_upload_document.dart';
import 'package:tmjappdrive/data/sms_code.dart';
import '../data/api_response.dart';
import 'base_api.dart';

class OnbordingApi {
  BaseApi baseApi = BaseApi();

  /// Função auxiliar para decodificar o JSON de forma segura
  T? _parseJson<T>(
    dynamic decodedBody,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (decodedBody is Map<String, dynamic>) {
      // 1. Tenta ler de dentro da chave 'data'
      if (decodedBody.containsKey('data') &&
          decodedBody['data'] is Map<String, dynamic>) {
        return fromJson(decodedBody['data']);
      }
      // 2. Tenta ler da raiz
      try {
        return fromJson(decodedBody);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<ApiResponseModel<OnboardingStatus?>> fetchOnboardingStatus(
    String userId,
  ) async {
    try {
      Response response = await baseApi.get(
        Uri.parse("v2/auth/onboarding-status/$userId"),
        headers: await baseApi.getHeaders(),
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody != null &&
            decodedBody is Map<String, dynamic> &&
            decodedBody["onboardingStatus"] is Map<String, dynamic>) {
          OnboardingStatus onboardingStatus = OnboardingStatus.fromJson(
            decodedBody["onboardingStatus"],
          );
          return ApiResponseModel(response, onboardingStatus);
        } else {
          return ApiResponseModel(response, null);
        }
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  Future<ApiResponseModel<SmsCodeResponse?>> newCodePhone(String userId) async {
    try {
      Response response = await baseApi.post(
        Uri.parse("v2/auth/phone/send-code"),
        body: {},
        headers: await baseApi.getHeaders(),
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        final result =
            _parseJson(decodedBody, SmsCodeResponse.fromJson) ??
            SmsCodeResponse(
              message:
                  decodedBody is Map<String, dynamic>
                      ? decodedBody["message"]
                      : "Código enviado por SMS",
              phoneValidation: PhoneValidation(),
            );
        return ApiResponseModel(response, result);
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  Future<ApiResponseModel<SmsCodeResponse?>> verifyCodePhone(
    String userId,
    String code,
  ) async {
    try {
      var body = {"code": code};

      Response response = await baseApi.post(
        Uri.parse("v2/auth/phone/verify"),
        body: body,
        headers: await baseApi.getHeaders(),
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);

        final result = _parseJson(decodedBody, SmsCodeResponse.fromJson);

        if (result == null) {
          return ApiResponseModel(
            response,
            SmsCodeResponse(
              message:
                  decodedBody is Map<String, dynamic>
                      ? decodedBody["message"]
                      : "Telefone validado com sucesso",
              phoneValidation: PhoneValidation(),
            ),
          );
        }

        return ApiResponseModel(response, result);
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  // --- Email endpoints ---
  Future<ApiResponseModel<SmsCodeResponse?>> newCodeEmail(String userId) async {
    try {
      Response response = await baseApi.post(
        Uri.parse("v2/auth/email/send-code"),
        body: {},
        headers: await baseApi.getHeaders(),
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        final result =
            _parseJson(decodedBody, SmsCodeResponse.fromJson) ??
            SmsCodeResponse(
              message:
                  decodedBody is Map<String, dynamic>
                      ? decodedBody["message"]
                      : "Código enviado por e-mail",
              phoneValidation: PhoneValidation(),
            );
        return ApiResponseModel(response, result);
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  Future<ApiResponseModel<SmsCodeResponse?>> verifyCodeEmail(
    String userId,
    String code,
  ) async {
    try {
      var body = {"code": code};

      Response response = await baseApi.post(
        Uri.parse("v2/auth/email/verify"),
        body: body,
        headers: await baseApi.getHeaders(),
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        final result =
            _parseJson(decodedBody, SmsCodeResponse.fromJson) ??
            SmsCodeResponse(
              message:
                  decodedBody is Map<String, dynamic>
                      ? decodedBody["message"]
                      : "E-mail validado com sucesso",
              phoneValidation: PhoneValidation(),
            );
        return ApiResponseModel(response, result);
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  // --- Profile photo upload ---
  Future<ApiResponseModel<ResponseSingup?>> uploadProfilePhoto(
    String userId,
    String filePath,
  ) async {
    try {
      final uri = Uri.parse('${baseApi.baseUrl}v2/driver/profile/photo');
      final request = MultipartRequest('PUT', uri);
      request.files.add(await MultipartFile.fromPath('file', filePath));

      final headers = await baseApi.getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      final streamed = await baseApi.client.send(request);
      final response = await Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = jsonDecode(response.body);
        final result = _parseJson(decodedBody, ResponseSingup.fromJson);
        return ApiResponseModel(response, result);
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  Future<ApiResponseModel<OnboardingStatus?>> uploadOnboardingDocuments({
    required File cnhFront,
    required File cnhBack,
    required File selfie,
  }) async {
    try {
      final uri = Uri.parse('${baseApi.baseUrl}v2/driver/onboarding/documents');
      final request = MultipartRequest('POST', uri);

      request.files.add(
        await MultipartFile.fromPath('cnhFront', cnhFront.path),
      );
      request.files.add(await MultipartFile.fromPath('cnhBack', cnhBack.path));
      request.files.add(await MultipartFile.fromPath('selfie', selfie.path));

      final headers = await baseApi.getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      final streamed = await baseApi.client.send(request);
      final response = await Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map<String, dynamic> &&
            decodedBody['onboardingStatus'] is Map<String, dynamic>) {
          return ApiResponseModel(
            response,
            OnboardingStatus.fromJson(decodedBody['onboardingStatus']),
          );
        }
      }

      return ApiResponseModel(response, null);
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  // --- Generic document upload ---
  Future<ApiResponseModel<Map<String, dynamic>?>> uploadDocument(
    String userId,
    String filePath,
    String docType,
  ) async {
    try {
      final uri = Uri.parse('${baseApi.baseUrl}users/upload-document');
      final request = MultipartRequest('POST', uri);

      request.files.add(await MultipartFile.fromPath('file', filePath));
      request.fields['userId'] = userId;
      request.fields['type'] = docType;

      final headers = await baseApi.getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      final streamed = await baseApi.client.send(request);
      final response = await Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody != null && decodedBody is Map<String, dynamic>) {
          if (decodedBody.containsKey('data') && decodedBody['data'] is Map) {
            return ApiResponseModel(response, decodedBody['data']);
          }
          return ApiResponseModel(response, decodedBody);
        } else {
          return ApiResponseModel(response, null);
        }
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  // --- Driver documents upload ---
  Future<ApiResponseModel<ResponseUploadDocument?>> uploadDriverDocument(
    String user,
    String type,
    String filePath,
  ) async {
    try {
      final uri = Uri.parse('${baseApi.baseUrl}v2/driver-documents/upload');
      final request = MultipartRequest('POST', uri);

      request.files.add(await MultipartFile.fromPath('file', filePath));
      request.fields['user'] = user;
      request.fields['type'] = type;

      final headers = await baseApi.getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      final streamed = await baseApi.client.send(request);
      final response = await Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = jsonDecode(response.body);
        final result = _parseJson(decodedBody, ResponseUploadDocument.fromJson);
        return ApiResponseModel(response, result);
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  Future<ApiResponseModel<Map<String, dynamic>?>> registerVehicle({
    required String userId,
    required String brand,
    required String model,
    required String year,
    required String color,
    required String plate,
    required String vehicleType,
    required String usage,
    String? renavam,
  }) async {
    try {
      final body = {
        "userId": userId,
        "vehicleType": vehicleType.toLowerCase(),
        "manufacturer": brand,
        "modelName": model,
        "year": year,
        "color": color,
        "vehiclePlate": plate.toUpperCase(),
        "usage": usage.toUpperCase(),
        "renavam": (renavam == null || renavam.trim().isEmpty) ? null : renavam,
      };

      final response = await baseApi.post(
        Uri.parse("v2/driver/onboarding/vehicle"),
        body: body,
        headers: await baseApi.getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map<String, dynamic>) {
          return ApiResponseModel(response, decodedBody);
        }
      }
      return ApiResponseModel(response, null);
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }
}
