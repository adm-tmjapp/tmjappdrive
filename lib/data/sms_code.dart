import 'package:tmjappdrive/data/onboardingStatus.dart';
import 'package:tmjappdrive/data/user.dart';

class SmsCodeResponse {
  String? message;
  PhoneValidation? phoneValidation;
  String? token;
  User? user;
  OnboardingStatus? onboardingStatus;

  SmsCodeResponse({
    required this.message,
    this.phoneValidation,
    this.token,
    this.user,
    this.onboardingStatus,
  });

  factory SmsCodeResponse.fromJson(Map<String, dynamic> json) {
    return SmsCodeResponse(
      message: json["message"],
      phoneValidation:
          json["phoneValidation"] != null
              ? PhoneValidation.fromJson(json["phoneValidation"])
              : null,
      token: json["token"],
      user: json["user"] != null ? User.fromJson(json["user"]) : null,
      onboardingStatus:
          json["onboardingStatus"] != null
              ? OnboardingStatus.fromJson(json["onboardingStatus"])
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "message": message,
    "phoneValidation": phoneValidation,
    "token": token,
    "user": user,
    "onboardingStatus": onboardingStatus,
  };
}

class PhoneValidation {
  String? code;
  String? sentAt;

  PhoneValidation({this.code, this.sentAt});
  factory PhoneValidation.fromJson(Map<String, dynamic> json) {
    return PhoneValidation(code: json["code"], sentAt: json["sentAt"]);
  }

  Map<String, dynamic> toJson() => {"code": code, "sentAt": sentAt};
}
