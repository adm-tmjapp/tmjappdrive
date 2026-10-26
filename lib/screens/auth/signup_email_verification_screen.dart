import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/response_login.dart';
import '../../features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import '../../repository/auth_repository.dart';

class SignupEmailVerificationScreen extends StatefulWidget {
  const SignupEmailVerificationScreen({super.key, required this.responseLogin});

  final ResponseLogin responseLogin;

  @override
  State<SignupEmailVerificationScreen> createState() =>
      _SignupEmailVerificationScreenState();
}

class _SignupEmailVerificationScreenState
    extends State<SignupEmailVerificationScreen> {
  static const _resendDelay = Duration(seconds: 60);

  final _codeController = TextEditingController();
  final _authRepository = AuthRepository();
  Timer? _resendTimer;
  int _resendSeconds = 0;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _error;
  String? _notice;

  String get _maskedEmail {
    final email = widget.responseLogin.user?.email?.trim() ?? '';
    final parts = email.split('@');
    if (parts.length != 2 || parts.first.length < 2) return 'seu e-mail';
    return '${parts.first.substring(0, 2)}•••@${parts.last}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSending || _resendSeconds > 0) return;
    setState(() {
      _isSending = true;
      _error = null;
      _notice = null;
    });

    try {
      await _authRepository.sendSignupEmailVerificationCode();
      if (!mounted) return;
      setState(
        () => _notice = 'Enviamos o código de confirmação para $_maskedEmail.',
      );
      _startResendCooldown();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = _message(error, 'Não foi possível enviar o código.'),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = _resendDelay.inSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || _isVerifying) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _error = null;
      _notice = null;
    });

    try {
      final verifiedSession = await _authRepository.verifySignupEmailCode(code);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnboardingFlowScreen(responseLogin: verifiedSession),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, 'Código inválido ou expirado.'));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  String _message(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? fallback : message;
  }

  @override
  Widget build(BuildContext context) {
    final canVerify = _codeController.text.trim().length == 6 && !_isVerifying;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Confirmar e-mail',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 70,
                    color: Color(0xFFC62F78),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Confirme seu e-mail',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Antes de começar seu onboarding, digite o código de 6 dígitos enviado para $_maskedEmail.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••••',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF1F2937)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF1F2937)),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    _FeedbackText(text: _error!, isError: true),
                  if (_notice != null)
                    _FeedbackText(text: _notice!, isError: false),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: canVerify ? _verifyCode : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62F78),
                        disabledBackgroundColor: const Color(0xFF5E2645),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          _isVerifying
                              ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Confirmar e continuar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        _isSending || _resendSeconds > 0 ? null : _sendCode,
                    child: Text(
                      _isSending
                          ? 'Enviando código...'
                          : _resendSeconds > 0
                          ? 'Reenviar em 00:${_resendSeconds.toString().padLeft(2, '0')}'
                          : 'Reenviar código',
                      style: const TextStyle(color: Color(0xFFF9A8D4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Voltar e revisar meus dados',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackText extends StatelessWidget {
  const _FeedbackText({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
        fontSize: 13,
      ),
    );
  }
}
