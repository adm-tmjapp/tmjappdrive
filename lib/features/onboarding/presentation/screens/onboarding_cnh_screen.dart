import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/onboarding_providers.dart';
import '../../domain/onboarding_models.dart';
import '../widgets/onboarding_ui.dart';

class OnboardingCnhScreen extends ConsumerStatefulWidget {
  const OnboardingCnhScreen({super.key, required this.session});

  final DriverOnboardingSession session;

  @override
  ConsumerState<OnboardingCnhScreen> createState() =>
      _OnboardingCnhScreenState();
}

class _OnboardingCnhScreenState extends ConsumerState<OnboardingCnhScreen> {
  final _picker = ImagePicker();
  File? _front;
  File? _back;
  File? _selfie;
  String _pendingKind = 'front';

  @override
  void initState() {
    super.initState();
    _recoverLostImage();
  }

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
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        title: Text(
          'CNH',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
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
                      'Onboarding TMJApp',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Etapa 4 de 7',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: 4 / 7,
                    minHeight: 6,
                    backgroundColor: Color(0xFF27272A),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      onboardingPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  Text(
                    'Documentação CNH',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Por favor, envie fotos legíveis do seu documento original para validação imediata.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: onboardingSubtitle,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _CnhUploadCard(
                    title: 'Foto da frente da CNH',
                    subtitle: 'Lado com a foto e dados principais',
                    file: _front,
                    icon: Icons.upload_outlined,
                    previewIcon: Icons.image_outlined,
                    buttonLabel: 'Enviar foto',
                    onTap: () => _pick('front'),
                  ),
                  const SizedBox(height: 14),
                  _CnhUploadCard(
                    title: 'Foto do verso da CNH',
                    subtitle: 'Lado com as observações e QR Code',
                    file: _back,
                    icon: Icons.upload_outlined,
                    previewIcon: Icons.image_outlined,
                    buttonLabel: 'Enviar foto',
                    onTap: () => _pick('back'),
                  ),
                  const SizedBox(height: 14),
                  _CnhUploadCard(
                    title: 'Prova de vida',
                    subtitle: 'Selfie segurando o documento aberto',
                    file: _selfie,
                    icon: Icons.photo_camera_outlined,
                    previewIcon:
                        Icons.face_outlined, // Ícone de rosto do mockup
                    buttonLabel: 'Tirar Selfie',
                    onTap: () => _pick('selfie', cameraOnly: true),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: onboardingPrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: onboardingPrimary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: onboardingPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Certifique-se de estar em um ambiente bem iluminado. Evite reflexos e sombras sobre os documentos para uma aprovação mais rápida.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: onboardingSubtitle,
                              height: 1.5,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_front == null || _back == null || _selfie == null)
                          ? null
                          : () async {
                            final ok = await controller.uploadCnhDocuments(
                              cnhFront: _front!,
                              cnhBack: _back!,
                              selfie: _selfie!,
                            );
                            if (!context.mounted) return;
                            if (ok) {
                              Navigator.of(context).pop();
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onboardingPrimary,
                    disabledBackgroundColor: onboardingPrimary.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      state.isSubmitting
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
                            'Confirmar e Continuar',
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

  Future<void> _pick(String kind, {bool cameraOnly = false}) async {
    _pendingKind = kind;
    try {
      final picked = await _picker.pickImage(
        source: cameraOnly ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (picked == null) return;
      await _useImage(kind, File(picked.path));
    } catch (_) {
      _showCameraError();
    }
  }

  Future<void> _recoverLostImage() async {
    try {
      final response = await _picker.retrieveLostData();
      final image = response.files?.firstOrNull;
      if (image != null) await _useImage(_pendingKind, File(image.path));
    } catch (_) {
      _showCameraError();
    }
  }

  Future<void> _useImage(String kind, File file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cada arquivo deve ter no máximo 5 MB.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      switch (kind) {
        case 'front':
          _front = file;
          break;
        case 'back':
          _back = file;
          break;
        default:
          _selfie = file;
      }
    });
  }

  void _showCameraError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível recuperar a foto. Tente novamente.'),
      ),
    );
  }
}

class _CnhUploadCard extends StatelessWidget {
  const _CnhUploadCard({
    required this.title,
    required this.subtitle,
    required this.file,
    required this.icon,
    required this.previewIcon,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final File? file;
  final IconData icon;
  final IconData previewIcon;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(
          0xFF0F141E,
        ), // Fundo azul marinho bem escuro do mockup
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 1),
      ),
      child: Row(
        children: [
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
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: onboardingPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18, color: onboardingPrimary),
                        const SizedBox(width: 8),
                        Text(
                          buttonLabel,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: onboardingPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Container de Visualização da Imagem
          SizedBox(
            width: 88,
            height: 88,
            child:
                file == null
                    ? CustomPaint(
                      painter: _DashedBorderPainter(
                        color: const Color(0xFF334155),
                        radius: 14,
                      ),
                      child: Center(
                        child: Icon(
                          previewIcon,
                          color: const Color(0xFF64748B),
                          size: 32,
                        ),
                      ),
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(file!, fit: BoxFit.cover),
                    ),
          ),
        ],
      ),
    );
  }
}

// Pintor customizado para desenhar a borda tracejada exata do Figma
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = Path();

    const dashWidth = 6.0;
    const dashSpace = 5.0;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
