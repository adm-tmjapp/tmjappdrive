import 'package:flutter/foundation.dart';

enum DriverAvailability { online, offline }

enum DashboardPeriod { weekly, biweekly, monthly }

@immutable
class DashboardFilters {
  final bool highPriorityOnly;
  final bool passengerOnly;
  final DashboardPeriod period;

  const DashboardFilters({
    this.highPriorityOnly = false,
    this.passengerOnly = false,
    this.period = DashboardPeriod.weekly,
  });

  DashboardFilters copyWith({
    bool? highPriorityOnly,
    bool? passengerOnly,
    DashboardPeriod? period,
  }) {
    return DashboardFilters(
      highPriorityOnly: highPriorityOnly ?? this.highPriorityOnly,
      passengerOnly: passengerOnly ?? this.passengerOnly,
      period: period ?? this.period,
    );
  }
}

@immutable
class RideCardItem {
  final String id;
  final String status;
  final String type;
  final String route;
  final String details;
  final String price;
  final bool isHighPriority;
  final bool isPassenger;
  final String pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final double distanceKm;
  final int etaMin;
  final String paymentMethodLabel;
  final String passengerName;
  final String? passengerPhotoUrl;
  final String passengerPhone;
  final double? passengerRating;
  final int? dispatchTimeoutMs;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? arrivedAt;
  final DateTime? pickedUpAt;
  final DateTime? completedAt;

  const RideCardItem({
    required this.id,
    required this.status,
    required this.type,
    required this.route,
    required this.details,
    required this.price,
    required this.isHighPriority,
    required this.isPassenger,
    required this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    required this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    required this.distanceKm,
    required this.etaMin,
    required this.paymentMethodLabel,
    required this.passengerName,
    this.passengerPhotoUrl,
    required this.passengerPhone,
    this.passengerRating,
    this.dispatchTimeoutMs,
    this.startedAt,
    this.expiresAt,
    this.arrivedAt,
    this.pickedUpAt,
    this.completedAt,
  });

  RideCardItem copyWith({
    String? id,
    String? status,
    String? type,
    String? route,
    String? details,
    String? price,
    bool? isHighPriority,
    bool? isPassenger,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
    double? distanceKm,
    int? etaMin,
    String? paymentMethodLabel,
    String? passengerName,
    String? passengerPhotoUrl,
    String? passengerPhone,
    double? passengerRating,
    int? dispatchTimeoutMs,
    DateTime? startedAt,
    DateTime? expiresAt,
    DateTime? arrivedAt,
    DateTime? pickedUpAt,
    DateTime? completedAt,
  }) {
    return RideCardItem(
      id: id ?? this.id,
      status: status ?? this.status,
      type: type ?? this.type,
      route: route ?? this.route,
      details: details ?? this.details,
      price: price ?? this.price,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      isPassenger: isPassenger ?? this.isPassenger,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMin: etaMin ?? this.etaMin,
      paymentMethodLabel: paymentMethodLabel ?? this.paymentMethodLabel,
      passengerName: passengerName ?? this.passengerName,
      passengerPhotoUrl: passengerPhotoUrl ?? this.passengerPhotoUrl,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerRating: passengerRating ?? this.passengerRating,
      dispatchTimeoutMs: dispatchTimeoutMs ?? this.dispatchTimeoutMs,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

@immutable
class DashboardSummary {
  final int todayRides;
  final String todayEarnings;
  final int progressPercent;

  const DashboardSummary({
    required this.todayRides,
    required this.todayEarnings,
    required this.progressPercent,
  });
}

@immutable
class DashboardSnapshot {
  final DriverAvailability availability;
  final DashboardSummary summary;
  final List<RideCardItem> rides;

  const DashboardSnapshot({
    required this.availability,
    required this.summary,
    required this.rides,
  });

  DashboardSnapshot copyWith({
    DriverAvailability? availability,
    DashboardSummary? summary,
    List<RideCardItem>? rides,
  }) {
    return DashboardSnapshot(
      availability: availability ?? this.availability,
      summary: summary ?? this.summary,
      rides: rides ?? this.rides,
    );
  }
}
