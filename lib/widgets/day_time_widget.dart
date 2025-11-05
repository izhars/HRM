import 'package:flutter/material.dart';

class DayTimeWidget extends StatefulWidget {
  const DayTimeWidget({Key? key}) : super(key: key);

  @override
  State<DayTimeWidget> createState() => _DayTimeWidgetState();
}

class _DayTimeWidgetState extends State<DayTimeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  int _getCurrentTimeIndex() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 0; // Morning
    } else if (hour >= 12 && hour < 17) {
      return 1; // Afternoon
    } else {
      return 2; // Evening/Night
    }
  }

  _TimeSection _getCurrentSection() {
    final sections = [
      _TimeSection(
        title: "Morning",
        subtitle: "Rise and shine!",
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD194), Color(0xFFFFA751)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.wb_sunny_rounded,
        timeRange: "5:00 AM - 12:00 PM",
      ),
      _TimeSection(
        title: "Afternoon",
        subtitle: "Keep up the energy!",
        gradient: const LinearGradient(
          colors: [Color(0xFF74EBD5), Color(0xFFACB6E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.wb_cloudy_rounded,
        timeRange: "12:00 PM - 5:00 PM",
      ),
      _TimeSection(
        title: "Evening",
        subtitle: "Relax and unwind.",
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.nightlight_round,
        timeRange: "5:00 PM - 5:00 AM",
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
              child: _DayTimeCard(section: section),
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
  final LinearGradient gradient;
  final IconData icon;
  final String timeRange;

  _TimeSection({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.timeRange,
  });
}

class _DayTimeCard extends StatefulWidget {
  final _TimeSection section;

  const _DayTimeCard({required this.section});

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
      duration: const Duration(milliseconds: 2500),
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
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.97 : 1.0),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: widget.section.gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: widget.section.gradient.colors.last.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: widget.section.gradient.colors.first.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Animated shimmer effect
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          transform: GradientRotation(
                            _shimmerController.value * 6.28,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Icon container with glow
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.section.icon,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.section.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.section.subtitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.section.timeRange,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow indicator
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}