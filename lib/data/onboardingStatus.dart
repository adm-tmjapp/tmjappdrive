class OnboardingStatusData {
  OnboardingStatus? onboardingStatus;

  OnboardingStatusData({this.onboardingStatus});

  factory OnboardingStatusData.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusData(
      onboardingStatus: json["onboardingStatus"] != null
          ? OnboardingStatus.fromJson(json["onboardingStatus"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {"onboardingStatus": onboardingStatus?.toJson()};
  }
}

class OnboardingStatus {
  bool? isCompleted;
  bool? isUnderReview;
  bool? canDrive;
  Steps? steps;

  OnboardingStatus({
    this.isCompleted,
    this.isUnderReview,
    this.canDrive,
    this.steps,
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    var nested = json;
    for (var index = 0; index < 3; index++) {
      final unwrapped =
          _mapValue(nested['onboardingStatus']) ??
          _mapValue(nested['onboarding_status']) ??
          _mapValue(nested['data']);
      if (unwrapped == null) break;
      nested = unwrapped;
    }
    final rawStatus = _normalizedStatus(nested['status'] ?? nested['state']);
    final completed =
        _asBool(
          nested["isCompleted"] ??
              nested["is_completed"] ??
              nested['completed'],
        ) ??
        _statusIsCompleted(rawStatus);
    final underReview =
        _asBool(
          nested["isUnderReview"] ??
              nested["is_under_review"] ??
              nested['underReview'] ??
              nested['under_review'],
        ) ??
        _statusIsReviewing(rawStatus);
    final canDrive =
        _asBool(
          nested["canDrive"] ?? nested["can_drive"] ?? nested['approved'],
        ) ??
        _statusIsCompleted(rawStatus);

    final stepsValue =
        nested["steps"] ??
        nested['onboardingSteps'] ??
        nested['onboarding_steps'];

    return OnboardingStatus(
      isCompleted: completed,
      isUnderReview: underReview,
      canDrive: canDrive,
      steps: stepsValue is Map
          ? Steps.fromJson(Map<String, dynamic>.from(stepsValue))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "isCompleted": isCompleted,
      "isUnderReview": isUnderReview,
      "canDrive": canDrive,
      "steps": steps?.toJson(),
    };
  }
}

class Steps {
  StepStatus? profilePhoto;
  StepStatus? email;
  StepStatus? phone;
  StepStatus? documents;
  StepStatus? vehicle;
  StepStatus? vehiclePhotos;

  Steps({
    this.profilePhoto,
    this.email,
    this.phone,
    this.documents,
    this.vehicle,
    this.vehiclePhotos,
  });

  factory Steps.fromJson(Map<String, dynamic> json) {
    return Steps(
      profilePhoto: _step(
        json["profilePhoto"] ?? json["profile_photo"] ?? json["profile"],
      ),
      email: _step(json["email"] ?? json["emailVerification"]),
      phone: _step(json["phone"] ?? json["phoneVerification"]),
      documents: _step(json["documents"] ?? json["cnh"] ?? json["license"]),
      vehicle: _step(json["vehicle"]),
      vehiclePhotos: _step(
        json["vehiclePhotos"] ?? json["vehicle_photos"] ?? json["photos"],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "profilePhoto": profilePhoto?.toJson(),
      "email": email?.toJson(),
      "phone": phone?.toJson(),
      "documents": documents?.toJson(),
      "vehicle": vehicle?.toJson(),
      "vehiclePhotos": vehiclePhotos?.toJson(),
    };
  }
}

class StepStatus {
  bool? completed;
  bool? underReview;

  StepStatus({this.completed, this.underReview});

  factory StepStatus.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json["status"] ?? json["state"] ?? "")
        .toString()
        .trim()
        .toLowerCase();
    return StepStatus(
      completed:
          _asBool(json["completed"] ?? json["isCompleted"]) ??
          ({'approved', 'aprovado', 'completed', 'complete'}.contains(rawStatus)
              ? true
              : null),
      underReview:
          _asBool(
            json["underReview"] ??
                json["under_review"] ??
                json["isUnderReview"],
          ) ??
          ({
                'pending',
                'under_review',
                'em_analise',
                'submitted',
                'enviado',
              }.contains(rawStatus)
              ? true
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "completed": completed,
      if (underReview != null) "underReview": underReview,
    };
  }
}

StepStatus? _step(dynamic value) {
  if (value is Map) {
    return StepStatus.fromJson(Map<String, dynamic>.from(value));
  }
  if (value is bool || value is num || value is String) {
    final normalized = value.toString().trim().toLowerCase();
    return StepStatus(
      completed:
          _asBool(value) ??
          ({
                'approved',
                'aprovado',
                'completed',
                'complete',
              }.contains(normalized)
              ? true
              : null),
      underReview: {
        'pending',
        'under_review',
        'em_analise',
        'submitted',
        'enviado',
      }.contains(normalized),
    );
  }
  return null;
}

Map<String, dynamic>? _mapValue(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'sim':
      case 'approved':
      case 'completed':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'nao':
      case 'não':
      case 'pending':
        return false;
    }
  }
  return null;
}

String _normalizedStatus(dynamic value) => (value ?? '')
    .toString()
    .trim()
    .toLowerCase()
    .replaceAll('-', '_')
    .replaceAll(' ', '_');

bool _statusIsCompleted(String status) => {
  'approved',
  'aprovado',
  'completed',
  'complete',
  'active',
  'ativo',
  'ready',
}.contains(status);

bool _statusIsReviewing(String status) => {
  'pending',
  'under_review',
  'em_analise',
  'submitted',
  'enviado',
  'reviewing',
}.contains(status);
