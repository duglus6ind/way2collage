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
  BitmapDescriptor? _stopIcon;
  BitmapDescriptor? _intermediateStopIcon;
  Set<Marker> _stopMarkers = {};

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
      _stopIcon = await getMarkerIconFromData(Icons.location_on, Colors.red, size: 120);
      _intermediateStopIcon = await getMarkerIconFromData(Icons.location_on, Colors.orange, size: 80);
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
                  _stopMarkers.clear();
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

                            // Periodic route update (every 15 seconds)
                            if (_busId != null &&
                                (_lastFetchTime == null ||
                                    DateTime.now().difference(_lastFetchTime!).inSeconds > 15)) {
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
      Set<Marker> newMarkers = {};

      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        LatLng? pos;

        if (stop['lat'] != null && stop['lng'] != null) {
          pos = LatLng((stop['lat'] as num).toDouble(), (stop['lng'] as num).toDouble());
        }

        final isTarget = _assignedStopName != null && stop['name'] == _assignedStopName;
        final isDestination = i == stops.length - 1;

        if (pos != null) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('stop_${i}_${stop['name']}'),
              position: pos,
              infoWindow: InfoWindow(title: stop['name']),
              icon: isTarget
                  ? (_stopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
                  : (_intermediateStopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)),
            ),
          );
        }

        if (isDestination) {
          destination = pos ?? stop['name'].toString();
        } else {
          waypoints.add(pos ?? stop['name'].toString());
        }
      }

      if (mounted) setState(() => _stopMarkers = newMarkers);

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
          _lastFetchTime = DateTime.now();
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
                    ),
                  ..._stopMarkers,
                  if (_currentPosition == null && _stopMarkers.isEmpty)
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

            // TOP BAR
            Positioned(
              top: 16,
              left: 16,
              child: _iconButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
            ),

            // BUS STATUS CARD
            Positioned(
              top: 90, 
              left: 16, 
              right: 16, 
              child: _busStatusCard(),
            ),

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
            
            // ETA Logic
            String? etaInfo;
            if (_distance.isNotEmpty && _duration.isNotEmpty) {
              etaInfo = "Arriving in $_duration (${_distance})";
            }

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
                  etaText: etaInfo,
                );

              case "BREAKDOWN":
                return _statusContainer(
                  title: "Bus Breakdown",
                  subtitle: "Please wait for updates",
                  footer: footerText,
                  color: Colors.white,
                  titleColor: Colors.red,
                  etaText: etaInfo,
                );

              default:
                return _statusContainer(
                  title: "Bus On the Way",
                  subtitle: "Arriving as scheduled",
                  footer: footerText,
                  color: Colors.white,
                  titleColor: Colors.green,
                  etaText: etaInfo,
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
    String? etaText,
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
            height: (etaText != null) ? 140 : 100, // Dynamic height
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    const SizedBox(height: 4),
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

                  if (etaText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        etaText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],

                  if (footer.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      footer,
                      textAlign: TextAlign.center, // ✅ CENTER
                      style: TextStyle(
                        fontSize: 11,
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
