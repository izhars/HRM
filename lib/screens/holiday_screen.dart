
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/holiday_api.dart';

class PremiumHolidayCalendar extends StatefulWidget {
  const PremiumHolidayCalendar({super.key});

  @override
  State<PremiumHolidayCalendar> createState() => _PremiumHolidayCalendarState();
}

class _PremiumHolidayCalendarState extends State<PremiumHolidayCalendar>
    with TickerProviderStateMixin {
  Map<DateTime, List<Map<String, String>>> _holidays = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late AnimationController _shimmerController;
  late AnimationController _fadeController;

  // IST offset is +5:30 hours from UTC
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  // Light color palette
  static const Color primaryLight = Color(0xFF6B9FFF);
  static const Color primaryDark = Color(0xFF5B8FF9);
  static const Color accentLight = Color(0xFFFF9B9B);
  static const Color accentDark = Color(0xFFFF8787);
  static const Color backgroundColor = Color(0xFFF8FAFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color shimmerBase = Color(0xFFF0F4FF);
  static const Color shimmerHighlight = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize with IST time
    _focusedDay = _convertToIST(DateTime.now());
    _loadHolidays(_focusedDay.year, _focusedDay.month);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Converts UTC DateTime to IST DateTime
  DateTime _convertToIST(DateTime utcDateTime) {
    return utcDateTime.toUtc().add(_istOffset);
  }

  /// Converts IST DateTime to UTC DateTime
  DateTime _convertToUTC(DateTime istDateTime) {
    return istDateTime.subtract(_istOffset).toUtc();
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

  /// Creates a date key for the holidays map (always in IST)
  DateTime _createDateKey(int year, int month, int day) {
    return DateTime(year, month, day);
  }

  Future<void> _loadHolidays(int year, int month) async {
    setState(() => _loading = true);

    try {
      final service = HolidayService();
      final holidays = await service.fetchHolidays(year: year, month: month);

      final Map<DateTime, List<Map<String, String>>> processedHolidays = {};

      for (var holiday in holidays) {
        DateTime holidayDate;

        // Handle the date from API - convert to IST if it's in UTC
        if (holiday['date'] is DateTime) {
          final originalDate = holiday['date'] as DateTime;

          // If the date from API is in UTC, convert to IST
          // If it's already local time, normalize it to IST date
          holidayDate = originalDate.isUtc
              ? _normalizeDateIST(originalDate)
              : _createDateKey(originalDate.year, originalDate.month, originalDate.day);
        } else {
          // Handle string dates or other formats
          holidayDate = _createDateKey(year, month, 1); // fallback
        }

        // Create or append to the list for this date
        if (processedHolidays.containsKey(holidayDate)) {
          processedHolidays[holidayDate]!.add({
            "name": holiday['name'] as String,
            "description": holiday['description'] as String,
          });
        } else {
          processedHolidays[holidayDate] = [
            {
              "name": holiday['name'] as String,
              "description": holiday['description'] as String,
            }
          ];
        }
      }

      setState(() {
        _holidays = processedHolidays;
        _loading = false;
      });

      _fadeController.forward();
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackBar("Failed to load holidays: ${e.toString()}");
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: accentDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    // Normalize the day to IST date format for lookup
    final normalizedDay = _createDateKey(day.year, day.month, day.day);
    return _holidays[normalizedDay] ?? [];
  }

  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          color: backgroundColor,
          child: Column(
            children: [
              Container(
                height: 350,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-1.0, -0.3),
                    end: const Alignment(1.0, 0.3),
                    colors: [
                      shimmerBase,
                      shimmerHighlight,
                      shimmerBase,
                    ],
                    stops: [
                      _shimmerController.value - 0.3,
                      _shimmerController.value,
                      _shimmerController.value + 0.3,
                    ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              ...List.generate(
                3,
                    (index) => Container(
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-1.0, -0.3),
                      end: const Alignment(1.0, 0.3),
                      colors: [
                        shimmerBase,
                        shimmerHighlight,
                        shimmerBase,
                      ],
                      stops: [
                        _shimmerController.value - 0.3,
                        _shimmerController.value,
                        _shimmerController.value + 0.3,
                      ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Holiday Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'IST',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // Reset to current IST date
              final currentIST = _getCurrentIST();
              setState(() {
                _focusedDay = currentIST;
                _selectedDay = currentIST;
              });
              _loadHolidays(currentIST.year, currentIST.month);
            },
            icon: const Icon(Icons.today),
            tooltip: 'Today (IST)',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // IST Time Display
            Expanded(
              child: _loading
                  ? _buildShimmerEffect()
                  : FadeTransition(
                opacity: _fadeController,
                child: _buildCalendarContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarContent() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
            children: [
              _buildCalendarHeader(),
              TableCalendar<Map<String, String>>(
                firstDay: DateTime(2023, 1, 1),
                lastDay: DateTime(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  if (_selectedDay == null) return false;
                  // Compare dates in IST format
                  final selectedIST = _createDateKey(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
                  final dayIST = _createDateKey(day.year, day.month, day.day);
                  return isSameDay(selectedIST, dayIST);
                },
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronVisible: false,
                  rightChevronVisible: false,
                  titleTextStyle: TextStyle(fontSize: 0),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: const TextStyle(
                    color: accentDark,
                    fontWeight: FontWeight.w600,
                  ),
                  holidayTextStyle: const TextStyle(
                    color: accentDark,
                    fontWeight: FontWeight.w600,
                  ),
                  todayDecoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryLight, primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryLight.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  selectedDecoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [accentLight, accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentLight.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  defaultTextStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: textPrimary,
                  ),
                  todayTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  selectedTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  tablePadding: const EdgeInsets.all(16),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  weekendStyle: TextStyle(
                    color: accentDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  // Load holidays for the new month when user swipes
                  _loadHolidays(focusedDay.year, focusedDay.month);
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [accentLight, accentDark],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentLight.withOpacity(0.6),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  // Custom today marker to ensure it uses IST
                  todayBuilder: (context, date, _) {
                    final currentIST = _getCurrentIST();
                    final isToday = isSameDay(date, currentIST);

                    if (isToday) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryLight, primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryLight.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          date.day.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildEventsList(),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: primaryLight.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              final newFocusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
              setState(() {
                _focusedDay = newFocusedDay;
              });
              // Load holidays when navigating to previous month
              _loadHolidays(newFocusedDay.year, newFocusedDay.month);
            },
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: cardBackground,
              foregroundColor: primaryLight,
              padding: const EdgeInsets.all(8),
              elevation: 2,
              shadowColor: primaryLight.withOpacity(0.3),
            ),
          ),
          Column(
            children: [
              Text(
                "${_getMonthName(_focusedDay.month)} ${_focusedDay.year}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const Text(
                "Tap to view holidays (IST)",
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              final newFocusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
              setState(() {
                _focusedDay = newFocusedDay;
              });
              // Load holidays when navigating to next month
              _loadHolidays(newFocusedDay.year, newFocusedDay.month);
            },
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: cardBackground,
              foregroundColor: primaryLight,
              padding: const EdgeInsets.all(8),
              elevation: 2,
              shadowColor: primaryLight.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    final selectedDate = _selectedDay ?? _focusedDay;
    final events = _getEventsForDay(selectedDate);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryLight.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryLight, primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryLight.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Holiday Events",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          "${events.length} ${events.length == 1 ? 'event' : 'events'} • ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} (IST)",
                          style: const TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: events.isEmpty
                  ? _buildEmptyState()
                  : AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: _buildEventCard(event, index),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryLight.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: primaryLight.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No holidays today",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select another date to view holidays",
            style: TextStyle(
              fontSize: 14,
              color: textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, String> event, int index) {
    final gradients = [
      [primaryLight, primaryDark],
      [accentLight, accentDark],
      [const Color(0xFF72C6FF), const Color(0xFF5BB5FF)],
      [const Color(0xFF7FD8BE), const Color(0xFF6BC9AB)],
    ];

    final gradient = gradients[index % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient[0].withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.celebration_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          event['name']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            event['description']!,
            style: const TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: gradient[0].withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.star_rounded,
            color: gradient[0],
            size: 20,
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
