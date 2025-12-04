import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({Key? key}) : super(key: key);

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Check if user is logged in using AuthService
      _isLoggedIn = await _authService.isLoggedIn();

      if (!_isLoggedIn) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current user to check verification status
      final user = await _authService.getCurrentUser();

      if (user == null) {
        // If no user data found, clear storage and redirect to login
        await _authService.logout();
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
        return;
      }

      // Check verification status
      await _checkVerificationStatus(user);

    } catch (e) {
      debugPrint('Error checking login status: $e');
      await _authService.logout();
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkVerificationStatus(User user) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
        return;
      }

      // Call the check-verification API using AuthService pattern
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/check-verification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isVerified = data['isVerified'] == true;
          _isLoading = false;
        });
      } else if (response.statusCode == 403) {
        // HR unverified user
        await _authService.logout();
        _showBlockedDialog('Your account has been unverified by HR. Please contact HR.');
      } else {
        // Other errors (e.g., token expired)
        await _authService.logout();
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking verification: $e');
      await _authService.logout();
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  void _showBlockedDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Access Denied'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Optional: recheck verification when app resumes
      // _checkLoginStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking session...'),
            ],
          ),
        ),
      );
    }

    // ✅ Only allow Dashboard if both logged in & verified
    return _isLoggedIn && _isVerified
        ? const DashboardScreen()
        : LoginScreen();
  }
}