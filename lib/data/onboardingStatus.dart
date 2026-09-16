class OnboardingStatusData {
  OnboardingStatus? onboardingStatus;

  OnboardingStatusData({this.onboardingStatus});

  factory OnboardingStatusData.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusData(
      onboardingStatus:
          json["onboardingStatus"] != null
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
    return OnboardingStatus(
      isCompleted: _asBool(json["isCompleted"] ?? json["is_completed"]),
      isUnderReview: _asBool(json["isUnderReview"] ?? json["is_under_review"]),
      canDrive: _asBool(json["canDrive"] ?? json["can_drive"]),
      steps:
          json["steps"] is Map
              ? Steps.fromJson(Map<String, dynamic>.from(json["steps"] as Map))
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
      profilePhoto: _step(json["profilePhoto"] ?? json["profile_photo"]),
      email: _step(json["email"]),
      phone: _step(json["phone"]),
      documents: _step(json["documents"]),
      vehicle: _step(json["vehicle"]),
      vehiclePhotos: _step(json["vehiclePhotos"] ?? json["vehicle_photos"]),
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
    return StepStatus(
      completed: _asBool(json["completed"] ?? json["isCompleted"]),
      underReview: _asBool(
        json["underReview"] ?? json["under_review"] ?? json["isUnderReview"],
      ),
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
    return StepStatus(completed: _asBool(value));
  }
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
