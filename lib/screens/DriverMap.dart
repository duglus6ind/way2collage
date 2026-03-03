import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/services/notification_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class DriverMap extends StatefulWidget {
  final String userId;

  const DriverMap({super.key, required this.userId});

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  String? _busId;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  String _loadingMessage = "Acquiring GPS location...";

  @override
  void initState() {
    super.initState();
    _initDriverLocation();
  }

  Future<void> _initDriverLocation() async {
    // 1. Get User's Bus ID
    _userSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .snapshots()
        .listen((snap) {
          if (snap.exists) {
            final data = snap.data() as Map<String, dynamic>;
            if (mounted) {
              setState(() {
                _busId = data['AssignedBusId'];
              });
            }
          }
        });

    // 2. Request Location Permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted)
        setState(
          () => _loadingMessage =
              "Location services are disabled.\nPlease enable GPS.",
        );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          setState(() => _loadingMessage = "Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted)
        setState(
          () =>
              _loadingMessage = "Location permissions are permanently denied.",
        );
      return;
    }

    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(
            initialPosition.latitude,
            initialPosition.longitude,
          );
        });
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _loadingMessage =
              "Waiting for GPS signal...\n(If on emulator, set a mock location)",
        );
    }

    // 3. Start Tracking Location
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // update every 5 meters
          ),
        ).listen((Position position) {
          if (mounted) {
            bool isFirst = _currentPosition == null;
            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);
            });
            if (!isFirst) {
              _mapController.move(_currentPosition!, 16.0); // Center map
            }
          }

          // 4. Update Firestore
          if (_busId != null) {
            FirebaseFirestore.instance.collection('Buses').doc(_busId).update({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'lastLocationUpdate': FieldValue.serverTimestamp(),
            });
          }
        });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _positionStream?.cancel();
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

            // LOADING MESSAGE OVERLAY (Top center if loading)
            if (_currentPosition == null)
              Positioned(
                top: 130,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _loadingMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
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
                  child: _busStatusText(),
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
          .doc(widget.userId)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const SizedBox();
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        final busId = userData?['AssignedBusId'];

        if (busId == null) {
          return _statusChip(label: "No bus assigned", color: Colors.grey);
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Buses')
              .doc(busId)
              .snapshots(),
          builder: (context, busSnap) {
            if (!busSnap.hasData || !busSnap.data!.exists) {
              return _statusChip(label: "Bus not found", color: Colors.grey);
            }

            final busData = busSnap.data!.data() as Map<String, dynamic>;

            final status = busData['status'] ?? "ON_THE_WAY";
            final delayMinutes = busData['delayMinutes'];

            final color = _statusColor(status);

            final label = status == "DELAYED" && delayMinutes != null
                ? "Delayed • $delayMinutes min"
                : _statusLabel(status);

            return _statusChip(label: label, color: color);
          },
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "DELAYED":
        return Colors.orange;
      case "BREAKDOWN":
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Widget _statusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
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
        .doc(widget.userId)
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
      'statusUpdatedBy': widget.userId,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });

    // 🔔 Send notification to all students of this bus
    final students = await FirebaseFirestore.instance
        .collection('Users')
        .where('Role', isEqualTo: 'Student')
        .where('AssignedBusId', isEqualTo: busId)
        .get();

    final busDoc = await FirebaseFirestore.instance
        .collection('Buses')
        .doc(busId)
        .get();

    final busName = busDoc.data()?['busName'] ?? "Your Bus";
    for (var student in students.docs) {
      await NotificationService.sendNotification(
        toUserId: student.id,
        title: "$busName Status Updated",
        message: "Status changed to ${_statusLabel(status)}",
        busId: busId,
        busName: busName,
      );
    }
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
                    'statusUpdatedBy': widget.userId,
                    'statusUpdatedAt': FieldValue.serverTimestamp(),
                  });

              // 🔔 Notify students about delay
              final students = await FirebaseFirestore.instance
                  .collection('Users')
                  .where('Role', isEqualTo: 'Student')
                  .where('AssignedBusId', isEqualTo: busId)
                  .get();

              final busDoc = await FirebaseFirestore.instance
                  .collection('Buses')
                  .doc(busId)
                  .get();

              final busName = busDoc.data()?['busName'] ?? "Your Bus";

              for (var student in students.docs) {
                await NotificationService.sendNotification(
                  toUserId: student.id,
                  title: "$busName Delayed",
                  message: "Delayed by ${delayController.text} minutes",
                  busId: busId,
                  busName: busName,
                );
              }

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
