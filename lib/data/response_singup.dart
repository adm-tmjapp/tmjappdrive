import 'package:tmjappdrive/data/user.dart';

class ResponseSingup {
  bool? success;
  User? user;

  ResponseSingup({required this.success, required this.user});

  factory ResponseSingup.fromJson(Map<String, dynamic> json) {
    return ResponseSingup(
      success: json["success"],
      user: User.fromJson(json["user"]),
    );
  }

  Map<String, dynamic> toJson() => {"success": success, "user": user};
}
