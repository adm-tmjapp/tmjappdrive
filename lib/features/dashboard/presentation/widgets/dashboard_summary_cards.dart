import 'package:flutter/material.dart';
import '../../domain/dashboard_models.dart';

class DashboardSummaryCards extends StatelessWidget {
  const DashboardSummaryCards({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Faturado',
                      value: summary.todayEarnings,
                      icon: Icons.show_chart_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Corridas',
                      value: '${summary.todayRides}',
                      icon: Icons.equalizer_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _SummaryCard(
                label: 'Nota',
                value: _rating(summary.progressPercent),
                icon: Icons.star_rounded,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Faturado',
                value: summary.todayEarnings,
                icon: Icons.show_chart_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Corridas',
                value: '${summary.todayRides}',
                icon: Icons.equalizer_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Nota',
                value: _rating(summary.progressPercent),
                icon: Icons.star_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  String _rating(int progressPercent) {
    final rating = 4 + (progressPercent / 100);
    return rating.toStringAsFixed(1);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC62F78), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFC62F78),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDisplayValue(),
                  style: const TextStyle(
                    fontSize: 19,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: 6),
                Icon(icon, color: const Color(0xFFC62F78), size: 19),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayValue() {
    return value;
  }
}
