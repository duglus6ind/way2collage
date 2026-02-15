import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDeactivationScreen extends StatefulWidget {
  const UserDeactivationScreen({super.key});

  @override
  State<UserDeactivationScreen> createState() => _UserDeactivationScreenState();
}

class _UserDeactivationScreenState extends State<UserDeactivationScreen> {
  String? selectedRole;
  String searchUserId = "";

  final List<String> roles = [
    'All',
    'Bus Secretary',
    'Driver',
    'Student',
    'Bus Attendant',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Deactivation",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF154C79),
      ),
      body: Column(
        children: [
          // FILTER SECTION
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
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
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
                    final isActive = user['Active'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.person,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                        title: Text(user['Name']),
                        subtitle: Text(
                          "ID: ${user['UserId']} • Role: ${user['Role']}",
                        ),
                        trailing: Switch(
                          value: isActive,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            FirebaseFirestore.instance
                                .collection('Users')
                                .doc(user.id)
                                .update({'Active': value});
                          },
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
