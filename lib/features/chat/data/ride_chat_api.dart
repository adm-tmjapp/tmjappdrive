import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../api/base_api.dart';

class RideChatMessage {
  const RideChatMessage({
    required this.id,
    required this.content,
    required this.isMine,
  });
  factory RideChatMessage.fromJson(Map<String, dynamic> json) =>
      RideChatMessage(
        id: '${json['id'] ?? json['_id'] ?? ''}',
        content: '${json['content'] ?? ''}',
        isMine: json['isMine'] == true,
      );
  final String id;
  final String content;
  final bool isMine;
}

class RideChatApi {
  RideChatApi({BaseApi? api}) : _api = api ?? BaseApi();
  final BaseApi _api;
  Future<List<RideChatMessage>> list(String rideId) async {
    final response = await _api.get(
      Uri.parse('v2/driver/rides/$rideId/messages'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw Exception(_message(response));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['messages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RideChatMessage.fromJson)
        .toList();
  }

  Future<RideChatMessage> send(String rideId, String content) async {
    final response = await _api.post(
      Uri.parse('v2/driver/rides/$rideId/messages'),
      body: {'content': content},
    );
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw Exception(_message(response));
    return RideChatMessage.fromJson(
      ((jsonDecode(response.body) as Map<String, dynamic>)['message'])
          as Map<String, dynamic>,
    );
  }

  Future<void> markRead(String rideId) async =>
      _api.patch(Uri.parse('v2/driver/rides/$rideId/messages/read'));
  String _message(http.Response response) {
    try {
      return (jsonDecode(response.body) as Map<String, dynamic>)['message']
              ?.toString() ??
          'Não foi possível carregar o chat.';
    } catch (_) {
      return 'Não foi possível carregar o chat.';
    }
  }
}
