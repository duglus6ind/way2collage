import 'package:bus_tracker/utils/id_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/screens/MapPickerScreen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_tracker/widgets/CustomBackButton.dart';

class AssignBusScreen extends StatefulWidget {
  const AssignBusScreen({super.key});

  @override
  State<AssignBusScreen> createState() => _AssignBusScreenState();
}

class _AssignBusScreenState extends State<AssignBusScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEEAEA),

        // ================= APP BAR =================
        appBar: AppBar(
          backgroundColor: const Color(0xFF095C42),
          elevation: 4,
          shadowColor: Colors.black26,
          centerTitle: true,
          leading: const CustomBackButton(),
          title: const Text(
            "Assign Bus & Routes",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: 0.4,
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: "REGULAR"),
              Tab(text: "SPECIAL BOOKINGS"),
            ],
          ),
        ),

        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildBusList(),
                  _buildSpecialTripsList(),
                ],
              ),
            ),

            // Bottom Action Panel
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _primaryButton(
                          text: "ADD BUS",
                          onTap: () => _showAddBusDialog(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _outlineButton(
                          text: "ADD ROUTE",
                          onTap: () => _showAddRouteDialog(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _outlineButton(
                    text: "SPECIAL BOOKING",
                    onTap: () => _showSpecialBookingDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= BUS LIST =================

  Widget _buildBusList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Buses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final buses = snapshot.data!.docs;

        if (buses.isEmpty) {
          return const Center(
            child: Text(
              "No buses added",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final bus = buses[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_bus,
                        color: Color(0xFF095C42),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bus['busName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Route Dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Routes')
                        .snapshots(),
                    builder: (context, routeSnap) {
                      if (!routeSnap.hasData) {
                        return const SizedBox();
                      }

                      return DropdownButtonFormField<String>(
                        value: bus['routeId'],
                        decoration: const InputDecoration(
                          labelText: "Assigned Route",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        ),
                        items: routeSnap.data!.docs.map((doc) {
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(doc['Name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          FirebaseFirestore.instance
                              .collection('Buses')
                              .doc(bus.id)
                              .update({'routeId': value});
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _confirmDeleteBus(context, bus.id),
                      child: const Text(
                        "DELETE BUS",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= SPECIAL TRIPS LIST =================

  Widget _buildSpecialTripsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('SpecialTrips').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final trips = snapshot.data!.docs;
        if (trips.isEmpty) {
          return const Center(child: Text("No special bookings found.", style: TextStyle(fontSize: 16, color: Colors.black54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            final tripName = trip['tripName'] ?? 'Unnamed Trip';
            final busName = trip['busName'] ?? 'Unknown Bus';
            final destination = trip['destinationName'] ?? 'Unknown Destination';
            final Timestamp? scheduledTimeTs = trip.data().toString().contains('scheduledTime') ? trip['scheduledTime'] as Timestamp? : null;
            String timeStr = "Not Scheduled";
            if (scheduledTimeTs != null) {
              final dt = scheduledTimeTs.toDate();
              timeStr = "${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_seat, color: Color(0xFF095C42), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tripName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteSpecialTrip(context, trip.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("🚍 Assigned Bus: $busName", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("📍 Destination: $destination", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("⏰ Scheduled: $timeStr", style: const TextStyle(fontSize: 16)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSpecialTrip(BuildContext context, String tripId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Special Booking"),
        content: const Text("Are you sure you want to delete this trip?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('SpecialTrips').doc(tripId).delete();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ================= BUTTON STYLES =================

  Widget _primaryButton({required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF095C42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF095C42)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF095C42),
          ),
        ),
      ),
    );
  }

  // ================= DELETE BUS =================

  void _confirmDeleteBus(BuildContext context, String busId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Bus"),
        content: const Text(
          "This bus will be removed and unassigned from all users.\n\nAre you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteBus(busId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteBus(String busId) async {
    final users = await FirebaseFirestore.instance
        .collection('Users')
        .where('AssignedBusId', isEqualTo: busId)
        .get();

    for (var doc in users.docs) {
      doc.reference.update({'AssignedBusId': null});
    }

    await FirebaseFirestore.instance.collection('Buses').doc(busId).delete();
  }
}
// ================= DIALOG OPENERS =================

void _showAddBusDialog(BuildContext context) {
  showDialog(context: context, builder: (_) => const _AddBusDialog());
}

void _showAddRouteDialog(BuildContext context) {
  showDialog(context: context, builder: (_) => const _AddRouteDialog());
}

void _showSpecialBookingDialog(BuildContext context) {
  showDialog(context: context, builder: (_) => const _SpecialBookingDialog());
}
// ================= ADD BUS DIALOG =================

class _AddBusDialog extends StatefulWidget {
  const _AddBusDialog();

  @override
  State<_AddBusDialog> createState() => _AddBusDialogState();
}

class _AddBusDialogState extends State<_AddBusDialog> {
  final TextEditingController busNameController = TextEditingController();
  String? selectedRouteId;
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Add New Bus",
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: busNameController,
            decoration: const InputDecoration(
              labelText: "Bus Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Routes').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              return DropdownButtonFormField<String>(
                value: selectedRouteId,
                decoration: const InputDecoration(
                  labelText: "Select Route",
                  border: OutlineInputBorder(),
                ),
                items: snapshot.data!.docs.map((doc) {
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(doc['Name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRouteId = value;
                  });
                },
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _saveBus,
          child: const Text("Add"),
        ),
      ],
    );
  }

  Future<void> _saveBus() async {
    final busName = busNameController.text.trim();
    if (busName.isEmpty || selectedRouteId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => isSaving = true);

    final busId = normalizeId(busName);
    final docRef = FirebaseFirestore.instance.collection('Buses').doc(busId);

    if ((await docRef.get()).exists) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bus already exists")));
      return;
    }

    await docRef.set({'busName': busName, 'routeId': selectedRouteId});

    Navigator.pop(context);
  }
}
// ================= ADD ROUTE DIALOG =================

class _AddRouteDialog extends StatefulWidget {
  const _AddRouteDialog();

  @override
  State<_AddRouteDialog> createState() => _AddRouteDialogState();
}

class _AddRouteDialogState extends State<_AddRouteDialog> {
  final TextEditingController routeController = TextEditingController();
  final List<TextEditingController> stopControllers = [TextEditingController()];
  final List<LatLng?> stopCoordinates = [null];

  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Manage Routes",
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: routeController,
                decoration: const InputDecoration(
                  labelText: "Route Name",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Stops (Include Destination)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 10),

              ..._buildStopFields(),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Another Stop"),
                onPressed: () {
                  setState(() {
                    stopControllers.add(TextEditingController());
                    stopCoordinates.add(null);
                  });
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _addRoute,
                  child: const Text("Save Route"),
                ),
              ),

              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 10),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Existing Routes",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(height: 150, child: _buildRouteList()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }

  List<Widget> _buildStopFields() {
    return List.generate(stopControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: stopControllers[index],
                decoration: InputDecoration(
                  labelText: "Stop ${index + 1}",
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: stopCoordinates[index] != null
                      ? Colors.green.withOpacity(0.1)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                stopCoordinates[index] != null
                    ? Icons.map
                    : Icons.add_location_alt_outlined,
                color: stopCoordinates[index] != null
                    ? Colors.green
                    : Colors.blue,
              ),
              onPressed: () async {
                final LatLng? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPickerScreen(
                      initialPosition: stopCoordinates[index],
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    stopCoordinates[index] = result;
                  });
                }
              },
            ),
            if (stopControllers.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  setState(() {
                    stopControllers.removeAt(index);
                    stopCoordinates.removeAt(index);
                  });
                },
              ),
          ],
        ),
      );
    });
  }

  Future<void> _addRoute() async {
    final routeName = routeController.text.trim();
    if (routeName.isEmpty) return;

    List<Map<String, dynamic>> stops = [];

    for (int i = 0; i < stopControllers.length; i++) {
      final stopName = stopControllers[i].text.trim();
      if (stopName.isNotEmpty) {
        final coord = stopCoordinates[i];
        stops.add({
          'name': stopName,
          'order': i + 1,
          'lat': coord?.latitude,
          'lng': coord?.longitude,
        });
      }
    }

    if (stops.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add at least one stop")));
      return;
    }

    final routeId = normalizeId(routeName);
    final docRef = FirebaseFirestore.instance.collection('Routes').doc(routeId);

    if ((await docRef.get()).exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Route already exists")));
      return;
    }

    await docRef.set({'Name': routeName, 'Stops': stops});

    routeController.clear();
    stopControllers.clear();
    stopCoordinates.clear();
    stopControllers.add(TextEditingController());
    stopCoordinates.add(null);
  }

  Widget _buildRouteList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Routes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final routes = snapshot.data!.docs;

        if (routes.isEmpty) {
          return const Text("No routes available");
        }

        return ListView.builder(
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final route = routes[index];
            final routeName = route['Name'];

            return ListTile(
              title: Text(routeName),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () =>
                    _confirmDeleteRoute(context, route.id, routeName),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteRoute(
    BuildContext context,
    String routeId,
    String routeName,
  ) async {
    final busesUsingRoute = await FirebaseFirestore.instance
        .collection('Buses')
        .where('routeId', isEqualTo: routeId)
        .get();

    if (busesUsingRoute.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cannot delete route. It is assigned to one or more buses.",
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Route"),
        content: Text(
          "Are you sure you want to delete \"$routeName\"?\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('Routes')
                  .doc(routeId)
                  .delete();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ================= SPECIAL BOOKING DIALOG =================

class _SpecialBookingDialog extends StatefulWidget {
  const _SpecialBookingDialog();

  @override
  State<_SpecialBookingDialog> createState() => _SpecialBookingDialogState();
}

class _SpecialBookingDialogState extends State<_SpecialBookingDialog> {
  final TextEditingController tripNameController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  LatLng? destinationCoordinate;
  
  DateTime? selectedDateTime;
  
  String? selectedBusId;
  String? selectedBusName;

  final List<TextEditingController> stopControllers = [];
  final List<LatLng?> stopCoordinates = [];

  bool isSaving = false;

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    if (mounted) {
      setState(() {
        selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Special Trip Booking",
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 550,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: tripNameController,
                decoration: const InputDecoration(
                  labelText: "Trip Name (e.g. Museum Visit)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text("Schedule Time", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF095C42)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDateTime == null 
                            ? "Select Date & Time" 
                            : "${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} at ${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(
                            fontSize: 16,
                            color: selectedDateTime == null ? Colors.black54 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text("Select Bus", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Buses').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: selectedBusId,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['busName']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBusId = value;
                        selectedBusName = snapshot.data!.docs.firstWhere((doc) => doc.id == value)['busName'];
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              const Text("Destination", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: destinationController,
                      decoration: InputDecoration(
                        labelText: "Final Destination",
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: destinationCoordinate != null
                            ? Colors.green.withOpacity(0.1)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      destinationCoordinate != null ? Icons.map : Icons.add_location_alt_outlined,
                      color: destinationCoordinate != null ? Colors.green : Colors.blue,
                    ),
                    onPressed: () async {
                      final LatLng? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPickerScreen(
                            initialPosition: destinationCoordinate,
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          destinationCoordinate = result;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text("Route / Waypoints (Optional)", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._buildStopFields(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Waypoint"),
                onPressed: () {
                  setState(() {
                    stopControllers.add(TextEditingController());
                    stopCoordinates.add(null);
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _saveSpecialBooking,
          child: const Text("Save Booking"),
        ),
      ],
    );
  }

  List<Widget> _buildStopFields() {
    return List.generate(stopControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: stopControllers[index],
                decoration: InputDecoration(
                  labelText: "Waypoint ${index + 1}",
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: stopCoordinates[index] != null
                      ? Colors.green.withOpacity(0.1)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                stopCoordinates[index] != null ? Icons.map : Icons.add_location_alt_outlined,
                color: stopCoordinates[index] != null ? Colors.green : Colors.blue,
              ),
              onPressed: () async {
                final LatLng? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPickerScreen(
                      initialPosition: stopCoordinates[index],
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    stopCoordinates[index] = result;
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {
                setState(() {
                  stopControllers.removeAt(index);
                  stopCoordinates.removeAt(index);
                });
              },
            ),
          ],
        ),
      );
    });
  }

  Future<void> _saveSpecialBooking() async {
    final tripName = tripNameController.text.trim();
    final destinationName = destinationController.text.trim();

    if (tripName.isEmpty || selectedBusId == null || destinationName.isEmpty || selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill Trip Name, Date & Time, Bus, and Destination")),
      );
      return;
    }

    setState(() => isSaving = true);

    List<Map<String, dynamic>> waypoints = [];
    for (int i = 0; i < stopControllers.length; i++) {
      final stopName = stopControllers[i].text.trim();
      if (stopName.isNotEmpty) {
        final coord = stopCoordinates[i];
        waypoints.add({
          'name': stopName,
          'order': i + 1,
          'lat': coord?.latitude,
          'lng': coord?.longitude,
        });
      }
    }

    try {
      await FirebaseFirestore.instance.collection('SpecialTrips').add({
        'tripName': tripName,
        'busId': selectedBusId,
        'busName': selectedBusName,
        'destinationName': destinationName,
        'destinationLat': destinationCoordinate?.latitude,
        'destinationLng': destinationCoordinate?.longitude,
        'scheduledTime': selectedDateTime,
        'waypoints': waypoints,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Special Trip booked successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
}
