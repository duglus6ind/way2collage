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
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F6F8,
      ), // A slightly cooler, modern off-white background
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          children: [
            // TOP BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _topLogo(),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.redAccent),
                              SizedBox(width: 10),
                              Text(
                                "Logout",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
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

            const SizedBox(height: 35),

            // ASSIGN BUS / ROLE CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _greenCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _whiteTile(
                    "Assign Bus",
                    icon: Icons.directions_bus,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssignBusScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _whiteTile(
                    "Staff Assignment",
                    icon: Icons.badge,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssignStaffScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _whiteTile(
                    "Bus Pass Applications",
                    icon: Icons.credit_card,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BusPassApplicationsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // USER MANAGEMENT BUTTON
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManagementScreen()),
              ),
              child: Container(
                height: 75,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.manage_accounts,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "User Management",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // EMERGENCY HELP CARD
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SecretaryEmergencyList(),
                ),
              ),
              child: Container(
                height: 75,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: _whiteCard(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Emergency Help",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.black26,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        userId: userId,
        activeTab: NavTab.home,
      ),
    );
  }

  // TOP LOGO
  Widget _topLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 4)),
        ],
      ),
      child: Image.asset(
        'assets/images/Way2College.png',
        height: 28,
        fit: BoxFit.contain,
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
  Widget _whiteTile(
    String text, {
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF095C42).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF095C42), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black26,
                size: 16,
              ),
            ],
          ),
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
