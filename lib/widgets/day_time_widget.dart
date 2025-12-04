import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/air_quality_data.dart';
import '../services/aqi_service.dart';

// ===================== QUOTE MODEL =====================

class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['quote'] ?? '',
      author: json['author'] ?? 'Unknown',
    );
  }
}

// ===================== MAIN WIDGET =====================

class DayTimeWidget extends StatefulWidget {

  @override
  State<DayTimeWidget> createState() => _DayTimeWidgetState();
}

class _DayTimeWidgetState extends State<DayTimeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Quote? _currentQuote;
  bool _isLoadingQuote = true;

  // AQI related state
  AirQualityData? _airQualityData;
  bool _isLoadingAQI = true;
  String _address = 'Fetching location...';
  Position? _currentPosition;
  final AQIService _aqiService = AQIService();

  @override
  void initState() {
    super.initState();
    _fetchQuote();
    _getLocationAndAQI();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  Future<void> _getLocationAndAQI() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _address = 'Location permission denied';
            _isLoadingAQI = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _address = 'Location permission permanently denied';
          _isLoadingAQI = false;
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _address = 'Location services disabled';
          _isLoadingAQI = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;

      // Get address from coordinates
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final p = placemarks.isNotEmpty ? placemarks.first : null;
        final addr = p != null
            ? '${p.locality ?? ''}, ${p.administrativeArea ?? ''}'.trim()
            : 'Unknown location';

        if (mounted) {
          setState(() {
            _address = addr.isEmpty ? 'Unknown location' : addr;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _address = '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
          });
        }
      }

      // Fetch AQI data
      final aqiData = await _aqiService.fetchByGeo(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _airQualityData = aqiData;
          _isLoadingAQI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = 'Location error';
          _isLoadingAQI = false;
        });
      }
      debugPrint('Error getting location and AQI: $e');
    }
  }


  Future<void> _fetchQuote() async {
    try {
      final response = await http.get(
        Uri.parse('https://dummyjson.com/quotes/random'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _currentQuote = Quote.fromJson(data);
          _isLoadingQuote = false;
        });
      } else {
        throw Exception('Failed to load quote');
      }
    } catch (e) {
      setState(() {
        _currentQuote = Quote(
          text:
          "The best time to plant a tree was 20 years ago. The second best time is now.",
          author: "Chinese Proverb",
        );
        _isLoadingQuote = false;
      });
    }
  }

  int _getCurrentTimeIndex() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 0; // Morning
    } else if (hour >= 12 && hour < 17) {
      return 1; // Afternoon
    } else if (hour >= 17 && hour < 21) {
      return 2; // Evening
    } else {
      return 3; // Night
    }
  }

  _TimeSection _getCurrentSection() {
    final sections = [
      _TimeSection(
        title: "Good Morning",
        subtitle: "Rise and shine!",
        emoji: "☀️",
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD89B), Color(0xFFFF8066), Color(0xFFFF6A88)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.wb_sunny_rounded,
        timeRange: "5:00 AM - 12:00 PM",
      ),
      _TimeSection(
        title: "Good Afternoon",
        subtitle: "Keep the momentum!",
        emoji: "🌤️",
        gradient: const LinearGradient(
          colors: [Color(0xFF43E97B), Color(0xFF38F9D7), Color(0xFF4FACFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.wb_cloudy_rounded,
        timeRange: "12:00 PM - 5:00 PM",
      ),
      _TimeSection(
        title: "Good Evening",
        subtitle: "Time to unwind.",
        emoji: "🌆",
        gradient: const LinearGradient(
          colors: [Color(0xFFFA709A), Color(0xFFFA8BFF), Color(0xFF7B68EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.wb_twilight_rounded,
        timeRange: "5:00 PM - 9:00 PM",
      ),
      _TimeSection(
        title: "Good Night",
        subtitle: "Rest and recharge.",
        emoji: "🌙",
        gradient: const LinearGradient(
          colors: [Color(0xFF2E3192), Color(0xFF1BFFFF), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.nightlight_round,
        timeRange: "9:00 PM - 5:00 AM",
      ),
    ];

    return sections[_getCurrentTimeIndex()];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final section = _getCurrentSection();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _DayTimeCard(
                section: section,
                quote: _currentQuote,
                isLoadingQuote: _isLoadingQuote,
                onRefreshQuote: _fetchQuote,
                airQualityData: _airQualityData,
                isLoadingAQI: _isLoadingAQI,
                address: _address,
                onRefreshAQI: _getLocationAndAQI,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimeSection {
  final String title;
  final String subtitle;
  final String emoji;
  final LinearGradient gradient;
  final IconData icon;
  final String timeRange;

  _TimeSection({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.icon,
    required this.timeRange,
  });
}

// ===================== CARD WIDGET =====================

class _DayTimeCard extends StatefulWidget {
  final _TimeSection section;
  final Quote? quote;
  final bool isLoadingQuote;
  final VoidCallback onRefreshQuote;
  final AirQualityData? airQualityData;
  final bool isLoadingAQI;
  final String address;
  final VoidCallback onRefreshAQI;

  const _DayTimeCard({
    required this.section,
    required this.quote,
    required this.isLoadingQuote,
    required this.onRefreshQuote,
    required this.airQualityData,
    required this.isLoadingAQI,
    required this.address,
    required this.onRefreshAQI,
  });

  @override
  State<_DayTimeCard> createState() => _DayTimeCardState();
}

class _DayTimeCardState extends State<_DayTimeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.96 : 1.0)
          ..rotateZ(_isPressed ? -0.01 : 0.0),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: widget.section.gradient.colors[1].withOpacity(0.4),
              blurRadius: 28,
              offset: const Offset(0, 12),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: widget.section.gradient.colors.last.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Base gradient
              Container(
                decoration: BoxDecoration(
                  gradient: widget.section.gradient,
                ),
              ),

              // Glassmorphism overlay
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Shimmer effect
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(
                          _shimmerController.value * 2 * pi,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with emoji and title
                    Row(
                      children: [
                        Text(
                          widget.section.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.section.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Clock and Time Display
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Enhanced watch
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const _MiniWatch(),
                        ),
                        const SizedBox(width: 20),

                        // Digital Time Display
                        Expanded(
                          child: _DigitalTimeDisplay(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // AQI Section - NEW
                    if (!widget.isLoadingAQI && widget.airQualityData != null)
                      _AQICard(
                        airQualityData: widget.airQualityData!,
                        address: widget.address,
                        onRefresh: widget.onRefreshAQI,
                      )
                    else if (widget.isLoadingAQI)
                      _AQILoadingCard()
                    else
                      _AQIErrorCard(onRetry: widget.onRefreshAQI),

                    const SizedBox(height: 20),

                    // Quote Section
                    if (!widget.isLoadingQuote && widget.quote != null)
                      _QuoteCard(
                        quote: widget.quote!,
                        onRefresh: widget.onRefreshQuote,
                      )
                    else
                      _QuoteLoadingCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== DIGITAL TIME DISPLAY =====================

class _DigitalTimeDisplay extends StatefulWidget {
  @override
  State<_DigitalTimeDisplay> createState() => _DigitalTimeDisplayState();
}

class _DigitalTimeDisplayState extends State<_DigitalTimeDisplay> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime() {
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getPeriod() {
    return _now.hour >= 12 ? 'PM' : 'AM';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatTime(),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
                letterSpacing: -2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _getPeriod(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Date
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(_now),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================== QUOTE CARD =====================

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onRefresh;

  const _QuoteCard({
    required this.quote,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quote.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '— ${quote.author}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== QUOTE LOADING CARD =====================

class _QuoteLoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
          const SizedBox(width: 16),
          Text(
            'Loading inspiration...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== MINI WATCH =====================

class _MiniWatch extends StatefulWidget {
  const _MiniWatch();

  @override
  State<_MiniWatch> createState() => _MiniWatchState();
}

class _MiniWatchState extends State<_MiniWatch> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 100;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _MiniWatchPainter(_now),
      ),
    );
  }
}

class _MiniWatchPainter extends CustomPainter {
  final DateTime time;
  _MiniWatchPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Draw hour marks
    final hourMarkPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final minuteMarkPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * pi;
      final isHourMark = i % 5 == 0;
      final paint = isHourMark ? hourMarkPaint : minuteMarkPaint;
      final markLength = isHourMark ? 8.0 : 4.0;

      final start = Offset(
        center.dx + (radius - markLength) * cos(angle - pi / 2),
        center.dy + (radius - markLength) * sin(angle - pi / 2),
      );
      final end = Offset(
        center.dx + (radius - 2) * cos(angle - pi / 2),
        center.dy + (radius - 2) * sin(angle - pi / 2),
      );
      canvas.drawLine(start, end, paint);
    }

    final hour = (time.hour % 12) + time.minute / 60;
    final minute = time.minute + time.second / 60;
    final second = time.second.toDouble();

    final hourAngle = (hour / 12) * 2 * pi - pi / 2;
    final minuteAngle = (minute / 60) * 2 * pi - pi / 2;
    final secondAngle = (second / 60) * 2 * pi - pi / 2;

    // Draw hour hand shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + const Offset(1, 2),
      center +
          Offset(cos(hourAngle), sin(hourAngle)) * radius * 0.4 +
          const Offset(1, 2),
      shadowPaint,
    );

    // Draw hour hand
    final hourPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center + Offset(cos(hourAngle), sin(hourAngle)) * radius * 0.4,
      hourPaint,
    );

    // Draw minute hand
    final minPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center + Offset(cos(minuteAngle), sin(minuteAngle)) * radius * 0.65,
      minPaint,
    );

    // Draw second hand
    final secPaint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center - Offset(cos(secondAngle), sin(secondAngle)) * radius * 0.15,
      center + Offset(cos(secondAngle), sin(secondAngle)) * radius * 0.75,
      secPaint,
    );

    // Center dot
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      3,
      Paint()
        ..color = const Color(0xFFFF6B6B)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_MiniWatchPainter oldDelegate) =>
      oldDelegate.time != time;
}

// ===================== UTIL =====================

String _formatDate(DateTime now) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
}

class _AQICard extends StatelessWidget {
  final AirQualityData airQualityData;
  final String address;
  final VoidCallback onRefresh;

  const _AQICard({
    required this.airQualityData,
    required this.address,
    required this.onRefresh,
  });

  Color _getAQIColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF00E400); // Good
    if (aqi <= 100) return const Color(0xFFFFFF00); // Moderate
    if (aqi <= 150) return const Color(0xFFFF7E00); // Unhealthy for Sensitive
    if (aqi <= 200) return const Color(0xFFFF0000); // Unhealthy
    if (aqi <= 300) return const Color(0xFF8F3F97); // Very Unhealthy
    return const Color(0xFF7E0023); // Hazardous
  }

  String _getAQILabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  @override
  Widget build(BuildContext context) {
    final aqiColor = _getAQIColor(airQualityData.aqi);
    final aqiLabel = _getAQILabel(airQualityData.aqi);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.air,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Air Quality',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AQI Display
          Row(
            children: [
              // AQI Number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: aqiColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: aqiColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      airQualityData.aqi.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'AQI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // AQI Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: aqiColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: aqiColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        aqiLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pollutant: ${airQualityData.dominantPollutant.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Weather Info
          Row(
            children: [
              _WeatherInfoItem(
                icon: Icons.thermostat,
                value: '${airQualityData.temperature.toStringAsFixed(1)}°C',
                label: 'Temp',
              ),
              const SizedBox(width: 12),
              _WeatherInfoItem(
                icon: Icons.water_drop,
                value: '${airQualityData.humidity}%',
                label: 'Humidity',
              ),
              const SizedBox(width: 12),
              _WeatherInfoItem(
                icon: Icons.air,
                value: '${airQualityData.wind.toStringAsFixed(1)} m/s',
                label: 'Wind',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherInfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WeatherInfoItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== AQI LOADING CARD =====================

class _AQILoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
          const SizedBox(width: 16),
          Text(
            'Loading air quality data...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== AQI ERROR CARD =====================

class _AQIErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _AQIErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Unable to fetch air quality data',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
