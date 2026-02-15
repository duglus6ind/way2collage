import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentReportStatusPage extends StatelessWidget {
  final String studentId;

  const StudentReportStatusPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    debugPrint("STUDENT ID FROM PAGE: $studentId");

    return Scaffold(
      backgroundColor: const Color(0xFF0B5C43),
      body: SafeArea(
        child: Column(
          children: [
            // ---------------- TOP BAR ----------------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _iconButton(Icons.arrow_back, () => Navigator.pop(context)),
                  const Spacer(),
                  const Text(
                    "Report Status",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // ---------------- MAIN CARD ----------------
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: _reportStatusList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= REPORT STATUS LIST =================

  Widget _reportStatusList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('student_lost_reports')
          .where('reportedBy', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No reports submitted yet"));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return _reportCard(
              itemName: data['itemName'] ?? '',
              description: data['description'] ?? '',
              status: data['status'] ?? 'OPEN',
              reply: data['attendantReply'],
            );
          }).toList(),
        );
      },
    );
  }

  // ================= REPORT CARD =================

  Widget _reportCard({
    required String itemName,
    required String description,
    required String status,
    String? reply,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(description),
          const SizedBox(height: 10),

          Row(
            children: [
              const Text(
                "Status: ",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              _statusChip(status),
            ],
          ),

          if (reply != null && reply.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(),
            const Text(
              "Attendant Reply",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(reply),
          ],
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'FOUND':
        color = Colors.green;
        break;
      case 'CLOSED':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
