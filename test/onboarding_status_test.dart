import 'package:flutter_test/flutter_test.dart';
import 'package:tmjappdrive/data/onboardingStatus.dart';
import 'package:tmjappdrive/features/onboarding/domain/onboarding_models.dart';

void main() {
  group('OnboardingStatus', () {
    test('aceita campos camelCase e status booleanos', () {
      final status = OnboardingStatus.fromJson({
        'isCompleted': true,
        'isUnderReview': false,
        'canDrive': true,
        'steps': {
          'profilePhoto': {'completed': true},
          'vehiclePhotos': {'completed': true},
        },
      });

      expect(status.isCompleted, isTrue);
      expect(status.canDrive, isTrue);
      expect(status.steps?.profilePhoto?.completed, isTrue);
      expect(status.steps?.vehiclePhotos?.completed, isTrue);
    });

    test('aceita snake_case, números, textos e etapas simplificadas', () {
      final status = OnboardingStatus.fromJson({
        'is_completed': 1,
        'is_under_review': 'false',
        'can_drive': 'approved',
        'steps': {
          'profile_photo': true,
          'email': 'completed',
          'vehicle_photos': {'completed': 'true'},
        },
      });

      expect(status.isCompleted, isTrue);
      expect(status.isUnderReview, isFalse);
      expect(status.canDrive, isTrue);
      expect(status.steps?.profilePhoto?.completed, isTrue);
      expect(status.steps?.email?.completed, isTrue);
      expect(status.steps?.vehiclePhotos?.completed, isTrue);
    });
  });

  test('snapshot mantém o progresso recebido pelo backend', () {
    final status = OnboardingStatus.fromJson({
      'steps': {
        'profilePhoto': true,
        'email': true,
        'phone': false,
        'documents': false,
        'vehicle': false,
        'vehiclePhotos': false,
      },
    });
    final snapshot = DriverOnboardingSnapshot(
      onboardingStatus: status,
      documents: null,
    );

    expect(snapshot.checklistItems[0].isCompleted, isTrue);
    expect(snapshot.checklistItems[1].isCompleted, isTrue);
    expect(snapshot.progress, closeTo(2 / 7, 0.0001));
    expect(snapshot.hasSubmittedAllSteps, isFalse);
    expect(snapshot.shouldShowPendingReview, isFalse);
  });

  test('análise só aparece depois que todas as etapas foram enviadas', () {
    final incomplete = DriverOnboardingSnapshot(
      onboardingStatus: OnboardingStatus.fromJson({
        'isUnderReview': true,
        'steps': {
          'profilePhoto': {'completed': true},
          'email': {'completed': true},
          'phone': {'completed': true},
          'documents': {'underReview': true},
          'vehicle': {'completed': false},
          'vehiclePhotos': {'completed': false},
        },
      }),
      documents: null,
    );

    expect(incomplete.shouldShowPendingReview, isFalse);
  });
}
