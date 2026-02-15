import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentReportsPage extends StatelessWidget {
  const StudentReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    "Student Reports",
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
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: _reportsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= REPORT LIST =================

  Widget _reportsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('student_lost_reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No student reports"));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _reportCard(context, doc.id, data); // ✅ doc.id passed
          }).toList(),
        );
      },
    );
  }

  // ================= REPORT CARD =================

  Widget _reportCard(
    BuildContext context,
    String reportId, // ✅ THIS IS THE DOC ID
    Map<String, dynamic> data,
  ) {
    final TextEditingController replyController = TextEditingController(
      text: data['attendantReply'] ?? "",
    );

    final String status = data['status'] ?? "OPEN";

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
          // ITEM NAME
          Text(
            data['itemName'] ?? "Unknown Item",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),

          const SizedBox(height: 6),

          // DESCRIPTION
          Text(data['description'] ?? ""),

          const SizedBox(height: 10),

          // STATUS ROW
          Row(
            children: [
              const Text(
                "Status: ",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _statusColor(status),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // REPLY FIELD
          TextField(
            controller: replyController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Reply to student",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ACTION ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // STATUS DROPDOWN
              DropdownButton<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: "OPEN", child: Text("OPEN")),
                  DropdownMenuItem(value: "FOUND", child: Text("FOUND")),
                  DropdownMenuItem(value: "CLOSED", child: Text("CLOSED")),
                ],
                onChanged: (value) async {
                  if (value == null) return;

                  final docRef = FirebaseFirestore.instance
                      .collection('student_lost_reports')
                      .doc(reportId); // ✅ FIXED HERE

                  if (value == "CLOSED") {
                    // TTL starts ONLY when CLOSED
                    await docRef.update({
                      'status': 'CLOSED',
                      'expireAt': Timestamp.fromDate(
                        DateTime.now().add(const Duration(days: 7)),
                      ),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    // No TTL for OPEN or FOUND
                    await docRef.update({
                      'status': value,
                      'expireAt': FieldValue.delete(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  }
                },
              ),

              // SEND REPLY
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('student_lost_reports')
                      .doc(reportId)
                      .update({
                        'attendantReply': replyController.text.trim(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Reply sent")));
                },
                child: const Text("Send Reply"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Color _statusColor(String status) {
    switch (status) {
      case "FOUND":
        return Colors.green;
      case "CLOSED":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon),
      ),
    );
  }
}
