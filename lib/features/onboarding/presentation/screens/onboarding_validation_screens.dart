import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/onboarding_providers.dart';
import '../../domain/onboarding_models.dart';
// Mantenha os imports do seu projeto
import '../widgets/onboarding_ui.dart';

// Cores do layout (Substitua as do onboarding_ui.dart caso prefira estas)
const Color _onboardingBg = Color(0xFF000000);
const Color _onboardingPrimary = Color(0xFFC62F78);
const Color _onboardingSubtitle = Color(0xFF94A3B8);

// ==============================================================
// TELA DE VALIDAÇÃO DE E-MAIL
// ==============================================================
class OnboardingEmailValidationScreen extends ConsumerStatefulWidget {
  const OnboardingEmailValidationScreen({super.key, required this.session});

  final DriverOnboardingSession session;

  @override
  ConsumerState<OnboardingEmailValidationScreen> createState() =>
      _OnboardingEmailValidationScreenState();
}

class _OnboardingEmailValidationScreenState
    extends ConsumerState<OnboardingEmailValidationScreen> {
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _codeReady = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_syncCodeState);
  }

  @override
  void dispose() {
    _codeController.removeListener(_syncCodeState);
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverOnboardingControllerProvider(widget.session));
    final controller = ref.read(
      driverOnboardingControllerProvider(widget.session).notifier,
    );

    return _ValidationLayout(
      title: 'E-mail',
      headline: 'Verificação de E-mail',
      description:
          'Enviamos um código de 6 dígitos para o seu e-mail. Por favor, digite-o abaixo para confirmar.',
      stepLabel: 'Onboarding',
      currentStep: 2,
      totalSteps: 7,
      codeController: _codeController,
      isLoading: state.isSubmitting,
      error: state.error,
      codeSent: _codeSent,
      codeReady: _codeReady,
      onSendCode: () async {
        final ok = await controller.sendEmailCode();
        if (!mounted) return;
        if (ok) {
          setState(() => _codeSent = true);
        }
      },
      onSubmit: () async {
        final ok = await controller.verifyEmailCode(
          _codeController.text.trim(),
        );
        if (!context.mounted) return;
        if (ok) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _syncCodeState() {
    final ready = _codeController.text.trim().length == 6;
    if (ready != _codeReady && mounted) {
      setState(() => _codeReady = ready);
    }
  }
}

// ==============================================================
// TELA DE VALIDAÇÃO DE CELULAR
// ==============================================================
class OnboardingPhoneValidationScreen extends ConsumerStatefulWidget {
  const OnboardingPhoneValidationScreen({super.key, required this.session});

  final DriverOnboardingSession session;

  @override
  ConsumerState<OnboardingPhoneValidationScreen> createState() =>
      _OnboardingPhoneValidationScreenState();
}

class _OnboardingPhoneValidationScreenState
    extends ConsumerState<OnboardingPhoneValidationScreen> {
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _codeReady = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_syncCodeState);
  }

  @override
  void dispose() {
    _codeController.removeListener(_syncCodeState);
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverOnboardingControllerProvider(widget.session));
    final controller = ref.read(
      driverOnboardingControllerProvider(widget.session).notifier,
    );

    return _ValidationLayout(
      title: 'Celular',
      headline: 'Verificação de Celular',
      description:
          'Enviamos um código de 6 dígitos para o seu celular. Por favor, digite-o abaixo para confirmar.',
      stepLabel: 'Onboarding',
      currentStep: 3,
      totalSteps: 7,
      codeController: _codeController,
      isLoading: state.isSubmitting,
      error: state.error,
      codeSent: _codeSent,
      codeReady: _codeReady,
      onSendCode: () async {
        final ok = await controller.sendPhoneCode();
        if (!mounted) return;
        if (ok) {
          setState(() => _codeSent = true);
        }
      },
      onSubmit: () async {
        final ok = await controller.verifyPhoneCode(
          _codeController.text.trim(),
        );
        if (!context.mounted) return;
        if (ok) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _syncCodeState() {
    final ready = _codeController.text.trim().length == 6;
    if (ready != _codeReady && mounted) {
      setState(() => _codeReady = ready);
    }
  }
}

// ==============================================================
// WIDGET DO LAYOUT PRINCIPAL (REAPROVEITADO PARA AS DUAS TELAS)
// ==============================================================
class _ValidationLayout extends StatelessWidget {
  const _ValidationLayout({
    required this.title,
    required this.headline,
    required this.description,
    required this.stepLabel,
    required this.currentStep,
    required this.totalSteps,
    required this.codeController,
    required this.isLoading,
    required this.error,
    required this.codeSent,
    required this.codeReady,
    required this.onSendCode,
    required this.onSubmit,
  });

  final String title;
  final String headline;
  final String description;
  final String stepLabel;
  final int currentStep;
  final int totalSteps;
  final TextEditingController codeController;
  final bool isLoading;
  final String? error;
  final bool codeSent;
  final bool codeReady;
  final VoidCallback onSendCode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _onboardingBg,
      appBar: AppBar(
        backgroundColor: _onboardingBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stepLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$currentStep de $totalSteps',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: currentStep / totalSteps,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF27272A),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _onboardingPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: _onboardingSubtitle,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ==========================================
                    // LAYOUT ESTÁTICO DO CÓDIGO (Como solicitado)
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 45,
                          height: 50,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFF334155),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '0',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                color: Colors.white.withValues(alpha: 0.3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    // ==========================================
                    const SizedBox(height: 32),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Reenviar código em ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _onboardingSubtitle,
                          ),
                          children: [
                            TextSpan(
                              text: '01:00',
                              style: GoogleFonts.inter(
                                color: _onboardingPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading || !codeReady ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _onboardingPrimary,
                    disabledBackgroundColor: _onboardingPrimary.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      isLoading
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
                            'Confirmar',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
