import 'package:flutter/foundation.dart';

@immutable
class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.partnerSince,
    required this.totalRides,
    this.cpfMasked,
    this.profilePhotoUrl,
    this.rating,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String? cpfMasked;
  final String? profilePhotoUrl;
  final DateTime partnerSince;
  final double? rating;
  final int totalRides;
}

@immutable
class DriverProfileVehicle {
  const DriverProfileVehicle({
    required this.id,
    required this.manufacturer,
    required this.modelName,
    required this.vehiclePlate,
    required this.color,
    required this.vehicleType,
    this.year,
    this.status,
    this.documentationStatus,
    this.photoUrl,
  });

  final String id;
  final String manufacturer;
  final String modelName;
  final String? year;
  final String vehiclePlate;
  final String color;
  final String vehicleType;
  final String? status;
  final String? documentationStatus;
  final String? photoUrl;

  String get displayName {
    final yearPart = (year == null || year!.trim().isEmpty) ? '' : ' $year';
    return '$manufacturer $modelName$yearPart'.trim();
  }

  String get displaySubtitle => 'Placa: $vehiclePlate • Cor: $color';

  bool get isActive => (status ?? '').toUpperCase() == 'ACTIVE';
}

@immutable
class DriverProfileCreateVehicleInput {
  const DriverProfileCreateVehicleInput({
    required this.manufacturer,
    required this.modelName,
    required this.year,
    required this.vehiclePlate,
    required this.color,
    required this.vehicleType,
    this.photoPath,
  });

  final String manufacturer;
  final String modelName;
  final String year;
  final String vehiclePlate;
  final String color;
  final String vehicleType;
  final String? photoPath;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'manufacturer': manufacturer,
      'modelName': modelName,
      'year': year,
      'vehiclePlate': vehiclePlate,
      'color': color,
      'vehicleType': vehicleType,
    };
  }
}

@immutable
class DriverProfileDocumentItem {
  const DriverProfileDocumentItem({
    required this.status,
    this.url,
    this.fileName,
    this.uploadedAt,
    this.reviewedAt,
    this.reason,
  });

  final String status;
  final String? url;
  final String? fileName;
  final DateTime? uploadedAt;
  final DateTime? reviewedAt;
  final String? reason;
}

@immutable
class DriverVehicleDocumentItem {
  const DriverVehicleDocumentItem({
    required this.type,
    required this.status,
    this.url,
    this.reason,
    this.fileName,
    this.uploadedAt,
    this.reviewedAt,
  });

  final String type;
  final String status;
  final String? url;
  final String? reason;
  final String? fileName;
  final DateTime? uploadedAt;
  final DateTime? reviewedAt;
}

@immutable
class DriverProfileDocuments {
  const DriverProfileDocuments({
    required this.cnhFront,
    required this.cnhBack,
    required this.selfie,
    required this.profilePhoto,
    required this.residenceProof,
    required this.criminalRecord,
  });

  final DriverProfileDocumentItem cnhFront;
  final DriverProfileDocumentItem cnhBack;
  final DriverProfileDocumentItem selfie;
  final DriverProfileDocumentItem profilePhoto;
  final DriverProfileDocumentItem residenceProof;
  final DriverProfileDocumentItem criminalRecord;
}

@immutable
class DriverProfileSecurity {
  const DriverProfileSecurity({
    required this.privacyPolicyUrl,
    required this.termsUrl,
    required this.appVersion,
  });

  final String privacyPolicyUrl;
  final String termsUrl;
  final String appVersion;
}

@immutable
class DriverProfilePayload {
  const DriverProfilePayload({
    required this.profile,
    required this.documents,
    required this.security,
    required this.vehicles,
    this.address,
    this.vehicle,
  });

  final DriverProfile profile;
  final DriverProfileVehicle? vehicle;
  final List<DriverProfileVehicle> vehicles;
  final DriverProfileDocuments documents;
  final DriverProfileSecurity security;
  final DriverProfileAddress? address;
}

@immutable
class DriverProfileAddress {
  const DriverProfileAddress({
    required this.formattedAddress,
    this.street,
    this.number,
    this.district,
    this.city,
    this.state,
    this.zipCode,
    this.complement,
    this.latitude,
    this.longitude,
    this.label,
    this.id,
  });

  final String formattedAddress;
  final String? street;
  final String? number;
  final String? district;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? complement;
  final double? latitude;
  final double? longitude;
  final String? label;
  final String? id;

  String get title {
    if (street != null && street!.trim().isNotEmpty) {
      final numberPart =
          (number == null || number!.trim().isEmpty) ? '' : ', $number';
      return '${street!.trim()}$numberPart';
    }
    final raw = formattedAddress.trim();
    if (!raw.contains(' - ')) return raw;
    return raw.split(' - ').first.trim();
  }

  String get subtitle {
    final parts = <String>[
      if (district != null && district!.trim().isNotEmpty) district!.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      if (state != null && state!.trim().isNotEmpty) state!.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    if (!formattedAddress.contains(' - ')) return formattedAddress;
    return formattedAddress.split(' - ').skip(1).join(' - ').trim();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'street': street,
      'number': number,
      'district': district,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'complement': complement,
      'latitude': latitude,
      'longitude': longitude,
      'formattedAddress': formattedAddress,
    };
  }
}

@immutable
class DriverProfileUpdateInput {
  const DriverProfileUpdateInput({
    required this.name,
    required this.email,
    required this.phone,
    required this.cpf,
  });

  final String name;
  final String email;
  final String phone;
  final String cpf;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'cpf': cpf,
    };
  }
}
