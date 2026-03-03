import 'package:bus_tracker/utils/id_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignBusScreen extends StatefulWidget {
  const AssignBusScreen({super.key});

  @override
  State<AssignBusScreen> createState() => _AssignBusScreenState();
}

class _AssignBusScreenState extends State<AssignBusScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEAEA),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF095C42),
        elevation: 4,
        shadowColor: Colors.black26,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Assign Bus & Routes",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: 0.4,
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(child: _buildBusList()),

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
                _primaryButton(
                  text: "ADD BUS",
                  onTap: () => _showAddBusDialog(context),
                ),
                const SizedBox(height: 12),
                _outlineButton(
                  text: "ADD ROUTE",
                  onTap: () => _showAddRouteDialog(context),
                ),
              ],
            ),
          ),
        ],
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
                ),
              ),
            ),
            if (stopControllers.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  setState(() {
                    stopControllers.removeAt(index);
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
        stops.add({'name': stopName, 'order': i + 1});
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
    stopControllers.add(TextEditingController());
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
