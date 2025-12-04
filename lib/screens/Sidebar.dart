import 'dart:io';
import 'package:flutter/material.dart';
import 'package:staffsync/screens/AQIScreen.dart';
import 'package:staffsync/screens/faq_screen.dart';
import 'package:staffsync/screens/profile_screen.dart';

import 'AQIMapScreen.dart';
import 'about_page.dart';
import 'help_and_support.dart';

class Sidebar extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String employeeId;
  final File? avatarFile;
  final String? avatarUrl;
  final VoidCallback onLogout;
  final BuildContext parentContext; // ✅ Get parent context

  const Sidebar({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.employeeId,
    this.avatarFile,
    this.avatarUrl,
    required this.onLogout,
    required this.parentContext, // ✅ Required parent context
  });

  void _navigateTo(Widget page) {
    // Close drawer first
    Navigator.pop(parentContext);
    // Then navigate to page
    Navigator.push(
      parentContext,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _navigateToProfile() {
    Navigator.pop(parentContext);
    // Assuming you have a ProfilePage widget
    Navigator.push(
      parentContext,
      MaterialPageRoute(builder: (context) => ProfileScreen()), // Replace with your actual profile page
    );
  }

  void _handleLogout() {
    Navigator.pop(parentContext); // Close drawer
    onLogout(); // Call the logout callback
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Profile Section
            _buildProfileSection(),

            const SizedBox(height: 32),

            // Menu Items
            _buildMenuItems(),

            const Spacer(),

            // Logout Button
            _buildLogoutButton(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        // Avatar with subtle shadow
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: _navigateToProfile,
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: avatarFile != null
                    ? FileImage(avatarFile!)
                    : const AssetImage('assets/profile.png') as ImageProvider,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // User Name
        Text(
          userName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // User Email
        Text(
          userEmail,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Employee ID
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "ID: $employeeId",
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.home_outlined,
            title: "Home",
            onTap: () => Navigator.pop(parentContext), // Just close drawer for home
          ),
          _buildMenuItem(
            icon: Icons.person_outlined,
            title: "Profile",
            onTap: _navigateToProfile,
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: "Settings",
            onTap: () => _navigateTo(SettingsPage()), // Replace with your SettingsPage
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: "Help & Support",
            onTap: () => _navigateTo(HelpSupportPage()), // Replace with your HelpSupportPage
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: "About",
            onTap: () => _navigateTo(AboutPage()), // Replace with your AboutPage
          ),
          _buildMenuItem(
            icon: Icons.question_answer,
            title: "FAQ",
            onTap: () => _navigateTo(FAQScreen()), // Replace with your AboutPage
          ),
          _buildMenuItem(
            icon: Icons.air,
            title: "AQI",
            onTap: () => _navigateTo(AQIScreen()), // Replace with your AboutPage
          ),
          _buildMenuItem(
            icon: Icons.map,
            title: "Map",
            onTap: () => _navigateTo(AQIMapScreen()), // Replace with your AboutPage
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: Colors.white,
            foregroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade200, width: 1),
            ),
            elevation: 0,
          ),
          icon: Icon(
            Icons.logout,
            color: Colors.red.shade600,
            size: 20,
          ),
          label: Text(
            "Logout",
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          onPressed: _handleLogout,
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Settings')), body: Center(child: Text('Settings Page')));
}