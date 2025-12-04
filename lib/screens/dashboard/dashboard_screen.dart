import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:staffsync/screens/Sidebar.dart';
import 'package:staffsync/screens/announcement.dart';
import 'package:staffsync/screens/combo_off_screen.dart';
import 'package:staffsync/screens/payroll_screen.dart';
import '../../app/AppScreen.dart';
import '../../component/AnnouncementsHomeWidget.dart';
import '../../component/AppInfo.dart';
import '../../component/BouncyFeatureCard.dart';
import '../../component/celebration_ui.dart' hide CelebrationScreen;
import '../../component/enhanced_attendance_card.dart';
import '../../component/top_bar.dart';
import '../../component/upcoming_festivals.dart';
import '../../core/geocoding_service.dart';
import '../../core/location_service.dart';
import '../../models/user.dart';
import '../../services/attendance_api.dart';
import '../../services/auth_service.dart';
import '../../services/avatar_api.dart';
import '../../utils/device_info.dart';
import '../../widgets/day_time_widget.dart';
import '../FeedbackScreen.dart';
import '../PollScreen.dart';
import '../SupportScreen.dart';
import '../award_screen.dart';
import '../celebration_screen.dart';
import '../leave_screen.dart';
import '../holiday_screen.dart';
import '../report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // Location & Address
  LatLng? _currentLatLng;
  String _address = "Loading location...";
  String? _deviceLocation;
  File? _currentAvatar;
  bool _loadingAddress = false;
  User? _currentUser;
  String? token;
  // Loading States
  bool _isInitialLoading = true;
  bool _isAttendanceLoading = false;

  // Attendance State
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  String? _checkInTime;
  String? _checkOutTime;
  double? _currentWorkHours;
  String? _statusMessage;
  double? _latenessMinutes;

  // Device & App Info
  String? _currentDate;
  String? _deviceModel;
  String? _deviceOS;
  Map<String, String>? _info;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Services
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initAnimations();
    _initializeData();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final authService = AuthService();
    final fetchedToken = await authService.getToken(); // fetch token
    // ✅ Print in console
    print('Fetched Token: $fetchedToken');
    setState(() {
      token = fetchedToken;
    });
  }

  Future<void> _loadData() async {
    setState(() => _loadingAddress = true);
    final user = await AuthService().getCurrentUser(); // fetch user from storage
    final avatar = await AvatarService.getAvatar();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _currentAvatar = avatar;
        _loadingAddress = false;
      });
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  Future<void> _initializeData() async {
    _setCurrentDate();
    await Future.wait([
      _loadAppInfo(),
      _initDeviceInfo(),
      _getLocationAndAddress(),
    ]);
    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _getLocationAndAddress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    final details = await AppInfo.getAppDetails();
    if (mounted) {
      setState(() => _info = details);
    }
  }

  void _setCurrentDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    setState(() {
      _currentDate = "${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}";
    });
  }

  Future<void> _initDeviceInfo() async {
    final model = await DeviceInfo.model();
    final os = await DeviceInfo.os();
    if (mounted) {
      setState(() {
        _deviceModel = model;
        _deviceOS = os;
      });
    }
  }

  Future<void> _getLocationAndAddress() async {
    try {
      final current = await _locationService.getCurrentLocation();
      if (current == null) {
        setState(() => _address = "Unable to get location");
        return;
      }

      _currentLatLng = current;
      final location = await _geocodingService.reverseGeocode(
          current.latitude, current.longitude);

      if (mounted) {
        setState(() {
          _address = location.address ?? "Unknown location";
          _deviceLocation = "${current.latitude.toStringAsFixed(4)}, ${current.longitude.toStringAsFixed(4)}";
        });
      }

      await _loadTodayAttendance();
    } catch (e) {
      if (mounted) {
        setState(() => _address = "Location error: $e");
      }
      debugPrint("Error: $e");
    }
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final response = await _attendanceService.fetchTodayAttendance();

      if (response['success'] == true && mounted) {
        final attendance = response['attendance'];
        setState(() {
          _isCheckedIn = response['isCheckedIn'] ?? false;
          _isCheckedOut = response['isCheckedOut'] ?? false;

          if (attendance != null) {
            _checkInTime = response['checkInTimeFormatted'] ?? attendance['checkInTimeFormatted'];
            _checkOutTime = response['checkOutTimeFormatted'] ?? attendance['checkOutTimeFormatted'];
            _currentWorkHours = response['currentWorkHours']?.toDouble() ??
                attendance['workHours']?.toDouble() ?? 0.0;
            _latenessMinutes = attendance['lateBy']?.toDouble();
            _statusMessage = attendance['status'] ?? 'Present';
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching attendance: $e");
    }
  }

  Future<void> _checkIn() async {
    if (_currentLatLng == null) {
      _showSnackBar("Location not available", Colors.red.shade300);
      return;
    }

    setState(() => _isAttendanceLoading = true);

    try {
      final response = await _attendanceService.checkIn(
        latitude: _currentLatLng!.latitude,
        longitude: _currentLatLng!.longitude,
        address: _address,
        deviceInfo: "${_deviceOS ?? ''} | ${_deviceModel ?? ''}",
      );

      if (response['success'] == true && mounted) {
        setState(() {
          _isCheckedIn = true;
          _checkInTime = response['checkInTimeFormatted'] ?? response['attendance']['checkInTimeFormatted'];
          _statusMessage = response['message'];
          _latenessMinutes = response['lateBy']?.toDouble();
          _currentWorkHours = 0.0;
        });

        _showSnackBar("✅ ${_statusMessage ?? 'Checked in successfully'}", Colors.green.shade300);
      }
    } catch (e) {
      _showSnackBar("❌ Check-in failed: $e", Colors.red.shade300);
    } finally {
      if (mounted) {
        setState(() => _isAttendanceLoading = false);
      }
    }
  }

  Future<void> _checkOut() async {
    if (_currentLatLng == null || !_isCheckedIn) {
      _showSnackBar("Cannot check out without checking in first", Colors.orange.shade300);
      return;
    }

    setState(() => _isAttendanceLoading = true);

    try {
      final response = await _attendanceService.checkOut(
        latitude: _currentLatLng!.latitude,
        longitude: _currentLatLng!.longitude,
        address: _address,
        deviceInfo: "${_deviceOS ?? ''} | ${_deviceModel ?? ''}",
      );

      if (response['success'] == true && mounted) {
        setState(() {
          _isCheckedOut = true;
          _checkOutTime = response['checkOutTimeFormatted'] ?? response['attendance']['checkOut']['time'];
          _statusMessage = response['message'];
          _currentWorkHours = response['currentWorkHours']?.toDouble() ??
              response['attendance']['workHours']?.toDouble();
        });

        _showSnackBar("✅ ${_statusMessage ?? 'Checked out successfully'}", Colors.green.shade300);
      }
    } catch (e) {
      _showSnackBar("❌ Check-out failed: $e", Colors.red.shade300);
    } finally {
      if (mounted) {
        setState(() => _isAttendanceLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateTo(AppScreen screen) {
    final targetScreen = _screenMap[screen];
    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    }
  }

  final Map<AppScreen, Widget> _screenMap = {
    AppScreen.report: ReportScreen(),
    AppScreen.tasks: AwardScreen(),
    AppScreen.leaves: LeavesScreen(),
    AppScreen.payroll: PayrollScreen(),
    AppScreen.holiday: PremiumHolidayCalendar(),
    AppScreen.polls: PollScreen(),
    AppScreen.support: SupportScreen(),
    AppScreen.announcement: AnnouncementsPage(),
    AppScreen.feedback: FeedbackScreen(),
    AppScreen.combooff: ComboOffScreen(),
  };

  String _getStatusTitle() {
    if (_isCheckedOut) return "Session Complete";
    if (_isCheckedIn) {
      return (_latenessMinutes != null && _latenessMinutes! > 0)
          ? "Active Session (Late)"
          : "Active Session";
    }
    return "Ready to Check In";
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toUtc().add(const Duration(hours: 5, minutes: 30));
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : hour;
      return "${displayHour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return isoString;
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with gradient
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Logout?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Are you sure you want to logout from your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          // Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Logout Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Colors.red.shade200,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await AuthService().logout();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: Sidebar(
        userName: _currentUser?.fullName ?? 'Loading...',
        userEmail: _currentUser?.email ?? 'Loading...',
        employeeId: _currentUser?.employeeId ?? '---',  // <-- add this
        avatarFile: _currentAvatar,               // <-- unified source
        onLogout: _handleLogout,
        parentContext: context, // ✅ Pass the parent context         // <-- same navigation
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopBar(address: _address),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Skeletonizer(
          enabled: _isInitialLoading,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            physics: const AlwaysScrollableScrollPhysics(),
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
                          _buildFeatureGrid(),
                          AnnouncementsHomeWidget(),
                          AttendanceSummaryCard(
                            statusTitle: _getStatusTitle(),
                            currentDate: _currentDate,
                            checkInTime: _checkInTime != null ? _formatTime(_checkInTime!) : null,
                            checkOutTime: _checkOutTime != null ? _formatTime(_checkOutTime!) : null,
                            currentWorkHours: _currentWorkHours,
                            latenessMinutes: _latenessMinutes,
                            statusMessage: _statusMessage,
                            deviceModel: _deviceModel,
                            deviceOS: _deviceOS,
                            deviceLocation: _deviceLocation,
                            isCheckedIn: _isCheckedIn,
                            isCheckedOut: _isCheckedOut,
                            isLoading: _isAttendanceLoading,
                            onCheckIn: _checkIn,
                            onCheckOut: _checkOut,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.teal.shade50],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.teal.shade200,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.teal.shade200, Colors.teal.shade100],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.teal.shade100,
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.celebration_rounded,
                                          color: Colors.teal.shade600,
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
                                            color: Colors.teal.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const UpcomingFestivals(),
                                ],
                              ),
                            ),
                          ),
                          CelebrationWidget(
                            showHeader: true,
                            showViewAllButton: true,
                            onViewAllPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CelebrationScreen()),
                              );
                            },
                          ),
                          if (_info != null) _buildAppInfo(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
          return GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFeatureCard("Reports", Icons.analytics_rounded,
                  [Colors.blue.shade200, Colors.blue.shade100], Colors.blue.shade600, AppScreen.report),
              _buildFeatureCard("Tasks", Icons.task_alt_rounded,
                  [Colors.red.shade200, Colors.red.shade100], Colors.red.shade600, AppScreen.tasks),
              _buildFeatureCard("Leaves", Icons.event_available_rounded,
                  [Colors.green.shade200, Colors.green.shade100], Colors.green.shade600, AppScreen.leaves),
              _buildFeatureCard("Payroll", Icons.account_balance_wallet_rounded,
                  [Colors.purple.shade200, Colors.purple.shade100], Colors.purple.shade600, AppScreen.payroll),
              _buildFeatureCard("Holiday", Icons.event_rounded,
                  [Colors.teal.shade200, Colors.teal.shade100], Colors.teal.shade600, AppScreen.holiday),
              _buildFeatureCard("Polls", Icons.poll_rounded,
                  [Colors.indigo.shade200, Colors.indigo.shade100], Colors.indigo.shade600, AppScreen.polls),
              _buildFeatureCard("Support", Icons.support_agent,
                  [Colors.orange.shade200, Colors.orange.shade100], Colors.orange.shade600, AppScreen.support),
              _buildFeatureCard("Announcement", Icons.campaign_rounded,
                  [Colors.pink.shade200, Colors.pink.shade100], Colors.pink.shade600, AppScreen.announcement),
              _buildFeatureCard("Feedback", Icons.feedback_rounded,
                  [Colors.amber.shade200, Colors.amber.shade100], Colors.amber.shade700, AppScreen.feedback),
              _buildFeatureCard("Combooff", Icons.compare_arrows,
                  [Colors.grey.shade200, Colors.grey.shade100], Colors.grey.shade700, AppScreen.combooff),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(
      String title,
      IconData icon,
      List<Color> gradientColors,
      Color iconColor,
      AppScreen screen,
      ) {
    return BouncyFeatureCard(
      title: title,
      icon: icon,
      gradientColors: gradientColors,
      iconColor: iconColor,
      onTap: () => _navigateTo(screen),
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          'Version ${_info!['version']} (${_info!['buildNumber']})',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          _info!['copyright']!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          _info!['madeIn']!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}