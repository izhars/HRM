import 'dart:io';
import 'package:flutter/material.dart';
import '../services/avatar_api.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String address;
  final bool isLoadingAddress;
  final VoidCallback? onAvatarTap;   // <-- NEW

  const TopBar({
    super.key,
    required this.address,
    this.isLoadingAddress = false,
    this.onAvatarTap,
  });

  @override
  _TopBarState createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _TopBarState extends State<TopBar> {
  File? _avatar;
  bool _isLoadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      setState(() => _isLoadingAvatar = true);
      final avatar = await AvatarService.getAvatar();
      if (mounted) {
        setState(() {
          _avatar = avatar;
          _isLoadingAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load avatar: $e')),
        );
      }
    }
  }

  List<String> _splitAddress(String address) {
    final parts = address.split(',');
    if (parts.isEmpty) return ['', ''];
    final firstPart = parts[0].trim();
    final restParts = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
    return [firstPart, restParts];
  }

  Widget _buildSkeleton({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressParts = _splitAddress(widget.address);
    final firstPart = addressParts[0];
    final restPart = addressParts[1];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // ---- AVATAR (now also navigates to profile) ----
              GestureDetector(
                onTap: widget.onAvatarTap ?? () => Scaffold.of(context).openDrawer(),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue[100]!, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isLoadingAvatar
                      ? CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[200],
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                  )
                      : CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[100],
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: _avatar != null
                          ? FileImage(_avatar!)
                          : const AssetImage('assets/profile.png')
                      as ImageProvider,
                      onBackgroundImageError: (_, __) => setState(() => _avatar = null),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // ---- ADDRESS + LOCATION ICON (unchanged) ----
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: widget.isLoadingAddress
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSkeleton(width: 120, height: 18, borderRadius: 4),
                          const SizedBox(height: 6),
                          _buildSkeleton(width: 180, height: 14, borderRadius: 4),
                        ],
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (firstPart.isNotEmpty)
                            Text(
                              firstPart,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.right,
                            ),
                          if (restPart.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              restPart,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                                height: 1.3,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/location.png',
                        width: 22,
                        height: 22,
                        color: Colors.white,
                      ),
                    ),
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