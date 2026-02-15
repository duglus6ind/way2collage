import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DriverMap extends StatelessWidget {
  final String userId;

  const DriverMap({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // MAP PLACEHOLDER
            Positioned.fill(
              child: Image.asset(
                "assets/images/map_placeholder.png",
                fit: BoxFit.cover,
              ),
            ),

            // TOP BAR
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      _iconButton(icon: Icons.notifications_none),
                      const SizedBox(width: 12),
                      _iconButton(icon: Icons.menu),
                    ],
                  ),
                ],
              ),
            ),

            // BUS STATUS UPDATE CHIP
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _showStatusPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _busStatusText(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- STATUS DISPLAY ----------------

  Widget _busStatusText() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Text("Loading...");
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>;
        final busId = userData['AssignedBusId'];

        if (busId == null) {
          return const Text(
            "No bus assigned",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.deepOrange,
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Buses')
              .doc(busId)
              .snapshots(),
          builder: (context, busSnap) {
            if (!busSnap.hasData || !busSnap.data!.exists) {
              return const Text("Bus not found");
            }

            final busData = busSnap.data!.data() as Map<String, dynamic>;
            final status = busData['status'] ?? "ON_THE_WAY";

            return Text(
              _statusLabel(status),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- STATUS PICKER ----------------

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusOption(context, "ON_THE_WAY", "On the way"),
            _statusOption(context, "DELAYED", "Delayed"),
            _statusOption(context, "BREAKDOWN", "Breakdown"),
          ],
        );
      },
    );
  }

  Widget _statusOption(BuildContext context, String value, String label) {
    return ListTile(
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        await _updateBusStatusWithLogic(context, value);
      },
    );
  }

  // ---------------- STATUS UPDATE LOGIC ----------------

  Future<void> _updateBusStatusWithLogic(
    BuildContext context,
    String status,
  ) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get();

    final busId = userDoc.data()?['AssignedBusId'];
    if (busId == null) return;

    if (status == "DELAYED") {
      _showDelayDialog(context, busId);
      return;
    }

    await FirebaseFirestore.instance.collection('Buses').doc(busId).update({
      'status': status,
      'delayMinutes': null,
      'delayReason': null,
      'statusUpdatedBy': userId,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- DELAY POPUP ----------------

  void _showDelayDialog(BuildContext context, String busId) {
    final TextEditingController delayController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Delay Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: delayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Delay time (minutes)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Reason for delay",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (delayController.text.isEmpty ||
                  reasonController.text.isEmpty) {
                return;
              }

              await FirebaseFirestore.instance
                  .collection('Buses')
                  .doc(busId)
                  .update({
                    'status': "DELAYED",
                    'delayMinutes': int.parse(delayController.text),
                    'delayReason': reasonController.text.trim(),
                    'statusUpdatedBy': userId,
                    'statusUpdatedAt': FieldValue.serverTimestamp(),
                  });

              Navigator.pop(context);
            },
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------

  String _statusLabel(String status) {
    switch (status) {
      case 'DELAYED':
        return "Delayed";
      case 'BREAKDOWN':
        return "Breakdown";
      default:
        return "On the way";
    }
  }

  Widget _iconButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}
