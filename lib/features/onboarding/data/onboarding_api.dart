import 'dart:io';

import '../../../data/sms_code.dart';
import '../../../repository/onboarding_repository.dart' as legacy;
import '../../profile/data/profile_api.dart';
import '../../profile/domain/profile_models.dart';
import '../domain/onboarding_models.dart';

class DriverOnboardingApi {
  DriverOnboardingApi({
    legacy.OnboardingRepository? legacyRepository,
    ProfileApi? profileApi,
  }) : _legacyRepository = legacyRepository ?? legacy.OnboardingRepository(),
       _profileApi = profileApi ?? ProfileApi();

  final legacy.OnboardingRepository _legacyRepository;
  final ProfileApi _profileApi;

  Future<DriverOnboardingSnapshot> getSnapshot(String userId) async {
    final onboardingStatus = await _legacyRepository.fetchOnboardingStatus(
      userId,
    );
    DriverProfileDocuments? documents;
    try {
      documents = await _profileApi.getDocuments();
    } catch (_) {
      documents = null;
    }
    return DriverOnboardingSnapshot(
      onboardingStatus: onboardingStatus,
      documents: documents,
    );
  }

  Future<SmsCodeResponse?> sendPhoneCode(String userId) async {
    return await _legacyRepository.newCodePhone(userId);
  }

  Future<SmsCodeResponse?> verifyPhoneCode(String userId, String code) async {
    return await _legacyRepository.verifyCodePhone(userId, code);
  }

  Future<SmsCodeResponse?> sendEmailCode(String userId) async {
    return await _legacyRepository.newCodeEmail(userId);
  }

  Future<SmsCodeResponse?> verifyEmailCode(String userId, String code) async {
    return await _legacyRepository.verifyCodeEmail(userId, code);
  }

  Future<void> uploadProfilePhoto(String userId, File photo) async {
    final response = await _legacyRepository.uploadProfilePhoto(userId, photo);
    if (response == null) {
      throw Exception('Falha ao enviar foto de perfil.');
    }
  }

  Future<void> uploadCnhDocuments({
    required File cnhFront,
    required File cnhBack,
    required File selfie,
  }) async {
    final response = await _legacyRepository.uploadOnboardingDocuments(
      cnhFront: cnhFront,
      cnhBack: cnhBack,
      selfie: selfie,
    );
    if (response == null) {
      throw Exception('Falha ao enviar documentos da CNH.');
    }
  }

  Future<void> uploadCriminalRecord(String userId, File file) async {
    await _profileApi.uploadProfileDocument(
      userId: userId,
      type: 'antecedentes_criminais',
      filePath: file.path,
    );
  }

  Future<void> registerVehicle(
    String userId,
    DriverOnboardingVehicleInput input,
  ) async {
    final response = await _legacyRepository.registerVehicle(
      userId: userId,
      brand: input.brand,
      model: input.model,
      year: input.year,
      color: input.color,
      plate: input.plate,
      vehicleType: input.vehicleType,
      usage: input.usage,
      renavam: input.renavam,
    );
    if (response == null) {
      throw Exception('Falha ao cadastrar veiculo.');
    }
  }

  Future<void> uploadVehiclePhotos(
    String userId,
    DriverOnboardingVehiclePhotosInput input,
  ) async {
    final vehicle = await _profileApi.getVehicle();
    if (vehicle == null || vehicle.id.trim().isEmpty) {
      throw Exception(
        'Veículo não encontrado. Conclua o cadastro do veículo antes das fotos.',
      );
    }

    await Future.wait([
      _profileApi.uploadVehicleDocument(
        vehicleId: vehicle.id,
        type: 'VEHICLE_FRONT',
        filePath: input.front.path,
      ),
      _profileApi.uploadVehicleDocument(
        vehicleId: vehicle.id,
        type: 'VEHICLE_BACK',
        filePath: input.back.path,
      ),
      _profileApi.uploadVehicleDocument(
        vehicleId: vehicle.id,
        type: 'VEHICLE_INTERIOR',
        filePath: input.interior.path,
      ),
    ]);
  }
}
