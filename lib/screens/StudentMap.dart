import 'dart:async';
import 'dart:math' as math;
import 'package:bus_tracker/screens/SeatLayout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_tracker/utils/marker_helper.dart';
import 'package:bus_tracker/widgets/CustomBottomNav.dart';
import 'package:bus_tracker/services/directions_service.dart';
import 'package:bus_tracker/widgets/CustomBackButton.dart';

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
  List<String> _passedStops = [];
  bool _tripActive = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _initMapListener();
  }

  Future<void> _loadCustomMarker() async {
    try {
      _busIcon = await getMarkerIconFromData(Icons.directions_bus, Colors.blue);
      _stopIcon = await getMarkerIconFromData(
        Icons.location_on,
        Colors.red,
        size: 120,
      );
      _intermediateStopIcon = await getMarkerIconFromData(
        Icons.location_on,
        Colors.orange,
        size: 80,
      );
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
                        if (mounted) {
                          setState(() {
                            _passedStops = List<String>.from(busData['passedStops'] ?? []);
                            _tripActive = busData['tripActive'] == true;
                          });
                        }

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

                              if (_polylineCoordinates.isNotEmpty) {
                                double minDistance = double.infinity;
                                int closestIndex = 0;
                                int checkLimit = _polylineCoordinates.length < 50 ? _polylineCoordinates.length : 50;

                                for (int i = 0; i < checkLimit; i++) {
                                  double lat1 = _currentPosition!.latitude;
                                  double lon1 = _currentPosition!.longitude;
                                  double lat2 = _polylineCoordinates[i].latitude;
                                  double lon2 = _polylineCoordinates[i].longitude;
                                  
                                  var p = 0.017453292519943295; // Math.PI / 180
                                  var a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
                                          math.cos(lat1 * p) * math.cos(lat2 * p) * 
                                          (1 - math.cos((lon2 - lon1) * p))/2;
                                  var dist = 12742 * math.asin(math.sqrt(a));
                                  
                                  if (dist < minDistance) {
                                    minDistance = dist;
                                    closestIndex = i;
                                  }
                                }
                                
                                if (closestIndex > 0) {
                                  _polylineCoordinates.removeRange(0, closestIndex);
                                }
                                _polylineCoordinates[0] = _currentPosition!;
                              }
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
                                    DateTime.now()
                                            .difference(_lastFetchTime!)
                                            .inSeconds >
                                        15)) {
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
          final busDoc = await FirebaseFirestore.instance
              .collection('Buses')
              .doc(busId)
              .get();
          routeId = busDoc.data()?['routeId'] ?? dData['AssignedRouteId'];
        }
      } else {
        final busDoc = await FirebaseFirestore.instance
            .collection('Buses')
            .doc(busId)
            .get();
        if (busDoc.exists) routeId = busDoc.data()?['routeId'];
      }

      if (routeId == null) return;

      final collectionName = isSpecial ? 'SpecialTrips' : 'Routes';
      final routeDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(routeId)
          .get();
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
            {
              'name': destName,
              'lat': destLat,
              'lng': destLng,
              'order': (stops?.length ?? 0) + 1,
            },
          ];
        }
      } else {
        stops = routeDoc.data()?['Stops'] as List<dynamic>?;
      }
      if (stops == null || stops.isEmpty) return;

      List<dynamic> waypoints = [];
      dynamic destination;
      Set<Marker> newMarkers = {};

      int targetIndex = stops.length - 1;
      if (_assignedStopName != null) {
        int idx = stops.indexWhere((s) => s['name'] == _assignedStopName);
        if (idx != -1) {
          targetIndex = idx;
        }
      }

      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        LatLng? pos;

        if (stop['lat'] != null && stop['lng'] != null) {
          pos = LatLng(
            (stop['lat'] as num).toDouble(),
            (stop['lng'] as num).toDouble(),
          );
        }

        final isTarget =
            _assignedStopName != null && stop['name'] == _assignedStopName;

        if (pos != null) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('stop_${i}_${stop['name']}'),
              position: pos,
              infoWindow: InfoWindow(title: stop['name']),
              zIndex: 1.0,
              icon: isTarget
                  ? (_stopIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ))
                  : (_intermediateStopIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        )),
            ),
          );
        }

        // We only want the polyline up to the target stop.
        if (i == targetIndex) {
          destination = pos ?? stop['name'].toString();
        } else if (i < targetIndex) {
          // If the bus hasn't passed this intermediate stop, add it as a waypoint
          if (!_passedStops.contains(stop['name'])) {
            waypoints.add(pos ?? stop['name'].toString());
          }
        }
      }

      if (mounted) setState(() => _stopMarkers = newMarkers);

      // If trip is not active or bus has already passed the target stop, we don't draw polyline/ETA
      if (!_tripActive || (_assignedStopName != null && _passedStops.contains(_assignedStopName))) {
        if (mounted) {
          setState(() {
            _polylineCoordinates.clear();
            _distance = "";
            _duration = "";
          });
        }
        return;
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
          _polylineCoordinates = List<LatLng>.from(dirData['polylineCoordinates']);
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
                      zIndex: 2.0,
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
                      zIndex: 1.0,
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
                      width: 10,
                      zIndex: 0,
                      points: _polylineCoordinates,
                    ),
                },
              ),
            ),

            // TOP BAR
            Positioned(
              top: 8,
              left: 8,
              child: const CustomBackButton(),
            ),

            // BUS STATUS CARD
            Positioned(top: 90, left: 16, right: 16, child: _busStatusCard()),

            // CHECK SEATS BUTTON
            Positioned(
              bottom: 100,
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

            // BOTTOM NAV
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNav(userId: widget.userId, activeTab: NavTab.map),
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

            final timestamp = busData['statusUpdatedAt'];
            final DateTime? lastUpdated = timestamp != null && timestamp is Timestamp
                ? timestamp.toDate()
                : null;
            final String footerText = lastUpdated != null
                ? "Last updated: ${_formatTime(lastUpdated)}"
                : "";
            
            final tripActive = busData['tripActive'] == true;

            // ETA Logic
            String? etaInfo;
            String? etaUpdatedTime;
            if (tripActive && _distance.isNotEmpty && _duration.isNotEmpty) {
              etaInfo = "Arriving in $_duration ($_distance)";
              if (_lastFetchTime != null) {
                etaUpdatedTime = "ETA updated: ${_formatTime(_lastFetchTime!)}";
              }
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
                  etaUpdatedTime: etaUpdatedTime,
                );

              case "BREAKDOWN":
                return _statusContainer(
                  title: "Bus Breakdown",
                  subtitle: "Please wait for updates",
                  footer: footerText,
                  color: Colors.white,
                  titleColor: Colors.red,
                  etaText: etaInfo,
                  etaUpdatedTime: etaUpdatedTime,
                );

              default:
                return _statusContainer(
                  title: "Bus On the Way",
                  subtitle: "Arriving as scheduled",
                  footer: footerText,
                  color: Colors.white,
                  titleColor: Colors.green,
                  etaText: etaInfo,
                  etaUpdatedTime: etaUpdatedTime,
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
    String? etaUpdatedTime,
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
            height: (etaText != null)
                ? (etaUpdatedTime != null ? 160 : 140)
                : 100, // Dynamic height
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            etaText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          if (etaUpdatedTime != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              etaUpdatedTime,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ],
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

}
