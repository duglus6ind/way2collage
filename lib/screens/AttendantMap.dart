import 'dart:async';
import 'package:bus_tracker/screens/SeatLayout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracker/services/notification_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_tracker/utils/marker_helper.dart';
import 'package:bus_tracker/services/directions_service.dart';

class AttendantMap extends StatefulWidget {
  final String userId;

  const AttendantMap({super.key, required this.userId});

  @override
  State<AttendantMap> createState() => _AttendantMapState();
}

class _AttendantMapState extends State<AttendantMap> {
  String? _busId;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<DocumentSnapshot>? _busSubscription;
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  BitmapDescriptor? _busIcon;
  
  List<LatLng> _polylineCoordinates = [];
  String _distance = "";
  String _duration = "";
  bool _isFetchingRoute = false;
  DateTime? _lastRouteFetchTime;
  Set<Marker> _markers = {};
  BitmapDescriptor? _stopIcon;
  BitmapDescriptor? _destinationIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _initMapListener();
  }

  Future<void> _loadCustomMarker() async {
    try {
      _busIcon = await getMarkerIconFromData(Icons.directions_bus, Colors.blue);
      _stopIcon = await getMarkerIconFromData(Icons.location_on, Colors.orange, size: 100);
      _destinationIcon = await getMarkerIconFromData(Icons.location_on, Colors.red, size: 120);
      if (mounted) setState(() {});
    } catch (e) {
      print("Error loading custom marker: $e");
    }
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
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  _currentPosition!,
                                  16.0,
                                ),
                              );
                            }

                            // Periodic route update (every 30 seconds)
                            if (_busId != null &&
                                (_lastRouteFetchTime == null ||
                                    DateTime.now()
                                            .difference(_lastRouteFetchTime!)
                                            .inSeconds >
                                        30)) {
                              _fetchRoutePath(_busId!);
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

  Future<void> _fetchRoutePath(String busId) async {
    if (_isFetchingRoute) return;
    setState(() => _isFetchingRoute = true);

    try {
      bool isSpecial = false;
      String? routeId;

      final driverQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('Role', isEqualTo: 'Driver')
          .where('AssignedBusId', isEqualTo: busId)
          .limit(1)
          .get();

      if (driverQuery.docs.isNotEmpty) {
        final dData = driverQuery.docs.first.data();
        isSpecial = dData['isSpecialTrip'] == true;
        if (isSpecial) {
           routeId = dData['AssignedRouteId'];
        } else {
           final busDoc = await FirebaseFirestore.instance.collection('Buses').doc(busId).get();
           routeId = busDoc.data()?['routeId'] ?? dData['AssignedRouteId'];
        }
      } else {
        final busDoc = await FirebaseFirestore.instance.collection('Buses').doc(busId).get();
        if (busDoc.exists) routeId = busDoc.data()?['routeId'];
      }

      if (routeId == null) return;

      final collectionName = isSpecial ? 'SpecialTrips' : 'Routes';
      final routeDoc = await FirebaseFirestore.instance.collection(collectionName).doc(routeId).get();
      if (!routeDoc.exists) return;

      List<dynamic>? stops;
      if (isSpecial) {
        stops = routeDoc.data()?['waypoints'] as List<dynamic>?;
        final destName = routeDoc.data()?['destinationName'];
        final destLat = routeDoc.data()?['destinationLat'];
        final destLng = routeDoc.data()?['destinationLng'];
        if (destName != null && destLat != null && destLng != null) {
          stops = [
            ...(stops ?? []),
            {'name': destName, 'lat': destLat, 'lng': destLng, 'order': (stops?.length ?? 0) + 1}
          ];
        }
      } else {
        stops = routeDoc.data()?['Stops'] as List<dynamic>?;
      }
      if (stops == null || stops.isEmpty) return;

      List<dynamic> waypoints = [];
      dynamic destination;
      Set<Marker> stopMarkers = {};

      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        LatLng? pos;

        if (stop['lat'] != null && stop['lng'] != null) {
          pos = LatLng((stop['lat'] as num).toDouble(), (stop['lng'] as num).toDouble());
        }

        final isDestination = i == stops.length - 1;

        if (pos != null) {
          stopMarkers.add(
            Marker(
              markerId: MarkerId('stop_${i}_${stop['name']}'),
              position: pos,
              infoWindow: InfoWindow(title: stop['name']),
              icon: isDestination
                  ? (_destinationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
                  : (_stopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)),
            ),
          );
        }

        if (isDestination) {
          destination = pos ?? stop['name'].toString();
        } else {
          waypoints.add(pos ?? stop['name'].toString());
        }
      }

      if (mounted) setState(() => _markers = stopMarkers);

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
          _lastRouteFetchTime = DateTime.now();
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
                  ..._markers,
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

            // TOP BAR
            Positioned(
              top: 16,
              left: 16,
              child: _iconButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
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

            // TRACK SEATS BUTTON
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: () => _openSeatLayout(context),
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
                        "Track Seats",
                        style: TextStyle(fontWeight: FontWeight.w600),
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

  // ---------------- STATUS DISPLAY ----------------

  Widget _busStatusText() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Text("Loading...");
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        final busId = userData?['AssignedBusId'];

        if (busId == null) {
          return const Text(
            "No bus assigned",
            style: TextStyle(fontWeight: FontWeight.w600),
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
            final delayMinutes = busData['delayMinutes'];

            final color = _getStatusColor(status);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: color, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    status == "DELAYED" && delayMinutes != null
                        ? "Delayed • $delayMinutes min"
                        : _statusLabel(status),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
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

    // 🔔 Notify all students assigned to this bus
    final students = await FirebaseFirestore.instance
        .collection('Users')
        .where('AssignedBusId', isEqualTo: busId)
        .where('Role', isEqualTo: 'Student')
        .get();
    final busDoc = await FirebaseFirestore.instance
        .collection('Buses')
        .doc(busId)
        .get();

    final busName = busDoc.data()?['busName'] ?? "Your Bus";

    for (var doc in students.docs) {
      await NotificationService.sendNotification(
        toUserId: doc.id,
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
                  .where('AssignedBusId', isEqualTo: busId)
                  .where('Role', isEqualTo: 'Student')
                  .get();
              final busDoc = await FirebaseFirestore.instance
                  .collection('Buses')
                  .doc(busId)
                  .get();

              final busName = busDoc.data()?['busName'] ?? "Your Bus";

              for (var doc in students.docs) {
                await NotificationService.sendNotification(
                  toUserId: doc.id,
                  title: "$busName Delayed",
                  message:
                      "Delayed by ${delayController.text} min • ${reasonController.text}",
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

  Color _getStatusColor(String status) {
    switch (status) {
      case "DELAYED":
        return Colors.orange;
      case "BREAKDOWN":
        return Colors.red;
      default:
        return Colors.green;
    }
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
        builder: (_) => SeatLayoutPage(
          busId: busId,
          readOnly: false, // 👈 attendant can modify seats
        ),
      ),
    );
  }
}
