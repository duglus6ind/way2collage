import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/widgets/CustomBackButton.dart';

class AssignStaffScreen extends StatefulWidget {
  const AssignStaffScreen({super.key});

  @override
  State<AssignStaffScreen> createState() => _AssignStaffScreenState();
}

class _AssignStaffScreenState extends State<AssignStaffScreen> {
  // Used to force rebuild dropdowns when validation fails
  final Map<String, int> _refreshKeys = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: const Text(
          "Assign Staff",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF095C42),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .where('Role', whereIn: ['Driver', 'Bus Attendant'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allUsers = snapshot.data!.docs;
                final users = allUsers.where((doc) {
                  final name = doc['Name'].toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (users.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;

                    return _assignmentCard(context, user.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: "Search staff name...",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF095C42)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No staff members found",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentCard(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
  ) {
    final bool isDriver = data['Role'] == 'Driver';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF095C42).withOpacity(0.1),
                  child: Icon(
                    isDriver ? Icons.drive_eta_rounded : Icons.badge_rounded,
                    color: const Color(0xFF095C42),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['Name'],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isDriver ? Colors.blue : Colors.orange)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data['Role'],
                          style: TextStyle(
                            fontSize: 11,
                            color: isDriver ? Colors.blue : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // BUS DROPDOWN
                _busDropdown(userId, data),

                const SizedBox(height: 16),

                // ROUTE DROPDOWN
                _routeDropdown(userId, data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _busDropdown(String userId, Map<String, dynamic> data) {
    final String? assignedBusId = data['AssignedBusId'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Buses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final buses = snapshot.data!.docs;

        if (buses.isEmpty) {
          return const Text("No buses available");
        }

        final busIds = buses.map((b) => b.id).toList();

        final safeValue = busIds.contains(assignedBusId) ? assignedBusId : null;

        return DropdownButtonFormField<String>(
          key: ValueKey('${userId}_bus_${_refreshKeys[userId] ?? 0}'),
          value: safeValue,
          decoration: InputDecoration(
            labelText: "Assigned Bus",
            labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            prefixIcon: const Icon(Icons.directions_bus_rounded,
                size: 20, color: Color(0xFF095C42)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.02),
          ),
          items: buses.map((bus) {
            return DropdownMenuItem<String>(
              value: bus.id,
              child: Text(bus['busName'].toString()),
            );
          }).toList(),
          onChanged: (busId) async {
            if (busId == null) return;

            // Check if another user with the same role is already assigned to this bus
            final existingStaff = await FirebaseFirestore.instance
                .collection('Users')
                .where('AssignedBusId', isEqualTo: busId)
                .where('Role', isEqualTo: data['Role'])
                .get();

            final conflictUser = existingStaff.docs
                .where((doc) => doc.id != userId)
                .toList();

            if (conflictUser.isNotEmpty) {
              final otherName = conflictUser.first['Name'];
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Bus is already assigned to $otherName (${data['Role']})",
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                // Trigger a rebuild and change the key to reset the dropdown
                setState(() {
                  _refreshKeys[userId] = (_refreshKeys[userId] ?? 0) + 1;
                });
              }
              return;
            }

            final busDoc = await FirebaseFirestore.instance
                .collection('Buses')
                .doc(busId)
                .get();

            final routeId = busDoc.data()?['routeId'];

            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .update({'AssignedBusId': busId, 'AssignedRouteId': routeId});
          },
        );
      },
    );
  }

  Widget _routeDropdown(String userId, Map<String, dynamic> data) {
    final String? assignedRouteId = data['AssignedRouteId'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Routes').snapshots(),
      builder: (context, routeSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('SpecialTrips')
              .snapshots(),
          builder: (context, tripSnap) {
            if (!routeSnap.hasData || !tripSnap.hasData) {
              return const SizedBox();
            }

            final routes = routeSnap.data!.docs;
            final trips = tripSnap.data!.docs;

            if (routes.isEmpty && trips.isEmpty) {
              return const Text("No routes available");
            }

            // Create a combined list of DropdownMenuItem
            List<DropdownMenuItem<String>> dropdownItems = [];
            List<String> allIds = [];

            // Add Regular Routes
            for (var route in routes) {
              allIds.add(route.id);
              dropdownItems.add(
                DropdownMenuItem<String>(
                  value: route.id,
                  child: Text("Regular: ${route['Name']}"),
                ),
              );
            }

            // Add Special Trips
            for (var trip in trips) {
              allIds.add(trip.id);
              dropdownItems.add(
                DropdownMenuItem<String>(
                  value: trip.id,
                  child: Text("Special: ${trip['tripName']}"),
                ),
              );
            }

            final safeValue =
                allIds.contains(assignedRouteId) ? assignedRouteId : null;

            return DropdownButtonFormField<String>(
              key: ValueKey('${userId}_route_${_refreshKeys[userId] ?? 0}'),
              value: safeValue,
              decoration: InputDecoration(
                labelText: "Assigned Route/Trip",
                labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                prefixIcon: const Icon(Icons.route_rounded,
                    size: 20, color: Color(0xFF095C42)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.02),
              ),
              items: dropdownItems,
              onChanged: (value) async {
                if (value == null) return;

                // Determine if it's a special trip
                final isSpecialTrip = trips.any((t) => t.id == value);

                Map<String, dynamic> updates = {
                  'AssignedRouteId': value,
                  'isSpecialTrip': isSpecialTrip,
                };

                // If special trip, auto-assign the bus
                if (isSpecialTrip) {
                  final tripDoc = trips.firstWhere((t) => t.id == value);
                  final busId = tripDoc['busId'];
                  if (busId != null) {
                    // Validation: Check if another user with the same role is already assigned to this bus
                    final existingStaff = await FirebaseFirestore.instance
                        .collection('Users')
                        .where('AssignedBusId', isEqualTo: busId)
                        .where('Role', isEqualTo: data['Role'])
                        .get();

                    final conflictUser = existingStaff.docs
                        .where((doc) => doc.id != userId)
                        .toList();

                    if (conflictUser.isNotEmpty) {
                      final otherName = conflictUser.first['Name'];
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Bus is already assigned to $otherName (${data['Role']})",
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        // Trigger a rebuild and change the key to reset the dropdown
                        setState(() {
                          _refreshKeys[userId] =
                              (_refreshKeys[userId] ?? 0) + 1;
                        });
                      }
                      return;
                    }
                    updates['AssignedBusId'] = busId;
                  }
                }

                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(userId)
                    .update(updates);
              },
            );
          },
        );
      },
    );
  }
}
