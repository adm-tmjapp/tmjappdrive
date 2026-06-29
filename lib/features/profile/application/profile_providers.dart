import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_api.dart';
import '../data/profile_repository_impl.dart';
import '../domain/profile_repository.dart';
import 'profile_controller.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final api = ref.watch(profileApiProvider);
  return ProfileRepositoryImpl(api: api);
});

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return ProfileController(repository);
    });
