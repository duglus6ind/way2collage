import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/screens/UserDetailScreen.dart';

class ShowUsersScreen extends StatefulWidget {
  const ShowUsersScreen({super.key});

  @override
  State<ShowUsersScreen> createState() => _ShowUsersScreenState();
}

class _ShowUsersScreenState extends State<ShowUsersScreen> {
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
        title: const Text("All Users", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF095C42),
      ),
      body: Column(
        children: [
          //  FILTER SECTION
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
                    final bool isActive = user['Active'] ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserDetailScreen(userDoc: user),
                            ),
                          );
                        },
                        leading: Icon(
                          Icons.person,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                        title: Text(user['Name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ID: ${user['UserId']}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Role: ${user['Role']}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),

                        trailing: TextButton(
                          onPressed: () {
                            _confirmToggleUserStatus(context, user, isActive);
                          },
                          child: Text(
                            isActive ? "Deactivate" : "Activate",
                            style: TextStyle(
                              color: isActive ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  void _confirmToggleUserStatus(
    BuildContext context,
    DocumentSnapshot user,
    bool isActive,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? "Deactivate User" : "Activate User"),
        content: Text(
          isActive
              ? "Are you sure you want to deactivate this user?\n\nThe user will not be able to login."
              : "Are you sure you want to activate this user?\n\nThe user will be able to login again.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(user.id)
                  .update({'Active': !isActive});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isActive
                        ? "User deactivated successfully"
                        : "User activated successfully",
                  ),
                ),
              );
            },
            child: Text(
              isActive ? "Deactivate" : "Activate",
              style: TextStyle(color: isActive ? Colors.red : Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
