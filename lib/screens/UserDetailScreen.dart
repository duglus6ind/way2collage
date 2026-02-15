import 'package:bus_tracker/utils/PasswordUtils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailScreen extends StatefulWidget {
  final DocumentSnapshot userDoc;

  const UserDetailScreen({super.key, required this.userDoc});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late TextEditingController nameController;
  late TextEditingController userIdController;
  late String selectedRole;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isEditMode = false;

  final List<String> roles = [
    'Bus Secretary',
    'Driver',
    'Student',
    'Bus Attendant',
  ];

  @override
  void initState() {
    final data = widget.userDoc.data() as Map<String, dynamic>;
    nameController = TextEditingController(text: data['Name']);
    userIdController = TextEditingController(text: data['UserId']);
    selectedRole = data['Role'];
    super.initState();
  }

  Future<void> _saveChanges() async {
    final oldDocId = widget.userDoc.id;
    final newUserId = userIdController.text.trim();

    if (newUserId.isEmpty || nameController.text.trim().isEmpty) return;

    final data = widget.userDoc.data() as Map<String, dynamic>;

    //  Handle UserId change
    if (oldDocId != newUserId) {
      final newDocRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(newUserId);

      if ((await newDocRef.get()).exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User ID already exists")));
        return;
      }

      await newDocRef.set({
        ...data,
        'UserId': newUserId,
        'Name': nameController.text.trim(),
        'Role': selectedRole,
      });

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(oldDocId)
          .delete();
    } else {
      await FirebaseFirestore.instance.collection('Users').doc(oldDocId).update(
        {'Name': nameController.text.trim(), 'Role': selectedRole},
      );
    }

    setState(() {
      isEditMode = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("User updated successfully")));
  }

  void _confirmDeleteUser() {
    // if (selectedRole == 'Bus Secretary') {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text("Bus Secretary account cannot be deleted"),
    //     ),
    //   );
    //   return;
    // }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text(
          "Are you sure you want to delete this user?\n\n"
          "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser() async {
    final docId = widget.userDoc.id;

    await FirebaseFirestore.instance.collection('Users').doc(docId).delete();

    // Go back to Show Users screen
    Navigator.pop(context);
    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("User deleted successfully")));
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill both password fields")),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    final hashed = hashPassword(newPassword);

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userDoc.id)
        .update({'Password': hashed});

    Navigator.pop(context); // close dialog

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset successfully")),
    );
  }

  void _showResetPasswordDialog() {
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
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
          ElevatedButton(onPressed: _resetPassword, child: const Text("Reset")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.userDoc.data() as Map<String, dynamic>;
    final bool isActive = data['Active'] ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF154C79),
        actions: [
          IconButton(
            icon: Icon(
              isEditMode ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            isEditMode
                ? _editField("Name", nameController)
                : _infoTile("Name", data['Name']),

            isEditMode
                ? _editField("User ID", userIdController)
                : _infoTile("User ID", data['UserId']),

            isEditMode ? _roleDropdown() : _infoTile("Role", data['Role']),

            _infoTile(
              "Status",
              isActive ? "Active" : "Inactive",
              valueColor: isActive ? Colors.green : Colors.red,
            ),

            if (isEditMode) ...[
              // SAVE BUTTON
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showResetPasswordDialog,
                      child: const Text("RESET PASSWORD"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _confirmDeleteUser,
                      child: const Text("DELETE USER"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                  ),
                  child: const Text("SAVE CHANGES"),
                ),
              ),

              // if (selectedRole == 'Bus Secretary') ...[
              //   const SizedBox(height: 8),
              //   const Text(
              //     "Bus Secretary account cannot be deleted",
              //     style: TextStyle(color: Colors.red, fontSize: 12),
              //   ),
              // ],
            ],
          ],
        ),
      ),
    );
  }

  //  DISPLAY TILE
  Widget _infoTile(
    String label,
    String value, {
    Color valueColor = Colors.black,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  //  EDIT TEXT FIELD
  Widget _editField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  //  ROLE DROPDOWN
  Widget _roleDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selectedRole,
        decoration: const InputDecoration(
          labelText: "Role",
          border: OutlineInputBorder(),
        ),
        items: roles
            .map((role) => DropdownMenuItem(value: role, child: Text(role)))
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedRole = value!;
          });
        },
      ),
    );
  }
}
