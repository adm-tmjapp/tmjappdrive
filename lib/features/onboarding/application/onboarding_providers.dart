import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_api.dart';
import '../../../repository/onboarding_repository.dart' as legacy;
import '../data/onboarding_api.dart';
import '../data/onboarding_repository_impl.dart';
import '../domain/onboarding_models.dart';
import '../domain/onboarding_repository.dart';
import 'onboarding_controller.dart';

final driverOnboardingLegacyRepositoryProvider =
    Provider<legacy.OnboardingRepository>((ref) {
      return legacy.OnboardingRepository();
    });

final driverOnboardingProfileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi();
});

final driverOnboardingApiProvider = Provider<DriverOnboardingApi>((ref) {
  return DriverOnboardingApi(
    legacyRepository: ref.watch(driverOnboardingLegacyRepositoryProvider),
    profileApi: ref.watch(driverOnboardingProfileApiProvider),
  );
});

final driverOnboardingRepositoryProvider = Provider<DriverOnboardingRepository>(
  (ref) {
    return DriverOnboardingRepositoryImpl(
      api: ref.watch(driverOnboardingApiProvider),
    );
  },
);

final driverOnboardingControllerProvider = StateNotifierProvider.autoDispose
    .family<
      DriverOnboardingController,
      DriverOnboardingState,
      DriverOnboardingSession
    >((ref, session) {
      final repository = ref.watch(driverOnboardingRepositoryProvider);
      return DriverOnboardingController(repository, session);
    });
