import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../screens/auth/sign_in_screen.dart';
import '../../domain/onboarding_models.dart';

const onboardingBg = Color(0xFF000000);
const onboardingCard = Color(0xFF0B0F16);
const onboardingField = Color(0xFF0F172A);
const onboardingFieldBorder = Color(0xFF1F2937);
const onboardingPrimary = Color(0xFFC62F78);
const onboardingSubtitle = Color(0xFF94A3B8);
const onboardingHint = Color(0xFF64748B);

void backToLogin(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const SignInScreen()),
    (route) => false,
  );
}

class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
  });

  final String title;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBg,
      appBar: AppBar(
        backgroundColor: onboardingBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: onBack ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: child,
    );
  }
}

class OnboardingChecklistCard extends StatelessWidget {
  const OnboardingChecklistCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final DriverOnboardingChecklistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta(item.status);
    final icon = _stepIcon(item.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: meta.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: meta.foreground, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: meta.labelColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              meta.trailingIcon,
              color: meta.trailingColor,
              size: meta.trailingIcon == Icons.check_circle ? 22 : 20,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingProgressCard extends StatelessWidget {
  const OnboardingProgressCard({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    onboardingPrimary,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OnboardingUploadPreviewCard extends StatelessWidget {
  const OnboardingUploadPreviewCard({
    super.key,
    required this.icon,
    required this.file,
    required this.placeholder,
    required this.height,
  });

  final IconData icon;
  final File? file;
  final String placeholder;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF160710),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onboardingPrimary.withValues(alpha: 0.45)),
      ),
      child:
          file == null
              ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: onboardingPrimary.withValues(alpha: 0.16),
                    ),
                    child: Icon(icon, color: onboardingPrimary, size: 42),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      placeholder,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: onboardingSubtitle,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              )
              : ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  file!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
    );
  }
}

class OnboardingDocumentSectionCard extends StatelessWidget {
  const OnboardingDocumentSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onTap,
    required this.actionLabel,
    required this.icon,
    this.placeholder,
  });

  final String title;
  final String subtitle;
  final File? file;
  final VoidCallback onTap;
  final String actionLabel;
  final IconData icon;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF140710),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: onboardingPrimary.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 14, color: onboardingSubtitle),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2A0A1C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: onboardingPrimary.withValues(alpha: 0.55),
              ),
            ),
            child:
                file == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 42, color: onboardingPrimary),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            placeholder ?? 'Toque para enviar',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        file!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
          ),
          const SizedBox(height: 14),
          OnboardingSecondaryButton(
            icon: icon,
            label: actionLabel,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class OnboardingInfoBanner extends StatelessWidget {
  const OnboardingInfoBanner({
    super.key,
    required this.text,
    this.tone = const Color(0xFF0A2540),
    this.borderColor = const Color(0xFF1D4ED8),
  });

  final String text;
  final Color tone;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingLabeledInput extends StatelessWidget {
  const OnboardingLabeledInput({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 15, color: onboardingHint),
              filled: true,
              fillColor: onboardingField,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: onboardingFieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: onboardingPrimary),
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
}

class OnboardingDropdownField extends StatelessWidget {
  const OnboardingDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: onboardingField,
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: onboardingField,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: onboardingFieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: onboardingPrimary),
            ),
          ),
          items:
              items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: onboardingPrimary,
          disabledBackgroundColor: onboardingPrimary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 14,
          shadowColor: onboardingPrimary.withValues(alpha: 0.30),
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }
}

class OnboardingSecondaryButton extends StatelessWidget {
  const OnboardingSecondaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: onboardingFieldBorder),
          backgroundColor: onboardingField,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class OnboardingInlineFeedback extends StatelessWidget {
  const OnboardingInlineFeedback({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0x33EF4444) : const Color(0x3322C55E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0x66EF4444) : const Color(0x6622C55E),
        ),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class OnboardingCodeValidationView extends StatelessWidget {
  const OnboardingCodeValidationView({
    super.key,
    required this.title,
    required this.headline,
    required this.description,
    required this.codeController,
    required this.isLoading,
    required this.error,
    required this.codeSent,
    required this.codeReady,
    required this.onSendCode,
    required this.onSubmit,
    this.stepLabel = 'Onboarding',
    this.currentStep = 1,
    this.totalSteps = 1,
  });

  final String title;
  final String headline;
  final String description;
  final TextEditingController codeController;
  final bool isLoading;
  final String? error;
  final bool codeSent;
  final bool codeReady;
  final Future<void> Function() onSendCode;
  final Future<void> Function() onSubmit;
  final String stepLabel;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress =
        totalSteps <= 0 ? 0.0 : (currentStep / totalSteps).clamp(0.0, 1.0);

    return OnboardingShell(
      title: title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Row(
            children: [
              Text(
                stepLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                'Etapa $currentStep de $totalSteps',
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
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFF27272A),
              valueColor: const AlwaysStoppedAnimation<Color>(
                onboardingPrimary,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            headline,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: onboardingSubtitle,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 34),
          PinCodeTextField(
            appContext: context,
            controller: codeController,
            length: 6,
            keyboardType: TextInputType.number,
            autoDismissKeyboard: true,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.underline,
              activeColor: onboardingPrimary,
              selectedColor: onboardingPrimary,
              inactiveColor: const Color(0xFF3F3F46),
              fieldHeight: 56,
              fieldWidth: 44,
              activeFillColor: Colors.transparent,
              selectedFillColor: Colors.transparent,
              inactiveFillColor: Colors.transparent,
              borderWidth: 2,
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            enableActiveFill: false,
            onChanged: (_) {},
          ),
          const SizedBox(height: 18),
          Column(
            children: [
              Text(
                codeSent
                    ? 'Nao recebeu o codigo?'
                    : 'Envie o codigo para continuar',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: onboardingSubtitle,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading ? null : () => onSendCode(),
                style: TextButton.styleFrom(
                  foregroundColor: onboardingPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: Text(
                  codeSent ? 'Reenviar codigo agora' : 'Enviar codigo',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: onboardingPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            OnboardingInlineFeedback(message: error!, isError: true),
          ],
          const SizedBox(height: 26),
          OnboardingPrimaryButton(
            label: 'Confirmar',
            isLoading: isLoading,
            onTap: (!codeSent || !codeReady) ? null : () => onSubmit(),
          ),
        ],
      ),
    );
  }
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.background,
    required this.foreground,
    required this.labelColor,
    required this.trailingIcon,
    required this.trailingColor,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color labelColor;
  final IconData trailingIcon;
  final Color trailingColor;
}

_StatusMeta _statusMeta(DriverOnboardingStepStatus status) {
  switch (status) {
    case DriverOnboardingStepStatus.completed:
      return const _StatusMeta(
        label: 'Concluído',
        background: Color(0x33C62F78),
        foreground: Color(0xFFC62F78),
        labelColor: Color(0xFF10D6A2),
        trailingIcon: Icons.check_circle,
        trailingColor: Color(0xFF10D6A2),
      );
    case DriverOnboardingStepStatus.reviewing:
      return const _StatusMeta(
        label: 'Em análise',
        background: Color(0x33C62F78),
        foreground: Color(0xFFC62F78),
        labelColor: Color(0xFFF59E0B),
        trailingIcon: Icons.chevron_right,
        trailingColor: onboardingPrimary,
      );
    case DriverOnboardingStepStatus.pending:
      return const _StatusMeta(
        label: 'Pendente',
        background: Color(0x33C62F78),
        foreground: Color(0xFFC62F78),
        labelColor: Color(0xFF94A3B8),
        trailingIcon: Icons.chevron_right,
        trailingColor: onboardingPrimary,
      );
  }
}

IconData _stepIcon(DriverOnboardingStepType type) {
  switch (type) {
    case DriverOnboardingStepType.profilePhoto:
      return Icons.account_circle_outlined;
    case DriverOnboardingStepType.email:
      return Icons.mail_outline;
    case DriverOnboardingStepType.phone:
      return Icons.smartphone_outlined;
    case DriverOnboardingStepType.cnh:
      return Icons.badge_outlined;
    case DriverOnboardingStepType.criminalRecord:
      return Icons.gavel_outlined;
    case DriverOnboardingStepType.vehicle:
      return Icons.directions_car_outlined;
    case DriverOnboardingStepType.vehiclePhotos:
      return Icons.no_photography_outlined;
  }
}
