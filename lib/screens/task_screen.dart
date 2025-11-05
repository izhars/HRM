import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> _tasks = [
    {'title': 'Complete project proposal', 'due': 'Today', 'status': 'Pending'},
    {'title': 'Team meeting', 'due': 'Tomorrow', 'status': 'Pending'},
    {'title': 'Review code', 'due': 'Friday', 'status': 'Completed'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addTask,
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: task['status'] == 'Completed'
                    ? Colors.green
                    : Colors.orange,
                child: Icon(
                  task['status'] == 'Completed' ? Icons.check : Icons.pending,
                  color: Colors.white,
                ),
              ),
              title: Text(task['title']),
              subtitle: Text('Due: ${task['due']}'),
              trailing: Checkbox(
                value: task['status'] == 'Completed',
                onChanged: (value) => _toggleTask(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['status'] =
      _tasks[index]['status'] == 'Completed' ? 'Pending' : 'Completed';
    });
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Task'),
        content: TextField(
          decoration: InputDecoration(hintText: 'Enter task title'),
          onSubmitted: (value) {
            setState(() {
              _tasks.add({
                'title': value,
                'due': 'Tomorrow',
                'status': 'Pending'
              });
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}