import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:csv/csv.dart';
import 'package:bus_tracker/utils/PasswordUtils.dart';

class AddUsersScreen extends StatefulWidget {
  const AddUsersScreen({super.key});

  @override
  State<AddUsersScreen> createState() => _AddUsersScreenState();
}

class _AddUsersScreenState extends State<AddUsersScreen> {
  // -------- SINGLE USER --------
  final _userIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String role = 'Student';

  // -------- CSV --------
  bool isUploading = false;
  bool csvLoaded = false;
  List<List<dynamic>> csvRows = [];
  List<String> validationErrors = [];

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEAEA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF095C42),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
        title: const Text(
          "Add Users",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _greenActionCard(
              title: "Add Single User",
              subtitle: "Create one user manually",
              icon: Icons.person_add,
              onTap: _showSingleUserSheet,
            ),
            const SizedBox(height: 24),
            _greenActionCard(
              title: "Bulk Upload Users",
              subtitle: "Upload multiple users using CSV",
              icon: Icons.upload_file,
              onTap: _showBulkUploadSheet,
            ),
          ],
        ),
      ),
    );
  }

  // ================= ACTION CARDS =================

  Widget _greenActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF095C42),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(4, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 34, color: Colors.black),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SINGLE USER =================

  void _showSingleUserSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetTitle("Add Single User"),
            _textField(_userIdController, "User ID"),
            _textField(_nameController, "Name"),
            _textField(_passwordController, "Password"),
            DropdownButtonFormField(
              value: role,
              decoration: const InputDecoration(labelText: "Role"),
              items: const [
                DropdownMenuItem(
                  value: 'Bus Secretary',
                  child: Text("Secretary"),
                ),
                DropdownMenuItem(value: 'Driver', child: Text("Driver")),
                DropdownMenuItem(value: 'Student', child: Text("Student")),
                DropdownMenuItem(
                  value: 'Bus Attendant',
                  child: Text("Attendant"),
                ),
              ],
              onChanged: (value) => setState(() => role = value!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSingleUser,
              child: const Text("SAVE USER"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSingleUser() async {
    final userId = _userIdController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    List<String> errors = [];

    // -------- EMPTY CHECK --------
    if (userId.isEmpty) {
      errors.add("User ID is required");
    }

    if (name.isEmpty) {
      errors.add("Name is required");
    }

    if (password.isEmpty) {
      errors.add("Password is required");
    }

    // -------- NAME VALIDATION --------
    if (name.isNotEmpty) {
      if (RegExp(r'\d').hasMatch(name)) {
        errors.add("Name cannot contain numbers");
      }

      if (RegExp(r'[^\w\s]').hasMatch(name)) {
        errors.add("Name cannot contain special characters");
      }

      if (!RegExp(r'^[A-Za-z]').hasMatch(name)) {
        errors.add("Name must start with a letter");
      }
    }

    // -------- DUPLICATE CHECK --------
    if (userId.isNotEmpty) {
      final exists = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (exists.exists) {
        errors.add("User ID already exists in database");
      }
    }

    // -------- IF ANY ERROR, SHOW DIALOG --------
    if (errors.isNotEmpty) {
      _showValidationDialog(errors);
      return;
    }

    // -------- SAVE USER --------
    await FirebaseFirestore.instance.collection('Users').doc(userId).set({
      'UserId': userId,
      'Name': name,
      'Role': role,
      'Password': hashPassword(password),
      'Active': true,
      'ForcePasswordReset': true,
    });

    Navigator.pop(context);
    _clearSingleForm();
    _showSuccessDialog("User added successfully");
  }

  void _clearSingleForm() {
    _userIdController.clear();
    _nameController.clear();
    _passwordController.clear();
    role = 'Student';
  }

  void _showValidationDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Upload Errors",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================= BULK CSV =================

  void _showBulkUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetTitle("Bulk Upload Users"),
            ElevatedButton.icon(
              onPressed: _pickCSV,
              icon: const Icon(Icons.upload_file),
              label: const Text("SELECT CSV FILE"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: csvLoaded && validationErrors.isEmpty && !isUploading
                  ? _uploadCSV
                  : null,
              child: const Text("CONFIRM & UPLOAD"),
            ),
            if (isUploading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCSV() async {
    const typeGroup = XTypeGroup(label: 'CSV', extensions: ['csv']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final data = const CsvToListConverter().convert(
      await File(file.path).readAsString(),
    );
    data.removeAt(0); // header

    setState(() {
      csvRows = data;
      csvLoaded = true;
      validationErrors.clear();
    });

    await _validateCSV();
  }

  Future<void> _validateCSV() async {
    final nameRegex = RegExp(r'^[A-Za-z][A-Za-z ]*$');
    final seenUserIds = <String>{};

    for (int i = 0; i < csvRows.length; i++) {
      final row = csvRows[i];
      final userId = row[0].toString().trim();
      final name = row[1].toString().trim();

      if (userId.isEmpty || name.isEmpty) {
        validationErrors.add("Row ${i + 2}: Missing required fields");
        continue;
      }

      if (!nameRegex.hasMatch(name)) {
        validationErrors.add(
          "Row ${i + 2}: Invalid name '$name' (letters & spaces only)",
        );
      }

      if (seenUserIds.contains(userId)) {
        validationErrors.add("Row ${i + 2}: Duplicate User ID in CSV");
      }
      seenUserIds.add(userId);

      final exists = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (exists.exists) {
        validationErrors.add(
          "Row ${i + 2}: User ID already exists in database",
        );
      }
    }

    setState(() {});
    if (validationErrors.isNotEmpty) {
      _showValidationDialog(validationErrors);
    }
  }

  Future<void> _uploadCSV() async {
    setState(() => isUploading = true);

    for (var row in csvRows) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(row[0].toString().trim())
          .set({
            'UserId': row[0].toString().trim(),
            'Name': row[1].toString().trim(),
            'Role': row[2].toString().trim(),
            'Password': hashPassword(row[3].toString().trim()),
            'Active': true,
            'ForcePasswordReset': true,
          });
    }

    setState(() {
      isUploading = false;
      csvLoaded = false;
      csvRows.clear();
    });

    Navigator.pop(context);
    _showSnack("Bulk upload completed");
  }

  // ================= HELPERS =================

  Widget _sheetTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _textField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Success",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  bool isValidName(String name) {
    final nameRegex = RegExp(r'^[A-Za-z][A-Za-z ]*$');
    return nameRegex.hasMatch(name.trim());
  }
}
