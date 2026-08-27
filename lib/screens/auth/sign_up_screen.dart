import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../repository/auth_repository.dart';
import 'bloc/login_bloc.dart';
import 'bloc/login_event.dart';
import 'bloc/login_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _acceptedTerms = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context) {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa aceitar os Termos de Uso.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fullName = _fullNameController.text.trim();
    final parts =
        fullName
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();
    final firstName = parts.isEmpty ? fullName : parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    context.read<LoginBloc>().add(
      SignupRequested(
        phone: _phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        cpf: _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        name: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(authRepository: AuthRepository()),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is SignupLoading) {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          } else if (state is SignupSuccess) {
            Navigator.of(context, rootNavigator: true).pop();
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder:
                  (dialogContext) => AlertDialog(
                    title: const Text('Sucesso'),
                    content: const Text('Usuário criado com sucesso!'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Ir para Login'),
                      ),
                    ],
                  ),
            );
          } else if (state is SignupFailure) {
            Navigator.of(context, rootNavigator: true).maybePop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error.replaceAll('Exception: ', '')),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: _backgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crie sua conta',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Preencha os dados abaixo para\ncomeçar a dirigir com a TMJApp.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: _subtitleColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildInput(
                        label: 'Nome Completo',
                        controller: _fullNameController,
                        hint: 'Digite seu nome completo',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe seu nome completo';
                          }
                          if (value.trim().split(RegExp(r'\s+')).length < 2) {
                            return 'Informe nome e sobrenome';
                          }
                          return null;
                        },
                      ),
                      _buildInput(
                        label: 'E-mail',
                        controller: _emailController,
                        hint: 'exemplo@email.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline,
                        validator: _validateEmail,
                      ),
                      _buildInput(
                        label: 'Telefone',
                        controller: _phoneController,
                        hint: '(00) 00000-0000',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.call_outlined,
                        inputFormatters: [_phoneMask],
                        validator: (value) {
                          final digits =
                              value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                          if (digits.length != 11) {
                            return 'Informe um telefone válido';
                          }
                          return null;
                        },
                      ),
                      _buildInput(
                        label: 'CPF',
                        controller: _cpfController,
                        hint: '000.000.000-00',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.badge_outlined,
                        inputFormatters: [_cpfMask],
                        validator: (value) {
                          final digits =
                              value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                          if (digits.length != 11) {
                            return 'Informe um CPF válido';
                          }
                          return null;
                        },
                      ),
                      _buildInput(
                        label: 'Senha',
                        controller: _passwordController,
                        hint: 'Crie uma senha forte',
                        obscureText: !_showPassword,
                        prefixIcon: Icons.lock_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe uma senha';
                          }
                          if (value.length < 6) {
                            return 'A senha precisa ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _iconColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => _acceptedTerms = !_acceptedTerms);
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _checkboxBorderColor),
                                color:
                                    _acceptedTerms
                                        ? _accentColor.withValues(alpha: 0.18)
                                        : _fieldFillColor, // Modificado para bater com o design escuro
                              ),
                              child:
                                  _acceptedTerms
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Eu aceito os ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: _subtitleColor,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Termos de Uso',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _accentColor,
                                    ),
                                    recognizer:
                                        TapGestureRecognizer()
                                          ..onTap = showTermsConditions,
                                  ),
                                  const TextSpan(text: ' e a '),
                                  TextSpan(
                                    text: 'Política de\nPrivacidade',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _accentColor,
                                    ),
                                    recognizer:
                                        TapGestureRecognizer()
                                          ..onTap = showTermsConditions,
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              state is SignupLoading
                                  ? null
                                  : () => _onSubmit(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            disabledBackgroundColor: _accentColor.withValues(
                              alpha: 0.6,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation:
                                0, // Removida a sombra conforme o flat design da imagem
                          ),
                          child:
                              state is SignupLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    'CRIAR MINHA CONTA',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Já tem uma conta? ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white, // Alterado para branco puro
                            ),
                            children: [
                              TextSpan(
                                text: 'Entre agora',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _accentColor,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap =
                                          () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14, // Fonte do label reduzida para o padrão
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            height: 8,
          ), // Reduzido o espaço entre o label e o input
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            validator: validator,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _placeholderColor,
              ),
              errorStyle: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.redAccent,
              ),
              filled: true,
              fillColor: _fieldFillColor,
              prefixIcon: Icon(prefixIcon, color: _iconColor, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: suffixIcon,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ), // Raio arredondado para 12
                borderSide: const BorderSide(color: _fieldBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accentColor, width: 1.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu e-mail';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Informe um e-mail válido';
    }

    return null;
  }

  void showTermsConditions() {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF101014),
            title: const Text(
              'Termos e Privacidade',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Aqui entram os Termos de Uso e a Política de Privacidade.',
              style: TextStyle(color: Color(0xFFADB6D0)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Fechar',
                  style: TextStyle(color: _accentColor),
                ),
              ),
            ],
          ),
    );
  }
}

const _backgroundColor = Color(0xFF000000);
const _fieldFillColor = Color(
  0xFF0F0F12,
); // Ajuste fino baseado na paleta comum de modo escuro
const _fieldBorderColor = Color(0xFF1E1E24);
const _checkboxBorderColor = Color(0xFF333333);
const _accentColor = Color(
  0xFFC62F78,
); // Ajuste na cor exata do botão do mockup
const _subtitleColor = Color(0xFF8E9AB7);
const _placeholderColor = Color(0xFF66708C);
const _iconColor = Color(0xFF6B7280);
