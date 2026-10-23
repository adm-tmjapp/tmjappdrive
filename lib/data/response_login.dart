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
    final data =
        json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json;
    final userJson =
        data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : <String, dynamic>{};
    final onboarding =
        data['onboardingStatus'] ??
        data['onboarding_status'] ??
        json['onboardingStatus'] ??
        json['onboarding_status'];

    return ResponseLogin(
      success: _asBool(data["success"] ?? json["success"]),
      token: data["token"] ?? json["token"],
      user: User.fromJson(userJson),
      onboardingStatus:
          onboarding is Map
              ? OnboardingStatus.fromJson(Map<String, dynamic>.from(onboarding))
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "token": token,
    "user": user,
    "onboardingStatus": onboardingStatus,
  };

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'success':
        case 'ok':
          return true;
        case 'false':
        case '0':
          return false;
      }
    }
    return null;
  }
}
