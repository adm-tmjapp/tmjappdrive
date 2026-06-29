import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/sms_code.dart';
import '../domain/onboarding_models.dart';
import '../domain/onboarding_repository.dart';

class DriverOnboardingState {
  const DriverOnboardingState({
    required this.isLoading,
    required this.isSubmitting,
    this.snapshot,
    this.error,
    this.successMessage,
    this.lastCodeResponse,
  });

  final bool isLoading;
  final bool isSubmitting;
  final DriverOnboardingSnapshot? snapshot;
  final String? error;
  final String? successMessage;
  final SmsCodeResponse? lastCodeResponse;

  factory DriverOnboardingState.initial() {
    return const DriverOnboardingState(isLoading: true, isSubmitting: false);
  }

  DriverOnboardingState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    DriverOnboardingSnapshot? snapshot,
    String? error,
    String? successMessage,
    SmsCodeResponse? lastCodeResponse,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearCode = false,
  }) {
    return DriverOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      snapshot: snapshot ?? this.snapshot,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      lastCodeResponse:
          clearCode ? null : (lastCodeResponse ?? this.lastCodeResponse),
    );
  }
}

class DriverOnboardingController extends StateNotifier<DriverOnboardingState> {
  DriverOnboardingController(this._repository, this._session)
    : super(DriverOnboardingState.initial()) {
    load();
  }

  final DriverOnboardingRepository _repository;
  final DriverOnboardingSession _session;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final snapshot = await _repository.getSnapshot(_session.userId);
      state = state.copyWith(
        isLoading: false,
        snapshot: snapshot,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _message(e, 'Falha ao carregar onboarding.'),
      );
    }
  }

  Future<bool> sendPhoneCode() async {
    return _runCodeAction(
      action: () => _repository.sendPhoneCode(_session.userId),
      successFallback: 'Código enviado para o celular.',
    );
  }

  Future<bool> verifyPhoneCode(String code) async {
    return _runCodeAction(
      action: () => _repository.verifyPhoneCode(_session.userId, code),
      reloadAfter: true,
      successFallback: 'Celular validado com sucesso.',
    );
  }

  Future<bool> sendEmailCode() async {
    return _runCodeAction(
      action: () => _repository.sendEmailCode(_session.userId),
      successFallback: 'Código enviado para o e-mail.',
    );
  }

  Future<bool> verifyEmailCode(String code) async {
    return _runCodeAction(
      action: () => _repository.verifyEmailCode(_session.userId, code),
      reloadAfter: true,
      successFallback: 'E-mail validado com sucesso.',
    );
  }

  Future<bool> uploadProfilePhoto(File photo) async {
    return _runAction(
      action: () => _repository.uploadProfilePhoto(_session.userId, photo),
      successMessage: 'Foto de perfil enviada com sucesso.',
      reloadAfter: true,
    );
  }

  Future<bool> uploadCnhDocuments({
    required File cnhFront,
    required File cnhBack,
    required File selfie,
  }) async {
    return _runAction(
      action:
          () => _repository.uploadCnhDocuments(
            cnhFront: cnhFront,
            cnhBack: cnhBack,
            selfie: selfie,
          ),
      successMessage: 'Documentos da CNH enviados com sucesso.',
      reloadAfter: true,
    );
  }

  Future<bool> uploadCriminalRecord(File file) async {
    return _runAction(
      action: () => _repository.uploadCriminalRecord(_session.userId, file),
      successMessage: 'Documento de antecedentes enviado com sucesso.',
      reloadAfter: true,
    );
  }

  Future<bool> registerVehicle(DriverOnboardingVehicleInput input) async {
    return _runAction(
      action: () => _repository.registerVehicle(_session.userId, input),
      successMessage: 'Dados do veículo enviados com sucesso.',
      reloadAfter: true,
    );
  }

  Future<bool> uploadVehiclePhotos(
    DriverOnboardingVehiclePhotosInput input,
  ) async {
    return _runAction(
      action: () => _repository.uploadVehiclePhotos(_session.userId, input),
      successMessage: 'Fotos do veículo enviadas com sucesso.',
      reloadAfter: true,
    );
  }

  void clearFeedback() {
    state = state.copyWith(
      clearError: true,
      clearSuccess: true,
      clearCode: true,
    );
  }

  Future<bool> _runCodeAction({
    required Future<SmsCodeResponse?> Function() action,
    required String successFallback,
    bool reloadAfter = false,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
      clearCode: true,
    );
    try {
      final response = await action();
      if (reloadAfter) {
        await load();
      }
      state = state.copyWith(
        isSubmitting: false,
        lastCodeResponse: response,
        successMessage: response?.message ?? successFallback,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _message(e, 'Falha na validacao.'),
      );
      return false;
    }
  }

  Future<bool> _runAction({
    required Future<void> Function() action,
    required String successMessage,
    bool reloadAfter = false,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await action();
      if (reloadAfter) {
        await load();
      }
      state = state.copyWith(
        isSubmitting: false,
        successMessage: successMessage,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _message(e, 'Falha ao enviar dados do onboarding.'),
      );
      return false;
    }
  }

  String _message(Object error, String fallback) {
    final raw = error.toString();

    // 1. Intercepta o erro de JSON/HTML do servidor
    if (raw.contains('Unexpected character') ||
        raw.contains('<html>') ||
        raw.contains('FormatException')) {
      return 'Erro no servidor: O arquivo pode ser muito grande ou o sistema está indisponível.';
    }

    // 2. Limpa erros de exceção padrão
    final clean = raw.replaceAll('Exception: ', '').trim();

    return clean.isEmpty ? fallback : clean;
  }
}
