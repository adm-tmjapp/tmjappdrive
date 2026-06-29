import 'dart:io';

import 'ride_history_models.dart';

abstract class RideHistoryRepository {
  Future<RideHistorySummary> getSummary({
    required RideHistoryRange range,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<RideHistoryItem>> getHistory({
    required RideHistoryRange range,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<RideHistoryDetail> getHistoryDetail(String rideId);

  Future<List<RideSupportOption>> getSupportOptions(String rideId);

  Future<RideSupportTicketResult> createSupportTicket({
    required String rideId,
    required RideSupportIssueCode issueCode,
    required String subject,
    String? description,
    List<String> attachments = const <String>[],
  });

  Future<RideSupportTicketResult> createPaymentIssue({
    required String rideId,
    required double expectedAmount,
    required double receivedAmount,
    String? description,
    List<String> attachments = const <String>[],
  });

  Future<RideSupportTicketResult> createForgottenObject({
    required String rideId,
    required String description,
    List<String> attachments = const <String>[],
  });

  Future<RidePassengerAbsentResult> createPassengerAbsent({
    required String rideId,
    required bool waitedMoreThan5Minutes,
    required bool calledPassenger,
    required bool messagedPassenger,
    required bool atBoardingPoint,
    required double driverLat,
    required double driverLng,
    String? gpsEvidenceId,
  });

  Future<RideSupportUploadAsset> uploadAttachment(File file);

  Future<RideSupportContact> getSupportContact();
}
