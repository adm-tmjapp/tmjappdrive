

import 'package:tmjappdrive/data/onboardingStatus.dart';
import 'package:tmjappdrive/data/user.dart';

class ResponseLogin {
  bool? success;
  String? token;
  User? user;
  OnboardingStatus? onboardingStatus;

  ResponseLogin({
    required this.success,
    required this.token,
    required this.user,
    this.onboardingStatus,
  });

  factory ResponseLogin.fromJson(Map<String, dynamic> json) {
    return ResponseLogin(
      success: json["success"],
      token: json["token"],
      user: User.fromJson(json["user"]),
      onboardingStatus:
          json["onboardingStatus"] != null
              ? OnboardingStatus.fromJson(json["onboardingStatus"])
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "token": token,
    "user": user,
    "onboardingStatus": onboardingStatus,
  };
}
