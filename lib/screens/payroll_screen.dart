import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PayrollScreen extends StatefulWidget {
  @override
  _PayrollScreenState createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Payroll', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Current Month', '₹45,000', Colors.green)),
                SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('Last Month', '₹42,000', Colors.blue)),
              ],
            ),
            SizedBox(height: 20),

            // Payslips List
            Text('Payslips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(Icons.receipt, color: Colors.purple),
                    title: Text('January ${DateTime.now().year}'),
                    subtitle: Text('Generated on 2024-01-31'),
                    trailing: ElevatedButton(
                      onPressed: () => _downloadPayslip(),
                      child: Text('Download'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _downloadPayslip() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payslip downloaded successfully!')),
    );
  }
}