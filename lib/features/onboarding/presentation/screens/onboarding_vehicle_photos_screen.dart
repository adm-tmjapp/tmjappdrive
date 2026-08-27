import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/onboarding_providers.dart';
import '../../domain/onboarding_models.dart';
import '../widgets/onboarding_ui.dart';

class OnboardingVehiclePhotosScreen extends ConsumerStatefulWidget {
  const OnboardingVehiclePhotosScreen({super.key, required this.session});

  final DriverOnboardingSession session;

  @override
  ConsumerState<OnboardingVehiclePhotosScreen> createState() =>
      _OnboardingVehiclePhotosScreenState();
}

enum _VehiclePhotoStep { front, back, interior }

class _OnboardingVehiclePhotosScreenState
    extends ConsumerState<OnboardingVehiclePhotosScreen> {
  final _picker = ImagePicker();
  File? _front;
  File? _back;
  File? _interior;
  _VehiclePhotoStep _currentStep = _VehiclePhotoStep.front;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverOnboardingControllerProvider(widget.session));
    final controller = ref.read(
      driverOnboardingControllerProvider(widget.session).notifier,
    );
    final stepMeta = _stepMeta(_currentStep);
    final currentFile = _fileFor(_currentStep);
    final allReady = _front != null && _back != null && _interior != null;

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Cor de fundo do Figma
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        title: Text(
          'Foto do Veículo',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // BARRA DE PROGRESSO "PASSO X DE Y"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                        'Passo 7 de 7', // Mantido como na imagem do Figma
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: onboardingPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: onboardingPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: onboardingPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // CONTEÚDO PRINCIPAL SCROLLÁVEL
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                children: [
                  Text(
                    stepMeta.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8),
                      ),
                      children: [
                        TextSpan(text: stepMeta.descriptionPrefix),
                        TextSpan(
                          text: stepMeta.highlight,
                          style: GoogleFonts.inter(
                            color: onboardingPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: stepMeta.descriptionSuffix),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CONTAINER DA FOTO / SILHUETA
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF101217),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child:
                                currentFile == null
                                    ? _VehicleGuide(step: _currentStep)
                                    : ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file(
                                        currentFile,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                          ),
                          // Ícone de Flash do Mockup (Visual Apenas)
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flash_off,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // DICA / INFORMAÇÃO ABAIXO DA FOTO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: onboardingPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          stepMeta.tip,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFA1A1AA),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (state.error != null) ...[
                    const SizedBox(height: 24),
                    OnboardingInlineFeedback(
                      message: state.error!,
                      isError: true,
                    ),
                  ],
                ],
              ),
            ),

            // BOTÕES DE AÇÃO NO RODAPÉ
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          allReady
                              ? () async {
                                final ok = await controller.uploadVehiclePhotos(
                                  DriverOnboardingVehiclePhotosInput(
                                    front: _front!,
                                    back: _back!,
                                    interior: _interior!,
                                  ),
                                );
                                if (!context.mounted) return;
                                if (ok) {
                                  Navigator.of(context).popUntil(
                                    (route) =>
                                        route.isFirst ||
                                        route.settings.name == '/onboarding',
                                  );
                                }
                              }
                              : () => _pick(_currentStep, ImageSource.camera),
                      icon:
                          state.isSubmitting
                              ? const SizedBox.shrink()
                              : Icon(
                                allReady
                                    ? Icons.check_circle_outline
                                    : Icons.photo_camera_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                      label:
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
                                allReady ? 'Finalizar envio' : 'Capturar Foto',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed:
                          state.isSubmitting
                              ? null
                              : () => _pick(_currentStep, ImageSource.gallery),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF27272A),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Escolher da Galeria',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  File? _fileFor(_VehiclePhotoStep step) {
    switch (step) {
      case _VehiclePhotoStep.front:
        return _front;
      case _VehiclePhotoStep.back:
        return _back;
      case _VehiclePhotoStep.interior:
        return _interior;
    }
  }

  Future<void> _pick(_VehiclePhotoStep step, ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1920,
    );
    if (image == null) return;
    setState(() {
      final file = File(image.path);
      switch (step) {
        case _VehiclePhotoStep.front:
          _front = file;
          if (_back == null) {
            _currentStep = _VehiclePhotoStep.back;
          }
          break;
        case _VehiclePhotoStep.back:
          _back = file;
          if (_interior == null) {
            _currentStep = _VehiclePhotoStep.interior;
          }
          break;
        case _VehiclePhotoStep.interior:
          _interior = file;
          break;
      }
    });
  }
}

class _VehiclePhotoMeta {
  const _VehiclePhotoMeta({
    required this.title,
    required this.descriptionPrefix,
    required this.highlight,
    required this.descriptionSuffix,
    required this.tip,
  });

  final String title;
  final String descriptionPrefix;
  final String highlight;
  final String descriptionSuffix;
  final String tip;
}

_VehiclePhotoMeta _stepMeta(_VehiclePhotoStep step) {
  switch (step) {
    case _VehiclePhotoStep.front:
      return const _VehiclePhotoMeta(
        title: 'Tire uma foto da frente',
        descriptionPrefix:
            'Posicione o veículo dentro da silhueta. A placa deve estar ',
        highlight: 'visível e legível',
        descriptionSuffix: '.',
        tip: 'Evite reflexos e sombras sobre a placa',
      );
    case _VehiclePhotoStep.back:
      return const _VehiclePhotoMeta(
        title: 'Agora fotografe a traseira',
        descriptionPrefix:
            'Mostre a traseira completa do veículo e mantenha a placa ',
        highlight: 'centralizada',
        descriptionSuffix: '.',
        tip: 'Garanta que a placa e lanternas apareçam por inteiro',
      );
    case _VehiclePhotoStep.interior:
      return const _VehiclePhotoMeta(
        title: 'Finalize com o interior',
        descriptionPrefix: 'Mostre bancos e painel com ',
        highlight: 'boa iluminação',
        descriptionSuffix: ' para concluir o cadastro.',
        tip: 'Evite objetos cobrindo bancos, portas e painel',
      );
  }
}

// Widget da silhueta adaptado para o design do Figma
class _VehicleGuide extends StatelessWidget {
  const _VehicleGuide({required this.step});

  final _VehiclePhotoStep step;

  @override
  Widget build(BuildContext context) {
    final plateGuide = step != _VehiclePhotoStep.interior;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Representação da linha da silhueta principal
        Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: onboardingPrimary.withValues(alpha: 0.5),
              width: 2.5,
            ),
          ),
        ),
        Icon(
          step == _VehiclePhotoStep.interior
              ? Icons.airline_seat_recline_normal_rounded
              : Icons.directions_car_rounded,
          size: 140,
          color: onboardingPrimary.withValues(alpha: 0.15),
        ),
        // Guia da placa (Apenas nas fotos externas)
        if (plateGuide)
          Positioned(
            bottom: 44,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                // Usa um Dashed Border se tiver um CustomPainter, ou solid como fallback
                border: Border.all(
                  color: onboardingPrimary.withValues(alpha: 0.8),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
                color: onboardingPrimary.withValues(alpha: 0.1),
              ),
              child: Text(
                'PLACA AQUI',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: onboardingPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
