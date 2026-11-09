import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/onboarding_ui.dart';

/// In-app camera used for proof-of-life captures.
///
/// Keeping the capture inside the Flutter activity avoids depending on the
/// device's external camera application, which can terminate the app's
/// activity on lower-memory Android devices while it is in the background.
class OnboardingSelfieCameraScreen extends StatefulWidget {
  const OnboardingSelfieCameraScreen({super.key});

  @override
  State<OnboardingSelfieCameraScreen> createState() =>
      _OnboardingSelfieCameraScreenState();
}

class _OnboardingSelfieCameraScreenState
    extends State<OnboardingSelfieCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  String? _error;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      controller.dispose();
      _controller = null;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_controller?.value.isInitialized == true) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'no_camera',
          'Nenhuma câmera disponível neste dispositivo.',
        );
      }

      _camera ??= cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() => _error = _cameraErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _error =
                'Não foi possível abrir a câmera. Verifique a câmera e tente novamente.',
      );
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final image = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(File(image.path));
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _error = _cameraErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _error = 'Não foi possível registrar a selfie. Tente novamente.';
      });
    }
  }

  String _cameraErrorMessage(CameraException error) {
    if (error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt') {
      return 'Permita o acesso à câmera para registrar a prova de vida.';
    }
    if (error.code == 'CameraAccessRestricted') {
      return 'O acesso à câmera está restrito neste dispositivo.';
    }
    return error.description ??
        'Não foi possível abrir a câmera. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller?.value.isInitialized == true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isReady) CameraPreview(controller!) else const SizedBox(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.62),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0, 0.32, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.38),
                ),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              top: 26,
              left: 72,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prova de vida',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Segure sua CNH aberta ao lado do rosto.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _CameraErrorCard(
                    message: _error!,
                    onRetry: () {
                      setState(() => _error = null);
                      _initializeCamera();
                    },
                  ),
                ),
              )
            else if (!isReady)
              const Center(
                child: CircularProgressIndicator(color: onboardingPrimary),
              ),
            Positioned(
              bottom: 34,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Capturar selfie de prova de vida',
                  child: InkWell(
                    onTap: isReady ? _capture : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 78,
                      height: 78,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _isCapturing ? Colors.white54 : onboardingPrimary,
                        ),
                        child:
                            _isCapturing
                                ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                      ),
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

class _CameraErrorCard extends StatelessWidget {
  const _CameraErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F141E),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: onboardingPrimary,
              size: 38,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: onboardingPrimary),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
