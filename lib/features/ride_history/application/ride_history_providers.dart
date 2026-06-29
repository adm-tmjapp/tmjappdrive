import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ride_history_api.dart';
import '../data/ride_history_repository_impl.dart';
import '../domain/ride_history_repository.dart';

final rideHistoryApiProvider = Provider<RideHistoryApi>((ref) {
  return RideHistoryApi();
});

final rideHistoryRepositoryProvider = Provider<RideHistoryRepository>((ref) {
  final api = ref.watch(rideHistoryApiProvider);
  return RideHistoryRepositoryImpl(api: api);
});

final rideHistoryDetailProvider = FutureProvider.family.autoDispose((
  ref,
  String rideId,
) async {
  final repository = ref.watch(rideHistoryRepositoryProvider);
  return repository.getHistoryDetail(rideId);
});

final rideSupportOptionsProvider = FutureProvider.family.autoDispose((
  ref,
  String rideId,
) async {
  final repository = ref.watch(rideHistoryRepositoryProvider);
  return repository.getSupportOptions(rideId);
});
