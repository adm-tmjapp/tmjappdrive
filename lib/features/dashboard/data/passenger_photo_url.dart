import '../../../config/app_env.dart';

/// Converte o contrato de foto usado pelo aplicativo do passageiro em uma
/// URL que possa ser exibida pelo motorista. A API pode devolver o arquivo no
/// próprio passageiro, no perfil aninhado ou como caminho relativo.
String? resolvePassengerPhotoUrl(Object? passenger, {Object? ride}) {
  final passengerMap = _asMap(passenger);
  final profile = _asMap(passengerMap['profile']);
  final user = _asMap(passengerMap['user']);
  final rideMap = _asMap(ride);

  final value = _firstPresent(<Object?>[
    passengerMap['profilePhotoUrl'],
    passengerMap['profile_photo_url'],
    passengerMap['profilePhoto'],
    passengerMap['photoUrl'],
    passengerMap['photo_url'],
    passengerMap['avatarUrl'],
    passengerMap['avatar_url'],
    passengerMap['avatar'],
    passengerMap['imageUrl'],
    passengerMap['image_url'],
    passengerMap['image'],
    profile['profilePhotoUrl'],
    profile['profile_photo_url'],
    profile['profilePhoto'],
    profile['photoUrl'],
    profile['photo_url'],
    profile['avatarUrl'],
    profile['avatar_url'],
    profile['avatar'],
    profile['imageUrl'],
    profile['image_url'],
    profile['image'],
    user['profilePhotoUrl'],
    user['profile_photo_url'],
    user['profilePhoto'],
    user['photoUrl'],
    user['photo_url'],
    user['avatarUrl'],
    user['avatar_url'],
    user['avatar'],
    user['imageUrl'],
    user['image_url'],
    user['image'],
    rideMap['passengerPhotoUrl'],
    rideMap['passenger_photo_url'],
    rideMap['passengerPhoto'],
    rideMap['passengerAvatarUrl'],
    rideMap['passenger_avatar_url'],
    rideMap['passengerProfilePhotoUrl'],
    rideMap['passenger_profile_photo_url'],
    rideMap['riderPhotoUrl'],
    rideMap['rider_photo_url'],
  ]);
  final photoValue = _photoValue(value);
  if (photoValue == null) return null;

  final raw = photoValue.trim();
  if (raw.isEmpty || raw.startsWith('data:')) return null;
  final parsed = Uri.tryParse(raw);
  if (parsed == null) return null;
  if (parsed.hasScheme) return parsed.toString();

  final apiBase = Uri.parse(AppEnv.apiBaseUrl);
  final origin = apiBase.replace(path: '/', query: null, fragment: null);
  return origin.resolve(raw.startsWith('/') ? raw : '/$raw').toString();
}

String resolvePassengerName(Object? passenger, {Object? ride}) {
  final passengerMap = _asMap(passenger);
  final profile = _asMap(passengerMap['profile']);
  final user = _asMap(passengerMap['user']);
  final rideMap = _asMap(ride);
  final name = _firstPresent(<Object?>[
    passengerMap['name'],
    passengerMap['fullName'],
    passengerMap['full_name'],
    passengerMap['displayName'],
    passengerMap['display_name'],
    profile['name'],
    profile['fullName'],
    profile['full_name'],
    user['name'],
    user['fullName'],
    user['full_name'],
    user['displayName'],
    rideMap['passengerName'],
    rideMap['passenger_name'],
    rideMap['riderName'],
    rideMap['rider_name'],
    rideMap['customerName'],
    rideMap['customer_name'],
  ]);
  if (name != null) return name.toString().trim();

  for (final map in <Map<String, dynamic>>[passengerMap, profile, user]) {
    final first = _text(map['firstName'] ?? map['first_name']);
    final last = _text(map['lastName'] ?? map['last_name']);
    final fullName = <String>[
      first,
      last,
    ].where((part) => part.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) return fullName;
  }
  return '';
}

String resolvePassengerPhone(Object? passenger, {Object? ride}) {
  final passengerMap = _asMap(passenger);
  final profile = _asMap(passengerMap['profile']);
  final user = _asMap(passengerMap['user']);
  final rideMap = _asMap(ride);
  return _text(
    _firstPresent(<Object?>[
      passengerMap['phone'],
      passengerMap['phoneNumber'],
      passengerMap['phone_number'],
      profile['phone'],
      user['phone'],
      user['phoneNumber'],
      rideMap['passengerPhone'],
      rideMap['passenger_phone'],
      rideMap['riderPhone'],
      rideMap['customerPhone'],
    ]),
  );
}

Object? _firstPresent(List<Object?> values) {
  for (final value in values) {
    if (value != null && value.toString().trim().isNotEmpty) return value;
  }
  return null;
}

String? _photoValue(Object? value) {
  if (value == null) return null;
  if (value is Map) {
    final map = _asMap(value);
    return _photoValue(
      _firstPresent(<Object?>[
        map['url'],
        map['secureUrl'],
        map['secure_url'],
        map['location'],
        map['path'],
        map['fileUrl'],
        map['file_url'],
      ]),
    );
  }
  final raw = value.toString().trim();
  return raw.isEmpty ? null : raw;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

String _text(Object? value) => value?.toString().trim() ?? '';
