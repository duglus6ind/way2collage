import 'package:bus_tracker/screens/DriverMap.dart';
import 'package:bus_tracker/screens/ProfilePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/screens/UserLogin.dart';

class DriverDashboard extends StatelessWidget {
  final String userId;

  const DriverDashboard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEAEA),
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

            const SizedBox(height: 12),

            // ASSIGNED BUS CARD (FROM FIRESTORE)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _assignedBusCard(),
            ),

            const SizedBox(height: 20),

            // ACTION CARDS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _actionCard(
                    icon: Icons.warning,
                    text: "Emergency",
                    color: const Color(0xFF9E9E9E),
                    iconColor: Colors.red,
                    onTap: () {
                      // Emergency logic
                    },
                  ),
                  const SizedBox(height: 12),
                  _actionCard(
                    icon: Icons.map,
                    text: "Route Details",
                    color: const Color(0xFF8E8BC7),
                    onTap: () {
                      // Route details
                    },
                  ),
                  const SizedBox(height: 12),
                  _actionCard(
                    icon: Icons.report_problem,
                    text: "Report Issue",
                    color: const Color(0xFF8E8BC7),
                    onTap: () {
                      // Report issue
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: _bottomNav(context),
    );
  }

  // ---------------- FIRESTORE BUS CARD ----------------

  Widget _assignedBusCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const CircularProgressIndicator();
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>;
        final busId = userData['AssignedBusId'];
        final routeId = userData['AssignedRouteId'];

        if (busId == null || routeId == null) {
          return _emptyBusCard();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Buses')
              .doc(busId)
              .snapshots(),
          builder: (context, busSnap) {
            if (!busSnap.hasData) return const SizedBox();

            final busData = busSnap.data!.data() as Map<String, dynamic>;

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Routes')
                  .doc(routeId)
                  .snapshots(),
              builder: (context, routeSnap) {
                if (!routeSnap.hasData) return const SizedBox();

                final routeData =
                    routeSnap.data!.data() as Map<String, dynamic>;

                return _busInfoUI(
                  busName: busData['busName']?.toString() ?? "Unknown Bus",
                  routeName: routeData['Name']?.toString() ?? "Unknown Route",
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _busInfoUI({required String busName, required String routeName}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF095C42),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, color: Colors.orange, size: 32),
              const SizedBox(width: 12),
              Text(
                busName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text("Route", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(
            routeName,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _emptyBusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF095C42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        "No bus assigned yet",
        style: TextStyle(color: Colors.white),
      ),
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

  Widget _actionCard({
    required IconData icon,
    required String text,
    required Color color,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
            child: _navIcon(
              Icons.directions_bus,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DriverMap(userId: userId)),
                );
              },
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
                child: const Icon(Icons.home, color: Colors.white, size: 30),
              ),
            ),
          ),
          Positioned(
            right: 60,
            child: _navIcon(
              Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: userId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Icon(icon, color: Colors.black),
      ),
    );
  }

  // ---------------- LOGOUT ----------------

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UserLogin()),
      (route) => false,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
}
