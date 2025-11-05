import 'package:flutter/material.dart';
import '../models/celebration.dart';
import '../services/celebration_api.dart';

class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with SingleTickerProviderStateMixin {
  final CelebrationService _celebrationService = CelebrationService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  TodayCelebrations? _todayCelebrations;
  UpcomingCelebrations? _upcomingCelebrations;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCelebrations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCelebrations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final todayResponse = await _celebrationService.getTodayCelebrations();
      final upcomingResponse = await _celebrationService.getUpcomingCelebrations();

      setState(() {
        _todayCelebrations = todayResponse.data.today;
        _upcomingCelebrations = upcomingResponse.data.upcoming;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          '🎉 Celebrations',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadCelebrations,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildTodayView(),
          _buildUpcomingView(),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading celebrations',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCelebrations,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayView() {
    if (_todayCelebrations == null) {
      return const Center(child: Text('No data available'));
    }

    final totalCount = _todayCelebrations!.birthdays.count +
        _todayCelebrations!.marriageAnniversaries.count +
        _todayCelebrations!.workAnniversaries.count;

    if (totalCount == 0) {
      return _buildEmptyState('No celebrations today', '🎈');
    }

    return RefreshIndicator(
      onRefresh: _loadCelebrations,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_todayCelebrations!.birthdays.count > 0)
            _buildCelebrationSection(
              '🎂 Birthdays',
              _todayCelebrations!.birthdays.data,
              const Color(0xFFEC4899),
              CelebrationType.birthday,
            ),
          if (_todayCelebrations!.workAnniversaries.count > 0)
            _buildCelebrationSection(
              '💼 Work Anniversaries',
              _todayCelebrations!.workAnniversaries.data,
              const Color(0xFF8B5CF6),
              CelebrationType.workAnniversary,
            ),
          if (_todayCelebrations!.marriageAnniversaries.count > 0)
            _buildCelebrationSection(
              '💍 Marriage Anniversaries',
              _todayCelebrations!.marriageAnniversaries.data,
              const Color(0xFFF59E0B),
              CelebrationType.marriageAnniversary,
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingView() {
    if (_upcomingCelebrations == null) {
      return const Center(child: Text('No data available'));
    }

    final totalCount = _upcomingCelebrations!.birthdays.length +
        _upcomingCelebrations!.marriageAnniversaries.length +
        _upcomingCelebrations!.workAnniversaries.length;

    if (totalCount == 0) {
      return _buildEmptyState('No upcoming celebrations', '📅');
    }

    return RefreshIndicator(
      onRefresh: _loadCelebrations,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_upcomingCelebrations!.birthdays.isNotEmpty)
            _buildUpcomingSection(
              '🎂 Upcoming Birthdays',
              _upcomingCelebrations!.birthdays,
              const Color(0xFFEC4899),
            ),
          if (_upcomingCelebrations!.workAnniversaries.isNotEmpty)
            _buildUpcomingSection(
              '💼 Upcoming Work Anniversaries',
              _upcomingCelebrations!.workAnniversaries,
              const Color(0xFF8B5CF6),
            ),
          if (_upcomingCelebrations!.marriageAnniversaries.isNotEmpty)
            _buildUpcomingSection(
              '💍 Upcoming Marriage Anniversaries',
              _upcomingCelebrations!.marriageAnniversaries,
              const Color(0xFFF59E0B),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, String emoji) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationSection(
      String title,
      List<Employee> employees,
      Color color,
      CelebrationType type,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        ...employees.map((employee) => _buildTodayCard(employee, color, type)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTodayCard(Employee employee, Color color, CelebrationType type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle tap
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            employee.employeeId,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.business, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            employee.department,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(
      String title,
      List<UpcomingEvent> events,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        ...events.map((event) => _buildUpcomingCard(event, color)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUpcomingCard(UpcomingEvent event, Color color) {
    final daysText = event.daysUntil == 0
        ? 'Today'
        : event.daysUntil == 1
        ? 'Tomorrow'
        : 'In ${event.daysUntil} days';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle tap
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      event.firstName[0].toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
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
                        event.fullName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 13, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            event.employeeId,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.business, size: 13, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            event.department,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (event.yearsOfService != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${event.yearsOfService} ${event.yearsOfService == 1 ? 'year' : 'years'} of service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.8), color],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.celebrationDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum CelebrationType {
  birthday,
  marriageAnniversary,
  workAnniversary,
}