import 'dart:async';
import 'package:bus_tracker/screens/SeatLayout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class StudentMap extends StatefulWidget {
  final String userId;

  const StudentMap({super.key, required this.userId});

  @override
  State<StudentMap> createState() => _StudentMapState();
}

class _StudentMapState extends State<StudentMap> {
  String? _busId;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<DocumentSnapshot>? _busSubscription;
  LatLng? _currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initMapListener();
  }

  void _initMapListener() {
    _userSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .snapshots()
        .listen((userSnap) {
          if (userSnap.exists) {
            final data = userSnap.data() as Map<String, dynamic>;
            final newBusId = data['AssignedBusId'];
            if (newBusId != _busId) {
              if (mounted) {
                setState(() {
                  _busId = newBusId;
                });
              }
              _busSubscription?.cancel();
              if (_busId != null) {
                _busSubscription = FirebaseFirestore.instance
                    .collection('Buses')
                    .doc(_busId)
                    .snapshots()
                    .listen((busSnap) {
                      if (busSnap.exists) {
                        final busData = busSnap.data() as Map<String, dynamic>;
                        if (busData['latitude'] != null &&
                            busData['longitude'] != null) {
                          final newLat = (busData['latitude'] as num)
                              .toDouble();
                          final newLng = (busData['longitude'] as num)
                              .toDouble();
                          if (mounted) {
                            bool isFirst = _currentPosition == null;
                            setState(() {
                              _currentPosition = LatLng(newLat, newLng);
                            });
                            if (!isFirst) {
                              _mapController.move(_currentPosition!, 16.0);
                            }
                          }
                        }
                      }
                    });
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _busSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ACTUAL MAP
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _currentPosition ??
                      const LatLng(9.847694, 76.942194), // GEC Idukki
                  initialZoom: 16.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.bus_tracker',
                  ),
                  MarkerLayer(
                    markers: [
                      if (_currentPosition != null)
                        Marker(
                          point: _currentPosition!,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.directions_bus,
                            color: Colors.blue,
                            size: 40,
                          ),
                        )
                      else
                        const Marker(
                          point: LatLng(9.847694, 76.942194),
                          width: 60,
                          height: 60,
                          child: Icon(
                            Icons.school,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                    ],
                  ),
                ],
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

            // BUS STATUS CARD
            Positioned(top: 90, left: 16, right: 16, child: _busStatusCard()),

            // CHECK SEATS BUTTON
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  _openSeatLayout(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade600,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.event_seat, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        "Check Seats",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= BUS STATUS =================

  Widget _busStatusCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const SizedBox();
        }

        if (!userSnap.hasData || userSnap.data?.data() == null) {
          return const SizedBox();
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>;
        final busId = userData['AssignedBusId'];

        if (busId == null) {
          return _statusContainer(
            title: "Bus not assigned",
            subtitle: "",
            footer: "",
            color: Colors.grey,
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Buses')
              .doc(busId)
              .snapshots(),
          builder: (context, busSnap) {
            if (!busSnap.hasData || busSnap.data?.data() == null) {
              return _statusContainer(
                title: "Bus not found",
                subtitle: "",
                footer: "",
                color: Colors.white,
                titleColor: Colors.grey,
              );
            }
            if (!busSnap.hasData || !busSnap.data!.exists) {
              return _statusContainer(
                title: "Bus not found",
                subtitle: "",
                footer: "",
                color: Colors.grey,
              );
            }

            final busData = busSnap.data!.data() as Map<String, dynamic>;

            final status = busData['status'] ?? "ON_THE_WAY";
            final delayMinutes = busData['delayMinutes'];
            final delayReason = busData['delayReason'];

            final Timestamp? ts = busData['statusUpdatedAt'];
            final DateTime? lastUpdated = ts?.toDate();
            final String footerText = lastUpdated != null
                ? "Last updated: ${_formatTime(lastUpdated)}"
                : "";

            switch (status) {
              case "DELAYED":
                return _statusContainer(
                  title:
                      "Bus Delayed${delayReason != null ? " due to $delayReason" : ""}",
                  subtitle: delayMinutes != null
                      ? "$delayMinutes minutes late"
                      : "",
                  footer: footerText,
                  color: Colors.white,
                  titleColor: Colors.orange,
                );

              case "BREAKDOWN":
                return _statusContainer(
                  title: "Bus Breakdown",
                  subtitle: "Please wait for updates",
                  footer: footerText,
                  color: Colors.white,
                  titleColor: Colors.red,
                );

              default:
                return _statusContainer(
                  title: "Bus On the Way",
                  subtitle: "Arriving as scheduled",
                  footer: footerText,
                  color: Colors.white,
                  titleColor: Colors.green,
                );
            }
          },
        );
      },
    );
  }

  // ================= HELPERS =================

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  Future<void> _openSeatLayout(BuildContext context) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .get();

    final busId = userDoc.data()?['AssignedBusId'];

    if (busId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No bus assigned")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatLayoutPage(busId: busId, readOnly: true),
      ),
    );
  }

  // ================= UI =================

  Widget _statusContainer({
    required String title,
    required String subtitle,
    required String footer,
    required Color color,
    Color titleColor = Colors.black,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // 🔹 Left Color Indicator Bar
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: titleColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // ✅ CENTERED
                children: [
                  // 🔹 Status Row (Dot + Title)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // ✅ CENTERED
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: titleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.center, // ✅ CENTER TEXT
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center, // ✅ CENTER
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],

                  if (footer.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      footer,
                      textAlign: TextAlign.center, // ✅ CENTER
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
