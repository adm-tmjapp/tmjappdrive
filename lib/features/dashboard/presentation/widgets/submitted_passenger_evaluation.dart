import 'package:flutter/material.dart';

import '../../data/passenger_evaluation_store.dart';

class SubmittedPassengerEvaluation extends StatelessWidget {
  const SubmittedPassengerEvaluation({super.key, required this.evaluation});

  final PassengerEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232328)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUA AVALIAÇÃO DO PASSAGEIRO',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List<Widget>.generate(5, (index) {
              return Icon(
                Icons.star_rounded,
                color:
                    index < evaluation.rating
                        ? const Color(0xFFC62F78)
                        : const Color(0xFF2A2A35),
                size: 27,
              );
            }),
          ),
          if (evaluation.comment != null) ...[
            const SizedBox(height: 10),
            Text(
              evaluation.comment!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
