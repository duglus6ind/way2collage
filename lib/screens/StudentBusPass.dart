import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/screens/BusPassPayment.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
// import 'package:firebase_storage/firebase_storage.dart';

class StudentBusPassPage extends StatefulWidget {
  final String userId;
  const StudentBusPassPage({super.key, required this.userId});

  @override
  State<StudentBusPassPage> createState() => _StudentBusPassPageState();
}

class _StudentBusPassPageState extends State<StudentBusPassPage> {
  final _nameController = TextEditingController();
  final _admissionController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedSemester;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  String? _nameError;
  String? _admissionError;
  String? _departmentError;
  String? _semesterError;
  String? _imageError;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      final String extension = image.name.split('.').last.toLowerCase();
      if (extension == 'jpg' || extension == 'jpeg') {
        setState(() {
          _selectedImage = File(image.path);
          _imageError = null;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a .jpg or .jpeg image")),
        );
      }
    }
  }

  Future<void> _submitPassApplication() async {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? "This field can't be empty" : null;
      _admissionError = _admissionController.text.trim().isEmpty ? "This field can't be empty" : null;
      _departmentError = _selectedDepartment == null ? "Please select a department" : null;
      _semesterError = _selectedSemester == null ? "Please select a semester" : null;
      _imageError = _selectedImage == null ? "Please upload an image" : null;
    });

    if (_nameError != null ||
        _admissionError != null ||
        _departmentError != null ||
        _semesterError != null ||
        _imageError != null) {
      return;
    }

    setState(() => _loading = true);

    try {
      // Check for existing application
      final QuerySnapshot existingApps = await FirebaseFirestore.instance
          .collection('bus_pass_applications')
          .where('userId', isEqualTo: widget.userId)
          .where('semester', isEqualTo: _selectedSemester)
          .get();
          
      bool alreadyApplied = false;
      for (var doc in existingApps.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']?.toString().toUpperCase() ?? '';
        final paymentStatus = data['paymentStatus']?.toString().toLowerCase() ?? '';
        
        if (paymentStatus == 'paid' || paymentStatus == 'partial' || status == 'PENDING' || status == 'APPROVED') {
          alreadyApplied = true;
          break;
        }
      }
      
      if (alreadyApplied) {
        setState(() => _loading = false);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF0B5C43)),
                SizedBox(width: 8),
                Text("Notice"),
              ],
            ),
            content: const Text("You have already applied for current semester."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Color(0xFF0B5C43), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }

      // Convert image to Base64 string instead of uploading to Firebase Storage
      final List<int> imageBytes = await _selectedImage!.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      final String imageUrl = 'data:image/jpeg;base64,$base64Image';

      final docRef = await FirebaseFirestore.instance.collection('bus_pass_applications').add({
        'userId': widget.userId,
        'name': _nameController.text.trim(),
        'admissionNumber': _admissionController.text.trim(),
        'department': _selectedDepartment,
        'semester': _selectedSemester,
        'imageUrl': imageUrl,
        'status': 'PENDING',
        'paymentStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _admissionController.clear();
      setState(() {
        _selectedDepartment = null;
        _selectedSemester = null;
        _selectedImage = null;
      });

      setState(() => _loading = false);

      if (!mounted) return;
      
      // Navigate to payment screen instead of just popping
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusPassPaymentScreen(
            userId: widget.userId,
            applicationId: docRef.id,
          ),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _admissionController.dispose();
    super.dispose();
  }

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
                  const SizedBox(width: 16),
                  const Text(
                    "Apply for Bus Pass",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Application Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _inputField(
                        controller: _nameController,
                        hint: "Full Name",
                        errorText: _nameError,
                        onChanged: (val) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: _admissionController,
                        hint: "Admission Number",
                        errorText: _admissionError,
                        onChanged: (val) {
                          if (_admissionError != null) {
                            setState(() => _admissionError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _dropdownField(
                        hint: "Department",
                        value: _selectedDepartment,
                        errorText: _departmentError,
                        items: [
                          "Information technology",
                          "Mechanical",
                          "Computer Science",
                          "Electronics & Communication",
                          "Electrical",
                          "Robotics"
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                            _departmentError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _dropdownField(
                        hint: "Current Semester",
                        value: _selectedSemester,
                        errorText: _semesterError,
                        items: ["S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8"],
                        onChanged: (value) {
                          setState(() {
                            _selectedSemester = value;
                            _semesterError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      const Text(
                        "Student Photo (.jpg, .jpeg)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: _selectedImage == null
                                ? Border.all(color: _imageError != null ? Colors.red.shade700 : Colors.transparent)
                                : Border.all(color: const Color(0xFF0B5C43), width: 2),
                          ),
                          child: _selectedImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 40, color: _imageError != null ? Colors.red.shade700 : Colors.grey.shade500),
                                    const SizedBox(height: 8),
                                    Text("Tap to upload photo", style: TextStyle(color: _imageError != null ? Colors.red.shade700 : Colors.grey.shade600)),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                                ),
                        ),
                      ),
                      if (_imageError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Text(
                            _imageError!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submitPassApplication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B5C43),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.0),
                                )
                              : const Text(
                                  "Submit Application",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
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

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? errorText,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      decoration: InputDecoration(
        errorText: errorText,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
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
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}
