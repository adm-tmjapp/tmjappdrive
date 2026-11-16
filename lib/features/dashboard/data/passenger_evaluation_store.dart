import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PassengerEvaluation {
  const PassengerEvaluation({required this.rating, this.comment});

  final int rating;
  final String? comment;

  Map<String, Object> toJson() => <String, Object>{
    'rating': rating,
    if (comment != null && comment!.trim().isNotEmpty) 'comment': comment!,
  };

  static PassengerEvaluation? fromJson(Object? value) {
    if (value is! Map) return null;
    final rating = int.tryParse(value['rating']?.toString() ?? '');
    if (rating == null || rating < 1 || rating > 5) return null;
    final comment = value['comment']?.toString().trim();
    return PassengerEvaluation(
      rating: rating,
      comment: comment == null || comment.isEmpty ? null : comment,
    );
  }
}

/// Mantém o recibo da avaliação já aceita pela API para que o motorista possa
/// revê-la ao retornar ao resumo, mesmo se o endpoint de histórico ainda não
/// expuser esse campo.
class PassengerEvaluationStore {
  static const _keyPrefix = 'driver_passenger_evaluation_';

  Future<PassengerEvaluation?> load(String rideId) async {
    if (rideId.trim().isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$rideId');
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return PassengerEvaluation.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String rideId, PassengerEvaluation evaluation) async {
    if (rideId.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$rideId',
      jsonEncode(evaluation.toJson()),
    );
  }
}
