import 'dart:async';
import 'package:bus_tracker/screens/SeatLayout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_tracker/utils/marker_helper.dart';
import 'package:bus_tracker/services/directions_service.dart';

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
  GoogleMapController? _mapController;
  BitmapDescriptor? _busIcon;

  String? _assignedStopName;
  List<LatLng> _polylineCoordinates = [];
  String _distance = "";
  String _duration = "";
  bool _isFetchingRoute = false;
  DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _initMapListener();
  }

  Future<void> _loadCustomMarker() async {
    try {
      _busIcon = await getMarkerIconFromData(Icons.directions_bus, Colors.blue);
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
            final newStopName = data['AssignedStopName'];

            if (mounted) {
              setState(() {
                _assignedStopName = newStopName;
              });
            }

            if (newBusId != _busId) {
              if (mounted) {
                setState(() {
                  _busId = newBusId;
                  _polylineCoordinates.clear();
                  _distance = "";
                  _duration = "";
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

                            if (_assignedStopName != null) {
                              // Throttle API requests to every 15 seconds
                              if (_lastFetchTime == null ||
                                  DateTime.now()
                                          .difference(_lastFetchTime!)
                                          .inSeconds >
                                      15) {
                                _resolveStopAndFetchETA(
                                  _currentPosition!,
                                  _assignedStopName!,
                                  busData['routeId'],
                                );
                              }
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

  Future<void> _resolveStopAndFetchETA(
    LatLng origin,
    String stopName,
    String? routeId,
  ) async {
    if (routeId == null) return;

    dynamic destinationPoint = stopName;

    try {
      final routeDoc = await FirebaseFirestore.instance
          .collection('Routes')
          .doc(routeId)
          .get();
      if (routeDoc.exists) {
        final stops = routeDoc.data()?['Stops'] as List<dynamic>?;
        if (stops != null) {
          try {
            final targetStop = stops.firstWhere((s) => s['name'] == stopName);
            if (targetStop['lat'] != null && targetStop['lng'] != null) {
              destinationPoint = LatLng(
                (targetStop['lat'] as num).toDouble(),
                (targetStop['lng'] as num).toDouble(),
              );
            }
          } catch (_) {
            // Stop not found, fallback to string
          }
        }
      }
    } catch (e) {
      print("Error resolving exact stop location: $e");
    }

    _fetchETA(origin, destinationPoint);
  }

  Future<void> _fetchETA(LatLng origin, dynamic destination) async {
    if (_isFetchingRoute) return;
    setState(() => _isFetchingRoute = true);

    try {
      final dirData = await DirectionsService.getDirections(
        origin: origin,
        destination: destination,
      );

      if (dirData != null && mounted) {
        setState(() {
          _distance = dirData['distance'];
          _duration = dirData['duration'];
          _polylineCoordinates = dirData['polylineCoordinates'];
          _lastFetchTime = DateTime.now();
        });
      }
    } catch (e) {
      print("Error fetching ETA: $e");
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
            if (_assignedStopName != null &&
                _distance.isNotEmpty &&
                _duration.isNotEmpty)
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
                        "To: $_assignedStopName",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
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
