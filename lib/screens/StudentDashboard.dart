import 'package:bus_tracker/screens/ProfilePage.dart';
import 'package:bus_tracker/screens/StudentLostItems.dart';
import 'package:bus_tracker/screens/StudentBusPass.dart';
import 'package:bus_tracker/screens/StudentMap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_tracker/screens/UserLogin.dart';
import 'package:bus_tracker/widgets/NotificationBell.dart';
import 'dart:ui';

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
                  final selectedStopName = userData['AssignedStopName'];

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
                                        .update({
                                          'AssignedBusId': value,
                                          'AssignedStopName':
                                              null, // Reset stop if bus changes
                                        });
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ROUTE DETAILS (AUTO FROM BUS)
                            if (selectedBusId != null)
                              _routeDetailsFromBus(
                                selectedBusId,
                                selectedStopName,
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // APPLY FOR BUS PASS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentBusPassPage(userId: userId),
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
                      Icon(Icons.directions_bus, color: Colors.green),
                      SizedBox(width: 12),
                      Text(
                        "Apply for Bus Pass",
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

            // STUDENT BUS PASS AREA
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bus_pass_applications')
                  .where('userId', isEqualTo: userId)
                  .where('status', isEqualTo: 'APPROVED')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  // Premium Inactive Pass UI
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color.fromRGBO(0, 0, 0, 0.5),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            // 1. Blurred Background Content
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 8.0,
                                sigmaY: 8.0,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade700,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                            // 2. Glassy Overlay with Lock Icon & Message
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.1),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.lock_person_rounded,
                                        color: Color.fromRGBO(0, 110, 255, 1),
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Bus Pass Inactive",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10.0,
                                            color: Colors.black54,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                      ),
                                      child: Text(
                                        "Apply now or check your application status to activate your pass.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 11,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Show the first approved pass found
                final passData =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildBusPass(passData),
                );
              },
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

  Widget _buildBusPass(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
        border: Border.all(
          color: const Color.fromRGBO(0, 170, 255, 1),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // COLLEGE LOGO
                Image.asset(
                  'assets/images/collegeLogo.jpg',
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.school, size: 50),
                ),
                const SizedBox(width: 8),
                // HEADINGS
                Expanded(
                  child: Column(
                    children: const [
                      Text(
                        "Govt. Engineering College",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(2, 82, 243, 1),
                        ),
                      ),
                      Text(
                        "PAINAVU - IDUKKI",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // STUDENT PHOTO
                Container(
                  width: 60,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      data['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 40),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BODY (Nested box)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B5C43).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0B5C43).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _passInfoRow("Name", data['name'] ?? "N/A"),
                const Divider(height: 12),
                _passInfoRow("Semester", data['semester'] ?? "N/A"),
                const Divider(height: 12),
                _passInfoRow("Department", data['department'] ?? "N/A"),
                const Divider(height: 12),
                _passInfoRow("Admn No", data['admissionNumber'] ?? "N/A"),
              ],
            ),
          ),

          // FOOTER / STATUS
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(0, 170, 255, 1),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: const Text(
              "STUDENT BUS PASS",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(": "),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
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

  Widget _routeDetailsFromBus(String busId, String? currentStopName) {
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
                const SizedBox(height: 16),

                // STOP DROPDOWN
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentStopName,
                      hint: const Text(
                        "Select Your Stop",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      isExpanded: true,
                      items:
                          (routeData['Stops'] as List<dynamic>?)?.map((
                            stopObj,
                          ) {
                            final stopName = stopObj['name'] as String;
                            return DropdownMenuItem<String>(
                              value: stopName,
                              child: Text(stopName),
                            );
                          }).toList() ??
                          [],
                      onChanged: (value) async {
                        if (value != null) {
                          await FirebaseFirestore.instance
                              .collection('Users')
                              .doc(userId)
                              .update({'AssignedStopName': value});
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
