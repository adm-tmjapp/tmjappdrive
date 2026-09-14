import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repository/auth_repository.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _repository = AuthRepository();

  bool _isSubmitting = false;
  bool _isResending = false;
  bool _showPassword = false;
  bool _showConfirmation = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await _repository.resetPassword(
        email: widget.email,
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Senha alterada'),
              content: const Text(
                'Sua senha foi redefinida. Você já pode entrar na sua conta.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('IR PARA LOGIN'),
                ),
              ],
            ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      await _repository.forgotPassword(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Um novo código foi enviado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 104,
                        height: 104,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            'assets/icon_white.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Redefina sua senha',
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Digite o código de 6 dígitos enviado para ${widget.email} e crie uma nova senha.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.5,
                        color: _subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _label('Código recebido'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if ((value?.trim().length ?? 0) != 6) {
                          return 'Informe o código de 6 dígitos.';
                        }
                        return null;
                      },
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                      ),
                      decoration: _decoration(
                        hint: '000000',
                        icon: Icons.password_rounded,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 22),
                    _label('Nova senha'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: _validatePassword,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: _decoration(
                        hint: 'Mínimo de 6 caracteres',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed:
                              () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _iconColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _label('Confirme a nova senha'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmationController,
                      obscureText: !_showConfirmation,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem.';
                        }
                        return null;
                      },
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: _decoration(
                        hint: 'Digite a senha novamente',
                        icon: Icons.lock_reset_rounded,
                        suffixIcon: IconButton(
                          onPressed:
                              () => setState(
                                () => _showConfirmation = !_showConfirmation,
                              ),
                          icon: Icon(
                            _showConfirmation
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _iconColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          disabledBackgroundColor: _accentColor.withValues(
                            alpha: 0.6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  'REDEFINIR SENHA',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: _isResending ? null : _resendCode,
                        child: Text(
                          _isResending ? 'REENVIANDO...' : 'REENVIAR CÓDIGO',
                          style: GoogleFonts.inter(
                            color: _accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Informe a nova senha.';
    if (value.length < 6) return 'Use pelo menos 6 caracteres.';
    return null;
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFE2E8F0),
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    String? counterText,
  }) {
    return InputDecoration(
      hintText: hint,
      counterText: counterText,
      hintStyle: GoogleFonts.inter(color: _hintColor, letterSpacing: 0),
      prefixIcon: Icon(icon, color: _iconColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _fieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
    );
  }
}

const _backgroundColor = Color(0xFF000000);
const _fieldColor = Color(0xFF0F172A);
const _fieldBorderColor = Color(0xFF1E293B);
const _accentColor = Color(0xFFC62F78);
const _subtitleColor = Color(0xFF94A3B8);
const _hintColor = Color(0xFF667085);
const _iconColor = Color(0xFF94A3B8);
