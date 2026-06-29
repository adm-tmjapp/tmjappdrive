import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';

import '../../../api/base_api.dart';
import '../domain/profile_models.dart';

class ProfileApiException implements Exception {
  const ProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileApi {
  ProfileApi({BaseApi? baseApi}) : _baseApi = baseApi ?? BaseApi();

  final BaseApi _baseApi;

  Future<DriverProfile> getProfile() async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/profile'),
      headers: await _baseApi.getHeaders(),
    );
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao carregar perfil.',
    );

    return DriverProfile(
      id: _asString(payload['id']),
      name: _asString(payload['name']),
      email: _asString(payload['email']),
      phone: _asString(payload['phone']),
      cpfMasked: _nullableString(payload['cpfMasked']),
      profilePhotoUrl: _nullableString(payload['profilePhotoUrl']),
      partnerSince:
          _asDateTimeOrNull(payload['partnerSince']) ?? DateTime(2021, 1, 1),
      rating: _asDoubleOrNull(payload['rating']),
      totalRides: _asInt(payload['totalRides']),
    );
  }

  Future<DriverProfileVehicle?> getVehicle() async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/profile/vehicle'),
      headers: await _baseApi.getHeaders(),
    );

    if (response.statusCode == 404) {
      return null;
    }

    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao carregar veiculo ativo.',
    );

    if (payload.isEmpty) return null;

    return DriverProfileVehicle(
      id: _asString(payload['id']),
      manufacturer: _asString(payload['manufacturer']),
      modelName: _asString(payload['modelName']),
      year: _nullableString(payload['year']),
      vehiclePlate: _asString(payload['vehiclePlate']),
      color: _asString(payload['color']),
      vehicleType: _asString(payload['vehicleType']),
      status: _nullableString(payload['status']),
      documentationStatus: _nullableString(payload['documentationStatus']),
      photoUrl: _nullableString(payload['photoUrl']),
    );
  }

  Future<List<DriverProfileVehicle>> getVehicles() async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/profile/vehicles'),
      headers: await _baseApi.getHeaders(),
    );

    final body = _decodeBody(response.body);
    final status = response.statusCode;

    if (status != 200 && status != 201) {
      throw ProfileApiException(
        _extractErrorMessage(body, 'Falha ao carregar veiculos.'),
      );
    }

    final rawList =
        body['data'] is List
            ? body['data'] as List<dynamic>
            : body['vehicles'] is List
            ? body['vehicles'] as List<dynamic>
            : const <dynamic>[];

    return rawList
        .whereType<Map<dynamic, dynamic>>()
        .map((raw) => _mapVehicle(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<DriverProfileDocuments> getDocuments() async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/profile/documents'),
      headers: await _baseApi.getHeaders(),
    );
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao carregar documentos.',
    );

    DriverProfileDocumentItem mapItem(dynamic raw) {
      final item = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      return DriverProfileDocumentItem(
        status: _asString(item['status']),
        url: _nullableString(item['url']),
        fileName: _nullableString(item['fileName'] ?? item['filename']),
        uploadedAt: _asDateTimeOrNull(item['uploadedAt'] ?? item['createdAt']),
        reviewedAt: _asDateTimeOrNull(item['reviewedAt'] ?? item['updatedAt']),
        reason: _nullableString(item['reason']),
      );
    }

    return DriverProfileDocuments(
      cnhFront: mapItem(
        _pickFirst(payload, const ['cnhFront', 'cnh_front', 'cnhFrente']),
      ),
      cnhBack: mapItem(
        _pickFirst(payload, const ['cnhBack', 'cnh_back', 'cnhVerso']),
      ),
      selfie: mapItem(
        _pickFirst(payload, const ['selfie', 'proofSelfie', 'selfieProvaVida']),
      ),
      profilePhoto: mapItem(
        _pickFirst(payload, const ['profilePhoto', 'profile_photo']),
      ),
      residenceProof: mapItem(
        _pickFirst(payload, const [
          'residenceProof',
          'proofOfResidence',
          'proof_residence',
          'comprovanteResidencia',
        ]),
      ),
      criminalRecord: mapItem(
        _pickFirst(payload, const [
          'criminalRecord',
          'criminalBackground',
          'criminal_record',
          'antecedentesCriminais',
        ]),
      ),
    );
  }

  Future<DriverProfileSecurity> getSecurity() async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/profile/security'),
      headers: await _baseApi.getHeaders(),
    );
    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao carregar dados de seguranca.',
    );

    return DriverProfileSecurity(
      privacyPolicyUrl: _asString(payload['privacyPolicyUrl']),
      termsUrl: _asString(payload['termsUrl']),
      appVersion: _asString(payload['appVersion']),
    );
  }

  Future<DriverProfileAddress?> getAddress() async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/profile/address'),
      headers: await _baseApi.getHeaders(),
    );

    if (response.statusCode == 404) return null;

    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao carregar endereco.',
    );
    if (payload.isEmpty) return null;
    return _mapAddress(payload);
  }

  Future<List<DriverProfileAddress>> searchAddresses(String query) async {
    final response = await _baseApi.get(
      Uri(path: 'v2/locations/search?q=${Uri.encodeQueryComponent(query)}'),
      headers: await _baseApi.getHeaders(),
    );
    final body = _decodeBody(response.body);
    final status = response.statusCode;
    if (status != 200 && status != 201) {
      throw ProfileApiException(
        _extractErrorMessage(body, 'Falha ao buscar enderecos.'),
      );
    }
    final rawList =
        body['data'] is List
            ? body['data'] as List<dynamic>
            : body['addresses'] is List
            ? body['addresses'] as List<dynamic>
            : const <dynamic>[];
    return rawList
        .whereType<Map<dynamic, dynamic>>()
        .map((raw) => _mapAddress(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<List<DriverProfileAddress>> getAddressHistory() async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/profile/address-history'),
      headers: await _baseApi.getHeaders(),
    );
    final body = _decodeBody(response.body);
    final status = response.statusCode;
    if (status == 404) return const <DriverProfileAddress>[];
    if (status != 200 && status != 201) {
      throw ProfileApiException(
        _extractErrorMessage(body, 'Falha ao carregar historico de enderecos.'),
      );
    }
    final rawList =
        body['data'] is List
            ? body['data'] as List<dynamic>
            : body['addresses'] is List
            ? body['addresses'] as List<dynamic>
            : const <dynamic>[];
    return rawList
        .whereType<Map<dynamic, dynamic>>()
        .map((raw) => _mapAddress(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<void> updateAddress(DriverProfileAddress address) async {
    final response = await _baseApi.client.put(
      Uri.parse('${_baseApi.baseUrl}v2/driver/profile/address'),
      headers: await _baseApi.getHeaders(),
      body: jsonEncode(address.toJson()),
    );
    _parsePayload(response, fallbackError: 'Falha ao atualizar endereco.');
  }

  Future<void> updateProfile(DriverProfileUpdateInput input) async {
    final response = await _baseApi.client.put(
      Uri.parse('${_baseApi.baseUrl}v2/driver/profile'),
      headers: await _baseApi.getHeaders(),
      body: jsonEncode(input.toJson()),
    );
    _parsePayload(response, fallbackError: 'Falha ao atualizar perfil.');
  }

  Future<String> createVehicle(DriverProfileCreateVehicleInput input) async {
    final response = await _baseApi.client.post(
      Uri.parse('${_baseApi.baseUrl}v2/driver/profile/vehicles'),
      headers: await _baseApi.getHeaders(),
      body: jsonEncode(<String, dynamic>{
        'manufacturer': input.manufacturer,
        'modelName': input.modelName,
        'year': input.year,
        'vehiclePlate': input.vehiclePlate.toUpperCase(),
        'color': input.color,
        'vehicleType': input.vehicleType,
      }),
    );

    final payload = _parsePayload(
      response,
      fallbackError: 'Falha ao cadastrar veiculo.',
    );
    return _asString(payload['id']);
  }

  Future<void> activateVehicle(String vehicleId) async {
    final response = await _baseApi.client.patch(
      Uri.parse(
        '${_baseApi.baseUrl}v2/driver/profile/vehicles/$vehicleId/activate',
      ),
      headers: await _baseApi.getHeaders(),
    );

    _parsePayload(response, fallbackError: 'Falha ao ativar veiculo.');
  }

  Future<void> uploadVehiclePhoto(String vehicleId, String filePath) async {
    final request = MultipartRequest(
      'POST',
      Uri.parse(
        '${_baseApi.baseUrl}v2/driver/profile/vehicles/$vehicleId/photo',
      ),
    );
    request.files.add(await MultipartFile.fromPath('file', filePath));

    final headers = await _baseApi.getHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    final streamed = await _baseApi.send(request);
    final response = await Response.fromStream(streamed);
    _parsePayload(response, fallbackError: 'Falha ao enviar foto do veiculo.');
  }

  Future<List<DriverVehicleDocumentItem>> getVehicleDocuments(
    String vehicleId,
  ) async {
    final response = await _baseApi.get(
      Uri(path: 'v2/driver/profile/vehicles/$vehicleId/documents'),
      headers: await _baseApi.getHeaders(),
    );

    final body = _decodeBody(response.body);
    final status = response.statusCode;
    if (status != 200 && status != 201) {
      throw ProfileApiException(
        _extractErrorMessage(body, 'Falha ao carregar documentos do veiculo.'),
      );
    }

    final rawList =
        body['documents'] is List
            ? body['documents'] as List<dynamic>
            : body['data'] is List
            ? body['data'] as List<dynamic>
            : const <dynamic>[];

    return rawList
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (raw) => DriverVehicleDocumentItem(
            type: _asString(raw['type']),
            status: _asString(raw['status']),
            url: _nullableString(raw['url']),
            reason: _nullableString(raw['reason']),
            fileName: _nullableString(raw['fileName']),
            uploadedAt: _asDateTimeOrNull(raw['uploadedAt']),
            reviewedAt: _asDateTimeOrNull(raw['reviewedAt']),
          ),
        )
        .toList();
  }

  Future<void> uploadVehicleDocument({
    required String vehicleId,
    required String type,
    required String filePath,
  }) async {
    final request = MultipartRequest(
      'POST',
      Uri.parse(
        '${_baseApi.baseUrl}v2/driver/profile/vehicles/$vehicleId/documents',
      ),
    );
    request.fields['type'] = type;
    request.files.add(await MultipartFile.fromPath('file', filePath));

    final headers = await _baseApi.getHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    final streamed = await _baseApi.send(request);
    final response = await Response.fromStream(streamed);
    _parsePayload(
      response,
      fallbackError: 'Falha ao enviar documento do veiculo.',
    );
  }

  Future<void> uploadProfileDocument({
    required String userId,
    required String type,
    required String filePath,
  }) async {
    final request = MultipartRequest(
      'POST',
      Uri.parse('${_baseApi.baseUrl}driver-documents/upload'),
    );
    request.fields['user'] = userId;
    request.fields['type'] = type;
    request.files.add(await MultipartFile.fromPath('file', filePath));

    final headers = await _baseApi.getHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    final streamed = await _baseApi.send(request);
    final response = await Response.fromStream(streamed);
    _parsePayload(response, fallbackError: 'Falha ao enviar documento.');
  }

  Future<void> uploadCnhDocuments({
    required File cnhFront,
    required File cnhBack,
    required File selfie,
  }) async {
    final request = MultipartRequest(
      'POST',
      Uri.parse('${_baseApi.baseUrl}v2/driver/onboarding/documents'),
    );
    request.files.add(await MultipartFile.fromPath('cnhFront', cnhFront.path));
    request.files.add(await MultipartFile.fromPath('cnhBack', cnhBack.path));
    request.files.add(await MultipartFile.fromPath('selfie', selfie.path));

    final headers = await _baseApi.getHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    final streamed = await _baseApi.send(request);
    final response = await Response.fromStream(streamed);
    _parsePayload(response, fallbackError: 'Falha ao enviar CNH.');
  }

  Future<void> logout() async {
    final response = await _baseApi.client.post(
      Uri.parse('${_baseApi.baseUrl}v2/auth/logout'),
      headers: await _baseApi.getHeaders(),
    );

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401) {
      return;
    }

    _parsePayload(response, fallbackError: 'Falha ao encerrar sessao.');
  }

  Map<String, dynamic> _parsePayload(
    Response response, {
    required String fallbackError,
  }) {
    final body = _decodeBody(response.body);
    final status = response.statusCode;

    if (status == 200 || status == 201) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return body;
    }

    throw ProfileApiException(_extractErrorMessage(body, fallbackError));
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  String _extractErrorMessage(Map<String, dynamic> body, String fallback) {
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    final error = body['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }
    return fallback;
  }

  String _asString(dynamic value) => value?.toString() ?? '';

  String? _nullableString(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return text.trim();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _asDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime? _asDateTimeOrNull(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  DriverProfileVehicle _mapVehicle(Map<String, dynamic> payload) {
    return DriverProfileVehicle(
      id: _asString(payload['id']),
      manufacturer: _asString(payload['manufacturer']),
      modelName: _asString(payload['modelName']),
      year: _nullableString(payload['year']),
      vehiclePlate: _asString(payload['vehiclePlate']),
      color: _asString(payload['color']),
      vehicleType: _asString(payload['vehicleType']),
      status: _nullableString(payload['status']),
      documentationStatus: _nullableString(payload['documentationStatus']),
      photoUrl: _nullableString(payload['photoUrl']),
    );
  }

  DriverProfileAddress _mapAddress(Map<String, dynamic> payload) {
    return DriverProfileAddress(
      id: _nullableString(payload['id']),
      label: _nullableString(payload['label']),
      street: _nullableString(payload['street']),
      number: _nullableString(payload['number']),
      district: _nullableString(payload['district']),
      city: _nullableString(payload['city']),
      state: _nullableString(payload['state']),
      zipCode: _nullableString(payload['zipCode']),
      complement: _nullableString(payload['complement']),
      latitude: _asDoubleOrNull(payload['latitude']),
      longitude: _asDoubleOrNull(payload['longitude']),
      formattedAddress:
          _nullableString(payload['formattedAddress']) ??
          _nullableString(payload['address']) ??
          _nullableString(payload['fullAddress']) ??
          '',
    );
  }

  dynamic _pickFirst(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      if (payload.containsKey(key)) return payload[key];
    }
    return null;
  }
}
