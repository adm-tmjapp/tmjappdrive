import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth_api.dart';
import '../data/api_response.dart';
import '../data/response_login.dart';
import '../utils/strings.dart';

class AuthRepository {
  final Authapi auth = Authapi();
  SharedPreferences? prefs;

  AuthRepository() {
    initData();
  }

  Future<void> _ensurePrefs() async {
    if (prefs == null) {
      await initData();
    }
  }

  Future<void> initData() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<ResponseLogin?>? login(String email, String password) async {
    await _ensurePrefs();
    ApiResponseModel<ResponseLogin?> response = await auth.login(
      password,
      email,
    );
    if (response.badRequest) {
      throw Exception(_extractApiMessage(response) ?? 'Credenciais inválidas.');
    }
    if (response.result == null) return null;
    final login = response.result!;
    if (login.token != null) {
      prefs?.setString(Strings.prefToken, login.token!);
    }
    if (login.user?.name != null && login.user!.name!.trim().isNotEmpty) {
      prefs?.setString(Strings.prefDriverName, login.user!.name!.trim());
    }
    if (login.user?.id != null && login.user!.id!.trim().isNotEmpty) {
      prefs?.setString(Strings.prefDriverId, login.user!.id!.trim());
    }
    if (login.user?.cpfMasked != null &&
        login.user!.cpfMasked!.trim().isNotEmpty) {
      prefs?.setString(
        Strings.prefDriverCpfMasked,
        login.user!.cpfMasked!.trim(),
      );
    }
    if (login.user?.walletAvailableMasked != null &&
        login.user!.walletAvailableMasked!.trim().isNotEmpty) {
      prefs?.setString(
        Strings.prefDriverWalletAvailableMasked,
        login.user!.walletAvailableMasked!.trim(),
      );
    }
    return login;
  }

  String? _extractApiMessage(ApiResponseModel response) {
    final body = response.response?.body;
    if (body == null || body.isEmpty) return response.response?.reasonPhrase;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }
      }
    } catch (_) {}

    return response.response?.reasonPhrase;
  }

  Future<ResponseLogin?>? loginWithPhone(String phone) async {
    await _ensurePrefs();
    ApiResponseModel<ResponseLogin?> response = await auth.loginWithPhone(
      phone,
    );
    if (response.badRequest || response.result == null) return null;
    final login = response.result!;
    if (login.token != null) {
      prefs?.setString(Strings.prefToken, login.token!);
    }
    if (login.user?.name != null && login.user!.name!.trim().isNotEmpty) {
      prefs?.setString(Strings.prefDriverName, login.user!.name!.trim());
    }
    if (login.user?.id != null && login.user!.id!.trim().isNotEmpty) {
      prefs?.setString(Strings.prefDriverId, login.user!.id!.trim());
    }
    if (login.user?.cpfMasked != null &&
        login.user!.cpfMasked!.trim().isNotEmpty) {
      prefs?.setString(
        Strings.prefDriverCpfMasked,
        login.user!.cpfMasked!.trim(),
      );
    }
    if (login.user?.walletAvailableMasked != null &&
        login.user!.walletAvailableMasked!.trim().isNotEmpty) {
      prefs?.setString(
        Strings.prefDriverWalletAvailableMasked,
        login.user!.walletAvailableMasked!.trim(),
      );
    }
    return login;
  }

  Future<ResponseLogin?>? signUp(
    String phone,
    String cpf,
    String name,
    String lastName,
    String email,
    String password,
  ) async {
    await _ensurePrefs();
    ApiResponseModel<ResponseLogin?> apiResponse = await auth.signUp(
      phone,
      cpf,
      name,
      lastName,
      email,
      password,
    );

    if (apiResponse.hasException) {
      throw Exception(
        apiResponse.exceptionMessage ?? 'Não foi possível conectar à API.',
      );
    }

    if (apiResponse.response != null && apiResponse.response!.body.isNotEmpty) {
      try {
        final body = jsonDecode(apiResponse.response!.body);

        if (body is Map &&
            body.containsKey('success') &&
            body['success'] == false) {
          final msg = body['message'] ?? 'Erro ao cadastrar.';
          throw Exception(msg);
        }

        if (body is Map && body.containsKey('message')) {
          if (apiResponse.result == null) {
            throw Exception(body['message']);
          }
        }
      } catch (e) {
        if (e.toString().contains("Exception:")) rethrow;
      }
    }

    if (apiResponse.badRequest || apiResponse.serverError) {
      throw Exception('Não foi possível cadastrar o usuário.');
    } else {
      final signup = apiResponse.result;
      if (signup?.token != null) {
        prefs?.setString(Strings.prefToken, signup!.token!);
      }
      if (signup?.user?.name != null && signup!.user!.name!.trim().isNotEmpty) {
        prefs?.setString(Strings.prefDriverName, signup.user!.name!.trim());
      }
      if (signup?.user?.id != null && signup!.user!.id!.trim().isNotEmpty) {
        prefs?.setString(Strings.prefDriverId, signup.user!.id!.trim());
      }
      return signup;
    }
  }

  Future<void> forgotPassword(String email) async {
    ApiResponseModel<bool> apiResponse = await auth.sendForgotPasswordEmail(
      email,
    );

    if (apiResponse.badRequest) {
      String errorMessage = "Falha ao enviar e-mail.";

      if (apiResponse.response != null &&
          apiResponse.response!.body.isNotEmpty) {
        try {
          final body = jsonDecode(apiResponse.response!.body);

          if (body is Map) {
            if (body.containsKey('message')) {
              errorMessage = body['message'];
            } else if (body.containsKey('error')) {
              errorMessage = body['error'];
            }
          }
        } catch (_) {}
      }

      throw Exception(errorMessage);
    }

    if (apiResponse.response != null) {
      try {
        final body = jsonDecode(apiResponse.response!.body);
        if (body is Map &&
            body.containsKey('success') &&
            body['success'] == false) {
          throw Exception(body['message'] ?? "Erro desconhecido.");
        }
      } catch (_) {}
    }
  }

  Future<void> sendSignupEmailVerificationCode() async {
    await _ensurePrefs();
    final response = await auth.sendSignupEmailVerificationCode();
    if (response.hasException || response.badRequest || response.serverError) {
      throw Exception(
        _extractApiMessage(response) ??
            'Não foi possível enviar o código de confirmação.',
      );
    }
  }

  Future<ResponseLogin> verifySignupEmailCode(String code) async {
    await _ensurePrefs();
    final response = await auth.verifySignupEmailCode(code);
    if (response.hasException || response.badRequest || response.serverError) {
      throw Exception(
        _extractApiMessage(response) ?? 'Código inválido ou expirado.',
      );
    }

    final verified = response.result;
    if (verified == null) {
      throw Exception('A API não retornou a sessão validada.');
    }

    if (verified.token?.trim().isNotEmpty == true) {
      await prefs?.setString(Strings.prefToken, verified.token!.trim());
    }
    if (verified.user?.id?.trim().isNotEmpty == true) {
      await prefs?.setString(Strings.prefDriverId, verified.user!.id!.trim());
    }
    if (verified.user?.name?.trim().isNotEmpty == true) {
      await prefs?.setString(
        Strings.prefDriverName,
        verified.user!.name!.trim(),
      );
    }

    return verified;
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final apiResponse = await auth.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    if (apiResponse.hasException) {
      throw Exception(
        apiResponse.exceptionMessage ??
            'Não foi possível conectar ao serviço de recuperação.',
      );
    }

    if (!apiResponse.ok || apiResponse.result != true) {
      var errorMessage = 'Código inválido ou expirado.';
      final responseBody = apiResponse.response?.body;
      if (responseBody != null && responseBody.isNotEmpty) {
        try {
          final body = jsonDecode(responseBody);
          if (body is Map) {
            final message = body['message'] ?? body['error'];
            if (message is String && message.trim().isNotEmpty) {
              errorMessage = message.trim();
            }
          }
        } catch (_) {}
      }
      throw Exception(errorMessage);
    }
  }
}
