import 'dart:io';

import '../../../data/sms_code.dart';
import 'onboarding_models.dart';

abstract class DriverOnboardingRepository {
  Future<DriverOnboardingSnapshot> getSnapshot(String userId);
  Future<SmsCodeResponse?> sendPhoneCode(String userId);
  Future<SmsCodeResponse?> verifyPhoneCode(String userId, String code);
  Future<SmsCodeResponse?> sendEmailCode(String userId);
  Future<SmsCodeResponse?> verifyEmailCode(String userId, String code);
  Future<void> uploadProfilePhoto(String userId, File photo);
  Future<void> uploadCnhDocuments({
    required File cnhFront,
    required File cnhBack,
    required File selfie,
  });
  Future<void> uploadCriminalRecord(String userId, File file);
  Future<void> registerVehicle(
    String userId,
    DriverOnboardingVehicleInput input,
  );
  Future<void> uploadVehiclePhotos(
    String userId,
    DriverOnboardingVehiclePhotosInput input,
  );
}
