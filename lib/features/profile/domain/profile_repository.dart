import 'dart:io';

import 'profile_models.dart';

abstract class ProfileRepository {
  Future<DriverProfilePayload> getProfilePayload();
  Future<DriverProfileAddress?> getAddress();
  Future<List<DriverProfileAddress>> searchAddresses(String query);
  Future<List<DriverProfileAddress>> getAddressHistory();
  Future<void> updateAddress(DriverProfileAddress address);
  Future<void> updateProfile(DriverProfileUpdateInput input);
  Future<void> createVehicle(DriverProfileCreateVehicleInput input);
  Future<void> activateVehicle(String vehicleId);
  Future<List<DriverVehicleDocumentItem>> getVehicleDocuments(String vehicleId);
  Future<void> uploadVehicleDocument({
    required String vehicleId,
    required String type,
    required String filePath,
  });
  Future<void> uploadProfileDocument({
    required String userId,
    required String type,
    required String filePath,
  });
  Future<void> uploadCnhDocuments({
    required File cnhFront,
    required File cnhBack,
    required File selfie,
  });
  Future<void> logout();
}
