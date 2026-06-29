import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/strings.dart';
import '../domain/profile_models.dart';
import '../domain/profile_repository.dart';
import 'profile_api.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required ProfileApi api}) : _api = api;

  final ProfileApi _api;

  @override
  Future<DriverProfilePayload> getProfilePayload() async {
    final results = await Future.wait<dynamic>([
      _api.getProfile(),
      _api.getVehicle(),
      _api.getVehicles(),
      _api.getDocuments(),
      _api.getSecurity(),
      _api.getAddress(),
    ]);

    final payload = DriverProfilePayload(
      profile: results[0] as DriverProfile,
      vehicle: results[1] as DriverProfileVehicle?,
      vehicles: results[2] as List<DriverProfileVehicle>,
      documents: results[3] as DriverProfileDocuments,
      security: results[4] as DriverProfileSecurity,
      address: results[5] as DriverProfileAddress?,
    );

    await _persistProfileSession(payload.profile);
    return payload;
  }

  @override
  Future<void> updateProfile(DriverProfileUpdateInput input) async {
    await _api.updateProfile(input);
  }

  @override
  Future<DriverProfileAddress?> getAddress() async {
    return _api.getAddress();
  }

  @override
  Future<List<DriverProfileAddress>> searchAddresses(String query) async {
    return _api.searchAddresses(query);
  }

  @override
  Future<List<DriverProfileAddress>> getAddressHistory() async {
    return _api.getAddressHistory();
  }

  @override
  Future<void> updateAddress(DriverProfileAddress address) async {
    await _api.updateAddress(address);
  }

  @override
  Future<void> createVehicle(DriverProfileCreateVehicleInput input) async {
    final vehicleId = await _api.createVehicle(input);
    if (input.photoPath != null && input.photoPath!.trim().isNotEmpty) {
      await _api.uploadVehiclePhoto(vehicleId, input.photoPath!.trim());
    }
  }

  @override
  Future<void> activateVehicle(String vehicleId) async {
    await _api.activateVehicle(vehicleId);
  }

  @override
  Future<List<DriverVehicleDocumentItem>> getVehicleDocuments(
    String vehicleId,
  ) async {
    return _api.getVehicleDocuments(vehicleId);
  }

  @override
  Future<void> uploadVehicleDocument({
    required String vehicleId,
    required String type,
    required String filePath,
  }) async {
    await _api.uploadVehicleDocument(
      vehicleId: vehicleId,
      type: type,
      filePath: filePath,
    );
  }

  @override
  Future<void> uploadProfileDocument({
    required String userId,
    required String type,
    required String filePath,
  }) async {
    await _api.uploadProfileDocument(
      userId: userId,
      type: type,
      filePath: filePath,
    );
  }

  @override
  Future<void> uploadCnhDocuments({
    required File cnhFront,
    required File cnhBack,
    required File selfie,
  }) async {
    await _api.uploadCnhDocuments(
      cnhFront: cnhFront,
      cnhBack: cnhBack,
      selfie: selfie,
    );
  }

  @override
  Future<void> logout() async {
    await _api.logout();
  }

  Future<void> _persistProfileSession(DriverProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Strings.prefDriverName, profile.name);
    await prefs.setString(Strings.prefDriverId, profile.id);
    if (profile.cpfMasked != null && profile.cpfMasked!.trim().isNotEmpty) {
      await prefs.setString(Strings.prefDriverCpfMasked, profile.cpfMasked!);
    }
    if (profile.profilePhotoUrl != null &&
        profile.profilePhotoUrl!.trim().isNotEmpty) {
      await prefs.setString(
        Strings.prefDriverProfileImage,
        profile.profilePhotoUrl!,
      );
    }
  }
}
