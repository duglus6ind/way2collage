import 'package:bus_tracker/screens/StudentReportsPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendantLostItems extends StatefulWidget {
  const AttendantLostItems({super.key});

  @override
  State<AttendantLostItems> createState() => _AttendantLostItemsState();
}

class _AttendantLostItemsState extends State<AttendantLostItems> {
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _loading = false;

  // ---------------- SUBMIT ----------------

  Future<void> _submitLostItem() async {
    if (_itemNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection('lost_items').add({
        'itemName': _itemNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'reportedBy': 'ATTENDANT',
        'status': 'FOUND',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _itemNameController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lost item registered successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _loading = false);
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
                  const Text(
                    "Lost Items",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
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
                    children: [
                      _inputField(
                        controller: _itemNameController,
                        hint: "Item name",
                      ),
                      const SizedBox(height: 12),

                      _inputField(
                        controller: _descriptionController,
                        hint: "Item description",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      _inputField(
                        controller: _imageUrlController,
                        hint: "Paste image URL",
                      ),
                      const SizedBox(height: 16),

                      // IMAGE PREVIEW
                      if (_imageUrlController.text.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrlController.text,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Text("Invalid image URL"),
                          ),
                        ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _loading ? null : _submitLostItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Submit"),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),

                      _actionTile("Student Reports & Replies", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentReportsPage(),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      _previousItemsList(),
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

  // ---------------- HELPERS ----------------

  Widget _previousItemsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lost_items')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Previously Found Items",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['itemName']),
                subtitle: Text(data['description']),
              );
            }),
          ],
        );
      },
    );
  }

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
