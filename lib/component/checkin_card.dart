import 'package:flutter/material.dart';

class CheckInCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCheckIn;
  final VoidCallback? onCheckOut;
  final bool isCheckedIn;
  final bool isCheckedOut;
  final String? checkInTime;
  final String? statusMessage;
  final bool? isLate;
  final int? lateBy; // in minutes

  const CheckInCard({
    Key? key,
    required this.isLoading,
    required this.onCheckIn,
    this.onCheckOut,
    required this.isCheckedIn,
    required this.isCheckedOut,
    this.checkInTime,
    this.statusMessage,
    this.isLate,
    this.lateBy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: _getGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _getGradientColors().first.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
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
                _buildHeader(),
                SizedBox(height: 16),
                _buildStatusInfo(),
                SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            _getStatusIcon(),
            color: Colors.white,
            size: 32,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusTitle(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _getStatusSubtitle(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (checkInTime != null) ...[
            _buildInfoRow(
              Icons.access_time,
              "Check-in Time",
              _formatTime(checkInTime!),
            ),
            if (isLate == true && lateBy != null) ...[
              SizedBox(height: 8),
              _buildInfoRow(
                Icons.warning_amber_rounded,
                "Late by",
                "${lateBy} minutes",
                isWarning: true,
              ),
            ],
          ],
          if (statusMessage != null) ...[
            if (checkInTime != null) SizedBox(height: 8),
            _buildInfoRow(
              Icons.info_outline,
              "Status",
              statusMessage!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isWarning = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isWarning ? Colors.amber : Colors.white.withOpacity(0.8),
        ),
        SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isWarning ? Colors.amber : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (isLoading) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            onPressed: isCheckedIn ? null : onCheckIn,
            icon: Icons.login_rounded,
            label: "Check In",
            isPrimary: true,
            isEnabled: !isCheckedIn,
          ),
        ),
        if (isCheckedIn && !isCheckedOut) ...[
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              onPressed: onCheckOut,
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
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? Colors.white
            : Colors.red.shade500,
        foregroundColor: isPrimary
            ? _getGradientColors().first
            : Colors.white,
        disabledBackgroundColor: Colors.white.withOpacity(0.3),
        disabledForegroundColor: Colors.white.withOpacity(0.5),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isPrimary ? 4 : 2,
        shadowColor: isPrimary ? Colors.black26 : Colors.red.withOpacity(0.3),
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (isCheckedOut) {
      return [Colors.grey.shade600, Colors.grey.shade400];
    }
    if (isCheckedIn) {
      if (isLate == true) {
        return [Colors.orange.shade600, Colors.orange.shade400];
      }
      return [Colors.green.shade600, Colors.green.shade400];
    }
    return [Colors.blue.shade600, Colors.blue.shade400];
  }

  IconData _getStatusIcon() {
    if (isCheckedOut) return Icons.check_circle_rounded;
    if (isCheckedIn) {
      if (isLate == true) return Icons.warning_rounded;
      return Icons.check_circle_rounded;
    }
    return Icons.schedule_rounded;
  }

  String _getStatusTitle() {
    if (isCheckedOut) return "Session Complete";
    if (isCheckedIn) {
      if (isLate == true) return "Active Session (Late)";
      return "Active Session";
    }
    return "Ready to Check In";
  }

  String _getStatusSubtitle() {
    if (isCheckedOut) return "You have successfully checked out";
    if (isCheckedIn) {
      if (isLate == true) return "Session started late";
      return "Session in progress";
    }
    return "Tap check-in to start your session";
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
