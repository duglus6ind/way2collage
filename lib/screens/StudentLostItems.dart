import 'package:bus_tracker/screens/StudentReportStatus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentLostItemsPage extends StatefulWidget {
  final String userId;
  const StudentLostItemsPage({super.key, required this.userId});

  @override
  State<StudentLostItemsPage> createState() => _StudentLostItemsPageState();
}

class _StudentLostItemsPageState extends State<StudentLostItemsPage> {
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _loading = false;

  // ---------------- SUBMIT STUDENT REPORT ----------------

  Future<void> _submitLostReport() async {
    if (_itemNameController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => _loading = true);

    final doc = await FirebaseFirestore.instance
        .collection('student_lost_reports')
        .add({
          'itemName': _itemNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'reportedBy': widget.userId,
          'status': 'OPEN',
          'createdAt': FieldValue.serverTimestamp(),
        });

    debugPrint("Student Lost Report ID: ${doc.id}");

    _itemNameController.clear();
    _descriptionController.clear();

    setState(() => _loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Lost item reported")));
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B5C43),
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _iconButton(Icons.arrow_back, () => Navigator.pop(context)),
                  const Spacer(),
                  _iconButton(Icons.menu, () {}),
                ],
              ),
            ),

            // MAIN CARD
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // REPORT LOST ITEM
                      _inputField(
                        controller: _itemNameController,
                        hint: "Enter the item name",
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: _descriptionController,
                        hint: "Enter item description",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _loading ? null : _submitLostReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Submit",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      _actionTile("Reports & Replies", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentReportStatusPage(
                              studentId: widget.userId,
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 24),
                      const Divider(),

                      // FOUND ITEMS BY ATTENDANT
                      const Text(
                        "Items Found in Bus",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _foundItemsList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FOUND ITEMS LIST ----------------

  Widget _foundItemsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lost_items')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No items found yet");
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final String itemName = data['itemName'] ?? "";
            final String description = data['description'] ?? "";
            final String status = data['status'] ?? "FOUND";
            final String? imageUrl = data['imageUrl'];

            final Timestamp? ts = data['createdAt'];
            final DateTime? dateTime = ts?.toDate();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 IMAGE
                  if (imageUrl != null &&
                      imageUrl.toString().startsWith("http"))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image, size: 80),
                      ),
                    ),

                  if (imageUrl != null) const SizedBox(height: 12),

                  // 🔹 ITEM NAME
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 🔹 DESCRIPTION
                  Text(description, style: const TextStyle(fontSize: 14)),

                  const SizedBox(height: 10),

                  // 🔹 STATUS + DATE ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status == "FOUND"
                              ? Colors.green.shade100
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == "FOUND"
                                ? Colors.green
                                : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (dateTime != null)
                        Text(
                          "${dateTime.day}/${dateTime.month}/${dateTime.year}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ---------------- HELPERS ----------------

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade300,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
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

  Widget _actionTile(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
