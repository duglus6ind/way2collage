import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/utils/PasswordUtils.dart';

class BulkUserUploadScreen extends StatefulWidget {
  const BulkUserUploadScreen({super.key});

  @override
  State<BulkUserUploadScreen> createState() => _BulkUserUploadScreenState();
}

class _BulkUserUploadScreenState extends State<BulkUserUploadScreen> {
  bool isUploading = false;
  String statusMessage = "";
  List<List<dynamic>> csvRows = [];
  List<String> validationErrors = [];
  bool csvLoaded = false;

  Future<void> _pickCSV() async {
    const XTypeGroup typeGroup = XTypeGroup(label: 'CSV', extensions: ['csv']);
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final data = const CsvToListConverter().convert(
      await File(file.path).readAsString(),
      eol: '\n',
    );

    data.removeAt(0); // remove header

    setState(() {
      csvRows = data;
      csvLoaded = true;
    });

    _validateCSV();
  }

  Future<void> _validateCSV() async {
    validationErrors.clear();
    final nameRegex = RegExp(r'^[A-Za-z][A-Za-z .]*$');

    final validRoles = ['Bus Secretary', 'Driver', 'Student', 'Bus Attendant'];

    final seenUserIds = <String>{};

    for (int i = 0; i < csvRows.length; i++) {
      final row = csvRows[i];

      final userId = row[0].toString().trim();
      final name = row[1].toString().trim();
      final role = row[2].toString().trim();
      final password = row[3].toString().trim();

      if (!nameRegex.hasMatch(name)) {
        validationErrors.add(
          "Row ${i + 2}: Invalid name '$name'. Only letters and spaces are allowed",
        );
      }

      if (userId.isEmpty || name.isEmpty || role.isEmpty || password.isEmpty) {
        validationErrors.add("Row ${i + 2}: Missing required fields");
        continue;
      }

      if (!validRoles.contains(role)) {
        validationErrors.add("Row ${i + 2}: Invalid role ($role)");
      }

      if (seenUserIds.contains(userId)) {
        validationErrors.add("Row ${i + 2}: Duplicate UserId in CSV");
      }
      seenUserIds.add(userId);

      final exists = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (exists.exists) {
        validationErrors.add("Row ${i + 2}: UserId already exists");
      }
    }

    setState(() {});
  }

  bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;

    final v = value.toString().toLowerCase().trim();
    return v == 'true' || v == '1' || v == 'yes';
  }

  Future<void> _uploadCSV() async {
    setState(() {
      isUploading = true;
      statusMessage = "Uploading users...";
    });

    try {
      for (var row in csvRows) {
        final userId = row[0].toString().trim();
        final name = row[1].toString().trim();
        final role = row[2].toString().trim();
        final password = row[3].toString().trim();
        final active = parseBool(row[4]);

        await FirebaseFirestore.instance.collection('Users').doc(userId).set({
          'UserId': userId,
          'Name': name,
          'Role': role,
          'Password': hashPassword(password),
          'Active': active,
          'ForcePasswordReset': true,
        }, SetOptions(merge: true));
      }

      setState(() {
        isUploading = false;
        statusMessage = "Upload completed successfully!";
        csvLoaded = false;
        csvRows.clear();
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Upload Complete"),
          content: Text("Successfully uploaded users"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        isUploading = false;
        statusMessage = "Upload failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Upload User List",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF154C79),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Upload users using CSV file",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: isUploading ? null : _pickCSV,
              icon: const Icon(Icons.upload_file),
              label: const Text("SELECT CSV FILE"),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: csvLoaded && validationErrors.isEmpty && !isUploading
                  ? _uploadCSV
                  : null,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("CONFIRM & UPLOAD"),
            ),

            if (csvLoaded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CSV Preview",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: csvRows.length,
                        itemBuilder: (context, index) {
                          final row = csvRows[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.person),
                              title: Text("${row[1]} (${row[0]})"),
                              subtitle: Text("Role: ${row[2]}"),
                            ),
                          );
                        },
                      ),
                    ),

                    if (validationErrors.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: validationErrors
                            .map(
                              (e) => Text(
                                e,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            if (isUploading) const CircularProgressIndicator(),

            const SizedBox(height: 12),

            Text(statusMessage, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
