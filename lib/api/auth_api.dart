import 'dart:convert';

import 'package:http/http.dart';
import 'package:tmjappdrive/data/response_singup.dart';

import '../data/api_response.dart';
import '../data/response_login.dart';
import 'base_api.dart';

class Authapi {
  BaseApi baseApi = BaseApi();

  Future<ApiResponseModel<ResponseLogin?>> login(
    String password,
    String email,
  ) async {
    try {
      var bodyObj = {"identifier": email, "password": password};
      Response response = await baseApi.post(
        Uri.parse("v2/auth/login"),
        headers:
            new Map<String, String>()
              ..putIfAbsent('Content-Type', () => 'application/json')
              ..putIfAbsent('Accept', () => 'application/json'),
        body: bodyObj,
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        final loginPayload =
            decodedBody is Map<String, dynamic>
                ? (decodedBody["data"] is Map<String, dynamic>
                    ? decodedBody["data"]
                    : decodedBody)
                : null;

        if (loginPayload != null && loginPayload.containsKey("token")) {
          ResponseLogin responseLogin = ResponseLogin.fromJson(loginPayload);
          return ApiResponseModel(response, responseLogin);
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

  Future<ApiResponseModel<ResponseLogin?>> loginWithPhone(String phone) async {
    try {
      var body = {"phone": phone};
      Response response = await baseApi.post(
        Uri.parse("users/auth-phone"),
        headers:
            new Map<String, String>()
              ..putIfAbsent('Content-Type', () => 'application/json')
              ..putIfAbsent('Accept', () => 'application/json'),
        body: body,
      );

      if (response.statusCode == 200) {
        ResponseLogin responseLogin = ResponseLogin.fromJson(
          jsonDecode(response.body)["data"],
        );
        return ApiResponseModel(response, responseLogin);
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  Future<ApiResponseModel<ResponseSingup?>> signUp(
    String phone,
    String cpf,
    String name,
    String lastName,
    String email,
    String password,
  ) async {
    try {
      var body = {
        "name": "$name $lastName",
        "email": email,
        "password": password,
        "phone": phone,
        "cpf": cpf,
        "role": "driver",
      };

      Response response = await baseApi.post(
        Uri.parse("v2/auth/register"),
        headers:
            new Map<String, String>()
              ..putIfAbsent('Content-Type', () => 'application/json')
              ..putIfAbsent('Accept', () => 'application/json'),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = jsonDecode(response.body);

        if (decodedBody is Map<String, dynamic>) {
          if (decodedBody.containsKey('data')) {
            ResponseSingup responseSingup = ResponseSingup.fromJson(
              decodedBody['data'],
            );
            return ApiResponseModel(response, responseSingup);
          } else {
            ResponseSingup responseSingup = ResponseSingup.fromJson(
              decodedBody,
            );
            return ApiResponseModel(response, responseSingup);
          }
        }
        return ApiResponseModel(response, null);
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  Future<ApiResponseModel<Map<String, String>?>> verifyEmail(
    int id,
    String email,
  ) async {
    try {
      var body = {"id": "$id", "email": email};

      Response response = await baseApi.post(
        Uri.parse("users/verify-email"),
        body: body,
      );

      if (response.statusCode == 200) {
        Map<String, String>? responseVerifyEmail =
            jsonDecode(response.body)["data"];
        return ApiResponseModel(response, responseVerifyEmail);
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }

  Future<ApiResponseModel<Map<String, String>?>> updateUsers(
    String phone,
    String name,
    String lastName,
    String email,
    String password,
  ) async {
    try {
      var body = {
        "name": "$name $lastName",
        "email": email,
        "password": password,
        "phone": phone,
        "role": "passenger",
      };

      Response response = await baseApi.patch(Uri.parse("users/1"), body: body);

      if (response.statusCode == 200) {
        Map<String, String>? responseUpdate = jsonDecode(response.body)["data"];
        return ApiResponseModel(response, responseUpdate);
      } else {
        return ApiResponseModel(response, null);
      }
    } catch (error, stackTrace) {
      return ApiResponseModel.fromException(error, stackTrace, null);
    }
  }
  // ... (Mantenha os outros métodos: login, signUp, etc)

  Future<ApiResponseModel<bool>> sendForgotPasswordEmail(String email) async {
    try {
      // TENTATIVA DE CORREÇÃO:
      // No seu Login você usa "identifier", talvez aqui seja o mesmo?
      // Vamos tentar manter 'email' primeiro, mas com DEBUG ativado.

      var bodyObj = {"email": email};
      // Se não funcionar com "email", troque a linha acima por:
      // var bodyObj = {"identifier": email};

      print("DEBUG REQUISIÇÃO: Enviando para auth/forgot-password");
      print("DEBUG BODY: $bodyObj");

      Response response = await baseApi.post(
        Uri.parse("auth/forgot-password"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: bodyObj,
      );

      print("DEBUG STATUS CODE: ${response.statusCode}");
      print(
        "DEBUG RESPOSTA DO SERVIDOR: ${response.body}",
      ); // <--- ISSO É O MAIS IMPORTANTE

      if (response.statusCode == 200) {
        return ApiResponseModel(response, true);
      } else {
        // Retorna falso se não for 200
        return ApiResponseModel(response, false);
      }
    } catch (error, stackTrace) {
      print("DEBUG ERRO API: $error");
      return ApiResponseModel.fromException(error, stackTrace, false);
    }
  }
}
