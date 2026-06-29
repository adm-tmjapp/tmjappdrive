import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/onboarding_providers.dart';
import '../../domain/onboarding_models.dart';
import '../widgets/onboarding_ui.dart';

class OnboardingProfilePhotoScreen extends ConsumerStatefulWidget {
  const OnboardingProfilePhotoScreen({super.key, required this.session});

  final DriverOnboardingSession session;

  @override
  ConsumerState<OnboardingProfilePhotoScreen> createState() =>
      _OnboardingProfilePhotoScreenState();
}

class _OnboardingProfilePhotoScreenState
    extends ConsumerState<OnboardingProfilePhotoScreen> {
  final _picker = ImagePicker();
  File? _selectedFile;
  static const int _stepNumber = 1;
  static const int _totalSteps = 7;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverOnboardingControllerProvider(widget.session));
    final controller = ref.read(
      driverOnboardingControllerProvider(widget.session).notifier,
    );

    return Scaffold(
      backgroundColor: onboardingBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Verificação de Identidade',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  _OnboardingLinearProgress(
                    currentStep: _stepNumber,
                    totalSteps: _totalSteps,
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Foto de Perfil',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Para sua segurança e dos passageiros, tire uma foto nítida. '
                    'Use boa iluminação, retire óculos escuros ou boné, e centralize seu rosto.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: onboardingSubtitle,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Center(child: _ProfilePhotoPreview(file: _selectedFile)),
                  const SizedBox(height: 28),
                  if (state.error != null) ...[
                    OnboardingInlineFeedback(
                      message: state.error!,
                      isError: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                children: [
                  _PhotoActionButton(
                    icon: Icons.photo_camera_rounded,
                    label: 'Tirar Foto',
                    isPrimary: true,
                    onTap: () => _pick(ImageSource.camera),
                  ),
                  const SizedBox(height: 14),
                  _PhotoActionButton(
                    icon: Icons.image_rounded,
                    label: 'Escolher da Galeria',
                    onTap: () => _pick(ImageSource.gallery),
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 14),
                    OnboardingPrimaryButton(
                      label: 'Continuar',
                      isLoading: state.isSubmitting,
                      onTap: () async {
                        final ok = await controller.uploadProfilePhoto(
                          _selectedFile!,
                        );
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _selectedFile = File(picked.path));
  }
}

class _OnboardingLinearProgress extends StatelessWidget {
  const _OnboardingLinearProgress({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps <= 0 ? 0.0 : currentStep / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Onboarding TMJApp',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.70),
              ),
            ),
            const Spacer(),
            Text(
              'Etapa $currentStep de $totalSteps',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 6,
            backgroundColor: const Color(0xFF22314A),
            valueColor: const AlwaysStoppedAnimation<Color>(onboardingPrimary),
          ),
        ),
      ],
    );
  }
}

class _ProfilePhotoPreview extends StatelessWidget {
  const _ProfilePhotoPreview({required this.file});

  final File? file;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 272,
      height: 272,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 272,
            height: 272,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: onboardingPrimary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: onboardingPrimary.withValues(alpha: 0.32),
                width: 3,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF241A4D), Color(0xFF121A35)],
              ),
            ),
            child: ClipOval(
              child:
                  file == null
                      ? Icon(
                        Icons.person_rounded,
                        size: 124,
                        color: Colors.white.withValues(alpha: 0.18),
                      )
                      : Image.file(
                        file!,
                        fit: BoxFit.cover,
                        width: 236,
                        height: 236,
                      ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: 42,
            child: Container(
              width: 68,
              height: 65,
              decoration: BoxDecoration(
                color: onboardingPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: Colors.white,
                size: 27.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isPrimary ? onboardingPrimary : const Color(0xFF16181D);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: isPrimary ? 0 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side:
                isPrimary
                    ? BorderSide.none
                    : BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
