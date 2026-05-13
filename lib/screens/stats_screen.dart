import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

enum _ViewMode { day, week, month }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _ViewMode _mode = _ViewMode.day;
  DateTime _refDate = DateTime.now();
  int? _selectedIndex;

  static const Color _darkGreen = Color(0xFF3D5C28);
  static const List<String> _weekLabels = ['일', '월', '화', '수', '목', '금', '토'];

  // ── 날짜 헬퍼 ──
  bool get _isToday =>
      _refDate.year == DateTime.now().year &&
      _refDate.month == DateTime.now().month &&
      _refDate.day == DateTime.now().day;

  bool get _canGoForward {
    final now = DateTime.now();
    switch (_mode) {
      case _ViewMode.day:
        return !_isToday;
      case _ViewMode.week:
        final weekStart = _weekStart(_refDate);
        final thisWeekStart = _weekStart(now);
        return weekStart.isBefore(thisWeekStart);
      case _ViewMode.month:
        return _refDate.year < now.year ||
            (_refDate.year == now.year && _refDate.month < now.month);
    }
  }

  DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: d.weekday % 7));
  }

  void _goBack() {
    setState(() {
      _selectedIndex = null;
      switch (_mode) {
        case _ViewMode.day:   _refDate = _refDate.subtract(const Duration(days: 1));
        case _ViewMode.week:  _refDate = _refDate.subtract(const Duration(days: 7));
        case _ViewMode.month: _refDate = DateTime(_refDate.year, _refDate.month - 1);
      }
    });
  }

  void _goForward() {
    if (!_canGoForward) return;
    setState(() {
      _selectedIndex = null;
      switch (_mode) {
        case _ViewMode.day:
          final next = _refDate.add(const Duration(days: 1));
          _refDate = next.isAfter(DateTime.now()) ? DateTime.now() : next;
        case _ViewMode.week:
          final next = _refDate.add(const Duration(days: 7));
          final now  = DateTime.now();
          _refDate = _weekStart(next).isAfter(_weekStart(now)) ? now : next;
        case _ViewMode.month:
          final next = DateTime(_refDate.year, _refDate.month + 1);
          final now  = DateTime.now();
          _refDate = (next.year > now.year || (next.year == now.year && next.month > now.month))
              ? now : next;
      }
    });
  }

  String get _dateLabel {
    switch (_mode) {
      case _ViewMode.day:
        final wd = _weekLabels[_refDate.weekday % 7];
        return "${_refDate.month}월 ${_refDate.day}일 ($wd)";
      case _ViewMode.week:
        final ws = _weekStart(_refDate);
        final we = ws.add(const Duration(days: 6));
        return "${ws.month}월 ${ws.day}일 - ${we.month}월 ${we.day}일";
      case _ViewMode.month:
        return "${_refDate.year}년 ${_refDate.month}월";
    }
  }

  String _formatSeconds(int seconds) {
    if (seconds == 0) return "없음";
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0 && m > 0) return "$h시간 $m분";
    if (h > 0) return "$h시간";
    if (m > 0 && s > 0) return "$m분 $s초";
    if (m > 0) return "$m분";
    return "$s초";
  }

  // ── 일별: 0~23시 ──
  List<Map<String, int>> _buildHourlyData(GameProvider provider) {
    final data = List.generate(24, (_) => <String, int>{});
    for (final s in provider.sessions) {
      if (s.startTime.year == _refDate.year &&
          s.startTime.month == _refDate.month &&
          s.startTime.day == _refDate.day) {
        final h = s.startTime.hour;
        data[h][s.categoryId] = (data[h][s.categoryId] ?? 0) + s.seconds;
      }
    }
    return data;
  }

  // ── 주별: 일~토 ──
  List<Map<String, int>> _buildWeeklyData(GameProvider provider) {
    final data = List.generate(7, (_) => <String, int>{});
    final ws = _weekStart(_refDate);
    final weekStartDay = DateTime(ws.year, ws.month, ws.day);
    for (final s in provider.sessions) {
      final diff = s.startTime.difference(weekStartDay).inDays;
      if (diff >= 0 && diff < 7) {
        data[diff][s.categoryId] = (data[diff][s.categoryId] ?? 0) + s.seconds;
      }
    }
    return data;
  }

  // ── 월별: 1~말일 ──
  List<Map<String, int>> _buildMonthlyData(GameProvider provider) {
    final daysInMonth = DateTime(_refDate.year, _refDate.month + 1, 0).day;
    final data = List.generate(daysInMonth, (_) => <String, int>{});
    for (final s in provider.sessions) {
      if (s.startTime.year == _refDate.year &&
          s.startTime.month == _refDate.month) {
        final idx = s.startTime.day - 1;
        data[idx][s.categoryId] = (data[idx][s.categoryId] ?? 0) + s.seconds;
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final provider   = context.watch<GameProvider>();
    final themeColor = provider.themeColor;
    final categories = provider.categories;

    List<Map<String, int>> chartData;
    switch (_mode) {
      case _ViewMode.day:   chartData = _buildHourlyData(provider);
      case _ViewMode.week:  chartData = _buildWeeklyData(provider);
      case _ViewMode.month: chartData = _buildMonthlyData(provider);
    }

    final total  = chartData.fold(0, (a, d) => a + d.values.fold(0, (b, v) => b + v));

    final selData  = _selectedIndex != null ? chartData[_selectedIndex!] : null;
    final selTotal = selData?.values.fold(0, (a, b) => a + b) ?? 0;

    // 오늘 인덱스 (주별일 때)
    final now = DateTime.now();
    final ws  = _weekStart(_refDate);
    final todayWeekIdx = now.difference(DateTime(ws.year, ws.month, ws.day)).inDays;

    return Scaffold(
      backgroundColor: themeColor,
      appBar: AppBar(
        title: const Text("📊 통계"),
        actions: [
          PopupMenuButton<_ViewMode>(
            icon: const Icon(Icons.calendar_view_week),
            tooltip: '기간 선택',
            onSelected: (mode) => setState(() {
              _mode = mode;
              _refDate = DateTime.now();
              _selectedIndex = null;
            }),
            itemBuilder: (_) => [
              PopupMenuItem(value: _ViewMode.day,   child: Text(_mode == _ViewMode.day   ? "✓ 하루"   : "  하루")),
              PopupMenuItem(value: _ViewMode.week,  child: Text(_mode == _ViewMode.week  ? "✓ 일주일" : "  일주일")),
              PopupMenuItem(value: _ViewMode.month, child: Text(_mode == _ViewMode.month ? "✓ 한달"   : "  한달")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 날짜 네비게이터 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: _darkGreen),
                  onPressed: _goBack,
                ),
                Text(
                  _dateLabel,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _darkGreen),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right,
                      color: _canGoForward ? _darkGreen : Colors.grey[300]),
                  onPressed: _canGoForward ? _goForward : null,
                ),
              ],
            ),
          ),

          // ── 총 공부시간 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("총 공부 시간",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    _formatSeconds(total),
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _darkGreen),
                  ),
                ],
              ),
            ),
          ),

          // ── 그래프 카드 ──
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: LayoutBuilder(builder: (ctx, outer) {
                    const legendH  = 36.0;
                    const dividerH = 24.0;
                    const detailH  = 120.0;
                    const labelH   = 24.0;
                    const padding  = 16.0; // 위아래 SizedBox 여백
                    final bottomH  = legendH + padding +
                        (_selectedIndex != null ? dividerH + detailH : 0);
                    final chartH   = max(60.0,
                        outer.maxHeight - bottomH - labelH);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      // 막대 그래프
                      SizedBox(
                        height: chartH + labelH,
                        child: _mode == _ViewMode.month
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: chartData.length * 28.0,
                                  child: _buildBars(chartData, chartData.length * 28.0, chartH, labelH, categories, todayWeekIdx),
                                ),
                              )
                            : LayoutBuilder(builder: (context, constraints) {
                                return _buildBars(chartData, constraints.maxWidth, chartH, labelH, categories, todayWeekIdx);
                              }),
                      ),

                      // ── 선택 상세 ──
                      if (_selectedIndex != null) ...[
                        const Divider(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: SingleChildScrollView(
                            child: _buildDetailCard(
                              _selectedLabel(),
                              selTotal,
                              selData ?? {},
                              categories,
                            ),
                          ),
                        ),
                      ],

                      // ── 범례 ──
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: categories.map((cat) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: cat.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(cat.name,
                                style: const TextStyle(
                                    fontSize: 11, color: _darkGreen)),
                          ],
                        )).toList(),
                      ),
                    ], // Column children
                  ); // Column / LayoutBuilder return
                }), // outer LayoutBuilder → Container.child 닫힘
              ), // Container
            ), // Padding
          ), // SafeArea
        ), // Expanded
        ],
      ),
    );
  }

  String _selectedLabel() {
    final i = _selectedIndex!;
    switch (_mode) {
      case _ViewMode.day:
        return "$i시";
      case _ViewMode.week:
        final ws  = _weekStart(_refDate);
        final day = ws.add(Duration(days: i));
        return "${day.month}/${day.day} (${_weekLabels[i]})";
      case _ViewMode.month:
        return "${_refDate.month}월 ${i + 1}일";
    }
  }

  Widget _buildBars(
      List<Map<String, int>> chartData,
      double totalWidth,
      double chartH,
      double labelH,
      List<StudyCategory> categories,
      int todayWeekIdx) {
    final count  = chartData.length;
    final barW   = totalWidth / count;
    final maxVal = chartData
        .map((d) => d.values.fold(0, (a, b) => a + b))
        .fold(0, (a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(count, (i) {
        final d      = chartData[i];
        final tot    = d.values.fold(0, (a, b) => a + b);
        final barH   = maxVal > 0 ? max(3.0, (tot / maxVal) * chartH) : 3.0;
        final isSel  = _selectedIndex == i;

        String label = '';
        switch (_mode) {
          case _ViewMode.day:
            label = i % 6 == 0 ? '$i' : '';
          case _ViewMode.week:
            label = _weekLabels[i];
          case _ViewMode.month:
            label = '${i + 1}';
        }

        final isHighlight = _mode == _ViewMode.week &&
            i == todayWeekIdx && todayWeekIdx >= 0 && todayWeekIdx < 7;

        return GestureDetector(
          onTap: () => setState(() {
            _selectedIndex = _selectedIndex == i ? null : i;
          }),
          child: SizedBox(
            width: barW,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: chartH,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: max(2.0, barW - (_mode == _ViewMode.month ? 2 : 3)),
                      height: barH,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: tot == 0
                          ? Container(color: isSel ? Colors.grey[400] : Colors.grey[200])
                          : _buildStackedBar(d, tot, categories, isSel),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: _mode == _ViewMode.day ? 9 : (_mode == _ViewMode.month ? 9 : 10),
                    fontWeight: (isSel || isHighlight) ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? _darkGreen : isHighlight ? _darkGreen : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStackedBar(
      Map<String, int> data,
      int total,
      List<StudyCategory> categories,
      bool isSelected) {
    final bars = <Widget>[];
    for (final cat in categories) {
      final secs = data[cat.id] ?? 0;
      if (secs == 0) continue;
      bars.add(Flexible(
        flex: (secs / total * 1000).round(),
        child: Container(
          color: isSelected ? cat.color : cat.color.withValues(alpha: 0.85),
        ),
      ));
    }
    final known   = categories.fold(0, (a, c) => a + (data[c.id] ?? 0));
    final unknown = total - known;
    if (unknown > 0) {
      bars.add(Flexible(
        flex: (unknown / total * 1000).round(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.black45, width: 1),
          ),
        ),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.max, children: bars);
  }

  Widget _buildDetailCard(
      String label,
      int total,
      Map<String, int> data,
      List<StudyCategory> categories) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _darkGreen)),
              Text(_formatSeconds(total),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _darkGreen)),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 6),
            ...categories
                .where((c) => (data[c.id] ?? 0) > 0)
                .map((cat) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: cat.color,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                          ),
                          const SizedBox(width: 6),
                          Text(cat.name,
                              style: const TextStyle(
                                  fontSize: 12, color: _darkGreen)),
                          const Spacer(),
                          Text(_formatSeconds(data[cat.id]!),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    )),
            // 삭제된 카테고리
            () {
              final known   = categories.fold(0, (a, c) => a + (data[c.id] ?? 0));
              final unknown = total - known;
              if (unknown <= 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.black45, width: 1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                    ),
                    const SizedBox(width: 6),
                    Text("(알수없음)",
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const Spacer(),
                    Text(_formatSeconds(unknown),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              );
            }(),
          ] else
            Text("공부 기록 없음",
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }
}