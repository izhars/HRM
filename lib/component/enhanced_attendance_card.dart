import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AttendanceSummaryCard extends StatefulWidget {
  final String? statusTitle;
  final String? currentDate;
  final String? checkInTime;
  final String? checkOutTime;
  final double? currentWorkHours;
  final double? latenessMinutes;
  final String? statusMessage;
  final String? deviceModel;
  final String? deviceOS;
  final String? deviceLocation;
  final bool isCheckedIn;
  final bool isCheckedOut;
  final bool isLoading;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;

  const AttendanceSummaryCard({
    super.key,
    this.statusTitle,
    this.currentDate,
    this.checkInTime,
    this.checkOutTime,
    this.currentWorkHours,
    this.latenessMinutes,
    this.statusMessage,
    this.deviceModel,
    this.deviceOS,
    this.deviceLocation,
    this.isCheckedIn = false,
    this.isCheckedOut = false,
    this.isLoading = false,
    this.onCheckIn,
    this.onCheckOut,
  });

  @override
  State<AttendanceSummaryCard> createState() => _AttendanceSummaryCardState();
}

class _AttendanceSummaryCardState extends State<AttendanceSummaryCard> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  // Check if biometric authentication is available on the device
  Future<void> _checkBiometricAvailability() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (canAuthenticate) {
        final List<BiometricType> availableBiometrics =
        await _auth.getAvailableBiometrics();
        debugPrint('Available biometrics: $availableBiometrics');
      }
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
    }
  }

  // Authenticate user with biometrics
  Future<bool> _authenticateWithBiometrics(String action) async {
    if (_isAuthenticating) return false;

    try {
      setState(() => _isAuthenticating = true);

      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      // If device has no biometrics or no secure lock at all — directly punch
      if (!canCheckBiometrics && !isDeviceSupported) {
        debugPrint('No biometric or device lock available. Skipping auth...');
        _showMessage('No biometric available. Auto $action successful!');
        return true; // ✅ Directly allow check-in/out
      }

      // Proceed with authentication (if supported)
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to $action',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        _showMessage('Authentication successful!');
        return true;
      } else {
        _showMessage('Authentication failed or canceled');
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('PlatformException: ${e.code} - ${e.message}');
      // In case of biometric not enrolled, unavailable, etc. — skip auth
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        _showMessage('No biometrics enrolled. Auto $action successful!');
        return true; // ✅ Auto allow check-in/out
      }

      _showMessage('Authentication error: ${e.message}');
      return false;
    } catch (e) {
      _showMessage('Unexpected error: $e');
      debugPrint('Error during authentication: $e');
      return false;
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }


  // Handle check-in with biometric authentication
  Future<void> _handleCheckIn() async {
    final authenticated = await _authenticateWithBiometrics('check in');
    if (authenticated && widget.onCheckIn != null) {
      widget.onCheckIn!();
    }
  }

  // Handle check-out with biometric authentication
  Future<void> _handleCheckOut() async {
    final authenticated = await _authenticateWithBiometrics('check out');
    if (authenticated && widget.onCheckOut != null) {
      widget.onCheckOut!();
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Get color scheme based on attendance status
  AttendanceColorScheme _getColorScheme() {
    if (widget.isCheckedOut) {
      return AttendanceColorScheme(
        primaryGradient: [Colors.teal.shade400, Colors.teal.shade700],
        shadowColor: Colors.teal.shade400,
        iconColor: Colors.teal.shade600,
        accentColor: Colors.teal.shade500,
      );
    } else if (widget.isCheckedIn) {
      if (widget.latenessMinutes != null && widget.latenessMinutes! > 0) {
        return AttendanceColorScheme(
          primaryGradient: [Colors.orange.shade400, Colors.orange.shade700],
          shadowColor: Colors.orange.shade400,
          iconColor: Colors.orange.shade600,
          accentColor: Colors.orange.shade500,
        );
      } else {
        return AttendanceColorScheme(
          primaryGradient: [Colors.green.shade400, Colors.green.shade700],
          shadowColor: Colors.green.shade400,
          iconColor: Colors.green.shade600,
          accentColor: Colors.green.shade500,
        );
      }
    } else {
      return AttendanceColorScheme(
        primaryGradient: [Colors.indigo.shade400, Colors.indigo.shade700],
        shadowColor: Colors.indigo.shade400,
        iconColor: Colors.indigo.shade600,
        accentColor: Colors.indigo.shade500,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getColorScheme();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: colorScheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colorScheme),
              const SizedBox(height: 24),
              _buildContentBox(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AttendanceColorScheme colorScheme) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12, width: 1),
          ),
          child: Icon(
            _getHeaderIcon(),
            color: colorScheme.iconColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.statusTitle ?? "Attendance",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.currentDate ?? "Today",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(colorScheme),
      ],
    );
  }

  Widget _buildStatusBadge(AttendanceColorScheme colorScheme) {
    String badgeText;
    IconData badgeIcon;

    if (widget.isCheckedOut) {
      badgeText = "Done";
      badgeIcon = Icons.check_circle;
    } else if (widget.isCheckedIn) {
      if (widget.latenessMinutes != null && widget.latenessMinutes! > 0) {
        badgeText = "Late";
        badgeIcon = Icons.warning_rounded;
      } else {
        badgeText = "Active";
        badgeIcon = Icons.timelapse_rounded;
      }
    } else {
      badgeText = "Pending";
      badgeIcon = Icons.schedule_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.accentColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: colorScheme.accentColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorScheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getHeaderIcon() {
    if (widget.isCheckedOut) {
      return Icons.task_alt_rounded;
    } else if (widget.isCheckedIn) {
      return Icons.access_time_filled;
    } else {
      return Icons.schedule_rounded;
    }
  }

  Widget _buildContentBox(BuildContext context, AttendanceColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTimeInfoRow(),
          const SizedBox(height: 16),
          _buildStatusRow(),
          if (_hasDeviceOrLocationInfo()) ...[
            const SizedBox(height: 16),
            _buildDeviceLocationRow(),
          ],
          const SizedBox(height: 20),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildTimeInfoRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTimeInfo(
            "Check-in",
            widget.checkInTime ?? "--:--",
            Icons.login_rounded,
            widget.isCheckedIn ? Colors.green.shade400 : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTimeInfo(
            "Check-out",
            widget.checkOutTime ?? "--:--",
            Icons.logout_rounded,
            widget.isCheckedOut ? Colors.red.shade400 : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        if (widget.currentWorkHours != null) ...[
          Expanded(
            child: _buildInfoChip(
              "Work Time",
              _formatWorkHours(widget.currentWorkHours!),
              Icons.access_time_rounded,
              Colors.blue.shade400,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _buildInfoChip(
            "Status",
            _getStatusText(),
            _getStatusIcon(),
            _getStatusColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceLocationRow() {
    return Column(
      children: [
        if (widget.deviceModel != null)
          _buildInfoChip(
            "Device",
            "${widget.deviceOS ?? ''} | ${widget.deviceModel ?? ''}",
            Icons.phone_android_rounded,
            Colors.purple.shade400,
          ),
        if (widget.deviceModel != null && widget.deviceLocation != null)
          const SizedBox(height: 12),
        if (widget.deviceLocation != null)
          _buildInfoChip(
            "Location",
            widget.deviceLocation!,
            Icons.location_on_rounded,
            Colors.teal.shade400,
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCheckInButton(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCheckOutButton(),
        ),
      ],
    );
  }

  Widget _buildCheckInButton() {
    final bool canCheckIn = !widget.isCheckedIn && !widget.isLoading && !_isAuthenticating;
    final bool showLoading = (widget.isLoading && !widget.isCheckedIn) ||
        (_isAuthenticating && !widget.isCheckedIn);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canCheckIn ? _handleCheckIn : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: canCheckIn
                ? LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [Colors.grey.shade300, Colors.grey.shade400],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: canCheckIn
                ? [
              BoxShadow(
                color: Colors.green.shade300.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  widget.isCheckedIn ? Icons.check_circle : Icons.fingerprint,
                  color: Colors.white,
                  size: 22,
                ),
              const SizedBox(width: 8),
              Text(
                widget.isCheckedIn ? "Checked In" : "Check In",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckOutButton() {
    final bool canCheckOut = widget.isCheckedIn && !widget.isCheckedOut &&
        !widget.isLoading && !_isAuthenticating;
    final bool showLoading = (widget.isLoading && widget.isCheckedIn && !widget.isCheckedOut) ||
        (_isAuthenticating && widget.isCheckedIn);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canCheckOut ? _handleCheckOut : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: canCheckOut
                ? LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [Colors.grey.shade300, Colors.grey.shade400],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: canCheckOut
                ? [
              BoxShadow(
                color: Colors.red.shade300.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  widget.isCheckedOut ? Icons.check_circle : Icons.fingerprint,
                  color: Colors.white,
                  size: 22,
                ),
              const SizedBox(width: 8),
              Text(
                widget.isCheckedOut ? "Checked Out" : "Check Out",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String title, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color == Colors.grey.shade400 ? Colors.black38 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
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

  bool _hasDeviceOrLocationInfo() => widget.deviceModel != null || widget.deviceLocation != null;

  String _getStatusText() {
    if (widget.latenessMinutes != null && widget.latenessMinutes! > 0) {
      return _formatLateTime(widget.latenessMinutes!);
    }
    return widget.statusMessage ?? "On time";
  }

  IconData _getStatusIcon() {
    return (widget.latenessMinutes != null && widget.latenessMinutes! > 0)
        ? Icons.warning_rounded
        : Icons.check_circle_rounded;
  }

  Color _getStatusColor() {
    return (widget.latenessMinutes != null && widget.latenessMinutes! > 0)
        ? Colors.orange.shade400
        : Colors.green.shade400;
  }

  String _formatWorkHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return h > 0 ? "${h}h ${m}m" : "${m}m";
  }

  String _formatLateTime(double mins) {
    final hours = (mins / 60).floor();
    final remainingMinutes = (mins % 60).round();
    return hours > 0
        ? "${hours}h ${remainingMinutes}m late"
        : "${remainingMinutes.toInt()} mins late";
  }
}

class AttendanceColorScheme {
  final List<Color> primaryGradient;
  final Color shadowColor;
  final Color iconColor;
  final Color accentColor;

  AttendanceColorScheme({
    required this.primaryGradient,
    required this.shadowColor,
    required this.iconColor,
    required this.accentColor,
  });
}
