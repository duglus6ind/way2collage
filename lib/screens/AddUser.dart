import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/utils/PasswordUtils.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String role = 'Student';

  void _saveUser() async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(_userIdController.text)
        .set({
          'UserId': _userIdController.text,
          'Password': hashPassword(_passwordController.text.trim()),
          'Name': _nameController.text,
          'Role': role,
          'Active': true,
          'ForcePasswordReset': true,
        });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add User",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF154C79),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(labelText: "User ID"),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: role,
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
              onChanged: (value) {
                setState(() {
                  role = value!;
                });
              },
              decoration: const InputDecoration(labelText: "Role"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveUser,
              child: const Text("SAVE USER"),
            ),
          ],
        ),
      ),
    );
  }
}
