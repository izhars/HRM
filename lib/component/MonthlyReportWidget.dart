import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyReportWidget extends StatelessWidget {
  final List<dynamic> attendanceList;
  final VoidCallback onRefresh;

  const MonthlyReportWidget({
    Key? key,
    required this.attendanceList,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthlyStats = _calculateMonthlyStats(attendanceList);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: Colors.indigo[600],
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildReportHeader('Monthly'),
          SizedBox(height: 24),
          if (attendanceList.isEmpty)
            _buildEmptyState()
          else ...[
            _buildMonthlyOverview(monthlyStats),
            SizedBox(height: 16),
            _buildMonthlyChart(monthlyStats),
            SizedBox(height: 16),
            _buildDetailedStats(monthlyStats),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateMonthlyStats(List<dynamic> attendance) {
    int totalDays = attendance.length;
    int presentDays = 0;
    int absentDays = 0;
    int lateDays = 0;
    int halfDays = 0;
    int leaveDays = 0;
    double totalWorkHours = 0.0;
    double totalLateMinutes = 0.0;

    for (var att in attendance) {
      final status = att['status']?.toString().toLowerCase() ?? '';

      if (status == 'present') presentDays++;
      if (status == 'absent') absentDays++;
      if (status == 'half-day') halfDays++;
      if (status == 'on-leave') leaveDays++;
      if (att['isLate'] == true) {
        lateDays++;
        totalLateMinutes += (att['lateBy'] ?? 0.0);
      }
      totalWorkHours += (att['workHours'] ?? 0.0);
    }

    double attendancePercentage = totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;
    double avgWorkHours = totalDays > 0 ? totalWorkHours / totalDays : 0.0;
    double avgLateMinutes = lateDays > 0 ? totalLateMinutes / lateDays : 0.0;

    return {
      'totalDays': totalDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'halfDays': halfDays,
      'leaveDays': leaveDays,
      'totalWorkHours': totalWorkHours,
      'avgWorkHours': avgWorkHours,
      'attendancePercentage': attendancePercentage,
      'avgLateMinutes': avgLateMinutes,
    };
  }

  Widget _buildReportHeader(String reportType) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[50]!, Colors.indigo[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: Colors.indigo[600], size: 28),
          SizedBox(width: 16),
          Text(
            '$reportType Report',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No attendance records found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyOverview(Map<String, dynamic> stats) {
    final attendancePercentage = stats['attendancePercentage'] as double;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[400]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'Monthly Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Attendance Percentage Circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${attendancePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewStat('Total Days', '${stats['totalDays']}'),
              _buildOverviewStat('Present', '${stats['presentDays']}'),
              _buildOverviewStat('Absent', '${stats['absentDays']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(Map<String, dynamic> stats) {
    final totalDays = stats['totalDays'] as int;
    final presentDays = stats['presentDays'] as int;
    final absentDays = stats['absentDays'] as int;
    final leaveDays = stats['leaveDays'] as int;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.indigo[600], size: 24),
              SizedBox(width: 12),
              Text(
                'Attendance Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Horizontal bar chart
          _buildBarChart('Present', presentDays, totalDays, Colors.green),
          SizedBox(height: 12),
          _buildBarChart('Absent', absentDays, totalDays, Colors.red),
          SizedBox(height: 12),
          _buildBarChart('On Leave', leaveDays, totalDays, Colors.purple),
          SizedBox(height: 12),
          _buildBarChart('Late', stats['lateDays'], totalDays, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildBarChart(String label, int value, int total, Color color) {
    double percentage = total > 0 ? (value / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedStats(Map<String, dynamic> stats) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: Colors.indigo[600], size: 24),
              SizedBox(width: 12),
              Text(
                'Detailed Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard(
                'Total Hours',
                '${stats['totalWorkHours'].toStringAsFixed(1)}h',
                Icons.schedule,
                Colors.blue,
              ),
              _buildStatCard(
                'Avg Hours/Day',
                '${stats['avgWorkHours'].toStringAsFixed(1)}h',
                Icons.timer,
                Colors.teal,
              ),
              _buildStatCard(
                'Half Days',
                '${stats['halfDays']}',
                Icons.access_time_filled,
                Colors.orange,
              ),
              _buildStatCard(
                'Avg Late Time',
                '${stats['avgLateMinutes'].toStringAsFixed(0)}m',
                Icons.warning_amber,
                Colors.deepOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}