import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/utils/PasswordUtils.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  String? selectedRole;
  String searchUserId = "";

  final List<String> roles = [
    'All',
    'Bus Secretary',
    'Driver',
    'Student',
    'Bus Attendant',
  ];

  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showResetDialog(String docId, String userId) {
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("User ID: $userId"),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_passwordController.text.trim().isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(docId)
                  .update({
                    'Password': hashPassword(_passwordController.text.trim()),
                  });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Password updated successfully")),
              );
            },
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Password Reset",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF154C79),
      ),
      body: Column(
        children: [
          //  FILTERS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: "Filter by Role",
                    border: OutlineInputBorder(),
                  ),
                  items: roles
                      .map(
                        (role) =>
                            DropdownMenuItem(value: role, child: Text(role)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Search by User ID",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchUserId = value.trim();
                    });
                  },
                ),
              ],
            ),
          ),

          //  USER LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((doc) {
                  final role = doc['Role'];
                  final userId = doc['UserId'];

                  final roleMatch =
                      selectedRole == null ||
                      selectedRole == 'All' ||
                      role == selectedRole;

                  final searchMatch =
                      searchUserId.isEmpty ||
                      userId.toString().toLowerCase().contains(
                        searchUserId.toLowerCase(),
                      );

                  return roleMatch && searchMatch;
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user['Name']),
                        subtitle: Text(
                          "ID: ${user['UserId']} • Role: ${user['Role']}",
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            _showResetDialog(user.id, user['UserId']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text("Reset"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
