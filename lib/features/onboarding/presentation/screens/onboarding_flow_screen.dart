import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/response_login.dart';
import '../../../../screens/dashboard_screen.dart';
import '../../application/onboarding_providers.dart';
import '../../domain/onboarding_models.dart';
import '../widgets/onboarding_ui.dart';
import 'onboarding_cnh_screen.dart';
import 'onboarding_criminal_record_screen.dart';
import 'onboarding_pending_review_screen.dart';
import 'onboarding_profile_photo_screen.dart';
import 'onboarding_validation_screens.dart';
import 'onboarding_vehicle_data_screen.dart';
import 'onboarding_vehicle_photos_screen.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key, required this.responseLogin});

  final ResponseLogin responseLogin;

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen>
    with WidgetsBindingObserver {
  DriverOnboardingSession get _session =>
      DriverOnboardingSession(responseLogin: widget.responseLogin);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(driverOnboardingControllerProvider(_session).notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverOnboardingControllerProvider(_session));
    final snapshot = state.snapshot;

    ref.listen(driverOnboardingControllerProvider(_session), (previous, next) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      final errorChanged = next.error != null && next.error != previous?.error;
      final successChanged =
          next.successMessage != null &&
          next.successMessage != previous?.successMessage;
      if (errorChanged) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      } else if (successChanged) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: const Color(0xFF166534),
          ),
        );
      }
    });

    if (snapshot?.canDrive == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => DashboardScreen()),
            (route) => false,
          );
        }
      });
    }

    if (state.isLoading && snapshot == null) {
      return const Scaffold(
        backgroundColor: onboardingBg,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: onboardingPrimary),
          ),
        ),
      );
    }
    if (snapshot != null && snapshot.shouldShowPendingReview) {
      return OnboardingPendingReviewScreen(session: _session);
    }
    return Scaffold(
      backgroundColor: onboardingBg,
      body: SafeArea(child: _ChecklistView(session: _session)),
    );
  }
}

class _ChecklistView extends ConsumerWidget {
  const _ChecklistView({required this.session});

  final DriverOnboardingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverOnboardingControllerProvider(session));
    final controller = ref.read(
      driverOnboardingControllerProvider(session).notifier,
    );
    final snapshot = state.snapshot;
    final items =
        snapshot?.checklistItems ?? const <DriverOnboardingChecklistItem>[];
    final progress = snapshot?.progress ?? 0;

    return RefreshIndicator(
      color: onboardingPrimary,
      onRefresh: controller.load,
      child: Stack(
        children: [
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => backToLogin(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Onboarding',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
              const SizedBox(height: 28),
              OnboardingProgressCard(progress: progress),
              const SizedBox(height: 18),
              Text(
                'Complete seu cadastro',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Valide os itens abaixo para começar a dirigir.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: onboardingSubtitle,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              if (state.error != null) ...[
                OnboardingInlineFeedback(message: state.error!, isError: true),
                const SizedBox(height: 16),
              ],
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OnboardingChecklistCard(
                    item: item,
                    onTap: () => _openStep(context, item.type, session),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed:
                    snapshot?.hasSubmittedAllSteps != true
                        ? null
                        : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => OnboardingPendingReviewScreen(
                                    session: session,
                                  ),
                            ),
                          );
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF233148),
                  disabledBackgroundColor: const Color(0xFF233148),
                  foregroundColor: Colors.white.withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Confirmar e Avançar',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openStep(
    BuildContext context,
    DriverOnboardingStepType step,
    DriverOnboardingSession session,
  ) {
    final Widget screen;
    switch (step) {
      case DriverOnboardingStepType.profilePhoto:
        screen = OnboardingProfilePhotoScreen(session: session);
        break;
      case DriverOnboardingStepType.email:
        screen = OnboardingEmailValidationScreen(session: session);
        break;
      case DriverOnboardingStepType.phone:
        screen = OnboardingPhoneValidationScreen(session: session);
        break;
      case DriverOnboardingStepType.cnh:
        screen = OnboardingCnhScreen(session: session);
        break;
      case DriverOnboardingStepType.criminalRecord:
        screen = OnboardingCriminalRecordScreen(session: session);
        break;
      case DriverOnboardingStepType.vehicle:
        screen = OnboardingVehicleDataScreen(session: session);
        break;
      case DriverOnboardingStepType.vehiclePhotos:
        screen = OnboardingVehiclePhotosScreen(session: session);
        break;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
