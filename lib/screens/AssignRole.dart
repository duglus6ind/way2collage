import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignStaffScreen extends StatelessWidget {
  const AssignStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEAEA),
      appBar: AppBar(
        title: const Text(
          "Assign Bus & Route",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF095C42),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .where('Role', whereIn: ['Driver', 'Bus Attendant'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(
              child: Text("No drivers or bus attendants found"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              return _assignmentCard(context, user.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _assignmentCard(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['Name'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(data['Role'], style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),

          // BUS DROPDOWN
          _busDropdown(userId, data),

          const SizedBox(height: 12),

          // ROUTE DROPDOWN
          _routeDropdown(userId, data),
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
          value: safeValue,
          decoration: const InputDecoration(
            labelText: "Assign Bus",
            border: OutlineInputBorder(),
          ),
          items: buses.map((bus) {
            return DropdownMenuItem<String>(
              value: bus.id,
              child: Text(bus['busName'].toString()),
            );
          }).toList(),
          onChanged: (busId) async {
            if (busId == null) return;

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
          stream: FirebaseFirestore.instance.collection('SpecialTrips').snapshots(),
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

            final safeValue = allIds.contains(assignedRouteId) ? assignedRouteId : null;

            return DropdownButtonFormField<String>(
              value: safeValue,
              decoration: const InputDecoration(
                labelText: "Assign Route/Trip",
                border: OutlineInputBorder(),
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
                  if (tripDoc['busId'] != null) {
                    updates['AssignedBusId'] = tripDoc['busId'];
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
