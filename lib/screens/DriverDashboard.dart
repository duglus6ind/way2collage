import 'package:bus_tracker/screens/DriverMap.dart';
import 'package:bus_tracker/screens/ProfilePage.dart';
import 'package:bus_tracker/screens/DriverEmergencyList.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/screens/UserLogin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_tracker/widgets/NotificationBell.dart';

class DriverDashboard extends StatelessWidget {
  final String userId;

  const DriverDashboard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEAEA),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .snapshots(),
          builder: (context, userSnap) {
            if (!userSnap.hasData)
              return const Center(child: CircularProgressIndicator());

            final userData = userSnap.data!.data() as Map<String, dynamic>;
            final busId = userData['AssignedBusId'];
            final routeId = userData['AssignedRouteId'];
            final isSpecialTrip = userData['isSpecialTrip'] == true;

            Widget buildDashboardContent(String busName, String routeName, List<dynamic>? stops) {
              return Column(
                children: [
                  _topBar(context),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _busInfoUI(
                      busName: busName,
                      routeName: routeName,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
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
                          icon: Icons.map,
                          text: "Route Details",
                          color: const Color(0xFF8E8BC7),
                          onTap: () => _showStopsPopUp(context, stops),
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
              );
            }

            if (busId == null) {
              return buildDashboardContent(
                "No Bus Assigned",
                "No routes",
                null,
              );
            }

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Buses')
                  .doc(busId)
                  .snapshots(),
              builder: (context, busSnap) {
                if (!busSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final String busName;
                if (!busSnap.data!.exists) {
                  busName = "Assigned bus not found";
                } else {
                  final busData = busSnap.data!.data() as Map<String, dynamic>;
                  busName = busData['busName']?.toString() ?? "Unknown Bus";
                }

                if (routeId == null) {
                  return buildDashboardContent(busName, "No routes", null);
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(isSpecialTrip ? 'SpecialTrips' : 'Routes')
                      .doc(routeId)
                      .snapshots(),
                  builder: (context, routeSnap) {
                    if (!routeSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    String displayRouteName = "No routes";
                    List<dynamic>? stops;

                    if (routeSnap.data!.exists) {
                      final routeData = routeSnap.data!.data() as Map<String, dynamic>;
                      displayRouteName = isSpecialTrip ? (routeData['tripName'] ?? "Special Trip") : (routeData['Name'] ?? "Unknown Route");
                      
                      if (isSpecialTrip) {
                        stops = routeData['waypoints'] as List<dynamic>?;
                        final destName = routeData['destinationName'];
                        final destLat = routeData['destinationLat'];
                        final destLng = routeData['destinationLng'];
                        if (destName != null && destLat != null && destLng != null) {
                          stops = [
                            ...(stops ?? []),
                            {'name': destName, 'lat': destLat, 'lng': destLng}
                          ];
                        }
                      } else {
                        stops = routeData['Stops'] as List<dynamic>?;
                      }
                    }

                    return buildDashboardContent(busName, displayRouteName, stops);
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
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
    );
  }

  void _showStopsPopUp(BuildContext context, List<dynamic>? stops) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.map, color: Color(0xFF095C42)),
              SizedBox(width: 10),
              Text("Route Stops"),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: stops == null || stops.isEmpty
                ? const Text("No stops assigned to this route.")
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: stops.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final stopName = stops[index]['name'] as String;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF095C42),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                stopName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _busInfoUI({required String busName, required String routeName}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF095C42),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, color: Colors.orange, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  busName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "ACTIVE ROUTE",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            routeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
