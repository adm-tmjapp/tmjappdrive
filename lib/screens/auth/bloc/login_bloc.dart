import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';
import 'package:tmjappdrive/repository/auth_repository.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc({required this.authRepository}) : super(LoginInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final response = await authRepository.login(event.email, event.password);
      if (response == null) {
        emit(LoginFailure('Credenciais inválidas.'));
        return;
      }
      emit(LoginSuccess(response));
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }

  /// Lógica executada quando o evento SignupRequested é disparado
  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<LoginState> emit,
  ) //
  async {
    // 1. Emite estado de carregamento (mostra o CircularProgressIndicator)
    emit(SignupLoading());

    try {
      // 2. Chama o repositório
      final response = await authRepository.signUp(
        event.phone,
        event.cpf,
        event.name,
        event.lastName,
        event.email,
        event.password,
      );

      // 3. Verifica a resposta e emite Sucesso ou Falha
      if (response == null) {
        emit(SignupFailure('Erro ao cadastrar usuário: Resposta nula'));
      } else {
        emit(SignupSuccess(response));
      }
    } catch (e) {
      // 4. Captura erros de rede ou exceções
      emit(SignupFailure(e.toString()));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<LoginState> emit,
  ) async {
    // 1. Mostra Loading
    emit(LoginLoading());

    try {
      // 2. Chama o repositório (que agora chama a API real)
      await authRepository.forgotPassword(event.email);

      // 3. Sucesso! Mostra o popup
      emit(ForgotPasswordSuccess());
    } catch (e) {
      // 4. Falha! Mostra o erro (remove "Exception: " se existir)
      final errorMsg = e.toString().replaceAll("Exception: ", "");
      emit(LoginFailure(errorMsg));
    }
  }
}
