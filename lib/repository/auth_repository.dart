import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmjappdrive/data/response_singup.dart';
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

  Future<ResponseSingup?>? signUp(
    String phone,
    String cpf,
    String name,
    String lastName,
    String email,
    String password,
  ) async {
    await _ensurePrefs();
    ApiResponseModel<ResponseSingup?> apiResponse = await auth.signUp(
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
      return apiResponse.result;
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
}
