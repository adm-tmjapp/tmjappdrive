import 'package:tmjappdrive/data/response_login.dart';
import 'package:tmjappdrive/data/response_singup.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class ForgotPasswordSuccess extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final ResponseLogin responseLogin;

  LoginSuccess(this.responseLogin);
}

class LoginFailure extends LoginState {
  final String error;

  LoginFailure(this.error);
}

class SignupLoading extends LoginState {}

class SignupSuccess extends LoginState {
  final ResponseSingup data;

  SignupSuccess(this.data);
}

class SignupFailure extends LoginState {
  final String error;

  SignupFailure(this.error);
}
