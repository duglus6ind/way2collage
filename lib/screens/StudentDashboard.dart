import 'package:bus_tracker/screens/ProfilePage.dart';
import 'package:bus_tracker/screens/StudentLostItems.dart';
import 'package:bus_tracker/screens/StudentMap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/screens/UserLogin.dart';

class StudentDashboard extends StatelessWidget {
  final String userId;
  const StudentDashboard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _topChip("Way2College"),
                  Row(
                    children: [
                      _iconBox(Icons.notifications_none),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'logout') {
                            _showLogoutDialog(context);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 10),
                                Text("Logout"),
                              ],
                            ),
                          ),
                        ],
                        child: _iconBox(Icons.menu),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ROUTE CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userId)
                    .snapshots(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const SizedBox();
                  }

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>;
                  final selectedBusId = userData['AssignedBusId'];

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Buses')
                        .snapshots(),
                    builder: (context, busSnap) {
                      if (!busSnap.hasData) {
                        return const SizedBox();
                      }

                      final buses = busSnap.data!.docs;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B5C43),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BUS DROPDOWN
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: buses.any((b) => b.id == selectedBusId)
                                      ? selectedBusId
                                      : null,
                                  hint: const Text(
                                    "Select Bus",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: buses.map((bus) {
                                    return DropdownMenuItem<String>(
                                      value: bus.id,
                                      child: Text(
                                        bus['busName']?.toString() ??
                                            "Unknown Bus",
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) async {
                                    await FirebaseFirestore.instance
                                        .collection('Users')
                                        .doc(userId)
                                        .update({'AssignedBusId': value});
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ROUTE DETAILS (AUTO FROM BUS)
                            if (selectedBusId != null)
                              _routeDetailsFromBus(selectedBusId),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // REPORT LOST ITEM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentLostItemsPage(userId: userId),
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(width: 16),
                      Icon(Icons.report_problem, color: Colors.blue),
                      SizedBox(width: 12),
                      Text(
                        "Report Lost Item",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // STUDENT INFO CARD PLACEHOLDER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _whiteBar(),
                          const SizedBox(height: 10),
                          _whiteBar(),
                          const SizedBox(height: 10),
                          _whiteBar(width: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: _bottomNav(context),
    );
  }

  // ---------------- LOGOUT (UNCHANGED) ----------------

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UserLogin()),
      (route) => false,
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget _topChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Icon(icon, color: Colors.black),
    );
  }

  Widget _whiteBar({double width = double.infinity}) {
    return Container(
      height: 14,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          Positioned(
            left: 60,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentMap(userId: userId)),
                );
              },
              child: _navIcon(Icons.directions_bus),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: const Icon(Icons.home, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            right: 60,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: userId),
                  ),
                );
              },
              child: _navIcon(Icons.person),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Icon(icon, color: Colors.black),
    );
  }

  Widget _routeDetailsFromBus(String busId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Buses')
          .doc(busId)
          .snapshots(),
      builder: (context, busSnap) {
        if (!busSnap.hasData || !busSnap.data!.exists) {
          return const SizedBox();
        }

        final busData = busSnap.data!.data() as Map<String, dynamic>;
        final routeId = busData['routeId'];

        if (routeId == null) {
          return const Text(
            "Route not assigned",
            style: TextStyle(color: Colors.white),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Routes')
              .doc(routeId)
              .snapshots(),
          builder: (context, routeSnap) {
            if (!routeSnap.hasData || !routeSnap.data!.exists) {
              return const SizedBox();
            }

            final routeData = routeSnap.data!.data() as Map<String, dynamic>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Route",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      routeData['Name']?.toString() ?? "Unknown Route",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Text(
                    //   routeData['Time'] ?? "",
                    //   style: const TextStyle(
                    //     color: Colors.white,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
