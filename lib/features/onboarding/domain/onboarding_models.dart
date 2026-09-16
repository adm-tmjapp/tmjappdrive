import 'dart:io';

import '../../../data/onboardingStatus.dart';
import '../../../data/response_login.dart';
import '../../profile/domain/profile_models.dart';

enum DriverOnboardingStepType {
  profilePhoto,
  email,
  phone,
  cnh,
  criminalRecord,
  vehicle,
  vehiclePhotos,
}

enum DriverOnboardingStepStatus { pending, completed, reviewing }

class DriverOnboardingSession {
  const DriverOnboardingSession({required this.responseLogin});

  final ResponseLogin responseLogin;

  String get userId => responseLogin.user?.id ?? '';
  String get email => responseLogin.user?.email ?? '';
  String get phone => responseLogin.user?.phone ?? '';
  String get driverName => responseLogin.user?.name ?? 'Motorista';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DriverOnboardingSession &&
            runtimeType == other.runtimeType &&
            userId == other.userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

class DriverOnboardingChecklistItem {
  const DriverOnboardingChecklistItem({
    required this.type,
    required this.title,
    required this.description,
    required this.status,
  });

  final DriverOnboardingStepType type;
  final String title;
  final String description;
  final DriverOnboardingStepStatus status;

  bool get isCompleted => status == DriverOnboardingStepStatus.completed;
  bool get isReviewing => status == DriverOnboardingStepStatus.reviewing;
  bool get isPending => status == DriverOnboardingStepStatus.pending;
}

class DriverOnboardingSnapshot {
  const DriverOnboardingSnapshot({
    required this.onboardingStatus,
    required this.documents,
  });

  final OnboardingStatus? onboardingStatus;
  final DriverProfileDocuments? documents;

  List<DriverOnboardingChecklistItem> get checklistItems {
    final steps = onboardingStatus?.steps;
    return <DriverOnboardingChecklistItem>[
      DriverOnboardingChecklistItem(
        type: DriverOnboardingStepType.profilePhoto,
        title: 'Foto de Perfil',
        description: 'Envie uma foto nítida do seu rosto.',
        status: _stepStatus(steps?.profilePhoto),
      ),
      DriverOnboardingChecklistItem(
        type: DriverOnboardingStepType.email,
        title: 'E-mail',
        description: 'Confirme o e-mail cadastrado.',
        status: _stepStatus(steps?.email),
      ),
      DriverOnboardingChecklistItem(
        type: DriverOnboardingStepType.phone,
        title: 'Celular',
        description: 'Confirme seu número de telefone.',
        status: _stepStatus(steps?.phone),
      ),
      DriverOnboardingChecklistItem(
        type: DriverOnboardingStepType.cnh,
        title: 'CNH',
        description: 'Envie frente, verso e selfie com documento.',
        status: _stepStatus(steps?.documents),
      ),
      DriverOnboardingChecklistItem(
        type: DriverOnboardingStepType.criminalRecord,
        title: 'Verificação de Segurança',
        description: 'Envie seus antecedentes criminais.',
        status: _documentStatus(documents?.criminalRecord.status),
      ),
      DriverOnboardingChecklistItem(
        type: DriverOnboardingStepType.vehicle,
        title: 'Veículo',
        description: 'Cadastre os dados do veículo.',
        status: _stepStatus(steps?.vehicle),
      ),
      DriverOnboardingChecklistItem(
        type: DriverOnboardingStepType.vehiclePhotos,
        title: 'Foto do Veículo',
        description: 'Envie frente, traseira e interior.',
        status: _stepStatus(steps?.vehiclePhotos),
      ),
    ];
  }

  bool get isUnderReview => onboardingStatus?.isUnderReview == true;
  bool get isCompleted => onboardingStatus?.isCompleted == true;
  bool get canDrive => onboardingStatus?.canDrive == true;

  bool get hasSubmittedAllSteps {
    final items = checklistItems;
    return items.isNotEmpty && items.every((item) => !item.isPending);
  }

  bool get shouldShowPendingReview =>
      !canDrive && isUnderReview && hasSubmittedAllSteps;

  double get progress {
    final items = checklistItems;
    if (items.isEmpty) return 0;
    final completed = items.where((item) => item.isCompleted).length;
    return completed / items.length;
  }

  static DriverOnboardingStepStatus _stepStatus(StepStatus? status) {
    if (status?.completed == true) {
      return DriverOnboardingStepStatus.completed;
    }
    if (status?.underReview == true) {
      return DriverOnboardingStepStatus.reviewing;
    }
    return DriverOnboardingStepStatus.pending;
  }

  static DriverOnboardingStepStatus _documentStatus(String? rawStatus) {
    final normalized = (rawStatus ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return DriverOnboardingStepStatus.pending;
    if ({'APPROVED', 'APROVADO', 'COMPLETED'}.contains(normalized)) {
      return DriverOnboardingStepStatus.completed;
    }
    if ({
      'UNDER_REVIEW',
      'EM_ANALISE',
      'PENDING',
      'SUBMITTED',
      'ENVIADO',
    }.contains(normalized)) {
      return DriverOnboardingStepStatus.reviewing;
    }
    return DriverOnboardingStepStatus.pending;
  }
}

class DriverOnboardingVehicleInput {
  const DriverOnboardingVehicleInput({
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.vehicleType,
    required this.usage,
    this.renavam,
  });

  final String brand;
  final String model;
  final String year;
  final String color;
  final String plate;
  final String vehicleType;
  final String usage;
  final String? renavam;
}

class DriverOnboardingVehiclePhotosInput {
  const DriverOnboardingVehiclePhotosInput({
    required this.front,
    required this.back,
    required this.interior,
  });

  final File front;
  final File back;
  final File interior;
}
