import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String? employeeId;

  const EmployeeDetailScreen({Key? key, this.employeeId}) : super(key: key);

  @override
  _EmployeeDetailScreenState createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      context.read<EmployeeProvider>().getEmployeeById(widget.employeeId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Employee Details')),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          // Assuming selectedEmployee is set in getEmployeeById
          final employee = provider.selectedEmployee;

          if (employee == null) {
            return Center(child: Text('Employee not found'));
          }

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(child: Text(employee.name[0])),
                  title: Text(employee.name),
                  subtitle: Text(employee.position),
                ),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${employee.email}'),
                        Text('Phone: ${employee.phone}'),
                        Text('Department ID: ${employee.departmentId}'),
                        Text('Hire Date: ${employee.hireDate.toString().split(' ')[0]}'),
                        Text('Status: ${employee.isActive ? 'Active' : 'Inactive'}'),
                      ],
                    ),
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Edit employee
                        },
                        child: Text('Edit'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Delete employee
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}