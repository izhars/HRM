import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:staffsync/component/test.dart';
import 'package:staffsync/screens/announcement.dart';
import 'package:staffsync/screens/chat_connection_screen.dart';
import 'package:staffsync/screens/payroll_screen.dart';
import '../../component/celebration_ui.dart' hide CelebrationScreen;
import '../../component/top_bar.dart';
import '../../component/upcoming_festivals.dart';
import '../../core/geocoding_service.dart';
import '../../core/location_service.dart';
import '../../services/attendance_api.dart';
import '../../utils/device_info.dart';
import '../../widgets/day_time_widget.dart';
import '../FeedbackScreen.dart';
import '../PollScreen.dart';
import '../SupportScreen.dart';
import '../celebration_screen.dart';
import '../leave_screen.dart';
import '../holiday_screen.dart';
import '../report_screen.dart';
import '../task_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  LatLng? _currentLatLng;
  String _address = "Loading location...";
  bool _isLoading = false;
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  String? _checkInTime;
  String? _checkOutTime;
  double? _currentWorkHours; // Change to double to handle decimal hours
  String? _statusMessage;
  double? _latenessMinutes;
  String? _currentDate;
  String? _deviceLocation;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();
  final AttendanceService _attendanceService = AttendanceService();

  String? _deviceModel;
  String? _deviceOS;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _initDeviceInfo();
    _getLocationAndAddress();
    _setCurrentDate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    setState(() {
      _currentDate = "${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}";
    });
  }

  Future<void> _initDeviceInfo() async {
    _deviceModel = await DeviceInfo.model();
    _deviceOS = await DeviceInfo.os();
    setState(() {});
  }

  Future<void> _getLocationAndAddress() async {
    setState(() => _isLoading = true);
    try {
      LatLng? current = await _locationService.getCurrentLocation();
      if (current == null) {
        setState(() {
          _address = "Unable to get location";
        });
        return;
      }

      _currentLatLng = current;
      final location = await _geocodingService.reverseGeocode(
          current.latitude, current.longitude);

      setState(() {
        _address = location.address ?? "Unknown location";
        _deviceLocation = "${current.latitude.toStringAsFixed(4)}, ${current.longitude.toStringAsFixed(4)}";
      });

      await _loadTodayAttendance();
    } catch (e) {
      setState(() {
        _address = "Location error: $e";
      });
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Convert decimal hours to hours and minutes format
  String _formatWorkHours(double? decimalHours) {
    if (decimalHours == null || decimalHours <= 0) return "0h 0m";

    final hours = decimalHours.floor();
    final minutes = ((decimalHours - hours) * 60).round();

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }

  // Convert minutes to hours and minutes format
  String _formatLateTime(double? minutes) {
    if (minutes == null || minutes <= 0) return "On time";

    final hours = (minutes / 60).floor();
    final remainingMinutes = (minutes % 60).round();

    if (hours > 0) {
      return "${hours}h ${remainingMinutes}m late";
    } else {
      return "${remainingMinutes}m late";
    }
  }

  Future<void> _checkOut() async {
    if (_currentLatLng == null || !_isCheckedIn) {
      _showSnackBar("Cannot check out without checking in first", Colors.orange.shade300);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _attendanceService.checkOut(
        latitude: _currentLatLng!.latitude,
        longitude: _currentLatLng!.longitude,
        address: _address,
        deviceInfo: "${_deviceOS ?? ''} | ${_deviceModel ?? ''}",
      );

      if (response['success'] == true) {
        setState(() {
          _isCheckedOut = true;
          _checkOutTime = response['checkOutTimeFormatted'] ?? response['attendance']['checkOut']['time'];
          _statusMessage = response['message'];
          _currentWorkHours = response['currentWorkHours']?.toDouble() ??
              response['attendance']['workHours']?.toDouble();
        });

        _showSnackBar("✅ ${_statusMessage ?? 'Checked out successfully'}", Colors.green.shade300);
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      _showSnackBar("❌ Check-out failed: $e", Colors.red.shade300);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final response = await _attendanceService.fetchTodayAttendance();

      if (response['success'] == true) {
        setState(() {
          _isCheckedIn = response['isCheckedIn'] ?? false;
          _isCheckedOut = response['isCheckedOut'] ?? false;

          final attendance = response['attendance'];
          if (attendance != null) {
            // Use the formatted times from the new API response
            _checkInTime = response['checkInTimeFormatted'] ?? attendance['checkInTimeFormatted'];
            _checkOutTime = response['checkOutTimeFormatted'] ?? attendance['checkOutTimeFormatted'];

            // Use currentWorkHours from the new API response
            _currentWorkHours = response['currentWorkHours']?.toDouble() ??
                attendance['workHours']?.toDouble() ?? 0.0;

            _latenessMinutes = attendance['lateBy']?.toDouble();
            _statusMessage = attendance['status'] ?? 'Present';
          }
        });
      }
    } catch (e) {
      print("Error fetching attendance: $e");
    }
  }

  Future<void> _checkIn() async {
    if (_currentLatLng == null) {
      _showSnackBar("Location not available", Colors.red.shade300);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _attendanceService.checkIn(
        latitude: _currentLatLng!.latitude,
        longitude: _currentLatLng!.longitude,
        address: _address,
        deviceInfo: "${_deviceOS ?? ''} | ${_deviceModel ?? ''}",
      );

      if (response['success'] == true) {
        setState(() {
          _isCheckedIn = true;
          _checkInTime = response['checkInTimeFormatted'] ?? response['attendance']['checkInTimeFormatted'];
          _statusMessage = response['message'];
          _latenessMinutes = response['lateBy']?.toDouble();
          _currentWorkHours = 0.0; // Start with 0 work hours
        });

        _showSnackBar("✅ ${_statusMessage ?? 'Checked in successfully'}", Colors.green.shade300);
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      _showSnackBar("❌ Check-in failed: $e", Colors.red.shade300);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
        backgroundColor: color,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
// Add this new navigation method
  void _navigateToHoliday() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PremiumHolidayCalendar()),
    );
  }

  void _navigateToReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReportScreen()),
    );
  }

  void _navigateToSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupportScreen()),
    );
  }

  void _navigateToAnnouncement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AnnouncementsPage()),
    );
  }

  void _navigateToPolls() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PollScreen()),
    );
  }

  void _navigateToTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TasksScreen()),
    );
  }

  void _navigateToLeaves() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LeavesScreen()),
    );
  }

  void _navigateToPayroll() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PayrollScreen()),
    );
  }

  void _navigateToFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FeedbackScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: TopBar(
          address: _address,
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _getLocationAndAddress,
        color: Colors.blue.shade300,
        child: ListView(
          padding: EdgeInsets.only(bottom: 20),
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        DayTimeWidget(),
                        // Enhanced Feature Cards Row with Light Colors
                        Container(
                          margin: EdgeInsets.all(10),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                children: [
                                  _buildSmallFeatureCard("Reports", Icons.analytics_rounded,
                                      [Colors.blue.shade200, Colors.blue.shade100], Colors.blue.shade600, _navigateToReport),
                                  _buildSmallFeatureCard("Tasks", Icons.task_alt_rounded,
                                      [Colors.red.shade200, Colors.red.shade100], Colors.red.shade600, _navigateToTasks),
                                  _buildSmallFeatureCard("Leaves", Icons.event_available_rounded,
                                      [Colors.green.shade200, Colors.green.shade100], Colors.green.shade600, _navigateToLeaves),
                                  _buildSmallFeatureCard("Payroll", Icons.account_balance_wallet_rounded,
                                      [Colors.purple.shade200, Colors.purple.shade100], Colors.purple.shade600, _navigateToPayroll),
                                  _buildSmallFeatureCard("Holiday", Icons.event_rounded,
                                      [Colors.teal.shade200, Colors.teal.shade100], Colors.teal.shade600, _navigateToHoliday),
                                  _buildSmallFeatureCard("Polls", Icons.poll_rounded,
                                      [Colors.indigo.shade200, Colors.indigo.shade100], Colors.indigo.shade600, _navigateToPolls),
                                  _buildSmallFeatureCard("Support", Icons.support_agent,
                                      [Colors.orange.shade200, Colors.orange.shade100], Colors.orange.shade600, _navigateToSupport),
                                  _buildSmallFeatureCard("Announcement", Icons.campaign_rounded,
                                      [Colors.pink.shade200, Colors.pink.shade100], Colors.pink.shade600, _navigateToAnnouncement),
                                  _buildSmallFeatureCard("Feedback", Icons.feedback_rounded,
                                      [Colors.amber.shade200, Colors.amber.shade100], Colors.amber.shade700, _navigateToFeedback,),
                                ],
                              );
                            },
                          ),
                        ),
                        // Enhanced Attendance Status Card with Light Colors
                        _buildEnhancedAttendanceCard(),
                        SizedBox(height: 20),
                        // Festivals Card with Light Colors
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          elevation: 4,
                          shadowColor: Colors.purple.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.purple.shade50],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.purple.shade200, Colors.purple.shade100],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.purple.shade100,
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.celebration_rounded,
                                          color: Colors.purple.shade600,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          "Public Holidays & Festivals",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const UpcomingFestivals(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        CelebrationWidget(
                          showHeader: true,
                          showViewAllButton: true,
                          onViewAllPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CelebrationScreen()),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallFeatureCard(String title, IconData icon, List<Color> gradientColors, Color iconColor, VoidCallback onTap) {
    return Container(
      width: 80, // Fixed width for small cards
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, List<Color> gradientColors, Color iconColor, VoidCallback onTap) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.1,
        child: Container(
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: iconColor, size: 32),
                    ),
                    SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAttendanceCard() {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: _getAttendanceGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _getAttendanceGradientColors().first.withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: _getStatusIconColor(),
                      size: 36,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusTitle(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _currentDate ?? "Today",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Status Information Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Time Information
                    if (_checkInTime != null || _checkOutTime != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeInfo(
                              "Check-in",
                              _checkInTime != null ? _formatTime(_checkInTime!) : "--:--",
                              Icons.login_rounded,
                              Colors.green.shade400,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildTimeInfo(
                              "Check-out",
                              _checkOutTime != null ? _formatTime(_checkOutTime!) : "--:--",
                              Icons.logout_rounded,
                              Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],

                    // Additional Information
                    Row(
                      children: [
                        if (_currentWorkHours != null) ...[
                          Expanded(
                            child: _buildInfoChip(
                              "Work Time",
                              _formatWorkHours(_currentWorkHours),
                              Icons.access_time_rounded,
                              Colors.blue.shade400,
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                        Expanded(
                          child: _buildInfoChip(
                            "Status",
                            _latenessMinutes != null && _latenessMinutes! > 0
                                ? _formatLateTime(_latenessMinutes)
                                : (_statusMessage ?? "On time"),
                            _latenessMinutes != null && _latenessMinutes! > 0
                                ? Icons.warning_rounded
                                : Icons.check_circle_rounded,
                            _latenessMinutes != null && _latenessMinutes! > 0
                                ? Colors.orange.shade400
                                : Colors.green.shade400,
                          ),
                        ),
                      ],
                    ),

                    // Device and Location Info
                    if (_deviceModel != null || _deviceLocation != null) ...[
                      SizedBox(height: 16),
                      Row(
                        children: [
                          if (_deviceModel != null) ...[
                            Expanded(
                              child: _buildInfoChip(
                                "Device",
                                "${_deviceOS ?? ''} | ${_deviceModel ?? ''}",
                                Icons.phone_android_rounded,
                                Colors.purple.shade400,
                              ),
                            ),
                          ],
                          if (_deviceLocation != null) ...[
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoChip(
                                "Location",
                                _deviceLocation!,
                                Icons.location_on_rounded,
                                Colors.teal.shade400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              SizedBox(height: 12),
              Text(
                "Processing...",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            onPressed: _isCheckedIn ? null : _checkIn,
            icon: Icons.login_rounded,
            label: _isCheckedIn ? "Checked In" : "Check In",
            isPrimary: true,
            isEnabled: !_isCheckedIn,
          ),
        ),
        if (_isCheckedIn && !_isCheckedOut) ...[
          SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              onPressed: _checkOut,
              icon: Icons.logout_rounded,
              label: "Check Out",
              isPrimary: false,
              isEnabled: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isEnabled,
  }) {
    return Container(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? Colors.white
              : Colors.red.shade300,
          foregroundColor: isPrimary
              ? _getAttendanceGradientColors().first
              : Colors.white,
          disabledBackgroundColor: Colors.white.withOpacity(0.5),
          disabledForegroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isPrimary ? 4 : 3,
          shadowColor: isPrimary ? Colors.black12 : Colors.red.shade100,
        ),
      ),
    );
  }

  List<Color> _getAttendanceGradientColors() {
    if (_isCheckedOut) {
      return [Colors.green.shade300, Colors.green.shade200]; // Light green for completed
    }
    if (_isCheckedIn) {
      if (_latenessMinutes != null && _latenessMinutes! > 0) {
        return [Colors.orange.shade300, Colors.orange.shade200]; // Light orange for late
      }
      return [Colors.blue.shade300, Colors.blue.shade200]; // Light blue for active
    }
    return [Colors.grey.shade300, Colors.grey.shade200]; // Light grey for inactive
  }

  Color _getStatusIconColor() {
    if (_isCheckedOut) return Colors.green.shade600;
    if (_isCheckedIn) {
      if (_latenessMinutes != null && _latenessMinutes! > 0) {
        return Colors.orange.shade600;
      }
      return Colors.blue.shade600;
    }
    return Colors.grey.shade600;
  }

  IconData _getStatusIcon() {
    if (_isCheckedOut) return Icons.check_circle_rounded;
    if (_isCheckedIn) {
      if (_latenessMinutes != null && _latenessMinutes! > 0) {
        return Icons.warning_rounded;
      }
      return Icons.timer_rounded;
    }
    return Icons.schedule_rounded;
  }

  String _getStatusTitle() {
    if (_isCheckedOut) return "Session Complete";
    if (_isCheckedIn) {
      if (_latenessMinutes != null && _latenessMinutes! > 0) {
        return "Active Session (Late)";
      }
      return "Active Session";
    }
    return "Ready to Check In";
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : hour;
      return "${displayHour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return isoString;
    }
  }
}
