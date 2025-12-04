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

  // Enhanced status color with priority for late and short attendance
  Color _getStatusColor(String status, {bool? isLate, bool? isShortAttendance}) {
    // Priority: Short Attendance > Late > Status
    if (isShortAttendance == true) {
      return Colors.deepOrange; // Distinct color for short attendance
    }
    if (isLate == true) {
      return Colors.amber[700]!; // Orange for late
    }

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
            // Enhanced Status Legend
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.indigo[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.indigo[600], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Status Legend',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _buildLegendItem('Present', Colors.green),
                      _buildLegendItem('Late', Colors.amber[700]!),
                      _buildLegendItem('Short', Colors.deepOrange),
                      _buildLegendItem('Absent', Colors.red),
                      _buildLegendItem('Half Day', Colors.orange),
                      _buildLegendItem('On Leave', Colors.purple),
                      _buildLegendItem('Holiday', Colors.blue),
                      _buildLegendItem('Combo Off', Colors.teal),
                    ],
                  ),
                ],
              ),
            ),

            // Enhanced Calendar Widget with better click handling
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
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
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });

                    // Show bottom sheet on day click
                    final events = _getEventsForDay(selectedDay);
                    if (events.isNotEmpty) {
                      _showDayDetailsBottomSheet(selectedDay, events);
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
                    _loadAttendance(month: focusedDay.month, year: focusedDay.year);
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.red[400], fontWeight: FontWeight.w600),
                    holidayTextStyle: TextStyle(color: Colors.red[400]),
                    selectedDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo[600]!, Colors.indigo[400]!],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.indigo[300],
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                    markerSize: 8.0,
                    markersOffset: PositionedOffset(bottom: 4, start: 0),
                    defaultTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    cellMargin: EdgeInsets.all(6),
                    cellPadding: EdgeInsets.all(0),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isNotEmpty) {
                        final event = events.first;
                        final status = event['status']?.toString() ?? '';
                        final isLate = event['isLate'] == true;
                        final isShortAttendance = event['isShortAttendance'] == true;

                        return Positioned(
                          bottom: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(status, isLate: isLate, isShortAttendance: isShortAttendance),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    // Add visual feedback for days with events
                    defaultBuilder: (context, day, focusedDay) {
                      final events = _getEventsForDay(day);
                      if (events.isNotEmpty) {
                        return Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.indigo[100]!, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
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
                      gradient: LinearGradient(
                        colors: [Colors.indigo[100]!, Colors.indigo[200]!],
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: Colors.indigo[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.indigo[600],
                      size: 28,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.indigo[600],
                      size: 28,
                    ),
                    headerPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    weekendStyle: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Selected Day Events (Enhanced)
            if (_selectedDay != null) _buildSelectedDayEvents(),

            // Stats Overview
            _buildStatsOverview(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Bottom sheet for day details on click
  void _showDayDetailsBottomSheet(DateTime day, List<dynamic> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[50]!, Colors.white],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.indigo[600], size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(day),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[700],
                            ),
                          ),
                          Text(
                            DateFormat('EEEE').format(day),
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
              ),

              // Content
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return _buildEnhancedAttendanceCard(events[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Enhanced attendance card with new fields
  Widget _buildEnhancedAttendanceCard(dynamic attendance) {
    final checkInRaw = attendance['checkInTimeFormatted'] ?? attendance['checkIn']?['time'];
    final checkOutRaw = attendance['checkOutTimeFormatted'] ?? attendance['checkOut']?['time'];

    final checkIn = _formatTime(checkInRaw);
    final checkOut = _formatTime(checkOutRaw);
    final workHours = attendance['workHours'] ?? 0;
    final status = attendance['status'] ?? 'N/A';
    final isLate = attendance['isLate'] == true;
    final lateBy = attendance['lateBy'] ?? 0;

    // NEW: Handle short attendance
    final isShortAttendance = attendance['isShortAttendance'] == true;
    final shortByMinutes = attendance['shortByMinutes'] ?? 0;

    // Determine primary color based on priority
    Color primaryColor = Colors.green;
    if (isShortAttendance) {
      primaryColor = Colors.deepOrange;
    } else if (isLate) {
      primaryColor = Colors.amber[700]!;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badges
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isShortAttendance)
                      _buildBadge(
                        'Short by $shortByMinutes min',
                        Colors.deepOrange,
                        Icons.schedule_outlined,
                      ),
                    if (isLate)
                      _buildBadge(
                        'Late by $lateBy min',
                        Colors.amber[700]!,
                        Icons.access_time_filled,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Body with time details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Check-in & Check-out row
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeCard(
                        icon: Icons.login_rounded,
                        label: "Check-In",
                        time: checkIn,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeCard(
                        icon: Icons.logout_rounded,
                        label: "Check-Out",
                        time: checkOut,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Work hours
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.amber[700], size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Work Hours: ',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${workHours.toStringAsFixed(2)} hrs',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timeValue) {
    if (timeValue == null || timeValue.toString().isEmpty) return "—";
    try {
      final dt = DateTime.parse(timeValue.toString()).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeValue.toString();
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Keep all your existing methods for _buildSelectedDayEvents, _buildStatsOverview, etc.
  Widget _buildSelectedDayEvents() {
    // Use your existing implementation from the file
    // ... [previous code]
    return Container(); // Placeholder
  }

  Widget _buildStatsOverview() {
    // Use your existing implementation
    // ... [previous code]
    return Container(); // Placeholder
  }

  Widget _buildReportContent(String reportType) {
    // Use your existing implementation
    // ... [previous code]
    return Container(); // Placeholder
  }
}
