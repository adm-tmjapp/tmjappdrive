import 'dart:io';

import '../../../data/sms_code.dart';
import '../domain/onboarding_models.dart';
import '../domain/onboarding_repository.dart';
import 'onboarding_api.dart';

class DriverOnboardingRepositoryImpl implements DriverOnboardingRepository {
  DriverOnboardingRepositoryImpl({required DriverOnboardingApi api})
    : _api = api;

  final DriverOnboardingApi _api;

  @override
  Future<DriverOnboardingSnapshot> getSnapshot(String userId) {
    return _api.getSnapshot(userId);
  }

  @override
  Future<SmsCodeResponse?> sendPhoneCode(String userId) {
    return _api.sendPhoneCode(userId);
  }

  @override
  Future<SmsCodeResponse?> verifyPhoneCode(String userId, String code) {
    return _api.verifyPhoneCode(userId, code);
  }

  @override
  Future<SmsCodeResponse?> sendEmailCode(String userId) {
    return _api.sendEmailCode(userId);
  }

  @override
  Future<SmsCodeResponse?> verifyEmailCode(String userId, String code) {
    return _api.verifyEmailCode(userId, code);
  }

  @override
  Future<void> uploadProfilePhoto(String userId, File photo) {
    return _api.uploadProfilePhoto(userId, photo);
  }

  @override
  Future<void> uploadCnhDocuments({
    required File cnhFront,
    required File cnhBack,
    required File selfie,
  }) {
    return _api.uploadCnhDocuments(
      cnhFront: cnhFront,
      cnhBack: cnhBack,
      selfie: selfie,
    );
  }

  @override
  Future<void> uploadCriminalRecord(String userId, File file) {
    return _api.uploadCriminalRecord(userId, file);
  }

  @override
  Future<void> registerVehicle(
    String userId,
    DriverOnboardingVehicleInput input,
  ) {
    return _api.registerVehicle(userId, input);
  }

  @override
  Future<void> uploadVehiclePhotos(
    String userId,
    DriverOnboardingVehiclePhotosInput input,
  ) {
    return _api.uploadVehiclePhotos(userId, input);
  }
}
