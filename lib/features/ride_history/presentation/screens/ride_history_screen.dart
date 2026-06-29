import 'package:flutter/material.dart';

import '../../data/ride_history_api.dart';
import '../../domain/ride_history_models.dart';
import 'ride_history_date_filter_screen.dart';
import 'ride_history_details_screen.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  RideHistoryRange _selectedRange = RideHistoryRange.week;
  DateTimeRange? _customRange;
  final RideHistoryApi _api = RideHistoryApi();

  RideHistorySummary? _summary;
  List<RideHistoryItem> _rides = const [];
  bool _isLoading = true;
  String? _error;

  static const Color _bg = Color(0xFF000000);
  static const Color _panel = Color(
    0xFF141013,
  ); // Fundo escuro levemente aquecido (Figma)
  static const Color _panelStroke = Color(
    0xFF2A1C24,
  ); // Borda sutil alinhada ao painel
  static const Color _primary = Color(0xFFC62F78);
  static const Color _success = Color(0xFF10B981); // Verde vibrante (Emerald)

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHistory,
        color: _primary,
        backgroundColor: _panel,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, widget.embedded ? 20 : 12, 16, 28),
          children: [
            _Header(embedded: widget.embedded),
            const SizedBox(height: 24),
            if (_isLoading && _summary == null)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width:
                            compact
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 16) / 2,
                        child: _SummaryCard(
                          title: 'TOTAL FATURADO',
                          value: _currencyBlock(_summary?.totalBilled ?? 0),
                          growthLabel: _summary?.billedGrowthLabel ?? '+0%',
                        ),
                      ),
                      SizedBox(
                        width:
                            compact
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 16) / 2,
                        child: _SummaryCard(
                          title: 'TOTAL CORRIDAS',
                          value: '${_summary?.totalRides ?? 0}',
                          growthLabel: _summary?.ridesGrowthLabel ?? '+0%',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _RangeChip(
                      label: 'Esta Semana',
                      selected: _selectedRange == RideHistoryRange.week,
                      onTap: () => _setRange(RideHistoryRange.week),
                    ),
                    const SizedBox(width: 12),
                    _RangeChip(
                      label: 'Este Mês',
                      selected: _selectedRange == RideHistoryRange.month,
                      onTap: () => _setRange(RideHistoryRange.month),
                    ),
                    const SizedBox(width: 12),
                    _RangeChip(
                      label: 'Personalizado',
                      selected: _selectedRange == RideHistoryRange.custom,
                      onTap: _openCustomDateFilter,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Corridas Recentes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: _primary),
                  ),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _panelStroke),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                )
              else if (_rides.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _panelStroke),
                  ),
                  child: const Text(
                    'Nenhuma corrida encontrada para o período selecionado.',
                    style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
                  ),
                )
              else
                ..._rides.map(
                  (ride) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _RideCard(
                      ride: ride,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => RideHistoryDetailsScreen(ride: ride),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return ColoredBox(color: _bg, child: body);
    }

    return Scaffold(backgroundColor: _bg, body: body);
  }

  Future<void> _setRange(RideHistoryRange range) async {
    if (_selectedRange == range) return;
    setState(() {
      _selectedRange = range;
      if (range != RideHistoryRange.custom) {
        _customRange = null;
      }
    });
    await _loadHistory();
  }

  Future<void> _openCustomDateFilter() async {
    final result = await Navigator.of(
      context,
    ).push<RideHistoryDateFilterResult>(
      MaterialPageRoute(
        builder:
            (_) => RideHistoryDateFilterScreen(
              initialStartDate: _customRange?.start,
              initialEndDate: _customRange?.end,
            ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedRange = RideHistoryRange.custom;
      _customRange = DateTimeRange(
        start: result.startDate,
        end: result.endDate,
      );
    });

    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _api.fetchSummary(
        range: _selectedRange,
        startDate: _customRange?.start,
        endDate: _customRange?.end,
      );
      final rides = await _api.fetchHistory(
        range: _selectedRange,
        startDate: _customRange?.start,
        endDate: _customRange?.end,
      );

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _rides = rides;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _rides = const [];
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _currencyBlock(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$\n$fixed';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.embedded});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return const Center(
        child: Text(
          'Histórico de Corridas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Histórico de Corridas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.growthLabel,
  });

  final String title;
  final String value;
  final String growthLabel;

  @override
  Widget build(BuildContext context) {
    final isSplit = value.contains('\n');
    final parts = isSplit ? value.split('\n') : [value];

    return Container(
      height: 144, // Altura ajustada perfeitamente ao Figma
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _RideHistoryScreenState._panel,
        borderRadius: BorderRadius.circular(16), // Confirmação de 16px
        border: Border.all(color: _RideHistoryScreenState._panelStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8), // Muted leve
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (isSplit) ...[
            Text(
              parts[0],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            Text(
              parts[1],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ] else ...[
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: _RideHistoryScreenState._success,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                growthLabel,
                style: const TextStyle(
                  color: _RideHistoryScreenState._success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ), // Propriedades retiradas do Inspector
        decoration: BoxDecoration(
          color:
              selected
                  ? _RideHistoryScreenState._primary
                  : _RideHistoryScreenState._panel,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected
                    ? Colors.transparent
                    : _RideHistoryScreenState._panelStroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFA1A1AA),
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride, required this.onTap});

  final RideHistoryItem ride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16), // Margem interna original
        decoration: BoxDecoration(
          color: _RideHistoryScreenState._panel,
          borderRadius: BorderRadius.circular(16), // Corrigido para 16px exatos
          border: Border.all(color: _RideHistoryScreenState._panelStroke),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _RideCardMeta(ride: ride)),
                const SizedBox(width: 16),
                _RideAmountBlock(ride: ride),
              ],
            ),
            const SizedBox(height: 18),
            _RouteTimeline(origin: ride.origin, destination: ride.destination),
          ],
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final target = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final time = '${_two(date.hour)}:${_two(date.minute)}';
    if (target == today) return 'Hoje, $time';
    if (target == yesterday) return 'Ontem, $time';
    return '${_two(date.day)}/${_two(date.month)}, $time';
  }

  static String _currency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _RideCardMeta extends StatelessWidget {
  const _RideCardMeta({required this.ride});

  final RideHistoryItem ride;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _RideCard._dateLabel(ride.startedAt),
          style: const TextStyle(
            color: Color(0xFF94A3B8), // Ajustado o tom de cinza
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6), // Menor gap para o badge, alinhado ao Figma
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _RideHistoryScreenState._success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            ride.statusLabel.toUpperCase(),
            style: const TextStyle(
              color: _RideHistoryScreenState._success,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _RideAmountBlock extends StatelessWidget {
  const _RideAmountBlock({required this.ride});

  final RideHistoryItem ride;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _RideCard._currency(ride.netAmount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${ride.distanceKm.toStringAsFixed(1)} km',
          style: const TextStyle(
            color: Color(0xFF94A3B8), // Cor de apoio
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline({required this.origin, required this.destination});

  final String origin;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(
              height: 2,
            ), // Alinhamento ótico com a altura da linha de texto
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _RideHistoryScreenState._success,
                  width: 2.5,
                ),
              ),
            ),
            Container(
              width: 2,
              height:
                  24, // Distância um pouco maior e linha contínua escura do mockup
              color: const Color(
                0xFF4A1934,
              ), // Linha conectora na cor rosa profundo
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _RideHistoryScreenState._primary,
                  width: 2.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                origin,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0), // Branco gelo/cinza ultra claro
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(
                height: 18,
              ), // Altura precisa em relação à linha lateral
              Text(
                destination,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
