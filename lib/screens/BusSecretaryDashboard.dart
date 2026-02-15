import 'package:bus_tracker/screens/AssignBus.dart';
import 'package:bus_tracker/screens/AssignRole.dart';
import 'package:bus_tracker/screens/ProfilePage.dart';
import 'package:bus_tracker/screens/SecretaryMap.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/screens/UserManagement.dart';
import 'package:bus_tracker/screens/UserLogin.dart';

class BusSecretaryDashboard extends StatelessWidget {
  final String userId;
  const BusSecretaryDashboard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEEEAEA),
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // TOP BAR ICONS
              Positioned(top: 60, left: 22, child: _iconBox(Icons.person)),
              Positioned(
                top: 60,
                right: 22,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      _showLogoutDialog(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
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
              ),
              // ASSIGN BUS / ROLE CARD
              // ASSIGN BUS / ROLE CARD
              Positioned(
                top: 134,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _greenCard(),
                  child: Column(
                    children: [
                      _whiteTile(
                        "Assign Bus",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AssignBusScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _whiteTile(
                        "Staff Assignment",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AssignStaffScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // USER MANAGEMENT BUTTON
              Positioned(
                top: 415,
                left: 45,
                right: 45,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(4, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      "User Management",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // LOWER WHITE CARD
              Positioned(
                top: 496,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _whiteCard(),
                  child: Column(
                    children: [
                      _gradientTile("Bus Pass Fee"),
                      const SizedBox(height: 16),
                      _gradientTile("Emergency Help"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 100,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Black rounded navigation bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),

            // Left button - Bus Route (white background)
            Positioned(
              left: 60,
              bottom: 28,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SecretaryMap(userId: userId),
                    ),
                  );
                },
                child: _navIcon(Icons.directions_bus),
              ),
            ),

            // Right button - Profile (white background)
            Positioned(
              right: 55,
              bottom: 28,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: userId),
                      ),
                    );
                  },
                  child: const Icon(Icons.person, color: Colors.black),
                ),
              ),
            ),

            // Center Home button (black + white border)
            Positioned(
              bottom: 22,
              child: Container(
                padding: const EdgeInsets.all(6), // white border thickness
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.home),
                    color: Colors.white,
                    iconSize: 32,
                    onPressed: () {
                      // Already on Home
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ICON BOX (TOP LEFT / RIGHT)
  Widget _iconBox(IconData icon) {
    return Container(
      height: 39,
      width: 39,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 4)),
        ],
      ),
      child: Icon(icon, color: Colors.black),
    );
  }

  // GREEN CARD
  BoxDecoration _greenCard() {
    return BoxDecoration(
      color: const Color(0xFF095C42),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(5, 5)),
      ],
    );
  }

  // WHITE CARD
  BoxDecoration _whiteCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(5, 5)),
      ],
    );
  }

  // WHITE TILE
  Widget _whiteTile(String text, {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: onTap,
      child: Container(
        height: 79,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // GRADIENT TILE
  Widget _gradientTile(String text) {
    return Container(
      height: 79,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        gradient: const LinearGradient(
          colors: [Color(0xFFAAA7D4), Color.fromRGBO(1, 1, 5, 0.5)],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 4)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  // LOGOUT HANDLERS (UNCHANGED LOGIC)
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
}
