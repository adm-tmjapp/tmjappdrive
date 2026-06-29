// import 'package:equatable/equatable.dart';

abstract class LoginEvent {}

class LoginRequested extends LoginEvent {
  final String email;
  final String password;

  LoginRequested({required this.email, required this.password});
}

class SignupRequested extends LoginEvent {
  final String phone;
  final String name;
  final String lastName;
  final String email;
  final String password;

  SignupRequested({
    required this.phone,
    required this.name,
    required this.lastName,
    required this.email,
    required this.password,
  });
}

class ForgotPasswordRequested extends LoginEvent {
  final String email;

  ForgotPasswordRequested({required this.email});
}
