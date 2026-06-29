import 'package:flutter/foundation.dart';

enum RideHistoryRange { week, month, custom }

enum RideSupportIssueCode {
  forgottenObject,
  paymentIssue,
  securityIncident,
  passengerAbsent,
  other,
}

@immutable
class RideHistorySummary {
  const RideHistorySummary({
    required this.totalBilled,
    required this.totalRides,
    required this.billedGrowthLabel,
    required this.ridesGrowthLabel,
  });

  final double totalBilled;
  final int totalRides;
  final String billedGrowthLabel;
  final String ridesGrowthLabel;
}

@immutable
class RideHistoryItem {
  const RideHistoryItem({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.origin,
    required this.destination,
    required this.netAmount,
    required this.grossAmount,
    required this.appFee,
    required this.paymentMethod,
    this.statusLabel = 'FINALIZADA',
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final String origin;
  final String destination;
  final double netAmount;
  final double grossAmount;
  final double appFee;
  final String paymentMethod;
  final String statusLabel;

  Duration get duration => endedAt.difference(startedAt);
}

@immutable
class RideHistoryDetail {
  const RideHistoryDetail({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.distanceKm,
    required this.originAddress,
    required this.destinationAddress,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.grossAmount,
    required this.appFee,
    required this.netAmount,
    required this.paymentMethodLabel,
    required this.polyline,
  });

  final String id;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final double distanceKm;
  final String? originAddress;
  final String? destinationAddress;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final double grossAmount;
  final double appFee;
  final double netAmount;
  final String paymentMethodLabel;
  final String? polyline;
}

@immutable
class RideSupportOption {
  const RideSupportOption({
    required this.code,
    required this.label,
    required this.enabled,
  });

  final RideSupportIssueCode code;
  final String label;
  final bool enabled;
}

@immutable
class RideSupportTicketResult {
  const RideSupportTicketResult({
    required this.ticketId,
    required this.status,
    required this.createdAt,
    this.message,
  });

  final String ticketId;
  final String status;
  final DateTime createdAt;
  final String? message;
}

@immutable
class RidePassengerAbsentResult {
  const RidePassengerAbsentResult({
    required this.requestId,
    required this.status,
    required this.createdAt,
    required this.penaltyWaiverRequested,
  });

  final String requestId;
  final String status;
  final DateTime createdAt;
  final bool penaltyWaiverRequested;
}

@immutable
class RideSupportContact {
  const RideSupportContact({
    required this.channel,
    required this.phone,
    required this.whatsApp,
    required this.chatUrl,
    required this.availability,
  });

  final String channel;
  final String? phone;
  final String? whatsApp;
  final String? chatUrl;
  final String availability;
}

@immutable
class RideSupportUploadAsset {
  const RideSupportUploadAsset({
    required this.fileId,
    required this.url,
    required this.mimeType,
    required this.size,
  });

  final String fileId;
  final String url;
  final String mimeType;
  final int size;
}
