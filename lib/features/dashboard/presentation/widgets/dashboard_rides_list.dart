import 'package:flutter/material.dart';

import '../../domain/dashboard_models.dart';

class DashboardRidesList extends StatelessWidget {
  const DashboardRidesList({
    super.key,
    required this.rides,
    this.isLoading = false,
  });

  final List<RideCardItem> rides;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Text(
          'Nenhuma corrida para os filtros atuais.',
          style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return IgnorePointer(
      ignoring: isLoading,
      child: Column(children: rides.map(_rideTile).toList(growable: false)),
    );
  }

  Widget _rideTile(RideCardItem ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0x331D0A17),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_taxi_outlined,
              color: Color(0xFFC62F78),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ride.route.replaceAll('->', '•'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              ride.price,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
