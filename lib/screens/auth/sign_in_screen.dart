import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmjappdrive/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:tmjappdrive/screens/auth/sign_up_screen.dart';

import '../../repository/auth_repository.dart';
import '../../utils/strings.dart';
import '../dashboard_screen.dart';
import 'bloc/login_bloc.dart';
import 'bloc/login_event.dart';
import 'bloc/login_state.dart';
import 'sign_es_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();

  bool _showPassword = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricLoading = false;
  BiometricType? _biometricType;
  String? _storedEmail;
  String? _storedPassword;
  String _appVersion = 'Versão carregando...';

  static const _secureEmailKey = 'tmjappdrive.login.email';
  static const _securePasswordKey = 'tmjappdrive.login.password';
  static const _biometricEnabledKey = 'tmjappdrive.biometric.enabled';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _loadBiometricAvailability();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = 'Versão ${info.version} · código ${info.buildNumber}';
    });
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    var email = await _secureStorage.read(key: _secureEmailKey);
    var password = await _secureStorage.read(key: _securePasswordKey);

    // Migrate the legacy plaintext values once, then remove them.
    final legacyEmail = prefs.getString(Strings.prefEmail);
    final legacyPassword = prefs.getString(Strings.prefPassword);
    if ((email == null || email.isEmpty) && legacyEmail != null) {
      email = legacyEmail;
    }
    if ((password == null || password.isEmpty) && legacyPassword != null) {
      password = legacyPassword;
    }
    if (email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty) {
      try {
        await _secureStorage.write(key: _secureEmailKey, value: email);
        await _secureStorage.write(key: _securePasswordKey, value: password);
        await prefs.remove(Strings.prefEmail);
        await prefs.remove(Strings.prefPassword);
      } catch (_) {
        // A regular login remains available if secure storage is unavailable.
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _emailController.text = email ?? '';
      _passwordController.text = password ?? '';
      _storedEmail = email;
      _storedPassword = password;
      _biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
    });
  }

  Future<void> _loadBiometricAvailability() async {
    try {
      if (!await _localAuth.isDeviceSupported() ||
          !await _localAuth.canCheckBiometrics) {
        return;
      }
      final available = await _localAuth.getAvailableBiometrics();
      if (!mounted) return;
      setState(() {
        _biometricAvailable = available.isNotEmpty;
        _biometricType =
            available.contains(BiometricType.face)
                ? BiometricType.face
                : available.isNotEmpty
                ? available.first
                : null;
      });
    } catch (_) {
      // The login form remains usable on devices without enrolled biometrics.
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final loginBloc = context.read<LoginBloc>();
    loginBloc.add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _loginWithBiometrics(BuildContext context) async {
    if (!_canUseBiometricLogin || _biometricLoading) return;

    setState(() => _biometricLoading = true);
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirme sua identidade para entrar no TMJ Motorista',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      if (!authenticated || !mounted) return;

      final email = await _secureStorage.read(key: _secureEmailKey);
      final password = await _secureStorage.read(key: _securePasswordKey);
      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        _showMessage(
          'Entre com e-mail e senha uma vez para ativar a biometria.',
        );
        return;
      }
      if (!context.mounted) return;
      context.read<LoginBloc>().add(
        LoginRequested(email: email, password: password),
      );
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(_biometricErrorMessage(error.code));
      }
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  Future<void> _saveCredentials() async {
    try {
      await _secureStorage.write(
        key: _secureEmailKey,
        value: _emailController.text.trim(),
      );
      await _secureStorage.write(
        key: _securePasswordKey,
        value: _passwordController.text,
      );
      _storedEmail = _emailController.text.trim();
      _storedPassword = _passwordController.text;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(Strings.prefEmail);
      await prefs.remove(Strings.prefPassword);
    } catch (_) {
      // Do not block a successful login if secure storage is unavailable.
    }
  }

  bool get _canUseBiometricLogin =>
      _biometricAvailable &&
      _biometricEnabled &&
      _storedEmail != null &&
      _storedPassword != null &&
      _emailController.text.trim() == _storedEmail &&
      _passwordController.text == _storedPassword;

  IconData get _biometricIcon =>
      _biometricType == BiometricType.face
          ? Icons.face_retouching_natural
          : Icons.fingerprint;

  String get _biometricLabel =>
      _biometricType == BiometricType.face
          ? 'Entrar com Face ID'
          : 'Entrar com biometria';

  String _biometricErrorMessage(String code) {
    switch (code) {
      case 'NotEnrolled':
      case 'notEnrolled':
        return 'Nenhuma biometria cadastrada neste aparelho.';
      case 'LockedOut':
      case 'lockedOut':
      case 'PermanentlyLockedOut':
      case 'permanentlyLockedOut':
        return 'Biometria temporariamente bloqueada. Use sua senha.';
      case 'no_fragment_activity':
        return 'A biometria precisa ser atualizada. Reinicie o aplicativo.';
      case 'NotAvailable':
      case 'notAvailable':
        return 'A biometria não está disponível neste aparelho.';
      default:
        return 'Não foi possível validar sua biometria. Tente novamente.';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(authRepository: AuthRepository()),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) async {
          if (state is LoginSuccess) {
            await _saveCredentials();
            if (!context.mounted) return;
            final onboarding = state.responseLogin.onboardingStatus;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        (onboarding?.canDrive == true)
                            ? DashboardScreen()
                            : OnboardingFlowScreen(
                              responseLogin: state.responseLogin,
                            ),
              ),
            );
          } else if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error.replaceAll('Exception: ', '')),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;

          return Scaffold(
            backgroundColor: _backgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                  const Positioned(
                    top: -80,
                    right: -80,
                    child: _GlowOrb(
                      size: 220,
                      color: _accentColor,
                      alpha: 0.10,
                    ),
                  ),
                  const Positioned(
                    bottom: -120,
                    left: -100,
                    child: _GlowOrb(
                      size: 240,
                      color: _accentColor,
                      alpha: 0.06,
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Center(
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Image.asset(
                                      'assets/icon_white.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 44),
                              Text(
                                'Login',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Acesse sua conta para começar a dirigir',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: _subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _buildInput(
                                label: 'Email',
                                controller: _emailController,
                                hint: 'Ex: seuemail@provedor.com',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.mail_outline,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 16),
                              _buildInput(
                                label: 'Senha',
                                controller: _passwordController,
                                hint: 'Sua senha de acesso',
                                obscureText: !_showPassword,
                                prefixIcon: Icons.lock_outline,
                                validator: _validatePassword,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(
                                      () => _showPassword = !_showPassword,
                                    );
                                  },
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: _iconColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed:
                                      isLoading
                                          ? null
                                          : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        const ForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Esqueceu a senha?',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _accentColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      isLoading ? null : () => _submit(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accentColor,
                                    disabledBackgroundColor: _accentColor
                                        .withValues(alpha: 0.6),
                                    shadowColor: _accentColor.withValues(
                                      alpha: 0.40,
                                    ),
                                    elevation: 12,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child:
                                      isLoading
                                          ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : Text(
                                            'ENTRAR',
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                ),
                              ),
                              if (_canUseBiometricLogin) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        isLoading || _biometricLoading
                                            ? null
                                            : () =>
                                                _loginWithBiometrics(context),
                                    icon:
                                        _biometricLoading
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: _accentColor,
                                              ),
                                            )
                                            : Icon(_biometricIcon),
                                    label: Text(_biometricLabel),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _accentColor,
                                      side: const BorderSide(
                                        color: _accentColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 40),
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: _subtitleColor,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Não tem uma conta? ',
                                      ),
                                      TextSpan(
                                        text: 'Cadastre-se',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _accentColor,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            const SignUpScreen(),
                                                  ),
                                                );
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: Text(
                                  _appVersion,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _subtitleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
    required String? Function(String?) validator,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFE2E8F0),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: _hintColor,
            ),
            prefixIcon: Icon(prefixIcon, color: _iconColor, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _fieldColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _fieldBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accentColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            errorStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail';
    }
    final email = value.trim();
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      return 'Informe um e-mail válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }
    return null;
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.alpha,
  });

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: alpha),
              blurRadius: 100,
              spreadRadius: 40,
            ),
          ],
        ),
      ),
    );
  }
}

const _backgroundColor = Color(0xFF000000);
const _fieldColor = Color(0x80111A2E);
const _fieldBorderColor = Color(0x4D334155);
const _accentColor = Color(0xFFC62F78);
const _iconColor = Color(0xB3C62F78);
const _subtitleColor = Color(0xFF94A3B8);
const _hintColor = Color(0xFF667085);
