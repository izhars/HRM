import 'package:flutter/material.dart';
import '../services/employee_service.dart';
import 'chat_connection_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final EmployeeService _employeeService = EmployeeService();
  late Future<List<Map<String, dynamic>>> _futureHRs;

  @override
  void initState() {
    super.initState();
    _futureHRs = _employeeService.getAllHRs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          'Support (HR List)',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureHRs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No HRs found'));
          }

          final hrs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: hrs.length,
            itemBuilder: (context, index) {
              final hr = hrs[index];
              return _buildHRCard(hr);
            },
          );
        },
      ),
    );
  }

  Widget _buildHRCard(Map<String, dynamic> hr) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.teal.shade100,
          child: Icon(Icons.person, color: Colors.teal.shade700, size: 30),
        ),
        title: Text(
          hr['fullName'] ?? '${hr['firstName']} ${hr['lastName']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hr['email'] ?? '', style: const TextStyle(color: Colors.black54)),
            Text(hr['designation'] ?? '', style: const TextStyle(color: Colors.teal)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.teal),
          onPressed: () => _navigateToChat(hr),
        ),
      ),
    );
  }

  void _navigateToChat(Map<String, dynamic> hr) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(targetUser: hr),
      ),
    );
  }
}
