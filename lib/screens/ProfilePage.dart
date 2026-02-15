import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEAEA),
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR (CLEANED)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconBox(
                    Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Text(
                    "My Profile",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  // Spacer to balance layout (icon removed intentionally)
                  const SizedBox(width: 38),
                ],
              ),
            ),

            // PROFILE CONTENT
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.data!.exists) {
                    return const Center(child: Text("Profile not found"));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  final String name = data['Name'] ?? "Unknown";
                  final String userCode = data['UserId'] ?? "-";
                  final String role = data['Role'] ?? "User";
                  final bool isActive = data['Active'] ?? false;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // HEADER CARD
                        _headerCard(name, role),

                        const SizedBox(height: 24),

                        // DETAILS CARD
                        _detailsCard(
                          userId: userCode,
                          role: role,
                          isActive: isActive,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _headerCard(String name, String role) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF095C42),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(4, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person, size: 42, color: Colors.black),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard({
    required String userId,
    required String role,
    required bool isActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(4, 5)),
        ],
      ),
      child: Column(
        children: [
          _infoRow("User ID", userId),
          const Divider(height: 1),
          _infoRow("Role", role),
          const Divider(height: 1),
          _statusRow(isActive),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              "Status",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? "Active" : "Inactive",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SMALL HELPERS =================

  Widget _iconBox(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(1, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}
