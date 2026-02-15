import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecretaryMap extends StatefulWidget {
  final String userId;
  const SecretaryMap({super.key, required this.userId});

  @override
  State<SecretaryMap> createState() => _SecretaryMapState();
}

class _SecretaryMapState extends State<SecretaryMap> {
  String? selectedBusId;

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

            // BUS SELECTOR + STATUS
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  _busDropdown(),
                  const SizedBox(height: 12),
                  if (selectedBusId != null) _busStatusCard(selectedBusId!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= BUS DROPDOWN =================

  Widget _busDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Buses').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _statusContainer(
            title: "No buses available",
            subtitle: "",
            color: Colors.grey.shade300,
          );
        }

        final buses = snap.data!.docs;

        // Auto select first bus
        selectedBusId ??= buses.first.id;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedBusId,
              items: buses.map((bus) {
                return DropdownMenuItem<String>(
                  value: bus.id,
                  child: Text(bus['busName']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBusId = value;
                });
              },
            ),
          ),
        );
      },
    );
  }

  // ================= BUS STATUS =================

  Widget _busStatusCard(String busId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Buses')
          .doc(busId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return _statusContainer(
            title: "Bus not found",
            subtitle: "",
            color: Colors.grey.shade300,
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final status = data['status'] ?? "ON_THE_WAY";
        final delayMinutes = data['delayMinutes'];
        final delayReason = data['delayReason'];

        switch (status) {
          case "DELAYED":
            return _statusContainer(
              title:
                  "Bus Delayed${delayReason != null ? " • $delayReason" : ""}",
              subtitle: delayMinutes != null
                  ? "$delayMinutes minutes late"
                  : "",
              color: Colors.orange.shade100,
              titleColor: Colors.red,
            );

          case "BREAKDOWN":
            return _statusContainer(
              title: "Bus Breakdown",
              subtitle: "Please wait for updates",
              color: Colors.red.shade100,
              titleColor: Colors.red,
            );

          default:
            return _statusContainer(
              title: "Bus On the Way",
              subtitle: "Arriving as scheduled",
              color: Colors.green.shade100,
              titleColor: Colors.green.shade800,
            );
        }
      },
    );
  }

  // ================= UI HELPERS =================

  Widget _statusContainer({
    required String title,
    required String subtitle,
    required Color color,
    Color titleColor = Colors.black,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
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
