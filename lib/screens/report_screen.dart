import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/attendance_api.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final List<String> _tabs = ['Calendar', 'Daily', 'Weekly', 'Monthly'];
  Map<String, dynamic>? _attendanceData;
  bool _isLoading = true;

  // Calendar specific variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _attendanceEvents = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
    _loadAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Updated method to handle month/year parameters
  Future<void> _loadAttendance({int? month, int? year}) async {
    setState(() => _isLoading = true);
    try {
      final data = await _attendanceService.fetchMyAttendance(
        month: month ?? _focusedDay.month,
        year: year ?? _focusedDay.year,
      );
      setState(() {
        _attendanceData = data;
        _isLoading = false;
        _processAttendanceEvents();
      });
    } catch (e) {
      setState(() {
        _attendanceData = null;
        _isLoading = false;
      });
      print('Error loading attendance: $e');
    }
  }

  void _processAttendanceEvents() {
    if (_attendanceData == null || _attendanceData!['attendance'] == null) return;

    _attendanceEvents.clear();
    final attendanceList = _attendanceData!['attendance'] as List<dynamic>;

    for (var attendance in attendanceList) {
      final dateStr = attendance['date'];
      if (dateStr != null) {
        final date = DateTime.parse(dateStr).toLocal();
        final normalizedDate = DateTime(date.year, date.month, date.day);

        if (_attendanceEvents[normalizedDate] != null) {
          _attendanceEvents[normalizedDate]!.add(attendance);
        } else {
          _attendanceEvents[normalizedDate] = [attendance];
        }
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _attendanceEvents[normalizedDay] ?? [];
  }

  // Get status color for calendar markers
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'half-day':
        return Colors.orange;
      case 'on-leave':
        return Colors.purple;
      case 'public-holiday':
        return Colors.blue;
      case 'combo-off':
        return Colors.teal;
      case 'non-working-day':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Attendance Reports',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[600]!, Colors.indigo[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[600]!, Colors.indigo[400]!],
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: _tabs.map((tab) => Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(tab),
                ),
              )).toList(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : _attendanceData == null || _attendanceData!['success'] != true
          ? _buildErrorWidget()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarView(),
          _buildReportContent('Daily'),
          _buildReportContent('Weekly'),
          _buildReportContent('Monthly'),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading attendance data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(32),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: 24),
            Text(
              'Failed to load attendance data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please check your connection and try again',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadAttendance(),
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return RefreshIndicator(
      onRefresh: () => _loadAttendance(),
      color: Colors.indigo[600],
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Status Legend
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Text(
                    'Status Legend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[600],
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildLegendItem('Present', Colors.green),
                      _buildLegendItem('Absent', Colors.red),
                      _buildLegendItem('Half Day', Colors.orange),
                      _buildLegendItem('On Leave', Colors.purple),
                      _buildLegendItem('Holiday', Colors.blue),
                      _buildLegendItem('Combo Off', Colors.teal),
                      _buildLegendItem('Non-Working', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),

            // Calendar Widget
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
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
              child: TableCalendar<dynamic>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  // Load attendance data when month/year changes
                  _loadAttendance(month: focusedDay.month, year: focusedDay.year);
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red[400]),
                  holidayTextStyle: TextStyle(color: Colors.red[400]),
                  selectedDecoration: BoxDecoration(
                    color: Colors.indigo[600],
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.indigo[300],
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  markerSize: 10.0,
                  markersOffset: PositionedOffset(bottom: 2, start: 2),
                  defaultTextStyle: TextStyle(fontWeight: FontWeight.w500),
                  weekNumberTextStyle: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.w500
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      final event = events.first;
                      final status = event['status']?.toString() ?? '';
                      return Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.indigo[100],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: Colors.indigo[600],
                    fontWeight: FontWeight.bold,
                  ),
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[600],
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.indigo[600],
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.indigo[600],
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Selected Day Events
            if (_selectedDay != null) _buildSelectedDayEvents(),

            // Stats Overview
            _buildStatsOverview(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // All the rest of your existing methods from the attached file
  Widget _buildSelectedDayEvents() {
    final events = _getEventsForDay(_selectedDay!);

    String _formatTime(dynamic timeValue) {
      if (timeValue == null || timeValue.toString().isEmpty) return "—";
      try {
        final dt = DateTime.parse(timeValue.toString()).toLocal();
        return DateFormat('hh:mm a').format(dt);
      } catch (_) {
        return timeValue.toString();
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.indigo.shade600],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.event_note, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  'Attendance - ${_formatDate(_selectedDay!)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Body
          if (events.isEmpty)
            Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 50, color: Colors.grey[400]),
                    SizedBox(height: 12),
                    Text(
                      'No attendance records for this day',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: events.map<Widget>((attendance) {
                  final checkInRaw = attendance['checkInTimeFormatted'] ??
                      attendance['checkIn']?['time'];
                  final checkOutRaw = attendance['checkOutTimeFormatted'] ??
                      attendance['checkOut']?['time'];

                  final checkIn = _formatTime(checkInRaw);
                  final checkOut = _formatTime(checkOutRaw);
                  final workHours = attendance['workHours'] ?? 0;
                  final status = attendance['status'] ?? 'N/A';
                  final isLate = attendance['isLate'] == true;
                  final lateBy = attendance['lateBy'] ?? 0;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Status + Late badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.verified_user,
                                    color: Colors.indigo, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                              ],
                            ),
                            if (isLate)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Late by $lateBy min',
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Row 2: Check-in & Check-out
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTimeTile(
                              icon: Icons.login_rounded,
                              label: "Check-In",
                              time: checkIn,
                              color: Colors.green,
                            ),
                            _buildTimeTile(
                              icon: Icons.logout_rounded,
                              label: "Check-Out",
                              time: checkOut,
                              color: Colors.red,
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Row 3: Work hours
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                color: Colors.amber[700], size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Work Hours: ${workHours.toStringAsFixed(1)} hrs',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeTile({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final stats = _attendanceData!['stats'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: EdgeInsets.all(16),
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
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[50]!, Colors.indigo[100]!],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.indigo[600], size: 24),
                SizedBox(width: 12),
                Text(
                  'Attendance Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[600],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: stats.entries.map<Widget>((entry) => _buildStatCard(entry.key, entry.value)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String key, dynamic value) {
    IconData icon;
    Color color;

    switch (key.toLowerCase()) {
      case 'totalpresent':
      case 'present':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'totalabsent':
      case 'absent':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'totallate':
      case 'late':
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

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
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatKey(key),
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

  Widget _buildReportContent(String reportType) {
    final attendanceList = _attendanceData!['attendance'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: () => _loadAttendance(),
      color: Colors.indigo[600],
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Report Header
          Container(
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
          ),
          SizedBox(height: 24),

          // Attendance List
          if (attendanceList.isEmpty)
            Container(
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
            )
          else
            ...attendanceList.map<Widget>((dynamic att) => _buildAttendanceCard(att as Map<String, dynamic>)).toList(),
        ],
      ),
    );
  }

  // Include all the rest of your methods from the attached file...
  // (I'm truncating here due to length, but you should include ALL methods from your original file)

  Widget _buildAttendanceCard(Map<String, dynamic> attendance, {bool isCompact = false}) {
    // Copy the entire method from your attached file
    final checkIn = attendance['checkIn'] as Map<String, dynamic>?;
    final checkOut = attendance['checkOut'] as Map<String, dynamic>?;
    final isLate = attendance['isLate'] as bool? ?? false;
    final status = attendance['status']?.toString() ?? 'Unknown';

    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'present':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'absent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'late':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(DateTime.parse(attendance['date']).toLocal()),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCompact)
                  IconButton(
                    onPressed: () => _showReportDetails(attendance),
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn('Work Hours', '${attendance['workHours'] ?? 0} hrs', Icons.schedule),
                    ),
                    Expanded(
                      child: _buildInfoColumn('Late By', '${attendance['lateBy'] ?? 0} mins', Icons.access_time_filled),
                    ),
                  ],
                ),
                if (!isCompact) ...[
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoColumn('Check-in', attendance['checkInTimeFormatted']?.toString() ?? '-', Icons.login),
                      ),
                      Expanded(
                        child: _buildInfoColumn('Check-out', attendance['checkOutTimeFormatted']?.toString() ?? '-', Icons.logout),
                      ),
                    ],
                  ),
                  if (checkIn != null) ...[
                    SizedBox(height: 16),
                    _buildLocationInfo('Check-in Location', checkIn['location']?['address']?.toString() ?? '-'),
                  ],
                  if (checkOut != null) ...[
                    SizedBox(height: 8),
                    _buildLocationInfo('Check-out Location', checkOut['location']?['address']?.toString() ?? '-'),
                  ],
                ],
              ],
            ),
          ),

          if (!isCompact)
            Container(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showReportDetails(attendance),
                icon: Icon(Icons.visibility, size: 18),
                label: Text('View Details'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo[600],
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Add all remaining methods from your attached file
  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> att) {
    // Include the complete method from your attached file
    final checkIn = att['checkIn'] as Map<String, dynamic>?;
    final checkOut = att['checkOut'] as Map<String, dynamic>?;
    final status = att['status']?.toString() ?? 'Unknown';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'present':
        statusColor = Colors.green;
        break;
      case 'absent':
        statusColor = Colors.red;
        break;
      case 'late':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.event_note, color: statusColor, size: 24),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatDate(DateTime.parse(att['date']).toLocal()),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDetailCard('Basic Information', [
                        _buildDetailRow('Status', status, Icons.info, statusColor),
                        _buildDetailRow('Work Hours', '${att['workHours'] ?? 0} hrs', Icons.access_time, Colors.blue),
                        _buildDetailRow('Late By', '${att['lateBy'] ?? 0} mins', Icons.schedule, Colors.orange),
                      ]),

                      SizedBox(height: 16),

                      _buildDetailCard('Check-in Information', [
                        _buildDetailRow('Time', att['checkInTimeFormatted']?.toString() ?? '-', Icons.login, Colors.green),
                        if (checkIn != null) ...[
                          _buildDetailRow('Device', checkIn['deviceInfo']?.toString() ?? '-', Icons.phone_android, Colors.grey),
                          _buildLocationDetailRow('Location', checkIn['location']?['address']?.toString() ?? '-'),
                        ],
                      ]),

                      if (checkOut != null) ...[
                        SizedBox(height: 16),
                        _buildDetailCard('Check-out Information', [
                          _buildDetailRow('Time', att['checkOutTimeFormatted']?.toString() ?? '-', Icons.logout, Colors.red),
                          _buildDetailRow('Device', checkOut['deviceInfo']?.toString() ?? '-', Icons.phone_android, Colors.grey),
                          _buildLocationDetailRow('Location', checkOut['location']?['address']?.toString() ?? '-'),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[600],
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Widget _buildLocationDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, size: 18, color: Colors.blue),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
