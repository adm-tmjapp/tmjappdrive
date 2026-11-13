import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../api/base_api.dart';

class RideChatMessage {
  const RideChatMessage({
    required this.id,
    required this.content,
    required this.isMine,
  });
  factory RideChatMessage.fromJson(Map<String, dynamic> json) {
    final sender =
        '${json['senderType'] ?? json['senderRole'] ?? json['sender'] ?? ''}'
            .toLowerCase();
    return RideChatMessage(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      content: '${json['content'] ?? json['text'] ?? json['message'] ?? ''}',
      isMine:
          json['isMine'] == true ||
          json['isMine']?.toString().toLowerCase() == 'true' ||
          sender == 'driver' ||
          sender == 'motorista',
    );
  }
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
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final payload =
        data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
    return (payload['messages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RideChatMessage.fromJson)
        .toList();
  }

  Future<RideChatMessage> send(String rideId, String content) async {
    final response = await _api.post(
      Uri.parse('v2/driver/rides/$rideId/messages'),
      body: {'content': content},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response));
    }
    return RideChatMessage.fromJson(
      ((jsonDecode(response.body) as Map<String, dynamic>)['message'])
          as Map<String, dynamic>,
    );
  }

  Future<void> markRead(String rideId) async {
    final response = await _api.patch(
      Uri.parse('v2/driver/rides/$rideId/messages/read'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response));
    }
  }

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
