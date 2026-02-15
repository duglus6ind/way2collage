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
      appBar: AppBar(
        title: const Text("Assign Bus", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF095C42),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildBusList()),

          // Bottom action panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: const [
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

  // BUS LIST UI
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
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus['busName'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ROUTE DROPDOWN
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
                          border: OutlineInputBorder(),
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

  // BUTTON STYLES
  Widget _primaryButton({required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF095C42),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  // DELETE CONFIRMATION
  void _confirmDeleteBus(BuildContext context, String busId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Bus"),
        content: const Text(
          "This bus will be removed and unassigned from all users.\n\n"
          "Are you sure?",
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

// DIALOG OPENERS
void _showAddBusDialog(BuildContext context) {
  showDialog(context: context, builder: (_) => const _AddBusDialog());
}

void _showAddRouteDialog(BuildContext context) {
  showDialog(context: context, builder: (_) => const _AddRouteDialog());
}

class _AddBusDialog extends StatefulWidget {
  const _AddBusDialog();

  @override
  State<_AddBusDialog> createState() => _AddBusDialogState();
}

class _AddBusDialogState extends State<_AddBusDialog> {
  final TextEditingController busNameController = TextEditingController();
  String? selectedRouteId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Bus"),
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
                    child: Text(doc['Name'].toString()),
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
          child: const Text("CANCEL"),
        ),
        ElevatedButton(onPressed: _saveBus, child: const Text("ADD")),
      ],
    );
  }

  Future<void> _saveBus() async {
    final busName = busNameController.text.trim();
    if (busName.isEmpty || selectedRouteId == null) return;

    final busId = normalizeId(busName);

    final docRef = FirebaseFirestore.instance.collection('Buses').doc(busId);

    if ((await docRef.get()).exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bus already exists")));
      return;
    }

    await docRef.set({'busName': busName, 'routeId': selectedRouteId});

    Navigator.pop(context);
  }
}

class _AddRouteDialog extends StatefulWidget {
  const _AddRouteDialog();

  @override
  State<_AddRouteDialog> createState() => _AddRouteDialogState();
}

class _AddRouteDialogState extends State<_AddRouteDialog> {
  final TextEditingController routeController = TextEditingController();
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Manage Routes"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: routeController,
              decoration: const InputDecoration(
                labelText: "New Route Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _addRoute,
                child: const Text("ADD ROUTE"),
              ),
            ),

            const SizedBox(height: 20),
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

            Expanded(child: _buildRouteList()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CLOSE"),
        ),
      ],
    );
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

  Future<void> _addRoute() async {
    final routeName = routeController.text.trim();
    if (routeName.isEmpty) return;

    final routeId = normalizeId(routeName);

    final docRef = FirebaseFirestore.instance.collection('Routes').doc(routeId);

    if ((await docRef.get()).exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Route already exists")));
      return;
    }

    await docRef.set({'Name': routeName});

    routeController.clear();
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
          "Are you sure you want to delete \"$routeName\"?\n\n"
          "This action cannot be undone.",
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

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Route deleted successfully")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
