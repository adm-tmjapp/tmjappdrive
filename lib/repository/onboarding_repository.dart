import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmjappdrive/data/onboardingStatus.dart';
import 'package:tmjappdrive/data/response_singup.dart';
import 'package:tmjappdrive/data/response_upload_document.dart';
import 'package:tmjappdrive/data/sms_code.dart';
import '../api/onbording_api.dart'; // Verifique se este caminho está correto
import '../data/api_response.dart';
import '../utils/strings.dart';

class OnboardingRepository {
  // 1. Inicialização da API (Se OnbordingApi() for pesado, pode travar. Vamos testar assim primeiro)
  final OnbordingApi api = OnbordingApi();

  SharedPreferences? prefs;

  OnboardingRepository() {
    initData();
  }

  Future<void> initData() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<OnboardingStatus?> fetchOnboardingStatus(String userId) async {
    try {
      ApiResponseModel<OnboardingStatus?> response = await api
          .fetchOnboardingStatus(userId);
      if (response.badRequest) {
        return null;
      } else {
        return response.result;
      }
    } catch (e) {
      throw Exception('Erro na API: $e');
    }
  }

  // --- MÉTODO QUE ESTAVA CAUSANDO DÚVIDA ---

  Future<Map<String, dynamic>?> registerVehicle({
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
      final response = await api.registerVehicle(
        userId: userId,
        brand: brand,
        model: model,
        year: year,
        color: color,
        plate: plate,
        vehicleType: vehicleType,
        usage: usage,
        renavam: renavam,
      );
      return response.badRequest ? null : response.result;
    } catch (e) {
      throw Exception('Erro na API: $e');
    }
  }

  // --- OUTROS MÉTODOS ---

  Future<SmsCodeResponse?>? newCodePhone(String userId) async {
    ApiResponseModel<SmsCodeResponse?> response = await api.newCodePhone(
      userId,
    );
    return response.badRequest ? null : response.result;
  }

  Future<SmsCodeResponse?>? verifyCodePhone(String userId, String code) async {
    ApiResponseModel<SmsCodeResponse?> response = await api.verifyCodePhone(
      userId,
      code,
    );
    if (response.badRequest || response.result == null) {
      return null;
    }
    await initData();
    if (response.result?.token != null) {
      prefs?.setString(Strings.prefToken, response.result!.token!);
    }
    return response.result;
  }

  Future<SmsCodeResponse?>? newCodeEmail(String userId) async {
    ApiResponseModel<SmsCodeResponse?> response = await api.newCodeEmail(
      userId,
    );
    if (response.badRequest) {
      throw Exception(
        _extractApiMessage(response) ?? 'Falha ao enviar código.',
      );
    }
    return response.result;
  }

  Future<SmsCodeResponse?>? verifyCodeEmail(String userId, String code) async {
    ApiResponseModel<SmsCodeResponse?> response = await api.verifyCodeEmail(
      userId,
      code,
    );
    if (response.badRequest) {
      throw Exception(
        _extractApiMessage(response) ?? 'Código inválido ou expirado.',
      );
    }
    if (response.result == null) {
      return null;
    }
    await initData();
    if (response.result?.token != null) {
      prefs?.setString(Strings.prefToken, response.result!.token!);
    }
    return response.result;
  }

  String? _extractApiMessage(ApiResponseModel response) {
    final body = response.response?.body;
    if (body == null || body.isEmpty) {
      return response.message;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        final error = decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          if (error is String &&
              error.trim().isNotEmpty &&
              error.trim() != message.trim()) {
            return '${message.trim()}: ${error.trim()}';
          }
          return message.trim();
        }
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }
      }
    } catch (_) {}

    return response.message;
  }

  Future<ResponseSingup?> uploadProfilePhoto(String userId, File photo) async {
    ApiResponseModel<ResponseSingup?> response = await api.uploadProfilePhoto(
      userId,
      photo.path,
    );
    _ensureUploadSucceeded(response, 'Falha ao enviar foto de perfil.');
    return response.result ?? ResponseSingup(success: true, user: null);
  }

  Future<OnboardingStatus?> uploadOnboardingDocuments({
    required File cnhFront,
    required File cnhBack,
    required File selfie,
  }) async {
    final response = await api.uploadOnboardingDocuments(
      cnhFront: cnhFront,
      cnhBack: cnhBack,
      selfie: selfie,
    );
    _ensureUploadSucceeded(response, 'Falha ao enviar documentos da CNH.');
    return response.result ?? OnboardingStatus();
  }

  Future<Map<String, dynamic>?> uploadDocument(
    String userId,
    File photo,
    String docType,
  ) async {
    ApiResponseModel<Map<String, dynamic>?> response = await api.uploadDocument(
      userId,
      photo.path,
      docType,
    );
    if (response.badRequest) {
      return null;
    } else {
      return response.result;
    }
  }

  /// Novo wrapper para o endpoint `/api/driver-documents/upload`.
  /// Campos multipart: `user`, `type`, `file` (igual ao curl fornecido).
  Future<ResponseUploadDocument?> uploadDriverDocument(
    String user,
    String type,
    File photo,
  ) async {
    ApiResponseModel<ResponseUploadDocument?> response = await api
        .uploadDriverDocument(user, type, photo.path);
    _ensureUploadSucceeded(response, 'Falha ao enviar documento.');
    return response.result ?? ResponseUploadDocument(success: true);
  }

  void _ensureUploadSucceeded(
    ApiResponseModel<dynamic> response,
    String fallback,
  ) {
    if (response.hasException) {
      throw Exception(response.exceptionMessage ?? fallback);
    }

    final statusCode = response.response?.statusCode;
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      throw Exception(_extractApiMessage(response) ?? fallback);
    }
  }

  // Wrappers específicos para o Bloc
  /// Faz upload utilizando o endpoint de driver documents e tenta retornar
  /// o `id` do documento como `String` (ou `null` se não encontrado).
  Future<String?> uploadDriverDocumentGetId(
    String user,
    String type,
    File photo,
  ) async {
    final ResponseUploadDocument? result = await uploadDriverDocument(
      user,
      type,
      photo,
    );
    if (result == null) return null;

    final id = result.document?.id;

    return id?.toString();
  }

  // Convenience wrappers
  Future<ResponseUploadDocument?> uploadCnhFront(
    String userId,
    File photo,
  ) async {
    return uploadDriverDocument(userId, 'cnh_frente', photo);
  }

  Future<ResponseUploadDocument?> uploadCnhBack(
    String userId,
    File photo,
  ) async {
    return uploadDriverDocument(userId, 'cnh_verso', photo);
  }

  Future<ResponseUploadDocument?> uploadProofSelfie(
    String userId,
    File photo,
  ) async {
    return uploadDriverDocument(userId, 'selfie_prova_vida', photo);
  }

  // --- Wrappers para Fotos do Veículo ---

  /// Envia a foto da FRENTE do veículo
  /// Tipo enviado: 'veiculo_frente'
  Future<ResponseUploadDocument?> uploadVehicleFront(
    String userId,
    File photo,
  ) async {
    return uploadDriverDocument(userId, 'veiculo_frente', photo);
  }

  /// Envia a foto da TRASEIRA do veículo
  /// Tipo enviado: 'veiculo_traseira'
  Future<ResponseUploadDocument?> uploadVehicleBack(
    String userId,
    File photo,
  ) async {
    return uploadDriverDocument(userId, 'veiculo_traseira', photo);
  }

  /// Envia a foto do INTERIOR do veículo
  /// Tipo enviado: 'veiculo_interior'
  Future<ResponseUploadDocument?> uploadVehicleInterior(
    String userId,
    File photo,
  ) async {
    return uploadDriverDocument(userId, 'veiculo_interior', photo);
  }
}
