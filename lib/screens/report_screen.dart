import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../component/DailyReportWidget.dart';
import '../component/MonthlyReportWidget.dart';
import '../component/MonthlyWorkHoursBottomSheet.dart';
import '../component/WeeklyReportWidget.dart';
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

  Color _getStatusColor(String status, {bool? isLate, bool? isShortAttendance}) {
    if (isShortAttendance == true) {
      return Colors.deepOrange;
    }
    if (isLate == true) {
      return Colors.amber[700]!;
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
          ? _buildSkeletonLoading()
          : _attendanceData == null || _attendanceData!['success'] != true
          ? _buildErrorWidget()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarView(),
          DailyReportWidget(
            attendanceList: _attendanceData!['attendance'] as List<dynamic>? ?? [],
            onRefresh: _loadAttendance,
          ),
          WeeklyReportWidget(
            attendanceList: _attendanceData!['attendance'] as List<dynamic>? ?? [],
            onRefresh: _loadAttendance,
          ),
          MonthlyReportWidget(
            attendanceList: _attendanceData!['attendance'] as List<dynamic>? ?? [],
            onRefresh: _loadAttendance,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView( // Wrap with SingleChildScrollView
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Skeleton for the legend section
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
                      _buildSkeletonLegendItem('Present'),
                      _buildSkeletonLegendItem('Late'),
                      _buildSkeletonLegendItem('Short'),
                      _buildSkeletonLegendItem('Absent'),
                      _buildSkeletonLegendItem('Half Day'),
                      _buildSkeletonLegendItem('On Leave'),
                      _buildSkeletonLegendItem('Holiday'),
                      _buildSkeletonLegendItem('Comp Off'),
                    ],
                  ),
                ],
              ),
            ),

            // Skeleton for calendar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
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
                children: [
                  // Calendar header skeleton
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 100,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Calendar grid skeleton - Reduced height
                  Container(
                    height: 280, // Fixed height to prevent overflow
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 4, // Reduced spacing
                        mainAxisSpacing: 4, // Reduced spacing
                      ),
                      itemCount: 42, // 6 weeks
                      itemBuilder: (context, index) {
                        return Container(
                          height: 30, // Reduced height
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Skeleton for selected day events - Made more compact
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
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
                    width: 200,
                    height: 16, // Reduced height
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 12), // Reduced spacing
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50, // Reduced height
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(width: 8), // Reduced spacing
                      Expanded(
                        child: Container(
                          height: 50, // Reduced height
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Skeleton for stats overview - Made more compact
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
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
                    width: 180,
                    height: 16, // Reduced height
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 12), // Reduced spacing
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3, // Reduced aspect ratio
                      crossAxisSpacing: 8, // Reduced spacing
                      mainAxisSpacing: 8, // Reduced spacing
                    ),
                    itemCount: 6, // Reduced from 8 to 6 items
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8), // Reduced radius
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8), // Reduced padding
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24, // Reduced size
                                height: 24, // Reduced size
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(height: 6), // Reduced spacing
                              Container(
                                width: 30, // Reduced width
                                height: 12, // Reduced height
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              SizedBox(height: 4), // Reduced spacing
                              Container(
                                width: 50, // Reduced width
                                height: 10, // Reduced height
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(3),
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
            ),

            // Add some bottom padding to ensure everything fits
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLegendItem(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
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
                      _buildLegendItem('Comp Off', Colors.teal),
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

            if (_selectedDay != null) _buildSelectedDayEvents(),
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
                  final checkInRaw = attendance['checkInTimeFormatted'] ?? attendance['checkIn']?['time'];
                  final checkOutRaw = attendance['checkOutTimeFormatted'] ?? attendance['checkOut']?['time'];

                  final checkIn = _formatTime(checkInRaw);
                  final checkOut = _formatTime(checkOutRaw);
                  final workHours = attendance['workHours'] ?? 0;
                  final status = attendance['status'] ?? 'N/A';
                  final isLate = attendance['isLate'] == true;
                  final lateBy = attendance['lateBy'] ?? 0;
                  final isShortAttendance = attendance['isShortAttendance'] == true;
                  final shortByMinutes = attendance['shortByMinutes'] ?? 0;

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.verified_user, color: Colors.indigo, size: 20),
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
                            Row(
                              children: [
                                if (isLate)
                                  Container(
                                    margin: EdgeInsets.only(left: 6),
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                if (isShortAttendance)
                                  Container(
                                    margin: EdgeInsets.only(left: 6),
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Short by $shortByMinutes min',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTimeTile(
                              icon: Icons.login_rounded,
                              label: "Check-In",
                              time: checkIn,
                              color: Colors.green,
                            ),
                            SizedBox(width: 10),
                            _buildTimeTile(
                              icon: Icons.logout_rounded,
                              label: "Check-Out",
                              time: checkOut,
                              color: Colors.red,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, color: Colors.amber[700], size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Work Hours: ${workHours.toStringAsFixed(2)} hrs',
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
              children: stats.entries
                  .map<Widget>((entry) => _buildStatCard(context, entry.key, entry.value))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String key, dynamic value) {
    // Normalize key (ignore case and spacing)
    final normalizedKey = key.toLowerCase().replaceAll(' ', '');

    // Define icons and colors
    final Map<String, Map<String, dynamic>> statConfig = {
      'totaldays': {'icon': Icons.calendar_today, 'color': Colors.blue},
      'present': {'icon': Icons.check_circle, 'color': Colors.green},
      'absent': {'icon': Icons.cancel, 'color': Colors.red},
      'halfday': {'icon': Icons.remove_circle_outline, 'color': Colors.orange},
      'onleave': {'icon': Icons.beach_access, 'color': Colors.teal},
      'holiday': {'icon': Icons.card_giftcard, 'color': Colors.pink},
      'weeklyoff': {'icon': Icons.weekend, 'color': Colors.purple},
      'combooff': {'icon': Icons.event_available, 'color': Colors.deepPurple},
      'totalworkhours': {'icon': Icons.schedule, 'color': Colors.indigo},
      'latecount': {'icon': Icons.access_time, 'color': Colors.amber},
    };

    final config = statConfig[normalizedKey] ??
        {'icon': Icons.info, 'color': Colors.grey};

    // Format value
    String formattedValue;
    if (value is double) {
      formattedValue = value.toStringAsFixed(1);
    } else {
      formattedValue = '$value';
    }

    return GestureDetector(
      onTap: () {
        if (normalizedKey == 'totalworkhours') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const MonthlyWorkHoursBottomSheet(),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: config['color'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config['color'].withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(config['icon'], color: config['color'], size: 28),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formattedValue,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: config['color'],
                  ),
                ),
              ),
              const SizedBox(height: 4),
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
      ),
    );
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

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}