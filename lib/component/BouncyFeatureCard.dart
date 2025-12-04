import 'package:flutter/material.dart';

class BouncyFeatureCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconColor;
  final VoidCallback onTap;

  const BouncyFeatureCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.iconColor,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BouncyFeatureCard> createState() => _BouncyFeatureCardState();
}

class _BouncyFeatureCardState extends State<BouncyFeatureCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.93);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    Future.delayed(const Duration(milliseconds: 100), widget.onTap);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque, // Fixed: Ensure tap detection works
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          // Removed fixed width and height - let GridView handle sizing
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                widget.gradientColors.first.withOpacity(0.85),
                widget.gradientColors.last.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.last.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            // Removed BackdropFilter for better performance
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      child: Icon(widget.icon, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible( // Added: Prevents text overflow
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 2, // Added: Limit to 2 lines
                        overflow: TextOverflow.ellipsis, // Added: Handle overflow
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
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
}
