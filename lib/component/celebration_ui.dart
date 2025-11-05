import 'package:flutter/material.dart';
import 'package:staffsync/screens/celebration_screen.dart';
import '../models/celebration.dart';
import '../services/celebration_api.dart';

class CelebrationWidget extends StatefulWidget {
  final bool showHeader;
  final bool showViewAllButton;
  final VoidCallback? onViewAllPressed;

  const CelebrationWidget({
    super.key,
    this.showHeader = true,
    this.showViewAllButton = true,
    this.onViewAllPressed,
  });

  @override
  State<CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<CelebrationWidget> {
  final CelebrationService _celebrationService = CelebrationService();
  bool _isLoading = true;
  String? _error;
  TodayCelebrations? _todayCelebrations;
  List<UpcomingEvent>? _upcomingEvents;
  List<String>? _upcomingEventTypes;

  @override
  void initState() {
    super.initState();
    _loadCelebrations();
  }

  Future<void> _loadCelebrations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final todayResponse = await _celebrationService.getTodayCelebrations();
      final upcomingResponse = await _celebrationService.getUpcomingCelebrations();

      final allUpcoming = <Map<String, dynamic>>[
        ...upcomingResponse.data.upcoming?.birthdays
            ?.map((e) => {'event': e, 'type': '🎂 Birthday'}) ??
            [],
        ...upcomingResponse.data.upcoming?.marriageAnniversaries
            ?.map((e) => {'event': e, 'type': '💍 Anniversary'}) ??
            [],
        ...upcomingResponse.data.upcoming?.workAnniversaries
            ?.map((e) => {'event': e, 'type': '💼 Work Anniversary'}) ??
            [],
      ];
      allUpcoming.sort((a, b) => a['event'].daysUntil.compareTo(b['event'].daysUntil));

      setState(() {
        _todayCelebrations = todayResponse.data.today;
        _upcomingEvents = allUpcoming.take(5).map((e) => e['event'] as UpcomingEvent).toList();
        _upcomingEventTypes = allUpcoming.take(5).map((e) => e['type'] as String).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildUpcomingCard(UpcomingEvent event, int index) {
    final daysText = event.daysUntil == 0
        ? 'Today'
        : event.daysUntil == 1
        ? 'Tomorrow'
        : '${event.daysUntil}d';
    final eventType = _upcomingEventTypes![index];

    // Map event types to icons
    const eventIcons = {
      '🎂 Birthday': Icons.cake,
      '💍 Anniversary': Icons.favorite,
      '💼 Work Anniversary': Icons.work,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                event.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Name
                Text(
                  event.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // Event type label (Birthday / Marriage / Work)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    eventType,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFEC4899),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Department + Designation in a single row
                Row(
                  children: [
                    Icon(Icons.apartment, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${event.department} | ${event.designation}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  eventIcons[eventType],
                  color: const Color(0xFFEC4899),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  daysText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Update the _buildUpcomingSection to pass the index
  // Update the _buildUpcomingSection to pass the index
  Widget _buildUpcomingSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '📅 UPCOMING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._upcomingEvents!.asMap().entries.map((entry) => _buildUpcomingCard(entry.value, entry.key)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) _buildHeader(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorView()
            else
              _buildCelebrationContent(),
          ],
        ),
      ),
    );
  }

  

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.celebration, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Celebrations',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Today & Upcoming',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.showViewAllButton)
            TextButton(
              onPressed: widget.onViewAllPressed ?? () {
                print("View All pressed"); // debug
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CelebrationScreen(),
                  ),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Unable to load celebrations',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadCelebrations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationContent() {
    final todayEmployees = _getAllTodayEmployees();
    final hasToday = todayEmployees.isNotEmpty;
    final hasUpcoming = _upcomingEvents?.isNotEmpty ?? false;

    if (!hasToday && !hasUpcoming) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Text('🎉', style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(
                'No celebrations this week',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (hasToday) _buildTodaySection(todayEmployees),
        if (hasUpcoming) _buildUpcomingSection(),
      ],
    );
  }

  List<Map<String, dynamic>> _getAllTodayEmployees() {
    final List<Map<String, dynamic>> employees = [];

    if (_todayCelebrations != null) {
      for (var emp in _todayCelebrations!.birthdays.data) {
        employees.add({'employee': emp, 'type': '🎂 Birthday'});
      }
      for (var emp in _todayCelebrations!.workAnniversaries.data) {
        employees.add({'employee': emp, 'type': '💼 Work Anniversary'});
      }
      for (var emp in _todayCelebrations!.marriageAnniversaries.data) {
        employees.add({'employee': emp, 'type': '💍 Anniversary'});
      }
    }

    return employees;
  }

  Widget _buildTodaySection(List<Map<String, dynamic>> todayEmployees) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF97316)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🎊 TODAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...todayEmployees.map((data) => _buildTodayCard(
            data['employee'] as Employee,
            data['type'] as String,
          )),
        ],
      ),
    );
  }

  Widget _buildTodayCard(Employee employee, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(0.1),
                    const Color(0xFF6366F1).withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      employee.firstName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFEC4899),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        employee.department,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cake,
                    color: Color(0xFFEC4899),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

