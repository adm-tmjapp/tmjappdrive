import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/onboarding_providers.dart';
import '../../domain/onboarding_models.dart';
import '../widgets/onboarding_ui.dart';

class OnboardingCriminalRecordScreen extends ConsumerStatefulWidget {
  const OnboardingCriminalRecordScreen({super.key, required this.session});

  final DriverOnboardingSession session;

  @override
  ConsumerState<OnboardingCriminalRecordScreen> createState() =>
      _OnboardingCriminalRecordScreenState();
}

class _OnboardingCriminalRecordScreenState
    extends ConsumerState<OnboardingCriminalRecordScreen> {
  File? _selectedFile;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverOnboardingControllerProvider(widget.session));
    final controller = ref.read(
      driverOnboardingControllerProvider(widget.session).notifier,
    );

    return Scaffold(
      backgroundColor: onboardingBg,
      appBar: AppBar(
        backgroundColor: onboardingBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: Text(
          'Verificação de Segurança',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Row(
                    children: [
                      Text(
                        'Onboarding TMJApp',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Etapa 5 de 7',
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
                    child: const LinearProgressIndicator(
                      value: 5 / 7,
                      minHeight: 6,
                      backgroundColor: Color(0xFF1E293B),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        onboardingPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Antecedentes Criminais',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Para garantir a segurança de todos na plataforma, solicitamos a certidão de antecedentes criminais.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: onboardingSubtitle,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _openGuide,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Como emitir este documento?',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: onboardingPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: onboardingPrimary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SecurityActionCard(
                    title: 'Tirar uma foto',
                    subtitle: 'Capture a imagem do documento impresso',
                    icon: Icons.photo_camera_outlined,
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: 14),
                  _SecurityActionCard(
                    title: 'Carregar PDF',
                    subtitle: 'Selecione o arquivo digital original',
                    icon: Icons.upload_file_outlined,
                    onTap: _pickFile,
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: onboardingPrimary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: onboardingPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedFile!.path.split('/').last,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: onboardingPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Seus dados são protegidos por criptografia de ponta a ponta e processados seguindo a LGPD. O documento será analisado em até 24 horas úteis.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: onboardingSubtitle,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    OnboardingInlineFeedback(
                      message: state.error!,
                      isError: true,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: onboardingBg,
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              child: OnboardingPrimaryButton(
                label: 'Continuar',
                isLoading: state.isSubmitting,
                onTap:
                    _selectedFile == null
                        ? null
                        : () async {
                          final ok = await controller.uploadCriminalRecord(
                            _selectedFile!,
                          );
                          if (!context.mounted) return;
                          if (ok) {
                            Navigator.of(context).pop();
                          }
                        },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGuide() async {
    final uri = Uri.parse(
      'https://www.gov.br/pt-br/servicos/emitir-certidao-de-antecedentes-criminais',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _selectedFile = File(path));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1920,
    );
    if (image == null) return;
    setState(() => _selectedFile = File(image.path));
  }
}

class _SecurityActionCard extends StatelessWidget {
  const _SecurityActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: onboardingPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: onboardingPrimary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: onboardingSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
