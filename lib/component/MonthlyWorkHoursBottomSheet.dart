import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/attendance_api.dart';

class MonthlyWorkHoursBottomSheet extends StatefulWidget {
  const MonthlyWorkHoursBottomSheet({super.key});

  @override
  State<MonthlyWorkHoursBottomSheet> createState() =>
      _MonthlyWorkHoursBottomSheetState();
}

class _MonthlyWorkHoursBottomSheetState
    extends State<MonthlyWorkHoursBottomSheet> {
  final AttendanceService _attendanceService = AttendanceService();

  late int selectedMonth;
  late int selectedYear;

  Map<String, dynamic>? apiData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final data = await _attendanceService.getMonthlyWorkHours(
        month: selectedMonth,
        year: selectedYear,
      );
      setState(() {
        apiData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickMonthAndYear() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(selectedYear, selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Month & Year',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedMonth = pickedDate.month;
        selectedYear = pickedDate.year;
      });
      await _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[50]!, Colors.indigo[100]!],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded,
                      color: Colors.indigo[700],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Work Hours Analysis',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          Text(
                            apiData != null && apiData!['period'] != null
                                ? (apiData!['period']['display'] ??
                                '${_monthName(selectedMonth)} $selectedYear')
                                : '${_monthName(selectedMonth)} $selectedYear',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.indigo[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _pickMonthAndYear,
                        icon: Icon(Icons.calendar_month, color: Colors.indigo[600]),
                        tooltip: 'Change Month',
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : apiData == null ||
                    apiData!['success'] != true ||
                    (apiData!['chart'] as List?)?.isEmpty == true
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(apiData!),
                      const SizedBox(height: 24),
                      _buildChartSection(apiData!),
                      const SizedBox(height: 24),
                      _buildDetailedList(apiData!),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading work hours data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No work hours data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different month',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickMonthAndYear,
            icon: const Icon(Icons.calendar_month),
            label: const Text('Select Month'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final totalHours = (summary['totalWorkHours'] as num?)?.toDouble() ?? 0.0;
    final avgHours = (summary['averageDaily'] as num?)?.toDouble() ?? 0.0;
    final workingDays = (summary['workingDays'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.access_time_rounded,
            title: 'Total Hours',
            value: totalHours.toStringAsFixed(1),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.trending_up,
            title: 'Avg/Day',
            value: avgHours.toStringAsFixed(1),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.event_available,
            title: 'Days',
            value: workingDays.toString(),
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.indigo[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Daily Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildChart(data),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Map<String, dynamic> data) {
    final chartData = (data['chart'] ?? []) as List;

    if (chartData.isEmpty) {
      return const Center(child: Text('No chart data available'));
    }

    final workHours = chartData
        .map((d) => (d['workHours'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final labels = chartData
        .map((d) => (d['label'] as String?) ?? '')
        .toList();

    // Calculate max Y with some padding
    final maxHours = workHours.reduce((a, b) => a > b ? a : b);
    final maxY = maxHours > 0 ? (maxHours + 2).ceilToDouble() : 10.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: labels.length > 15 ? 5 : labels.length > 10 ? 3 : 2,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx >= 0 && idx < labels.length) {
                  // Extract day number from label (e.g., "01 Oct" -> "01")
                  final day = labels[idx].split(' ')[0];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            left: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        minX: 0,
        maxX: (workHours.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              workHours.length,
                  (i) => FlSpot(i.toDouble(), workHours[i]),
            ),
            isCurved: true,
            color: Colors.indigo[600],
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Only show dots for days with work hours > 0
                if (spot.y > 0) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.indigo[600]!,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.indigo[600]!.withOpacity(0.3),
                  Colors.indigo[600]!.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            // tooltipBgColor: Colors.indigo[600]!.withOpacity(0.9),
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final dataPoint = chartData[spot.x.toInt()];
                final date = dataPoint['label'] as String? ?? '';
                final day = dataPoint['day'] as String? ?? '';
                return LineTooltipItem(
                  '$date ($day)\n${spot.y.toStringAsFixed(2)} hrs',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedList(Map<String, dynamic> data) {
    final chartData = (data['chart'] ?? []) as List;

    if (chartData.isEmpty) return const SizedBox.shrink();

    // Filter to show only days with work hours > 0
    final workingDaysData = chartData.where((item) {
      final hours = (item['workHours'] as num?)?.toDouble() ?? 0.0;
      return hours > 0;
    }).toList();

    if (workingDaysData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No working days recorded',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.indigo[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Working Days Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${workingDaysData.length} days',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workingDaysData.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final item = workingDaysData[index];
              final label = item['label'] as String? ?? '';
              final day = item['day'] as String? ?? '';
              final hours = (item['workHours'] as num?)?.toDouble() ?? 0.0;
              final date = item['date'] as String? ?? '';
              final isWeekend = day == 'Sat' || day == 'Sun';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isWeekend
                        ? Colors.red[50]
                        : Colors.indigo[50],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWeekend
                          ? Colors.red[200]!
                          : Colors.indigo[200]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label.split(' ')[0], // Day number
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isWeekend
                              ? Colors.red[700]
                              : Colors.indigo[700],
                        ),
                      ),
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isWeekend
                              ? Colors.red[600]
                              : Colors.indigo[600],
                        ),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getHoursColor(hours).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getHoursColor(hours).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getHoursIcon(hours),
                        size: 16,
                        color: _getHoursColor(hours),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${hours.toStringAsFixed(2)} hrs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getHoursColor(hours),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getHoursColor(double hours) {
    if (hours >= 8) return Colors.green[600]!;
    if (hours >= 6) return Colors.orange[600]!;
    if (hours > 0) return Colors.red[600]!;
    return Colors.grey;
  }

  IconData _getHoursIcon(double hours) {
    if (hours >= 8) return Icons.check_circle;
    if (hours >= 6) return Icons.warning_rounded;
    return Icons.error_rounded;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}