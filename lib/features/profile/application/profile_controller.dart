import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/strings.dart';
import '../domain/profile_models.dart';
import '../domain/profile_repository.dart';

class ProfileState {
  const ProfileState({
    required this.isLoading,
    required this.isUpdating,
    required this.isLoggingOut,
    this.payload,
    this.error,
    this.successMessage,
  });

  final bool isLoading;
  final bool isUpdating;
  final bool isLoggingOut;
  final DriverProfilePayload? payload;
  final String? error;
  final String? successMessage;

  factory ProfileState.initial() {
    return const ProfileState(
      isLoading: true,
      isUpdating: false,
      isLoggingOut: false,
    );
  }

  ProfileState copyWith({
    bool? isLoading,
    bool? isUpdating,
    bool? isLoggingOut,
    DriverProfilePayload? payload,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      payload: payload ?? this.payload,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._repository) : super(ProfileState.initial()) {
    load();
  }

  final ProfileRepository _repository;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final payload = await _repository.getProfilePayload();
      state = state.copyWith(
        isLoading: false,
        payload: payload,
        clearError: true,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _message(e, 'Falha ao carregar perfil.'),
      );
    }
  }

  Future<bool> updateProfile(DriverProfileUpdateInput input) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repository.updateProfile(input);
      await load();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Perfil atualizado com sucesso.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: _message(e, 'Falha ao atualizar perfil.'),
      );
      return false;
    }
  }

  Future<List<DriverProfileAddress>> searchAddresses(String query) async {
    return _repository.searchAddresses(query);
  }

  Future<List<DriverProfileAddress>> getAddressHistory() async {
    return _repository.getAddressHistory();
  }

  Future<bool> updateAddress(DriverProfileAddress address) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repository.updateAddress(address);
      await load();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Endereco atualizado com sucesso.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: _message(e, 'Falha ao atualizar endereco.'),
      );
      return false;
    }
  }

  Future<bool> createVehicle(DriverProfileCreateVehicleInput input) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repository.createVehicle(input);
      await load();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Veiculo cadastrado com sucesso.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: _message(e, 'Falha ao cadastrar veiculo.'),
      );
      return false;
    }
  }

  Future<bool> activateVehicle(String vehicleId) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repository.activateVehicle(vehicleId);
      await load();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Veiculo ativado com sucesso.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: _message(e, 'Falha ao ativar veiculo.'),
      );
      return false;
    }
  }

  Future<List<DriverVehicleDocumentItem>> getVehicleDocuments(
    String vehicleId,
  ) async {
    return _repository.getVehicleDocuments(vehicleId);
  }

  Future<bool> uploadVehicleDocument({
    required String vehicleId,
    required String type,
    required String filePath,
  }) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repository.uploadVehicleDocument(
        vehicleId: vehicleId,
        type: type,
        filePath: filePath,
      );
      await load();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Documento enviado com sucesso.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: _message(e, 'Falha ao enviar documento do veiculo.'),
      );
      return false;
    }
  }

  Future<bool> uploadProfileDocument({
    required String userId,
    required String type,
    required String filePath,
  }) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repository.uploadProfileDocument(
        userId: userId,
        type: type,
        filePath: filePath,
      );
      await load();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Documento enviado com sucesso.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: _message(e, 'Falha ao enviar documento.'),
      );
      return false;
    }
  }

  Future<bool> uploadCnhDocuments({
    required File cnhFront,
    required File cnhBack,
    required File selfie,
  }) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repository.uploadCnhDocuments(
        cnhFront: cnhFront,
        cnhBack: cnhBack,
        selfie: selfie,
      );
      await load();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'CNH enviada com sucesso.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: _message(e, 'Falha ao enviar CNH.'),
      );
      return false;
    }
  }

  Future<bool> logout() async {
    state = state.copyWith(
      isLoggingOut: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repository.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(Strings.prefToken);
      await prefs.remove(Strings.prefDriverName);
      await prefs.remove(Strings.prefDriverId);
      await prefs.remove(Strings.prefDriverProfileImage);
      await prefs.remove(Strings.prefDriverCpfMasked);
      await prefs.remove(Strings.prefDriverWalletAvailableMasked);
      state = state.copyWith(isLoggingOut: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoggingOut: false,
        error: _message(e, 'Falha ao encerrar sessao.'),
      );
      return false;
    }
  }

  String _message(Object error, String fallback) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.isEmpty) return fallback;
    return text;
  }
}
