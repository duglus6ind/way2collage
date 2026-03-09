import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/services/notification_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bus_tracker/utils/marker_helper.dart';
import 'package:bus_tracker/services/directions_service.dart';

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
  GoogleMapController? _mapController;
  String _loadingMessage = "Acquiring GPS location...";
  BitmapDescriptor? _busIcon;

  List<LatLng> _polylineCoordinates = [];
  String _distance = "";
  String _duration = "";
  bool _isFetchingRoute = false;
  bool _isTripStarted = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _initDriverLocation();
  }

  Future<void> _loadCustomMarker() async {
    try {
      _busIcon = await getMarkerIconFromData(Icons.directions_bus, Colors.blue);
      if (mounted) setState(() {});
    } catch (e) {
      print("Error loading custom marker: $e");
    }
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
              if (_busId != null && !_isFetchingRoute) {
                _fetchRoutePath(_busId!);
              }
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
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_currentPosition!, 16.0),
              ); // Center map
            }
          }

          // 4. Update Firestore only if trip is started
          if (_busId != null && _isTripStarted) {
            FirebaseFirestore.instance.collection('Buses').doc(_busId).update({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'lastLocationUpdate': FieldValue.serverTimestamp(),
            });
          }
        });
  }

  Future<void> _fetchRoutePath(String busId) async {
    if (_isFetchingRoute || !_isTripStarted) return;
    setState(() => _isFetchingRoute = true);

    try {
      final busDoc = await FirebaseFirestore.instance
          .collection('Buses')
          .doc(busId)
          .get();
      if (!busDoc.exists) return;
      final routeId = busDoc.data()?['routeId'];
      if (routeId == null) return;

      final routeDoc = await FirebaseFirestore.instance
          .collection('Routes')
          .doc(routeId)
          .get();
      if (!routeDoc.exists) return;

      final stops = routeDoc.data()?['Stops'] as List<dynamic>?;
      if (stops == null || stops.isEmpty) return;

      List<dynamic> waypoints = [];
      dynamic destination;

      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        dynamic locationPoint;

        // Use exact Map GPS coordinate if the Secretary selected one, else fallback to String query
        if (stop['lat'] != null && stop['lng'] != null) {
          locationPoint = LatLng(
            (stop['lat'] as num).toDouble(),
            (stop['lng'] as num).toDouble(),
          );
        } else {
          locationPoint = stop['name'].toString();
        }

        if (i == stops.length - 1) {
          destination = locationPoint; // Last stop is destination
        } else {
          waypoints.add(locationPoint);
        }
      }

      while (_currentPosition == null) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
      }

      final dirData = await DirectionsService.getDirections(
        origin: _currentPosition!,
        destination: destination,
        waypoints: waypoints,
      );

      if (dirData != null && mounted) {
        setState(() {
          _distance = dirData['distance'];
          _duration = dirData['duration'];
          _polylineCoordinates = dirData['polylineCoordinates'];
        });
      }
    } catch (e) {
      print("Error fetching route path: $e");
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
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
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target:
                      _currentPosition ??
                      const LatLng(9.847694, 76.942194), // GEC Idukki
                  zoom: 16.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                markers: {
                  if (_currentPosition != null)
                    Marker(
                      markerId: const MarkerId('busPosition'),
                      position: _currentPosition!,
                      icon:
                          _busIcon ??
                          BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue,
                          ),
                    )
                  else
                    Marker(
                      markerId: const MarkerId('schoolPosition'),
                      position: const LatLng(9.847694, 76.942194),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                },
                polylines: {
                  if (_polylineCoordinates.isNotEmpty)
                    Polyline(
                      polylineId: const PolylineId('route_path'),
                      color: Colors.blueAccent,
                      width: 5,
                      points: _polylineCoordinates,
                    ),
                },
              ),
            ),

            // ETA INFO CARD (Top right)
            if (_distance.isNotEmpty && _duration.isNotEmpty)
              Positioned(
                top: 80,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _distance,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _duration,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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

            // START/END TRIP BOTTOM PANEL
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTripStarted
                      ? Colors.red
                      : const Color(0xFF095C42),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 6,
                ),
                onPressed: _toggleTrip,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isTripStarted
                          ? Icons.stop_circle
                          : Icons.play_circle_fill,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isTripStarted ? "END TRIP" : "START TRIP",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TRIP TOGGLE ----------------
  void _toggleTrip() {
    setState(() {
      _isTripStarted = !_isTripStarted;

      if (_isTripStarted) {
        // Start Trip
        if (_busId != null) {
          _fetchRoutePath(_busId!);
        }
      } else {
        // End Trip
        _polylineCoordinates.clear();
        _distance = "";
        _duration = "";
      }
    });

    if (_isTripStarted && _busId != null && _currentPosition != null) {
      // Immediately push first coordinate to wake up student apps
      FirebaseFirestore.instance.collection('Buses').doc(_busId).update({
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    }
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
