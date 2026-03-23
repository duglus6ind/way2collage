import 'package:bus_tracker/screens/AssignBus.dart';
import 'package:bus_tracker/screens/AssignRole.dart';
import 'package:bus_tracker/screens/SecretaryEmergencyList.dart';
import 'package:bus_tracker/widgets/CustomBottomNav.dart';
import 'package:bus_tracker/screens/BusPassApplicationsScreen.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/screens/UserManagement.dart';
import 'package:bus_tracker/screens/UserLogin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_tracker/widgets/NotificationBell.dart';

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
              Positioned(top: 60, left: 22, child: _topChip("Way2College")),
              Positioned(
                top: 60,
                right: 22,
                child: Row(
                  children: [
                    NotificationBell(userId: userId),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
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
                  ],
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
                      const SizedBox(height: 16),
                      _whiteTile(
                        "Bus Pass Applications",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BusPassApplicationsScreen(),
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
                top:
                    510, // Shifted down by 95px to accommodate the new tile in the green card
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
                top: 591, // Shifted down by 95px
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _whiteCard(),
                  child: Column(
                    children: [
                      _gradientTile("Bus Pass Fee"),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SecretaryEmergencyList(),
                            ),
                          );
                        },
                        child: _gradientTile("Emergency Help"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        userId: userId,
        activeTab: NavTab.home,
      ),
    );
  }

  // TOP CHIP
  Widget _topChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 4)),
        ],
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
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
}
