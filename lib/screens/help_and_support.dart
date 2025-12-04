import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar for FAQs
            TextField(
              decoration: InputDecoration(
                hintText: "Search help topics...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.indigo[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick help cards
            const Text(
              "Popular Help Topics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              children: [
                _HelpCard(
                  icon: Icons.account_circle,
                  title: "Profile & Settings",
                ),
                _HelpCard(
                  icon: Icons.payment,
                  title: "Salary & Payslips",
                ),
                _HelpCard(
                  icon: Icons.schedule,
                  title: "Attendance & Leaves",
                ),
                _HelpCard(
                  icon: Icons.support_agent,
                  title: "HR Policies",
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contact Support section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Need More Help?",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      "You can contact our support team via chat or submit a ticket. We'll get back to you ASAP!"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Open chat support
                          },
                          icon: const Icon(Icons.chat),
                          label: const Text("Chat Now"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Open ticket form
                          },
                          icon: const Icon(Icons.email),
                          label: const Text("Submit Ticket"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Section
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _FAQTile(
              question: "How do I update my profile information?",
              answer:
              "Go to Profile -> Edit Profile and update your details.",
            ),
            _FAQTile(
              question: "How do I apply for leave?",
              answer:
              "Navigate to Attendance -> Leave Requests and click 'Apply Leave'.",
            ),
            _FAQTile(
              question: "Where can I download my payslip?",
              answer:
              "Go to Salary -> Payslips, select the month, and download.",
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _HelpCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: () {
          // Navigate to topic details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.indigo),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(answer),
        )
      ],
    );
  }
}
