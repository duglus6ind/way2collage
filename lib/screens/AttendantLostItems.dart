import 'package:bus_tracker/screens/StudentReportsPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AttendantLostItems extends StatefulWidget {
  const AttendantLostItems({super.key});

  @override
  State<AttendantLostItems> createState() => _AttendantLostItemsState();
}

class _AttendantLostItemsState extends State<AttendantLostItems> {
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImage;
  bool _loading = false;

  // ================= IMAGE PICKER =================

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // ================= CLOUDINARY UPLOAD =================

  Future<String?> _uploadToCloudinary() async {
    if (_selectedImage == null) return null;

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/dqykgonu8/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = 'Way2College Lost Items';

    final bytes = await _selectedImage!.readAsBytes();
    final fileName = _selectedImage!.path.split('/').last;

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final data = jsonDecode(responseData);

    return data['secure_url'];
  }

  // ================= SUBMIT =================

  Future<void> _submitLostItem() async {
    if (_itemNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and upload image"),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final imageUrl = await _uploadToCloudinary();

      if (imageUrl == null) {
        throw Exception("Image upload failed");
      }

      await FirebaseFirestore.instance.collection('lost_items').add({
        'itemName': _itemNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'reportedBy': 'ATTENDANT',
        'status': 'FOUND',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _itemNameController.clear();
      _descriptionController.clear();

      setState(() {
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item registered successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _loading = false);
  }

  // ================= UI =================

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
                      const SizedBox(height: 16),

                      // IMAGE BUTTON
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: const Text(
                          "Upload Image",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // IMAGE PREVIEW
                      if (_selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // SUBMIT BUTTON
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
                            : const Text(
                                "Submit",
                                style: TextStyle(color: Colors.white),
                              ),
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

  // ================= PREVIOUS ITEMS =================

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
                leading:
                    (data['imageUrl'] != null &&
                        data['imageUrl'].toString().startsWith("http"))
                    ? Image.network(
                        data['imageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      )
                    : const Icon(Icons.image),
                title: Text(data['itemName']),
                subtitle: Text(data['description']),
              );
            }),
          ],
        );
      },
    );
  }

  // ================= HELPERS =================

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
