
import 'package:flutter/material.dart';
import '../services/holiday_api.dart';
import 'package:intl/intl.dart';

class UpcomingFestivals extends StatefulWidget {
  const UpcomingFestivals({Key? key}) : super(key: key);

  @override
  State<UpcomingFestivals> createState() => _UpcomingFestivalsState();
}

class _UpcomingFestivalsState extends State<UpcomingFestivals>
    with SingleTickerProviderStateMixin {
  final HolidayService _holidayService = HolidayService();
  late Future<List<Map<String, dynamic>>> _holidaysFuture;
  late AnimationController _animationController;

  // IST offset is +5:30 hours from UTC
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  // Light color palette matching the calendar
  static const Color primaryLight = Color(0xFF6B9FFF);
  static const Color primaryDark = Color(0xFF5B8FF9);
  static const Color accentLight = Color(0xFFFF9B9B);
  static const Color accentDark = Color(0xFFFF8787);
  static const Color backgroundColor = Color(0xFFF8FAFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color successColor = Color(0xFF7FD8BE);
  static const Color warningColor = Color(0xFFFFB84D);

  @override
  void initState() {
    super.initState();
    _holidaysFuture = _holidayService.fetchUpcomingHolidays();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Converts UTC DateTime to IST DateTime
  DateTime _convertToIST(DateTime utcDateTime) {
    return utcDateTime.toUtc().add(_istOffset);
  }

  /// Gets current IST time
  DateTime _getCurrentIST() {
    return _convertToIST(DateTime.now().toUtc());
  }

  /// Normalizes DateTime to date-only format in IST
  DateTime _normalizeDateIST(DateTime dateTime) {
    final istDate = _convertToIST(dateTime);
    return DateTime(istDate.year, istDate.month, istDate.day);
  }

  /// Process holiday date to ensure IST consistency
  DateTime _processHolidayDate(DateTime holidayDate) {
    // If the date from API is in UTC, convert to IST
    // If it's already local time, normalize it to IST date
    return holidayDate.isUtc
        ? _normalizeDateIST(holidayDate)
        : DateTime(holidayDate.year, holidayDate.month, holidayDate.day);
  }

  /// Calculate days until holiday from current IST time
  int _calculateDaysUntil(DateTime holidayDate) {
    final currentIST = _getCurrentIST();
    final currentISTDate = DateTime(currentIST.year, currentIST.month, currentIST.day);
    final processedHolidayDate = _processHolidayDate(holidayDate);

    return processedHolidayDate.difference(currentISTDate).inDays;
  }

  /// Get weekday name in IST
  String _getWeekdayName(DateTime date) {
    final istDate = _processHolidayDate(date);
    return DateFormat('EEEE').format(istDate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _holidaysFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          // Filter upcoming holidays using IST dates
          final upcomingHolidays = snapshot.data!.where((h) {
            final holidayDate = _processHolidayDate(h['date']);
            final currentIST = _getCurrentIST();
            final currentISTDate = DateTime(currentIST.year, currentIST.month, currentIST.day);

            return holidayDate.isAfter(currentISTDate) || holidayDate.isAtSameMomentAs(currentISTDate);
          }).toList();

          // Sort by IST dates
          upcomingHolidays.sort((a, b) {
            final dateA = _processHolidayDate(a['date']);
            final dateB = _processHolidayDate(b['date']);
            return dateA.compareTo(dateB);
          });

          if (upcomingHolidays.isEmpty) {
            return _buildEmptyState();
          }

          return _buildFestivalsList(upcomingHolidays);
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1.0, -0.3),
                  end: const Alignment(1.0, 0.3),
                  colors: const [
                    Color(0xFFF0F4FF),
                    Color(0xFFFFFFFF),
                    Color(0xFFF0F4FF),
                  ],
                  stops: [
                    _animationController.value - 0.3,
                    _animationController.value,
                    _animationController.value + 0.3,
                  ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentLight.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: accentDark,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _holidaysFuture = _holidayService.fetchUpcomingHolidays();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: primaryLight.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryLight.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                color: primaryLight.withOpacity(0.6),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Upcoming Festivals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for new celebrations',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFestivalsList(List<Map<String, dynamic>> holidays) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: holidays.length,
          itemBuilder: (context, index) {
            final holiday = holidays[index];
            return _buildFestivalCard(holiday, index);
          },
        ),
      ],
    );
  }

  Widget _buildFestivalCard(Map<String, dynamic> holiday, int index) {
    final DateTime originalDate = holiday['date'];
    final DateTime processedDate = _processHolidayDate(originalDate);
    final int daysUntil = _calculateDaysUntil(originalDate);
    final festivalColor = _getFestivalColor(holiday['type']);
    final String weekdayName = _getWeekdayName(originalDate);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: festivalColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: festivalColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showHolidayDetails(context, holiday),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Date Badge
                  _buildDateBadge(processedDate, festivalColor),
                  const SizedBox(width: 16),
                  // Festival Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                holiday['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            if (daysUntil <= 7)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentLight.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Soon',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: accentDark,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: textSecondary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              weekdayName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: textSecondary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getDaysUntilText(daysUntil),
                              style: TextStyle(
                                fontSize: 14,
                                color: festivalColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                          ],
                        ),
                        if (holiday['description'] != null &&
                            holiday['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            holiday['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Arrow Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: festivalColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: festivalColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBadge(DateTime date, Color color) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getMonthName(date.month),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFestivalColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'festival':
        return primaryLight;
      case 'holiday':
        return successColor;
      case 'celebration':
        return accentLight;
      default:
        return warningColor;
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[month];
  }

  String _getDaysUntilText(int days) {
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days < 7) return 'In $days days';
    if (days < 30) return 'In ${(days / 7).floor()} weeks';
    return 'In ${(days / 30).floor()} months';
  }

  void _showHolidayDetails(BuildContext context, Map<String, dynamic> holiday) {
    final festivalColor = _getFestivalColor(holiday['type']);
    final DateTime originalDate = holiday['date'];
    final DateTime processedDate = _processHolidayDate(originalDate);
    final int daysUntil = _calculateDaysUntil(originalDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [festivalColor, festivalColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: festivalColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          holiday['name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              holiday['type'] ?? 'Festival',
                              style: TextStyle(
                                fontSize: 14,
                                color: festivalColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryLight.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'IST',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Date info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: festivalColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: festivalColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: festivalColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d, y').format(processedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '${_getDaysUntilText(daysUntil)} • Indian Standard Time',
                            style: TextStyle(
                              fontSize: 14,
                              color: festivalColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Description
              if (holiday['description'] != null &&
                  holiday['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  holiday['description'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: festivalColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: festivalColor.withOpacity(0.4),
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
