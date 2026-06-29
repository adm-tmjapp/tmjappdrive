import 'package:flutter/material.dart';

class RideHistoryDateFilterResult {
  const RideHistoryDateFilterResult({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;
}

class RideHistoryDateFilterScreen extends StatefulWidget {
  const RideHistoryDateFilterScreen({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  @override
  State<RideHistoryDateFilterScreen> createState() =>
      _RideHistoryDateFilterScreenState();
}

class _RideHistoryDateFilterScreenState
    extends State<RideHistoryDateFilterScreen> {
  static const Color _bg = Color(0xFF000000);
  static const Color _panel = Color(0xFF061126);
  static const Color _stroke = Color(0xFF193159);
  static const Color _primary = Color(0xFFC62F78);
  static const Color _rangeFill = Color(0x55B11958);
  static const Color _muted = Color(0xFF94A3B8);

  late DateTime _visibleMonth;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _editingStartDate = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = _dateOnly(
      widget.initialStartDate ?? DateTime(now.year, now.month, 5),
    );
    _endDate = _dateOnly(
      widget.initialEndDate ?? DateTime(now.year, now.month, 11),
    );
    if (_endDate.isBefore(_startDate)) {
      _endDate = _startDate;
    }
    _visibleMonth = DateTime(_startDate.year, _startDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final days = _calendarDays();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons
                          .arrow_back_rounded, // Ajustado para setinha mais limpa
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Filtrar por data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18, // Ajustado para proporção do header
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Espaço para manter alinhamento
                ],
              ),
            ),
            const Divider(color: Color(0xFF10203B), height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecione o período',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Escolha o intervalo para ver suas corridas',
                      style: TextStyle(color: _muted, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month - 1,
                              );
                            });
                          },
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _monthLabel(_visibleMonth),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month + 1,
                              );
                            });
                          },
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        _WeekdayLabel('DOM'),
                        _WeekdayLabel('SEG'),
                        _WeekdayLabel('TER'),
                        _WeekdayLabel('QUA'),
                        _WeekdayLabel('QUI'),
                        _WeekdayLabel('SEX'),
                        _WeekdayLabel('SÁB'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: days.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 10,
                            crossAxisSpacing:
                                0, // Removido para o fundo se conectar
                            childAspectRatio:
                                1.0, // Quadrado perfeito para o Stack
                          ),
                      itemBuilder: (context, index) {
                        final day = days[index];
                        if (day == null) {
                          return const SizedBox.shrink();
                        }

                        final isStart = _sameDay(day, _startDate);
                        final isEnd = _sameDay(day, _endDate);
                        final inRange =
                            !day.isBefore(_startDate) && !day.isAfter(_endDate);

                        return _DayCell(
                          day: day.day,
                          isStart: isStart,
                          isEnd: isEnd,
                          inRange: inRange,
                          onTap: () => _handleDayTap(day),
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Data Inicial',
                            value: _formatDate(_startDate),
                            selected: _editingStartDate,
                            onTap: () {
                              setState(() {
                                _editingStartDate = true;
                                _visibleMonth = DateTime(
                                  _startDate.year,
                                  _startDate.month,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DateField(
                            label: 'Data Final',
                            value: _formatDate(_endDate),
                            selected: !_editingStartDate,
                            onTap: () {
                              setState(() {
                                _editingStartDate = false;
                                _visibleMonth = DateTime(
                                  _endDate.year,
                                  _endDate.month,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    const Divider(color: Color(0xFF10203B), height: 1),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56, // Ajuste para proporção do design original
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            RideHistoryDateFilterResult(
                              startDate: _startDate,
                              endDate: _endDate,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0, // Removido elevation excessivo
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Confirmar Período',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime?> _calendarDays() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final leadingEmpty = firstDay.weekday % 7;
    final cells = <DateTime?>[];

    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(null);
    }

    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, day));
    }

    return cells;
  }

  void _handleDayTap(DateTime day) {
    final normalized = _dateOnly(day);
    setState(() {
      if (_editingStartDate) {
        _startDate = normalized;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
        _editingStartDate = false;
      } else {
        _endDate = normalized;
        if (_endDate.isBefore(_startDate)) {
          final previousStart = _startDate;
          _startDate = _endDate;
          _endDate = previousStart;
        }
      }
    });
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _RideHistoryDateFilterScreenState._muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isStart,
    required this.isEnd,
    required this.inRange,
    required this.onTap,
  });

  final int day;
  final bool isStart;
  final bool isEnd;
  final bool inRange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEdge = isStart || isEnd;
    final primaryColor = _RideHistoryDateFilterScreenState._primary;
    final rangeColor = _RideHistoryDateFilterScreenState._rangeFill;

    // Lógica visual para construir a linha contínua do período de datas
    Widget background = const SizedBox.shrink();
    if (inRange && !isStart && !isEnd) {
      background = Container(color: rangeColor);
    } else if (isStart && !isEnd) {
      background = Row(
        children: [
          Expanded(child: const SizedBox.shrink()),
          Expanded(child: Container(color: rangeColor)),
        ],
      );
    } else if (isEnd && !isStart) {
      background = Row(
        children: [
          Expanded(child: Container(color: rangeColor)),
          Expanded(child: const SizedBox.shrink()),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: background),
        Center(
          child: Container(
            width: 44, // Dimensão circular consistente
            height: 44,
            decoration: BoxDecoration(
              color: isEdge ? primaryColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isEdge ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(customBorder: const CircleBorder(), onTap: onTap),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 56, // Ajuste para uma altura mais clean
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _RideHistoryDateFilterScreenState._panel,
              borderRadius: BorderRadius.circular(
                16,
              ), // Igual ao design (Figma border 16)
              border: Border.all(
                color:
                    selected
                        ? _RideHistoryDateFilterScreenState._primary
                        : _RideHistoryDateFilterScreenState._stroke,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFFCBD5E1),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
