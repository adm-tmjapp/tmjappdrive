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

  Future<String> registerVehicle(
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
    final data = response['data'];
    final dataPayload = data is Map<String, dynamic> ? data : response;
    final vehicle = dataPayload['vehicle'];
    final payload = vehicle is Map<String, dynamic> ? vehicle : dataPayload;
    final vehicleId =
        payload['id']?.toString() ?? payload['vehicleId']?.toString();
    if (vehicleId != null && vehicleId.trim().isNotEmpty) {
      return vehicleId;
    }

    final normalizedPlate =
        input.plate.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final createdVehicle =
        (await _profileApi.getVehicles()).where((candidate) {
          final candidatePlate =
              candidate.vehiclePlate
                  .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
                  .toUpperCase();
          return candidatePlate == normalizedPlate;
        }).firstOrNull;
    if (createdVehicle == null || createdVehicle.id.trim().isEmpty) {
      throw Exception('A API não retornou o identificador do veículo.');
    }
    return createdVehicle.id;
  }

  Future<void> uploadVehiclePhotos(
    String userId,
    String? vehicleId,
    DriverOnboardingVehiclePhotosInput input,
  ) async {
    var targetVehicleId = vehicleId?.trim();
    if (targetVehicleId == null || targetVehicleId.isEmpty) {
      final vehicles = await _profileApi.getVehicles();
      final pendingVehicles =
          vehicles
              .where(
                (vehicle) =>
                    !{
                      'ACTIVE',
                      'ATIVO',
                    }.contains(vehicle.status?.trim().toUpperCase()),
              )
              .toList();
      if (pendingVehicles.isNotEmpty) {
        targetVehicleId = pendingVehicles.last.id.trim();
      } else {
        targetVehicleId = (await _profileApi.getVehicle())?.id.trim();
      }
    }
    if (targetVehicleId == null || targetVehicleId.isEmpty) {
      throw Exception(
        'O cadastro não retornou o identificador do veículo para anexar as fotos.',
      );
    }

    await Future.wait([
      _profileApi.uploadVehicleDocument(
        vehicleId: targetVehicleId,
        type: 'VEHICLE_FRONT',
        filePath: input.front.path,
      ),
      _profileApi.uploadVehicleDocument(
        vehicleId: targetVehicleId,
        type: 'VEHICLE_BACK',
        filePath: input.back.path,
      ),
      _profileApi.uploadVehicleDocument(
        vehicleId: targetVehicleId,
        type: 'VEHICLE_INTERIOR',
        filePath: input.interior.path,
      ),
    ]);
  }
}
