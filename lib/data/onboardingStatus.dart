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
      isCompleted: json["isCompleted"],
      isUnderReview: json["isUnderReview"],
      canDrive: json["canDrive"],
      steps: json["steps"] != null ? Steps.fromJson(json["steps"]) : null,
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
      profilePhoto:
          json["profilePhoto"] != null
              ? StepStatus.fromJson(json["profilePhoto"])
              : null,
      email: json["email"] != null ? StepStatus.fromJson(json["email"]) : null,
      phone: json["phone"] != null ? StepStatus.fromJson(json["phone"]) : null,
      documents:
          json["documents"] != null
              ? StepStatus.fromJson(json["documents"])
              : null,
      vehicle:
          json["vehicle"] != null ? StepStatus.fromJson(json["vehicle"]) : null,
      vehiclePhotos:
          json["vehiclePhotos"] != null
              ? StepStatus.fromJson(json["vehiclePhotos"])
              : null,
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
      completed: json["completed"],
      underReview: json["underReview"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "completed": completed,
      if (underReview != null) "underReview": underReview,
    };
  }
}
