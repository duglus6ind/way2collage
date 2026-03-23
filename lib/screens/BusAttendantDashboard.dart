import 'package:bus_tracker/screens/AttendantLostItems.dart';
import 'package:bus_tracker/screens/DriverEmergencyList.dart';
import 'package:bus_tracker/screens/BusPassVerificationScreen.dart';
import 'package:bus_tracker/screens/UserLogin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_tracker/widgets/NotificationBell.dart';
import 'package:bus_tracker/widgets/CustomBottomNav.dart';

class BusAttendantDashboard extends StatelessWidget {
  final String userId;

  const BusAttendantDashboard({super.key, required this.userId});

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
                      NotificationBell(userId: userId),
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

            // BUS DETAILS CARD
            // BUS DETAILS CARD (DYNAMIC FROM FIRESTORE)
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
                    icon: Icons.badge,
                    text: "Bus Pass Verify",
                    color: const Color(0xFF8E8BC7),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BusPassVerificationScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _actionCard(
                    icon: Icons.warning,
                    text: "Emergency",
                    color: const Color(0xFF8E8BC7),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DriverEmergencyList(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  _actionCard(
                    icon: Icons.inventory_2,
                    text: "Lost Items Report",
                    color: const Color(0xFF8E8BC7),
                    onTap: () {
                      // lost items page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendantLostItems(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: CustomBottomNav(
        userId: userId,
        activeTab: NavTab.home,
      ),
    );
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;
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

  // ---------------- WIDGETS ----------------

  Widget _assignedBusCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
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
                  busName: (busData['busName'] ?? "Unknown Bus").toString(),
                  routeName: (routeData['Name'] ?? "Unknown Route").toString(),
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(4, 5)),
        ],
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
            child: Text("Route", style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                routeName,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              // Text(
              //   time,
              //   style: const TextStyle(color: Colors.white, fontSize: 14),
              // ),
            ],
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
    Color textColor = Colors.white,
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
            Icon(icon, size: 30, color: textColor),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
