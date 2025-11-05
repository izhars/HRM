import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TestRoleScreen extends StatefulWidget {
  const TestRoleScreen({Key? key}) : super(key: key);

  @override
  State<TestRoleScreen> createState() => _TestRoleScreenState();
}

class _TestRoleScreenState extends State<TestRoleScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final userData = await _secureStorage.read(key: 'user_data');
    if (userData != null) {
      final userMap = jsonDecode(userData);
      setState(() {
        _role = userMap['role'] ?? 'Role not found';
        _isLoading = false;
      });
    } else {
      setState(() {
        _role = 'No user data found';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test User Role'),
        centerTitle: true,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Text(
          'User Role: $_role',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
