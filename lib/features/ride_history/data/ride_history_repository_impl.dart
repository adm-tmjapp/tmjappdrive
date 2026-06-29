import 'dart:io';

import '../domain/ride_history_models.dart';
import '../domain/ride_history_repository.dart';
import 'ride_history_api.dart';

class RideHistoryRepositoryImpl implements RideHistoryRepository {
  RideHistoryRepositoryImpl({required RideHistoryApi api}) : _api = api;

  final RideHistoryApi _api;

  @override
  Future<RideHistorySummary> getSummary({
    required RideHistoryRange range,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.fetchSummary(
      range: range,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<RideHistoryItem>> getHistory({
    required RideHistoryRange range,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.fetchHistory(
      range: range,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<RideHistoryDetail> getHistoryDetail(String rideId) {
    return _api.getHistoryDetail(rideId);
  }

  @override
  Future<List<RideSupportOption>> getSupportOptions(String rideId) {
    return _api.getSupportOptions(rideId);
  }

  @override
  Future<RideSupportTicketResult> createSupportTicket({
    required String rideId,
    required RideSupportIssueCode issueCode,
    required String subject,
    String? description,
    List<String> attachments = const <String>[],
  }) {
    return _api.createSupportTicket(
      rideId: rideId,
      issueCode: issueCode,
      subject: subject,
      description: description,
      attachments: attachments,
    );
  }

  @override
  Future<RideSupportTicketResult> createPaymentIssue({
    required String rideId,
    required double expectedAmount,
    required double receivedAmount,
    String? description,
    List<String> attachments = const <String>[],
  }) {
    return _api.createPaymentIssue(
      rideId: rideId,
      expectedAmount: expectedAmount,
      receivedAmount: receivedAmount,
      description: description,
      attachments: attachments,
    );
  }

  @override
  Future<RideSupportTicketResult> createForgottenObject({
    required String rideId,
    required String description,
    List<String> attachments = const <String>[],
  }) {
    return _api.createForgottenObject(
      rideId: rideId,
      description: description,
      attachments: attachments,
    );
  }

  @override
  Future<RidePassengerAbsentResult> createPassengerAbsent({
    required String rideId,
    required bool waitedMoreThan5Minutes,
    required bool calledPassenger,
    required bool messagedPassenger,
    required bool atBoardingPoint,
    required double driverLat,
    required double driverLng,
    String? gpsEvidenceId,
  }) {
    return _api.createPassengerAbsent(
      rideId: rideId,
      waitedMoreThan5Minutes: waitedMoreThan5Minutes,
      calledPassenger: calledPassenger,
      messagedPassenger: messagedPassenger,
      atBoardingPoint: atBoardingPoint,
      driverLat: driverLat,
      driverLng: driverLng,
      gpsEvidenceId: gpsEvidenceId,
    );
  }

  @override
  Future<RideSupportUploadAsset> uploadAttachment(File file) {
    return _api.uploadAttachment(file);
  }

  @override
  Future<RideSupportContact> getSupportContact() {
    return _api.getSupportContact();
  }
}
