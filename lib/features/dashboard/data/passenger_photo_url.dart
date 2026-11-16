import '../../../config/app_env.dart';

/// Converte o contrato de foto usado pelo aplicativo do passageiro em uma
/// URL que possa ser exibida pelo motorista. A API pode devolver o arquivo no
/// próprio passageiro, no perfil aninhado ou como caminho relativo.
String? resolvePassengerPhotoUrl(Object? passenger, {Object? ride}) {
  final value = _firstValue(
    <Object?>[passenger, ride],
    const <String>[
      'profilePhotoUrl',
      'profile_photo_url',
      'profilePhoto',
      'profile_photo',
      'photoUrl',
      'photo_url',
      'photo',
      'avatarUrl',
      'avatar_url',
      'avatar',
      'imageUrl',
      'image_url',
      'image',
      'profileImage',
      'profile_image',
      'photoPath',
      'photo_path',
      'avatarPath',
      'avatar_path',
      'imagePath',
      'image_path',
      'pictureUrl',
      'picture_url',
      'picture',
      'passengerPhotoUrl',
      'passenger_photo_url',
      'passengerPhoto',
      'passenger_photo',
      'passengerAvatarUrl',
      'passenger_avatar_url',
      'passengerProfilePhotoUrl',
      'passenger_profile_photo_url',
      'riderPhotoUrl',
      'rider_photo_url',
    ],
  );
  final photoValue = _photoValue(value);
  if (photoValue == null) return null;

  final raw = photoValue.trim();
  if (raw.isEmpty || raw.startsWith('data:')) return null;
  final parsed = Uri.tryParse(raw);
  if (parsed == null) return null;
  if (parsed.hasScheme) return parsed.toString();
  if (raw.startsWith('//')) return 'https:$raw';

  final apiBase = Uri.parse(AppEnv.apiBaseUrl);
  final origin = apiBase.replace(path: '/', query: null, fragment: null);
  return origin.resolve(raw.startsWith('/') ? raw : '/$raw').toString();
}

String resolvePassengerName(Object? passenger, {Object? ride}) {
  final maps = _relatedMaps(<Object?>[passenger, ride]);
  final name = _firstValueFromMaps(maps, const <String>[
    'name',
    'fullName',
    'full_name',
    'displayName',
    'display_name',
    'passengerName',
    'passenger_name',
    'riderName',
    'rider_name',
    'customerName',
    'customer_name',
  ]);
  if (name != null) return name.toString().trim();

  for (final map in maps) {
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
  return _text(
    _firstValue(
      <Object?>[passenger, ride],
      const <String>[
        'phone',
        'phoneNumber',
        'phone_number',
        'passengerPhone',
        'passenger_phone',
        'riderPhone',
        'customerPhone',
      ],
    ),
  );
}

Object? _firstValue(List<Object?> sources, List<String> keys) =>
    _firstValueFromMaps(_relatedMaps(sources), keys);

Object? _firstValueFromMaps(
  List<Map<String, dynamic>> maps,
  List<String> keys,
) {
  for (final map in maps) {
    final value = _firstPresent(keys.map((key) => map[key]).toList());
    if (value != null) return value;
  }
  return null;
}

/// O contrato da corrida pode colocar o passageiro dentro de `data`, `user`,
/// `profile`, `rider` ou `customer`. Percorremos somente esses invólucros
/// conhecidos para não depender de uma única versão da API.
List<Map<String, dynamic>> _relatedMaps(List<Object?> sources) {
  const nestedKeys = <String>[
    'data',
    'passenger',
    'rider',
    'customer',
    'passengerProfile',
    'passengerUser',
    'profile',
    'user',
  ];
  final result = <Map<String, dynamic>>[];
  final pending = <Map<String, dynamic>>[
    for (final source in sources) _asMap(source),
  ];
  final seen = <Map<String, dynamic>>{};

  while (pending.isNotEmpty && result.length < 24) {
    final map = pending.removeAt(0);
    if (map.isEmpty || !seen.add(map)) continue;
    result.add(map);
    for (final key in nestedKeys) {
      final nested = _asMap(map[key]);
      if (nested.isNotEmpty) pending.add(nested);
    }
  }
  return result;
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
